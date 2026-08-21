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

local MAX_TAGS_PER_GROUP = 3
local MAX_PERSONAL_FACTS = 4

local TAG_GROUPS = {
	{
		id = "organization",
		labelKey = "RATING_GROUP_ORGANIZATION",
		tags = {
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
		},
	},
	{
		id = "discipline",
		labelKey = "RATING_GROUP_DISCIPLINE",
		tags = {
			{ id = "on_time", labelKey = "RATING_TAG_ON_TIME", meta = "positive" },
			{ id = "prepared", labelKey = "RATING_TAG_PREPARED", meta = "positive" },
			{ id = "follows_instructions", labelKey = "RATING_TAG_FOLLOWS_INSTRUCTIONS", meta = "positive" },
		},
	},
	{
		id = "gameplay",
		labelKey = "RATING_GROUP_GAMEPLAY",
		tags = {
			{ id = "good_player", labelKey = "RATING_TAG_GOOD_PLAYER", meta = "positive" },
			{ id = "good_dps", labelKey = "RATING_TAG_GOOD_DPS", meta = "positive" },
			{ id = "good_tank", labelKey = "RATING_TAG_GOOD_TANK", meta = "positive" },
			{ id = "good_healer", labelKey = "RATING_TAG_GOOD_HEALER", meta = "positive" },
			{ id = "poor_performance", labelKey = "RATING_TAG_POOR_PERFORMANCE", meta = "negative" },
			{ id = "poor_mechanics", labelKey = "RATING_TAG_POOR_MECHANICS", meta = "negative" },
		},
	},
}

-- Role / identity facts (not opinion tags).
local FACT_CATALOG = {
	{ id = "raid_leader", labelKey = "RATING_FACT_RAID_LEADER", meta = "fact" },
	{ id = "pug_raid_leader", labelKey = "RATING_FACT_PUG_RAID_LEADER", meta = "fact" },
	{ id = "guild_master", labelKey = "RATING_FACT_GUILD_MASTER", meta = "fact" },
	{ id = "guild_officer", labelKey = "RATING_FACT_GUILD_OFFICER", meta = "fact" },
}

local EVENT_TYPES = {
	{ id = "left_raid", labelKey = "RATING_EVENT_LEFT_RAID", lootBased = false },
	{ id = "left_early", labelKey = "RATING_EVENT_LEFT_EARLY", lootBased = false },
	{ id = "left_group", labelKey = "RATING_EVENT_LEFT_GROUP", lootBased = false },
	{ id = "rage_quit", labelKey = "RATING_EVENT_RAGE_QUIT", lootBased = false },
	{ id = "late_arrival", labelKey = "RATING_EVENT_LATE_ARRIVAL", lootBased = false },
	{ id = "afk", labelKey = "RATING_EVENT_AFK", lootBased = false },
	{ id = "no_arrival", labelKey = "RATING_EVENT_NO_ARRIVAL", lootBased = false },
	{ id = "ninja_loot", labelKey = "RATING_EVENT_NINJA_LOOT", lootBased = true },
	{ id = "loot_dispute", labelKey = "RATING_EVENT_LOOT_DISPUTE", lootBased = true },
	{ id = "unfair_loot_distribution", labelKey = "RATING_EVENT_UNFAIR_LOOT_DISTRIBUTION", lootBased = true },
	{ id = "changed_loot_rules", labelKey = "RATING_EVENT_CHANGED_LOOT_RULES", lootBased = true },
	{ id = "loot_reservation_violation", labelKey = "RATING_EVENT_LOOT_RESERVATION_VIOLATION", lootBased = true },
	{ id = "raid_abandoned", labelKey = "RATING_EVENT_RAID_ABANDONED", lootBased = false },
	{ id = "helped_player", labelKey = "RATING_EVENT_HELPED_PLAYER", lootBased = false },
	{ id = "helped_with_gear", labelKey = "RATING_EVENT_HELPED_WITH_GEAR", lootBased = false },
	{ id = "explained_mechanics", labelKey = "RATING_EVENT_EXPLAINED_MECHANICS", lootBased = false },
	{ id = "toxic_behavior", labelKey = "RATING_EVENT_TOXIC_BEHAVIOR", lootBased = false },
	{ id = "scam", labelKey = "RATING_EVENT_SCAM", lootBased = false },
}

-- Old personal.tags ids → fact / event / drop during one-shot migration.
local LEGACY_TAG_TO_FACT = {
	raid_leader = "raid_leader",
	pug_leader = "pug_raid_leader",
	pug_raid_leader = "pug_raid_leader",
	guild_master = "guild_master",
	guild_officer = "guild_officer",
}

