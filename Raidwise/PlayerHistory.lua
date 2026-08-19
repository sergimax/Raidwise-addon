-- Persist party and raid encounters in RaidwiseDB.history (keyed by GUID).

local Addon = Raidwise

local function CopyIfValue(dest, src, key)
	local value = src[key]
	if value == nil or value == "" then
		return
	end
	dest[key] = value
end

local function MeetingZone()
	if type(GetInstanceInfo) == "function" then
		local name, instanceType = GetInstanceInfo()
		if name and name ~= "" and (instanceType == "raid" or instanceType == "party") then
			return name
		end
	end
	if type(GetRealZoneText) == "function" then
		local zone = GetRealZoneText()
		if zone and zone ~= "" then
			return zone
		end
	end
	if type(GetZoneText) == "function" then
		return GetZoneText() or ""
	end
	return ""
end

local function MeetingRealm()
	if type(GetRealmName) == "function" then
		return GetRealmName() or ""
	end
	return ""
end

local function CharacterRealm(member)
	if member and member.realm and member.realm ~= "" then
		return member.realm
	end
	return MeetingRealm()
end

local function GroupHistoryUnits()
	local units = {}
	local raidCount = (GetNumRaidMembers and GetNumRaidMembers()) or 0
	if raidCount > 0 then
		for index = 1, raidCount do
			local unit = "raid" .. index
			if UnitExists(unit) and not UnitIsUnit(unit, "player") then
				units[#units + 1] = unit
			end
		end
		return units
	end

	local partyCount = math.min(GetNumPartyMembers() or 0, 4)
	for index = 1, partyCount do
		local unit = "party" .. index
		if UnitExists(unit) then
			units[#units + 1] = unit
		end
	end
	return units
end

function Addon:HistoryStore()
	if not self.db then
		return {}
	end
	if type(self.db.history) ~= "table" then
		self.db.history = {}
	end
	return self.db.history
end

function Addon:FormatHistoryTime(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp then
		return "-"
	end
	return date("%Y-%m-%d %H:%M", timestamp)
end

function Addon:GetHistoryEntry(guid)
	if not guid or guid == "" then
		return nil
	end
	return self:HistoryStore()[guid]
end

local function EnsureHistoryFields(entry)
	if type(entry.notes) ~= "string" then
		entry.notes = ""
	end
	if type(entry.tags) ~= "table" then
		entry.tags = {}
	end
	if type(entry.links) ~= "table" then
		entry.links = {}
	end
	if type(entry.changes) ~= "table" then
		entry.changes = {}
	end
	if Addon.EnsurePersonalRating then
		Addon:EnsurePersonalRating(entry)
	end
	return entry
end

function Addon:EnsureHistoryEntryForGuid(guid, seed)
	if not guid or guid == "" then
		return nil
	end
	local store = self:HistoryStore()
	local entry = store[guid]
	if not entry then
		entry = {
			guid = guid,
			name = (seed and seed.name) or "?",
			realm = (seed and CharacterRealm(seed)) or "",
			class = (seed and seed.class) or "",
			classLabel = (seed and seed.classLabel) or "",
			spec = (seed and seed.spec) or "",
			specIcon = (seed and seed.specIcon) or "",
			gearScore = seed and seed.gearScore or nil,
			averageIlvl = seed and seed.averageIlvl or nil,
			guildName = seed and seed.guildName or nil,
			guildRank = seed and seed.guildRank or nil,
			notes = "",
			tags = {},
			links = {},
			changes = {},
			metZone = "",
			metAt = 0,
			metRealm = "",
			lastSeenAt = 0,
			lastSeenZone = "",
		}
		store[guid] = entry
	end
	return EnsureHistoryFields(entry)
end

function Addon:UpsertHistoryMember(member)
	if type(member) ~= "table" then
		return nil
	end

	local guid = member.guid
	if not guid or guid == "" then
		return nil
	end

	local entry = self:EnsureHistoryEntryForGuid(guid, member)
	local now = time()
	local zone = MeetingZone()
	local metRealm = MeetingRealm()

	if not entry.metAt or entry.metAt <= 0 then
		entry.metZone = zone
		entry.metAt = now
		entry.metRealm = metRealm
		entry.lastSeenAt = now
		entry.lastSeenZone = zone
		return entry
	end

	EnsureHistoryFields(entry)
	CopyIfValue(entry, member, "name")
	CopyIfValue(entry, member, "class")
	CopyIfValue(entry, member, "classLabel")
	CopyIfValue(entry, member, "spec")
	CopyIfValue(entry, member, "specIcon")
	CopyIfValue(entry, member, "guildName")
	CopyIfValue(entry, member, "guildRank")
	if CharacterRealm(member) ~= "" then
		entry.realm = CharacterRealm(member)
	end
	if member.gearScore then
		entry.gearScore = member.gearScore
	end
	if member.averageIlvl then
		entry.averageIlvl = member.averageIlvl
	end
	entry.lastSeenAt = now
	if zone ~= "" then
		entry.lastSeenZone = zone
	end
	return entry
end

function Addon:RecordCurrentGroupHistory(refreshGearScore)
	if not self.db then
		return
	end

	local collect = self.CollectPartyMember or self.CollectRaidMember
	for _, unit in ipairs(GroupHistoryUnits()) do
		local member
		if collect then
			local ok, snapshot = pcall(collect, self, unit, refreshGearScore)
			if ok and type(snapshot) == "table" then
				member = snapshot
			end
		end
		if not member then
			local name, realm = UnitName(unit)
			local localizedClass, classToken = UnitClass(unit)
			member = {
				unit = unit,
				guid = UnitGUID(unit) or "",
				name = name or "?",
				realm = realm or "",
				class = classToken or "",
				classLabel = localizedClass or "",
			}
		end
		self:UpsertHistoryMember(member)
	end

	local frame = self.mainFrame
	if frame and frame:IsShown() and frame.selectedTab == "history" and self.RefreshHistoryView then
		self:RefreshHistoryView()
	end
end

function Addon:BuildHistoryRoster()
	local roster = {}
	local store = self:HistoryStore()
	for _, entry in pairs(store) do
		if type(entry) == "table" then
			roster[#roster + 1] = EnsureHistoryFields(entry)
		end
	end

	table.sort(roster, function(left, right)
		local leftSeen = tonumber(left.lastSeenAt) or 0
		local rightSeen = tonumber(right.lastSeenAt) or 0
		if leftSeen ~= rightSeen then
			return leftSeen > rightSeen
		end
		return (left.name or "") < (right.name or "")
	end)

	return roster
end

function Addon:HistoryProfileForMember(member)
	if type(member) ~= "table" then
		return member
	end

	local guid = member.guid
	if (not guid or guid == "") and member.unit then
		guid = UnitGUID(member.unit) or ""
	end

	local saved = self:GetHistoryEntry(guid)
	local profile = {}
	for key, value in pairs(member) do
		profile[key] = value
	end
	profile.guid = guid or ""

	if saved then
		if not profile.metZone or profile.metZone == "" then
			profile.metZone = saved.metZone
		end
		if not profile.metAt then
			profile.metAt = saved.metAt
		end
		if not profile.metRealm or profile.metRealm == "" then
			profile.metRealm = saved.metRealm
		end
		if (not profile.spec or profile.spec == "") and saved.spec and saved.spec ~= "" then
			profile.spec = saved.spec
			profile.specIcon = saved.specIcon
		end
		if not profile.gearScore and saved.gearScore then
			profile.gearScore = saved.gearScore
		end
		if not profile.averageIlvl and saved.averageIlvl then
			profile.averageIlvl = saved.averageIlvl
		end
		if type(saved.notes) == "string" then
			profile.notes = saved.notes
		end
		if type(saved.tags) == "table" and #saved.tags > 0 then
			profile.tags = saved.tags
		end
		if type(saved.links) == "table" then
			profile.links = saved.links
		end
		if saved.rating then
			profile.rating = {
				personal = self.GetPersonalRating and self:GetPersonalRating(saved) or saved.rating.personal,
			}
		end
	end

	if self.GetPersonalRating then
		profile.rating = profile.rating or {}
		profile.rating.personal = self:GetPersonalRating(profile)
	end

	return profile
end

function Addon:SavePersonalRatingForGuid(guid, seed, opinion, tagIds)
	if not guid or guid == "" then
		return nil
	end
	local entry = self:EnsureHistoryEntryForGuid(guid, seed)
	if not entry then
		return nil
	end
	local personal = self:EnsurePersonalRating(entry)
	if seed then
		CopyIfValue(entry, seed, "name")
		CopyIfValue(entry, seed, "class")
		CopyIfValue(entry, seed, "classLabel")
		CopyIfValue(entry, seed, "spec")
		CopyIfValue(entry, seed, "specIcon")
		CopyIfValue(entry, seed, "guildName")
		CopyIfValue(entry, seed, "guildRank")
		if CharacterRealm(seed) ~= "" then
			entry.realm = CharacterRealm(seed)
		end
	end
	personal.opinion = self:NormalizePersonalOpinion(opinion)
	personal.tags = self:NormalizePersonalTags(tagIds)
	personal.updatedAt = time()
	return entry
end
