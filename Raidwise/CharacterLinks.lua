-- Local, manually recorded groups of characters belonging to one player.
local Addon = Raidwise
local ROLES = { main = true, alt = true }

local function LocalMain(group, id)
	local main = Addon.db.localCharacterMains and Addon.db.localCharacterMains[id]
	if main and group.members[main] then return main end
	if group.mainGuid and group.members[group.mainGuid] then return group.mainGuid end
	main = nil
	-- Deterministic local default for groups received without a Main preference.
	for guid in pairs(group.members) do
		if not main or guid < main then main = guid end
	end
	return main
end

function Addon:InitializeCharacterLinks()
	self.db.localCharacterMains = self.db.localCharacterMains or {}
	for id, group in pairs(self.db.characterGroups or {}) do
		self.db.localCharacterMains[id] = LocalMain(group, id)
		group.mainGuid = nil
		for guid in pairs(group.members) do group.members[guid] = "alt" end
	end
end

local function GroupForGuid(guid)
	local entry = Addon:GetHistoryEntry(guid)
	local groups = Addon.db and Addon.db.characterGroups
	local group = entry and groups and groups[entry.playerGroupId]
	if group and group.members and group.members[guid] then return group, entry.playerGroupId end
end

local function EnsureGroup(guid)
	Addon:InitializeCharacterLinks()
	local group, id = GroupForGuid(guid)
	if group then return group, id end
	Addon.db.characterGroups = Addon.db.characterGroups or {}
	local nextId = tonumber(Addon.db.nextCharacterGroupId) or 0
	repeat
		nextId = nextId + 1
		id = "player-" .. tostring(nextId)
	until not Addon.db.characterGroups[id]
	Addon.db.nextCharacterGroupId = nextId
	group = { members = { [guid] = "alt" } }
	Addon.db.localCharacterMains[id] = guid
	Addon.db.characterGroups[id] = group
	Addon:GetHistoryEntry(guid).playerGroupId = id
	return group, id
end

function Addon:LinkedCharacterName(entry)
	local name = entry and entry.name or "?"
	local realm = entry and (entry.realm or entry.metRealm) or ""
	return realm ~= "" and (name .. "-" .. realm) or name
end

function Addon:GetLinkedCharacters(guid)
	local group, id = GroupForGuid(guid)
	local result = {}
	local members = group and group.members or { [guid or ""] = "main" }
	for memberGuid, role in pairs(members) do
		local entry = self:GetHistoryEntry(memberGuid)
		if entry then
			result[#result + 1] = { guid = memberGuid, entry = entry,
				role = group and (LocalMain(group, id) == memberGuid and "main" or "alt") or role }
		end
	end
	table.sort(result, function(left, right)
		if (left.role == "main") ~= (right.role == "main") then return left.role == "main" end
		local leftName, rightName = Addon:LinkedCharacterName(left.entry), Addon:LinkedCharacterName(right.entry)
		if leftName ~= rightName then return leftName < rightName end
		return left.guid < right.guid
	end)
	return result
end

-- Exchange boundary: membership only, with no local role, opinion or history.
-- Sort by GUID so choosing a different local Main cannot change this payload.
function Addon:GetSharedCharacterLinks(guid)
	local result = {}
	for _, member in ipairs(self:GetLinkedCharacters(guid)) do
		result[#result + 1] = { guid = member.guid, name = member.entry.name,
			realm = member.entry.realm or member.entry.metRealm or "" }
	end
	table.sort(result, function(left, right) return left.guid < right.guid end)
	return result
end

