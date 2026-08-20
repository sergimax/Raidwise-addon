-- Persist party and raid encounters in RaidwiseDB.history (keyed by GUID).
-- Personal player rating catalog and helpers live in this file so they load
-- together with history persistence (avoids a separate toc entry).

local Addon = Raidwise

local OPINION_ORDER = { "positive", "neutral", "negative" }

local OPINIONS = {
	positive = {
		id = "positive",
		labelKey = "RATING_OPINION_POSITIVE",
		symbol = "+",
		color = { 0.35, 0.90, 0.35 },
	},
	neutral = {
		id = "neutral",
		labelKey = "RATING_OPINION_NEUTRAL",
		symbol = "=",
		color = { 0.90, 0.82, 0.35 },
	},
	negative = {
		id = "negative",
		labelKey = "RATING_OPINION_NEGATIVE",
		symbol = "-",
		color = { 0.95, 0.35, 0.35 },
	},
}

local TAG_GROUPS = {
	{
		id = "organization",
		labelKey = "RATING_GROUP_ORGANIZATION",
		tags = {
			{ id = "raid_leader", labelKey = "RATING_TAG_RAID_LEADER", meta = "fact" },
			{ id = "raid_organizer", labelKey = "RATING_TAG_RAID_ORGANIZER", meta = "fact" },
			{ id = "pug_leader", labelKey = "RATING_TAG_PUG_LEADER", meta = "fact" },
			{ id = "good_raid_leader", labelKey = "RATING_TAG_GOOD_RAID_LEADER", meta = "positive" },
			{ id = "well_organized", labelKey = "RATING_TAG_WELL_ORGANIZED", meta = "positive" },
			{ id = "poor_organization", labelKey = "RATING_TAG_POOR_ORGANIZATION", meta = "negative" },
			{ id = "bad_raid_leader", labelKey = "RATING_TAG_BAD_RAID_LEADER", meta = "negative" },
		},
	},
	{
		id = "behavior",
		labelKey = "RATING_GROUP_BEHAVIOR",
		tags = {
			{ id = "friendly", labelKey = "RATING_TAG_FRIENDLY", meta = "positive" },
			{ id = "helpful", labelKey = "RATING_TAG_HELPFUL", meta = "positive" },
			{ id = "respectful", labelKey = "RATING_TAG_RESPECTFUL", meta = "positive" },
			{ id = "reliable", labelKey = "RATING_TAG_RELIABLE", meta = "positive" },
			{ id = "toxic", labelKey = "RATING_TAG_TOXIC", meta = "negative" },
			{ id = "rude", labelKey = "RATING_TAG_RUDE", meta = "negative" },
			{ id = "aggressive", labelKey = "RATING_TAG_AGGRESSIVE", meta = "negative" },
			{ id = "drama", labelKey = "RATING_TAG_DRAMA", meta = "negative" },
		},
	},
	{
		id = "trust",
		labelKey = "RATING_GROUP_TRUST",
		tags = {
			{ id = "trustworthy", labelKey = "RATING_TAG_TRUSTWORTHY", meta = "positive" },
			{ id = "honest", labelKey = "RATING_TAG_HONEST", meta = "positive" },
			{ id = "fair", labelKey = "RATING_TAG_FAIR", meta = "positive" },
			{ id = "scammer", labelKey = "RATING_TAG_SCAMMER", meta = "negative" },
			{ id = "liar", labelKey = "RATING_TAG_LIAR", meta = "negative" },
			{ id = "untrustworthy", labelKey = "RATING_TAG_UNTRUSTWORTHY", meta = "negative" },
		},
	},
	{
		id = "loot",
		labelKey = "RATING_GROUP_LOOT",
		tags = {
			{ id = "fair_loot", labelKey = "RATING_TAG_FAIR_LOOT", meta = "positive" },
			{ id = "good_loot_master", labelKey = "RATING_TAG_GOOD_LOOT_MASTER", meta = "positive" },
			{ id = "ninja_looter", labelKey = "RATING_TAG_NINJA_LOOTER", meta = "negative" },
			{ id = "loot_drama", labelKey = "RATING_TAG_LOOT_DRAMA", meta = "negative" },
			{ id = "unfair_loot", labelKey = "RATING_TAG_UNFAIR_LOOT", meta = "negative" },
		},
	},
	{
		id = "discipline",
		labelKey = "RATING_GROUP_DISCIPLINE",
		tags = {
			{ id = "on_time", labelKey = "RATING_TAG_ON_TIME", meta = "positive" },
			{ id = "prepared", labelKey = "RATING_TAG_PREPARED", meta = "positive" },
			{ id = "follows_instructions", labelKey = "RATING_TAG_FOLLOWS_INSTRUCTIONS", meta = "positive" },
			{ id = "late", labelKey = "RATING_TAG_LATE", meta = "negative" },
			{ id = "afk", labelKey = "RATING_TAG_AFK", meta = "negative" },
			{ id = "leaves_early", labelKey = "RATING_TAG_LEAVES_EARLY", meta = "negative" },
			{ id = "rage_quit", labelKey = "RATING_TAG_RAGE_QUIT", meta = "negative" },
		},
	},
	{
		id = "gameplay",
		labelKey = "RATING_GROUP_GAMEPLAY",
		tags = {
			{ id = "good_player", labelKey = "RATING_TAG_GOOD_PLAYER", meta = "positive" },
			{ id = "experienced", labelKey = "RATING_TAG_EXPERIENCED", meta = "fact" },
			{ id = "good_dps", labelKey = "RATING_TAG_GOOD_DPS", meta = "positive" },
			{ id = "good_tank", labelKey = "RATING_TAG_GOOD_TANK", meta = "positive" },
			{ id = "good_healer", labelKey = "RATING_TAG_GOOD_HEALER", meta = "positive" },
			{ id = "poor_performance", labelKey = "RATING_TAG_POOR_PERFORMANCE", meta = "negative" },
			{ id = "poor_mechanics", labelKey = "RATING_TAG_POOR_MECHANICS", meta = "negative" },
		},
	},
}

