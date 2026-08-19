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

local function CopyArray(values)
	local out = {}
	if type(values) ~= "table" then
		return out
	end
	for index = 1, #values do
		out[index] = values[index]
	end
	return out
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
	local opinion = self:RatingOpinionLabel(personal.opinion)
	if #personal.tags == 0 then
		return self:T("RATING_PROFILE_SUMMARY", opinion, self:T("RATING_TAGS_NONE"))
	end
	return self:T("RATING_PROFILE_SUMMARY", opinion, self:RatingTagSummary(personal.tags, 3))
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

