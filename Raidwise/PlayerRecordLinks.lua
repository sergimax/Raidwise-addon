-- Active associations and profile deletion; legacy CharacterLinks keeps display helpers.
local Addon = Raidwise

local function GroupFor(key)
	local store = Addon:GetPlayerRecordStore()
	for id, group in pairs(store and store.groups or {}) do
		if group.members[key] then return group, id end
	end
end

local function Normalize(group, id)
	local store = Addon:GetPlayerRecordStore()
	local count, first = 0, nil
	for key in pairs(group.members) do
		count = count + 1
		if not first or key < first then first = key end
	end
	if count < 2 then store.groups[id] = nil
	elseif not group.members[group.mainKey] then group.mainKey = first end
end

function Addon:InitializeCharacterLinks()
	local store = self:GetPlayerRecordStore()
	if not store then return end
	for id, group in pairs(store.groups) do Normalize(group, id) end
end

local function Log(key, kind, detail)
	local store = Addon:GetPlayerRecordStore()
	local actorGuid = type(UnitGUID) == "function" and UnitGUID("player")
	local name, realm
	if type(UnitName) == "function" then name, realm = UnitName("player") end
	store.nextId = store.nextId + 1
	store.changes[key] = store.changes[key] or {}
	store.changes[key][#store.changes[key] + 1] = {id=tostring(store.nextId), at=time(), kind=kind,
		detail=detail, actor={guid=actorGuid, name=name, realm=realm or GetRealmName()}}
end

function Addon:GetLinkedCharacters(key)
	local store = self:GetPlayerRecordStore()
	local group = key and GroupFor(key)
	local result = {}
	for memberKey in pairs(group and group.members or key and {[key]=true} or {}) do
		local entry = store and store.identities[memberKey]
		if entry then
			result[#result + 1] = {guid=memberKey, entry=entry,
				role=(not group or group.mainKey == memberKey) and "main" or "alt"}
		end
	end
	table.sort(result, function(left, right)
		if left.role ~= right.role then return left.role == "main" end
		return self:LinkedCharacterName(left.entry) < self:LinkedCharacterName(right.entry)
	end)
	return result
end

function Addon:GetCharacterLinkCandidates(key, search)
	local store = self:GetPlayerRecordStore()
	local group = GroupFor(key)
	local result = {}
	search = (strlower or string.lower)(search or "")
	for candidateKey, entry in pairs(store and store.identities or {}) do
		if candidateKey ~= key and not (group and group.members[candidateKey])
			and (strlower or string.lower)(self:LinkedCharacterName(entry)):find(search, 1, true) then
			result[#result + 1] = entry
		end
	end
	table.sort(result, function(left, right) return self:LinkedCharacterName(left) < self:LinkedCharacterName(right) end)
	return result
end

function Addon:LinkPlayerCharacters(key, otherKey, seed)
	local store = self:GetPlayerRecordStore()
	if not store or type(key) ~= "string" or not store.identities[key]
		or type(otherKey) ~= "string" or otherKey == "" then return false, "CHAR_LINK_INVALID" end
	if key == otherKey then return false, "CHAR_LINK_SELF" end
	local group, id = GroupFor(key)
	local otherGroup = GroupFor(otherKey)
	if group and group == otherGroup then return false, "CHAR_LINK_EXISTS" end
	if otherGroup then return false, "CHAR_LINK_OTHER_GROUP" end
	local other = self:EnsureHistoryEntryForGuid(otherKey, seed)
	if not other then return false, "CHAR_LINK_INVALID" end
	otherKey = other.guid
	-- A target can resolve the source's name-only identity to its real GUID.
	if not store.identities[key] then return false, "CHAR_LINK_SELF" end
	if otherKey == key then return false, "CHAR_LINK_SELF" end
	otherGroup = GroupFor(otherKey)
	if group and group == otherGroup then return false, "CHAR_LINK_EXISTS" end
	if otherGroup then return false, "CHAR_LINK_OTHER_GROUP" end
	if not group then
		store.nextId = store.nextId + 1
		id = tostring(store.nextId)
		group = {members={[key]=true}, mainKey=key}
		store.groups[id] = group
	end
	for memberKey in pairs(group.members) do
		Log(memberKey, "character_link", self:LinkedCharacterName(other))
		Log(otherKey, "character_link", self:LinkedCharacterName(store.identities[memberKey]))
	end
	group.members[otherKey] = true
	return true
end

function Addon:UnlinkPlayerCharacter(key, otherKey)
	local group, id = GroupFor(key)
	if not group or not group.members[otherKey] then return false, "CHAR_LINK_INVALID" end
	if group.mainKey == otherKey then return false, "CHAR_LINK_MAIN_REQUIRED" end
	local store = self:GetPlayerRecordStore()
	for memberKey in pairs(group.members) do
		if memberKey ~= otherKey then
			Log(memberKey, "character_unlink", self:LinkedCharacterName(store.identities[otherKey]))
			Log(otherKey, "character_unlink", self:LinkedCharacterName(store.identities[memberKey]))
		end
	end
	group.members[otherKey] = nil
	Normalize(group, id)
	return true
end

function Addon:SetLinkedCharacterRole(key, memberKey, role)
	local group = GroupFor(key)
	if not group or not group.members[memberKey] or (role ~= "main" and role ~= "alt") then return false, "CHAR_LINK_INVALID" end
	if group.mainKey == memberKey then
		if role == "alt" then return false, "CHAR_LINK_MAIN_REQUIRED" end
		return true
	end
	if role == "main" then
		group.mainKey = memberKey
		for target in pairs(group.members) do
			Log(target, "character_role", {name=self:LinkedCharacterName(self:GetHistoryEntry(memberKey)), role="main"})
		end
	end
	return true
end

function Addon:DeleteCharacterDatabaseRecords(keys)
	local store = self:GetPlayerRecordStore()
	if not store then return 0 end
	if not keys then
		keys = {}
		for key in pairs(store.identities) do
			if self:IsPlayerRecordFilled(key) then keys[#keys + 1] = key end
		end
	end
	local removed, count = {}, 0
	for _, key in ipairs(keys) do
		local group = GroupFor(key)
		local openFrame = self.raidDetailFrame
		local isOpen = openFrame and openFrame.profileMember and openFrame.profileMember.guid == key
		if not removed[key] and store.identities[key]
			and (store.profiles[key] or store.notes[key] or store.changes[key] or group or isOpen) then
			removed[key], count = true, count + 1
			-- Tombstone invalidates every existing core draft, including note-only drafts.
			store.generations[key] = (store.generations[key] or 0) + 1
			if self.DiscardProfileEdits then self:DiscardProfileEdits(key) end
			store.profiles[key], store.notes[key], store.changes[key] = nil, nil, nil
		end
	end
	if count == 0 then return 0 end
	for id, group in pairs(store.groups) do
		for key in pairs(removed) do group.members[key] = nil end
		Normalize(group, id)
	end
	local frame = self.raidDetailFrame
	if frame and frame.profileMember and removed[frame.profileMember.guid] then
		frame.profileDraft, frame.profileMember, frame.pendingCharacterLink = nil, nil, nil
		if frame.notesBox and frame.notesBox.ClearFocus then frame.notesBox:ClearFocus() end
		frame:Hide()
	end
	if self.RefreshRatingViews then self:RefreshRatingViews() end
	if self.RefreshHistoryView then self:RefreshHistoryView() end
	return count
end