local META_COLORS = {
	fact = { 0.75, 0.75, 0.75 },
	positive = { 0.35, 0.90, 0.35 },
	negative = { 0.95, 0.35, 0.35 },
}

local TAGS_BY_ID = {}
for _, group in ipairs(TAG_GROUPS) do
	for _, tag in ipairs(group.tags) do
		tag.groupId = group.id
		tag.groupLabelKey = group.labelKey
		TAGS_BY_ID[tag.id] = tag
	end
end

function Addon:RatingDefaultPersonal()
	return {
		opinion = "neutral",
		tags = {},
		updatedAt = 0,
	}
end

function Addon:EnsurePersonalRating(entry)
	if type(entry) ~= "table" then
		return self:RatingDefaultPersonal()
	end
	if type(entry.rating) ~= "table" then
		entry.rating = {}
	end
	if type(entry.rating.personal) ~= "table" then
		entry.rating.personal = self:RatingDefaultPersonal()
	end
	local personal = entry.rating.personal
	personal.opinion = self:NormalizePersonalOpinion(personal.opinion)
	personal.tags = self:NormalizePersonalTags(personal.tags)
	personal.updatedAt = tonumber(personal.updatedAt) or 0
	return personal
end

function Addon:NormalizePersonalOpinion(opinion)
	if OPINIONS[opinion] then
		return opinion
	end
	return "neutral"
end

function Addon:IsValidPersonalTag(tagId)
	return TAGS_BY_ID[tagId] ~= nil
end