local LEGACY_TAG_TO_EVENT = {
	late = "late_arrival",
	afk = "afk",
	leaves_early = "left_early",
	rage_quit = "rage_quit",
	ninja_looter = "ninja_loot",
	loot_drama = "loot_dispute",
	unfair_loot = "unfair_loot_distribution",
}

local LEGACY_TAG_DROP = {
	raid_organizer = true,
	experienced = true,
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

local FACTS_BY_ID = {}
for _, fact in ipairs(FACT_CATALOG) do
	FACTS_BY_ID[fact.id] = fact
end

local EVENTS_BY_ID = {}
for _, eventType in ipairs(EVENT_TYPES) do
	EVENTS_BY_ID[eventType.id] = eventType
end

local function LocalPlayerCreatorId()
	if type(UnitGUID) == "function" then
		return UnitGUID("player") or ""
	end
	return ""
end

function Addon:RatingDefaultPersonal()
	return {
		opinion = "neutral",
		tags = {},
		facts = {},
		createdAt = 0,
		updatedAt = 0,
		creatorId = "",
	}
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

function Addon:IsValidPersonalFact(factId)
	return FACTS_BY_ID[factId] ~= nil
end

function Addon:IsValidEventType(eventTypeId)
	return EVENTS_BY_ID[eventTypeId] ~= nil
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

function Addon:NormalizePersonalFacts(facts)
	local normalized = {}
	local seen = {}
	if type(facts) ~= "table" then
		return normalized
	end
	for index = 1, #facts do
		local factId = facts[index]
		if self:IsValidPersonalFact(factId) and not seen[factId] then
			seen[factId] = true
			normalized[#normalized + 1] = factId
		end
	end
	table.sort(normalized)
	while #normalized > MAX_PERSONAL_FACTS do
		table.remove(normalized)
	end
	return normalized
end

local function AppendMigratedEvent(entry, eventTypeId, eventAt, creatorId)
	if not EVENTS_BY_ID[eventTypeId] then
		return
	end
	if type(entry.events) ~= "table" then
		entry.events = {}
	end
	for index = 1, #entry.events do
		local existing = entry.events[index]
		if type(existing) == "table" and existing.type == eventTypeId and existing._migrated then
			return
		end
	end
	entry.events[#entry.events + 1] = {
		id = string.format("mig-%s-%d", eventTypeId, #entry.events + 1),
		type = eventTypeId,
		creatorId = creatorId or "",
		eventAt = tonumber(eventAt) or time(),
		context = {},
		_migrated = true,
	}
end

local function MigrateLegacyPersonalTags(entry, personal)
	if personal.reputationV2 then
		return
	end
	local rawTags = type(personal.tags) == "table" and personal.tags or {}
	local rawFacts = type(personal.facts) == "table" and personal.facts or {}
	local keptTags = {}
	local facts = {}
	local factSeen = {}
	for index = 1, #rawFacts do
		local factId = LEGACY_TAG_TO_FACT[rawFacts[index]] or rawFacts[index]
		if FACTS_BY_ID[factId] and not factSeen[factId] then
			factSeen[factId] = true
			facts[#facts + 1] = factId
		end
	end
	local eventAt = tonumber(personal.updatedAt) or time()
	local creatorId = personal.creatorId
	if type(creatorId) ~= "string" then
		creatorId = ""
	end
	for index = 1, #rawTags do
		local tagId = rawTags[index]
		local factId = LEGACY_TAG_TO_FACT[tagId]
		if factId then
			if not factSeen[factId] then
				factSeen[factId] = true
				facts[#facts + 1] = factId
			end
		elseif LEGACY_TAG_TO_EVENT[tagId] then
			AppendMigratedEvent(entry, LEGACY_TAG_TO_EVENT[tagId], eventAt, creatorId)
		elseif LEGACY_TAG_DROP[tagId] then
			-- dropped
		elseif TAGS_BY_ID[tagId] then
			keptTags[#keptTags + 1] = tagId
		end
	end
	personal.tags = keptTags
	personal.facts = facts
	personal.reputationV2 = true
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
	if type(entry.events) ~= "table" then
		entry.events = {}
	end
	local personal = entry.rating.personal
	MigrateLegacyPersonalTags(entry, personal)
	personal.opinion = self:NormalizePersonalOpinion(personal.opinion)
	personal.tags = self:NormalizePersonalTags(personal.tags)
	personal.facts = self:NormalizePersonalFacts(personal.facts)
	personal.updatedAt = tonumber(personal.updatedAt) or 0
	personal.createdAt = tonumber(personal.createdAt) or 0
	if personal.createdAt <= 0 and personal.updatedAt > 0 then
		personal.createdAt = personal.updatedAt
	end
	if type(personal.creatorId) ~= "string" then
		personal.creatorId = ""
	end
	personal.reputationV2 = true
	return personal
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
		if type(saved) == "table" then
			self:EnsurePersonalRating(saved)
			entryOrMember = saved
		end
	end
	if type(entryOrMember.rating) == "table" and type(entryOrMember.rating.personal) == "table" then
		local personal = entryOrMember.rating.personal
		return {
			opinion = self:NormalizePersonalOpinion(personal.opinion),
			tags = self:NormalizePersonalTags(personal.tags),
			facts = self:NormalizePersonalFacts(personal.facts),
			createdAt = tonumber(personal.createdAt) or 0,
			updatedAt = tonumber(personal.updatedAt) or 0,
			creatorId = type(personal.creatorId) == "string" and personal.creatorId or "",
		}
	end
	return self:RatingDefaultPersonal()
end

function Addon:GetHistoryEvents(entryOrMember)
	if type(entryOrMember) ~= "table" then
		return {}
	end
	local guid = entryOrMember.guid
	if type(guid) == "string" and guid ~= "" and self.GetHistoryEntry then
		local saved = self:GetHistoryEntry(guid)
		if type(saved) == "table" then
			entryOrMember = saved
		end
	end
	if type(entryOrMember.events) ~= "table" then
		return {}
	end
	local list = {}
	for index = 1, #entryOrMember.events do
		local event = entryOrMember.events[index]
		if type(event) == "table" and self:IsValidEventType(event.type) then
			list[#list + 1] = event
		end
	end
	table.sort(list, function(left, right)
		return (tonumber(left.eventAt) or 0) > (tonumber(right.eventAt) or 0)
	end)
	return list
end

function Addon:RatingOpinions()
	return OPINION_ORDER, OPINIONS
end

function Addon:RatingTagGroups()
	return TAG_GROUPS
end

function Addon:FactCatalog()
	return FACT_CATALOG
end

function Addon:EventTypes()
	return EVENT_TYPES
end

function Addon:MaxPersonalFacts()
	return MAX_PERSONAL_FACTS
end

function Addon:MaxTagsPerGroup()
	return MAX_TAGS_PER_GROUP
end

function Addon:RatingTagById(tagId)
	return TAGS_BY_ID[tagId]
end

function Addon:FactById(factId)
	return FACTS_BY_ID[factId]
end

function Addon:EventTypeById(eventTypeId)
	return EVENTS_BY_ID[eventTypeId]
end

function Addon:RatingMetaColor(meta)
	return META_COLORS[meta] or META_COLORS.fact
end

function Addon:FactLabel(factId)
	local fact = FACTS_BY_ID[factId]
	if not fact then
		return tostring(factId or "")
	end
	return self:T(fact.labelKey)
end

function Addon:FactColoredLabel(factId)
	local fact = FACTS_BY_ID[factId]
	if not fact then
		return tostring(factId or "")
	end
	return self:RatingWrapColor(self:T(fact.labelKey), self:RatingMetaColor(fact.meta or "fact"))
end

function Addon:FactColoredSummary(facts, limit)
	limit = tonumber(limit) or 3
	local normalized = self:NormalizePersonalFacts(facts)
	if #normalized == 0 then
		return ""
	end
	local parts = {}
	local maxCount = math.min(#normalized, limit)
	for index = 1, maxCount do
		parts[#parts + 1] = self:FactColoredLabel(normalized[index])
	end
	local summary = table.concat(parts, ", ")
	if #normalized > limit then
		summary = summary .. self:T("RATING_TAGS_MORE", #normalized - limit)
	end
	return summary
end

function Addon:FactSummary(facts, limit)
	limit = tonumber(limit) or 3
	local normalized = self:NormalizePersonalFacts(facts)
	if #normalized == 0 then
		return ""
	end
	local parts = {}
	local maxCount = math.min(#normalized, limit)
	for index = 1, maxCount do
		parts[#parts + 1] = self:FactLabel(normalized[index])
	end
	local summary = table.concat(parts, ", ")
	if #normalized > limit then
		summary = summary .. self:T("RATING_TAGS_MORE", #normalized - limit)
	end
	return summary
end

function Addon:EventTypeLabel(eventTypeId)
	local eventType = EVENTS_BY_ID[eventTypeId]
	if not eventType then
		return tostring(eventTypeId or "")
	end
	return self:T(eventType.labelKey)
end

function Addon:CaptureEventContext()
	local context = {
		zoneName = "",
		zoneId = nil,
		instanceId = nil,
		instanceName = "",
		difficulty = nil,
		itemId = nil,
		bossId = nil,
	}
	if type(GetRealZoneText) == "function" then
		context.zoneName = GetRealZoneText() or ""
	elseif type(GetZoneText) == "function" then
		context.zoneName = GetZoneText() or ""
	end
	if type(GetCurrentMapAreaID) == "function" then
		local zoneId = GetCurrentMapAreaID()
		if zoneId and zoneId ~= 0 then
			context.zoneId = zoneId
		end
	end
	if type(GetInstanceInfo) == "function" then
		local name, instanceType, difficultyIndex, difficultyName = GetInstanceInfo()
		if name and name ~= "" and (instanceType == "raid" or instanceType == "party") then
			context.instanceName = name
			if difficultyName and difficultyName ~= "" then
				context.difficulty = difficultyName
			elseif difficultyIndex then
				context.difficulty = difficultyIndex
			end
		end
	end
	return context
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
	if type(entry.events) ~= "table" then
		entry.events = {}
	end
	if Addon.EnsurePersonalRating then
		Addon:EnsurePersonalRating(entry)
	end
	return entry
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
			events = {},
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
		if type(saved.events) == "table" then
			profile.events = saved.events
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
	if self.GetHistoryEvents then
		profile.events = self:GetHistoryEvents(profile)
	end

	return profile
end

function Addon:SavePersonalRatingForGuid(guid, seed, opinion, tagIds, factIds)
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
	local previousFacts = {}
	for index = 1, #(personal.facts or {}) do
		previousFacts[index] = personal.facts[index]
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
	local now = time()
	personal.opinion = self:NormalizePersonalOpinion(opinion)
	personal.tags = self:NormalizePersonalTags(tagIds)
	if factIds ~= nil then
		personal.facts = self:NormalizePersonalFacts(factIds)
	else
		personal.facts = self:NormalizePersonalFacts(personal.facts)
	end
	if personal.createdAt <= 0 then
		personal.createdAt = now
	end
	personal.updatedAt = now
	local creatorId = LocalPlayerCreatorId()
	if creatorId ~= "" then
		personal.creatorId = creatorId
	end
	if previousOpinion ~= personal.opinion then
		self:AppendProfileHistoryChange(entry, "opinion", personal.opinion)
	end
	if not TagsEqual(previousTags, personal.tags) then
		local tagSummary = self.RatingTagSummary and self:RatingTagSummary(personal.tags, 5) or ""
		self:AppendProfileHistoryChange(entry, "tags", tagSummary)
	end
	if factIds ~= nil and not TagsEqual(previousFacts, personal.facts) then
		local factSummary = self.FactSummary and self:FactSummary(personal.facts, 5) or ""
		self:AppendProfileHistoryChange(entry, "facts", factSummary)
	end
	return entry
end

function Addon:AddHistoryEventForGuid(guid, seed, eventTypeId)
	if not guid or guid == "" or not self:IsValidEventType(eventTypeId) then
		return nil
	end
	local entry = self:EnsureHistoryEntryForGuid(guid, seed)
	if not entry then
		return nil
	end
	EnsureHistoryFields(entry)
	local event = {
		id = string.format("%d-%d", time(), #entry.events + 1),
		type = eventTypeId,
		creatorId = LocalPlayerCreatorId(),
		eventAt = time(),
		context = self:CaptureEventContext(),
	}
	entry.events[#entry.events + 1] = event
	self:AppendProfileHistoryChange(entry, "event_add", eventTypeId)
	return entry, event
end

function Addon:RemoveHistoryEventForGuid(guid, eventId)
	if not guid or guid == "" or not eventId or eventId == "" then
		return nil
	end
	local entry = self:GetHistoryEntry(guid)
	if not entry then
		return nil
	end
	EnsureHistoryFields(entry)
	local removedType = nil
	local nextEvents = {}
	for index = 1, #entry.events do
		local event = entry.events[index]
		if type(event) == "table" and event.id == eventId then
			removedType = event.type
		else
			nextEvents[#nextEvents + 1] = event
		end
	end
	if not removedType then
		return entry
	end
	entry.events = nextEvents
	self:AppendProfileHistoryChange(entry, "event_remove", removedType)
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
	return entry
end