function Addon:GetCharacterLinkCandidates(guid, search)
	local candidates = {}
	local group = GroupForGuid(guid)
	search = string.lower(search or "")
	for memberGuid, entry in pairs(self.db and self.db.history or {}) do
		if type(entry) == "table" and memberGuid ~= guid and not (group and group.members[memberGuid]) then
			local label = self:LinkedCharacterName(entry)
			if search == "" or string.find(string.lower(label), search, 1, true) then
				candidates[#candidates + 1] = entry
			end
		end
	end
	table.sort(candidates, function(left, right)
		local leftName, rightName = Addon:LinkedCharacterName(left), Addon:LinkedCharacterName(right)
		if leftName ~= rightName then return leftName < rightName end
		return left.guid < right.guid
	end)
	return candidates
end

function Addon:LinkPlayerCharacters(guid, otherGuid, seed, chosenOpinion)
	if not self.db or not self:GetHistoryEntry(guid) or not otherGuid or otherGuid == "" then
		return false, "CHAR_LINK_INVALID"
	end
	if guid == otherGuid then return false, "CHAR_LINK_SELF" end
	local sourceGroup = GroupForGuid(guid)
	local otherGroup = GroupForGuid(otherGuid)
	if sourceGroup and sourceGroup == otherGroup then return false, "CHAR_LINK_EXISTS" end
	-- Joining two existing groups is deliberately explicit: unlink the selected
	-- character first, rather than silently moving all of its other characters.
	if otherGroup then
		local count = 0
		for _ in pairs(otherGroup.members) do count = count + 1 end
		if count > 1 then return false, "CHAR_LINK_OTHER_GROUP" end
	end
	local other = self:GetHistoryEntry(otherGuid)
	if not other and not seed then return false, "CHAR_LINK_INVALID" end
	local sourceOpinion = self:GetPersonalRating(self:GetHistoryEntry(guid)).opinion
	local otherOpinion = self:GetPersonalRating(other or seed).opinion
	if chosenOpinion ~= nil and chosenOpinion ~= "positive" and chosenOpinion ~= "negative" and chosenOpinion ~= "neutral" then
		return false, "CHAR_LINK_INVALID"
	end
	if sourceOpinion ~= otherOpinion and not chosenOpinion then return false, "CHAR_LINK_CONFLICT" end
	other = self:EnsureHistoryEntryForGuid(otherGuid, seed)
	local previousMembers = self:GetLinkedCharacters(guid)
	local group, id = EnsureGroup(guid)
	if otherGroup then
		local _, otherId = GroupForGuid(otherGuid)
		self.db.characterGroups[otherId] = nil
		self.db.localCharacterMains[otherId] = nil
	end
	group.members[otherGuid] = "alt"
	other.playerGroupId = id
	for _, member in ipairs(previousMembers) do
		self:AppendProfileHistoryChange(member.entry, "character_link", self:LinkedCharacterName(other))
		self:AppendProfileHistoryChange(other, "character_link", self:LinkedCharacterName(member.entry))
	end
	self:SyncLinkedPlayerOpinion(guid, chosenOpinion or sourceOpinion)
	return true
end

function Addon:UnlinkPlayerCharacter(guid, otherGuid)
	local group, id = GroupForGuid(guid)
	if not group or not group.members[otherGuid] then return false, "CHAR_LINK_INVALID" end
	local other = self:GetHistoryEntry(otherGuid)
	if not other then return false, "CHAR_LINK_INVALID" end
	if LocalMain(group, id) == otherGuid then return false, "CHAR_LINK_MAIN_REQUIRED" end
	for _, member in ipairs(self:GetLinkedCharacters(guid)) do
		if member.guid ~= otherGuid then
			self:AppendProfileHistoryChange(member.entry, "character_unlink", self:LinkedCharacterName(other))
			self:AppendProfileHistoryChange(other, "character_unlink", self:LinkedCharacterName(member.entry))
		end
	end
	group.members[otherGuid] = nil
	other.playerGroupId = nil
	if not next(group.members) then self.db.characterGroups[id] = nil end
	return true
end

function Addon:SetLinkedCharacterRole(guid, memberGuid, role)
	if not ROLES[role] or not self:GetHistoryEntry(guid) then return false, "CHAR_LINK_INVALID" end
	local group, id = GroupForGuid(guid)
	if guid ~= memberGuid and not (group and group.members[memberGuid]) then return false, "CHAR_LINK_INVALID" end
	group, id = EnsureGroup(guid)
	local oldRole = LocalMain(group, id) == memberGuid and "main" or "alt"
	if oldRole == role then return true end
	if role == "alt" and LocalMain(group, id) == memberGuid then return false, "CHAR_LINK_MAIN_REQUIRED" end
	if role == "main" then
		self.db.localCharacterMains[id] = memberGuid
	end
	group.members[memberGuid] = role == "main" and "alt" or role
	local entry = self:GetHistoryEntry(memberGuid)
	for _, member in ipairs(self:GetLinkedCharacters(guid)) do
		self:AppendProfileHistoryChange(member.entry, "character_role", {
			name = self:LinkedCharacterName(entry), role = role,
		})
	end
	return true
end

-- Only the opinion is shared. Tags, facts, events and private notes stay local
-- to each character. Unlinking preserves the last shared opinion as its snapshot.
function Addon:SyncLinkedPlayerOpinion(guid, opinion)
	local source = self:GetHistoryEntry(guid)
	if not source then return end
	local now = time()
	local creatorId = type(UnitGUID) == "function" and UnitGUID("player") or ""
	opinion = self:NormalizePersonalOpinion(opinion)
	for _, member in ipairs(self:GetLinkedCharacters(guid)) do
		local personal = self:EnsurePersonalRating(member.entry)
		if personal.opinion ~= opinion then
			personal.opinion = opinion
			personal.updatedAt = now
			if personal.createdAt <= 0 then personal.createdAt = now end
			personal.creatorId = creatorId or ""
			self:AppendProfileHistoryChange(member.entry, "opinion", opinion)
		end
	end
end

function Addon:BuildLinkedCharacterTooltipLines(member)
	local characters = self:GetLinkedCharacters(member and member.guid)
	if #characters < 2 then return {} end
	local lines = { self:T("CHAR_LINK_TOOLTIP") }
	for _, character in ipairs(characters) do
		local label = self:LinkedCharacterName(character.entry)
		local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[character.entry.class]
		if color then label = self:RatingWrapColor(label, { color.r, color.g, color.b }) end
		lines[#lines + 1] = self:T("CHAR_LINK_TOOLTIP_ROW", label, self:T("CHAR_ROLE_" .. string.upper(character.role)))
	end
	return lines
end