function Addon:NormalizePersonalTags(tags)
	local normalized = {}
	local seen = {}
	if type(tags) ~= "table" then
		return normalized
	end
	for index = 1, #tags do
		local tagId = tags[index]
		if self:IsValidPersonalTag(tagId) and not seen[tagId] then
			seen[tagId] = true
			normalized[#normalized + 1] = tagId
		end
	end
	table.sort(normalized, function(left, right)
		local leftTag = TAGS_BY_ID[left]
		local rightTag = TAGS_BY_ID[right]
		if leftTag and rightTag and leftTag.groupId ~= rightTag.groupId then
			return leftTag.groupId < rightTag.groupId
		end
		return left < right
	end)
	return normalized
end

function Addon:GetPersonalRating(entryOrMember)
	if type(entryOrMember) ~= "table" then
		return self:RatingDefaultPersonal()
	end
	-- Always prefer the live history row by GUID so profile labels are not stuck
	-- on a stale member.rating snapshot from when the window opened.
	local guid = entryOrMember.guid
	if type(guid) == "string" and guid ~= "" and self.GetHistoryEntry then
		local saved = self:GetHistoryEntry(guid)
		if type(saved) == "table" and type(saved.rating) == "table" and type(saved.rating.personal) == "table" then
			entryOrMember = saved
		end
	end
	if type(entryOrMember.rating) == "table" and type(entryOrMember.rating.personal) == "table" then
		local personal = entryOrMember.rating.personal
		return {
			opinion = self:NormalizePersonalOpinion(personal.opinion),
			tags = self:NormalizePersonalTags(personal.tags),
			updatedAt = tonumber(personal.updatedAt) or 0,
		}
	end
	return self:RatingDefaultPersonal()
end

function Addon:RatingOpinions()
	return OPINION_ORDER, OPINIONS
end

function Addon:RatingTagGroups()
	return TAG_GROUPS
end

function Addon:RatingTagById(tagId)
	return TAGS_BY_ID[tagId]
end

function Addon:RatingMetaColor(meta)
	return META_COLORS[meta] or META_COLORS.fact
end

function Addon:RatingColorHex(color)
	if type(color) ~= "table" then
		return "ffffff"
	end
	local red = math.floor((color[1] or 1) * 255 + 0.5)
	local green = math.floor((color[2] or 1) * 255 + 0.5)
	local blue = math.floor((color[3] or 1) * 255 + 0.5)
	return string.format("%02x%02x%02x", red, green, blue)
end

function Addon:RatingWrapColor(text, color)
	if not text or text == "" then
		return ""
	end
	return "|cff" .. self:RatingColorHex(color) .. text .. "|r"
end

function Addon:RatingTagColoredLabel(tagId)
	local tag = TAGS_BY_ID[tagId]
	if not tag then
		return tostring(tagId or "")
	end
	return self:RatingWrapColor(self:T(tag.labelKey), self:RatingMetaColor(tag.meta))
end

function Addon:RatingOpinionLabel(opinion)
	local data = OPINIONS[self:NormalizePersonalOpinion(opinion)] or OPINIONS.neutral
	return self:T(data.labelKey)
end

function Addon:RatingOpinionColor(opinion)
	local data = OPINIONS[self:NormalizePersonalOpinion(opinion)] or OPINIONS.neutral
	return data.color
end

function Addon:RatingOpinionSymbol(opinion)
	local data = OPINIONS[self:NormalizePersonalOpinion(opinion)] or OPINIONS.neutral
	return data.symbol
end

function Addon:RatingTagLabel(tagId)
	local tag = TAGS_BY_ID[tagId]
	if not tag then
		return tostring(tagId or "")
	end
	return self:T(tag.labelKey)
end

function Addon:RatingTagSummary(tags, limit)
	limit = tonumber(limit) or 2
	local normalized = self:NormalizePersonalTags(tags)
	if #normalized == 0 then
		return ""
	end
	local parts = {}
	local maxCount = math.min(#normalized, limit)
	for index = 1, maxCount do
		parts[#parts + 1] = self:RatingTagLabel(normalized[index])
	end
	local summary = table.concat(parts, ", ")
	if #normalized > limit then
		summary = summary .. self:T("RATING_TAGS_MORE", #normalized - limit)
	end
	return summary
end

function Addon:RatingTagColoredSummary(tags, limit)
	limit = tonumber(limit) or 2
	local normalized = self:NormalizePersonalTags(tags)
	if #normalized == 0 then
		return ""
	end
	local parts = {}
	local maxCount = math.min(#normalized, limit)
	for index = 1, maxCount do
		parts[#parts + 1] = self:RatingTagColoredLabel(normalized[index])
	end
	local summary = table.concat(parts, ", ")
	if #normalized > limit then
		summary = summary .. self:T("RATING_TAGS_MORE", #normalized - limit)
	end
	return summary
end

function Addon:RatingDisplayText(entryOrMember)
	local personal = self:GetPersonalRating(entryOrMember)
	local opinion = self:RatingOpinionLabel(personal.opinion)
	if #personal.tags == 0 then
		return opinion
	end
	return self:T("RATING_DISPLAY_WITH_TAGS", opinion, tostring(#personal.tags))
end

function Addon:RatingProfileSummary(entryOrMember)
	local personal = self:GetPersonalRating(entryOrMember)
	local opinion = self:RatingWrapColor(
		self:RatingOpinionLabel(personal.opinion),
		self:RatingOpinionColor(personal.opinion)
	)
	if #personal.tags == 0 then
		return self:T("RATING_PROFILE_SUMMARY", opinion, self:T("RATING_TAGS_NONE"))
	end
	return self:T("RATING_PROFILE_SUMMARY", opinion, self:RatingTagColoredSummary(personal.tags, 3))
end

function Addon:MergeRatingIntoMember(member)
	if type(member) ~= "table" then
		return member
	end
	local guid = member.guid
	local saved = guid and self.GetHistoryEntry and self:GetHistoryEntry(guid) or nil
	local source = saved or member
	member.rating = {
		personal = self:GetPersonalRating(source),
	}
	return member
end

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
	if not timestamp or timestamp <= 0 then
		return "-"
	end
	return date("%Y-%m-%d %H:%M", timestamp)
end

local MAX_PROFILE_HISTORY_CHANGES = 50

local function TagsEqual(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	end
	if #left ~= #right then
		return false
	end
	local seen = {}
	for index = 1, #left do
		seen[left[index]] = (seen[left[index]] or 0) + 1
	end
	for index = 1, #right do
		local tagId = right[index]
		if not seen[tagId] or seen[tagId] <= 0 then
			return false
		end
		seen[tagId] = seen[tagId] - 1
	end
	return true
end

function Addon:AppendProfileHistoryChange(entry, kind, detail)
	if type(entry) ~= "table" or not kind or kind == "" then
		return
	end
	EnsureHistoryFields(entry)
	entry.changes[#entry.changes + 1] = {
		at = time(),
		kind = kind,
		detail = detail or "",
	}
	while #entry.changes > MAX_PROFILE_HISTORY_CHANGES do
		table.remove(entry.changes, 1)
	end
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
			race = (seed and seed.race) or "",
			faction = (seed and seed.faction) or "",
			gender = seed and seed.gender or nil,
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
	CopyIfValue(entry, member, "race")
	CopyIfValue(entry, member, "faction")
	if member.gender then
		entry.gender = member.gender
	end
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
		if not profile.race or profile.race == "" then
			profile.race = saved.race
		end
		if not profile.faction or profile.faction == "" then
			profile.faction = saved.faction
		end
		if not profile.gender and saved.gender then
			profile.gender = saved.gender
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
		if type(saved.changes) == "table" then
			profile.changes = saved.changes
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
	local previousOpinion = personal.opinion
	local previousTags = {}
	for index = 1, #personal.tags do
		previousTags[index] = personal.tags[index]
	end
	if seed then
		CopyIfValue(entry, seed, "name")
		CopyIfValue(entry, seed, "class")
		CopyIfValue(entry, seed, "classLabel")
		CopyIfValue(entry, seed, "spec")
		CopyIfValue(entry, seed, "specIcon")
		CopyIfValue(entry, seed, "race")
		CopyIfValue(entry, seed, "faction")
		if seed.gender then
			entry.gender = seed.gender
		end
		CopyIfValue(entry, seed, "guildName")
		CopyIfValue(entry, seed, "guildRank")
		if CharacterRealm(seed) ~= "" then
			entry.realm = CharacterRealm(seed)
		end
	end
	personal.opinion = self:NormalizePersonalOpinion(opinion)
	personal.tags = self:NormalizePersonalTags(tagIds)
	personal.updatedAt = time()
	if previousOpinion ~= personal.opinion then
		self:AppendProfileHistoryChange(entry, "opinion", personal.opinion)
	end
	if not TagsEqual(previousTags, personal.tags) then
		local tagSummary = self.RatingTagSummary and self:RatingTagSummary(personal.tags, 5) or ""
		self:AppendProfileHistoryChange(entry, "tags", tagSummary)
	end
	return entry
end

function Addon:SaveProfileNotesForGuid(guid, seed, notes)
	if not guid or guid == "" then
		return nil
	end
	local entry = self:EnsureHistoryEntryForGuid(guid, seed)
	if not entry then
		return nil
	end
	local previousNotes = entry.notes or ""
	if seed then
		CopyIfValue(entry, seed, "name")
		CopyIfValue(entry, seed, "class")
		CopyIfValue(entry, seed, "classLabel")
		CopyIfValue(entry, seed, "spec")
		CopyIfValue(entry, seed, "specIcon")
		CopyIfValue(entry, seed, "race")
		CopyIfValue(entry, seed, "faction")
		if seed.gender then
			entry.gender = seed.gender
		end
		CopyIfValue(entry, seed, "guildName")
		CopyIfValue(entry, seed, "guildRank")
		if CharacterRealm(seed) ~= "" then
			entry.realm = CharacterRealm(seed)
		end
	end
	entry.notes = type(notes) == "string" and notes or ""
	if previousNotes ~= entry.notes then
		self:AppendProfileHistoryChange(entry, "notes", "")
	end
	return entry
end
