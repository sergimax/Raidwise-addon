-- Rating labels, tooltips, and chat marks.
local Addon = Raidwise

local _, OPINIONS = Addon:RatingOpinions()

local META_COLORS = {
	fact = { 0.75, 0.75, 0.75 },
	positive = { 0.35, 0.90, 0.35 },
	negative = { 0.95, 0.35, 0.35 },
}

local CHAT_OPINION_MARKS = {
	positive = { prefix = "Rw", color = "|cff64e6c2" },
	neutral = { prefix = "Rw", color = "|cffc4b5fd" },
	negative = { prefix = "Rw", color = "|cffff8f9c" },
}

local function ChatRealmKey(realm)
	return string.lower((realm or ""):gsub("%s+", ""))
end

local function FindChatHistoryEntry(sender, guid)
	local store = Addon:HistoryStore()
	if guid and guid ~= "" and store[guid] then
		return store[guid]
	end
	local name, realm = sender:match("^([^-]+)%-(.+)$")
	name = name or sender
	local currentRealm = ChatRealmKey(GetRealmName())
	local senderRealm = realm and ChatRealmKey(realm) or currentRealm
	for _, entry in pairs(store) do
		if type(entry) == "table" and entry.name == name then
			local entryRealm = ChatRealmKey(entry.realm)
			if entryRealm == "" then
				entryRealm = currentRealm
			end
			if entryRealm == senderRealm then
				return entry
			end
		end
	end
end

local function PersonalOpinionChatFilter(frame, event, message, sender, ...)
	if type(message) ~= "string" or type(sender) ~= "string" or sender == "" then
		return
	end
	-- Sender GUID is chat argument 12 in Wrath; older servers may omit it.
	local entry = FindChatHistoryEntry(sender, select(10, ...))
	if not entry then
		return
	end
	local personal = Addon:GetPersonalRating(entry)
	if not Addon:HasPersonalRatingData(personal) then
		return
	end
	local mark = CHAT_OPINION_MARKS[personal.opinion]
	if not mark then
		return
	end
	return false, "|cffffffff<" .. mark.color .. mark.prefix .. "|cffffffff>|r " .. message, sender, ...
end

for _, event in ipairs({
	"CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
}) do
	ChatFrame_AddMessageEventFilter(event, PersonalOpinionChatFilter)
end

function Addon:GetTooltipSettings()
	if not self.db then
		return {
			hidePersonal = false,
			hidePersonalTags = false,
			hideCommunity = false,
			hideCommunityTags = false,
		}
	end
	if type(self.db.tooltip) ~= "table" then
		self.db.tooltip = {
			hidePersonal = false,
			hidePersonalTags = false,
			hideCommunity = false,
			hideCommunityTags = false,
		}
	end
	local tip = self.db.tooltip
	if tip.hidePersonal == nil then
		tip.hidePersonal = false
	end
	if tip.hidePersonalTags == nil then
		tip.hidePersonalTags = false
	end
	if tip.hideCommunity == nil then
		tip.hideCommunity = false
	end
	if tip.hideCommunityTags == nil then
		tip.hideCommunityTags = false
	end
	return tip
end

-- Sample rows for Settings preview panels (not tied to a real player).
function Addon:GetTooltipPreviewSample()
	return {
		personal = {
			opinion = "positive",
			tags = { "good_raid_leader", "fair_loot", "good_player" },
			updatedAt = 1,
		},
		community = {
			positivePercent = 0,
			tags = { "fair_loot", "good_raid_leader", "good_player" },
			isMock = true,
		},
	}
end

-- Build tooltip lines for personal + community ratings.
-- layout: "compact" (default) or "stacked"
function Addon:BuildUnitTooltipRatingLines(personal, community, options, layout)
	options = options or self:GetTooltipSettings()
	layout = layout or "compact"
	local lines = {}

	if not options.hidePersonal and self:HasPersonalRatingData(personal) then
		local opinionText = self:RatingWrapColor(
			self:RatingOpinionLabel(personal.opinion),
			self:RatingOpinionColor(personal.opinion)
		)
		local tagSummary = ""
		if not options.hidePersonalTags then
			tagSummary = self:RatingTagColoredSummary(personal.tags, 3)
		end
		if layout == "stacked" then
			lines[#lines + 1] = opinionText
			if tagSummary ~= "" then
				lines[#lines + 1] = tagSummary
			end
		elseif tagSummary ~= "" then
			lines[#lines + 1] = opinionText .. ": " .. tagSummary
		else
			lines[#lines + 1] = opinionText
		end
	end

	if not options.hideCommunity and type(community) == "table" then
		local percent = tonumber(community.positivePercent)
		if percent then
			lines[#lines + 1] = self:T("TOOLTIP_COMMUNITY_POSITIVE", percent)
		end
		if not options.hideCommunityTags then
			local tagSummary = self:RatingTagColoredSummary(community.tags, 3)
			if tagSummary ~= "" then
				lines[#lines + 1] = tagSummary
			end
		end
	end

	return lines
end

function Addon:BuildUnitTooltipRatingLinesForMember(entryOrMember, options, layout)
	local personal = self:GetPersonalRating(entryOrMember)
	local community = self:GetCommunityRating(entryOrMember)
	return self:BuildUnitTooltipRatingLines(personal, community, options, layout)
end

function Addon:RatingMetaColor(meta)
	return META_COLORS[meta] or META_COLORS.fact
end

function Addon:FactLabel(factId)
	local fact = Addon:FactById(factId)
	if not fact then
		return tostring(factId or "")
	end
	return self:T(fact.labelKey)
end

function Addon:FactColoredLabel(factId)
	local fact = Addon:FactById(factId)
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
	local eventType = Addon:EventTypeById(eventTypeId)
	if not eventType then
		return tostring(eventTypeId or "")
	end
	return self:T(eventType.labelKey)
end

function Addon:EventTypeGroupLabel(eventTypeId)
	local eventType = Addon:EventTypeById(eventTypeId)
	if not eventType or not eventType.groupLabelKey then
		return ""
	end
	return self:T(eventType.groupLabelKey)
end

function Addon:EventTypeGroupIcon(eventTypeId)
	local eventType = Addon:EventTypeById(eventTypeId)
	if eventType and eventType.groupIcon and eventType.groupIcon ~= "" then
		return eventType.groupIcon
	end
	return nil
end

local CHANGE_KIND_ICONS = {
	opinion = "Interface\\Icons\\INV_Misc_Note_01",
	tags = "Interface\\Icons\\INV_Misc_Note_02",
	facts = "Interface\\Icons\\Achievement_General",
	notes = "Interface\\Icons\\INV_Misc_Book_11",
}

function Addon:ProfileHistoryChangeIcon(change)
	if type(change) ~= "table" or not change.kind then
		return nil
	end
	if change.kind == "event_add" or change.kind == "event_remove" then
		return self:EventTypeGroupIcon(change.detail) or "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	return CHANGE_KIND_ICONS[change.kind]
end

function Addon:EventTypeDisplayLabel(eventTypeId)
	local typeLabel = self:EventTypeLabel(eventTypeId)
	local groupLabel = self:EventTypeGroupLabel(eventTypeId)
	if not groupLabel or groupLabel == "" then
		return typeLabel
	end
	return groupLabel .. " · " .. typeLabel
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
	local tag = Addon:RatingTagById(tagId)
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

function Addon:RatingOpinionIcon(opinion)
	local data = OPINIONS[self:NormalizePersonalOpinion(opinion)] or OPINIONS.neutral
	return data.icon
end

function Addon:RatingTagLabel(tagId)
	local tag = Addon:RatingTagById(tagId)
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

-- DELETE candidate: no callers in Raidwise/ (profile uses PaintOpinionLabels instead).
function Addon:RatingDisplayText(entryOrMember)
	local personal = self:GetPersonalRating(entryOrMember)
	local opinion = self:RatingOpinionLabel(personal.opinion)
	if #personal.tags == 0 then
		return opinion
	end
	return self:T("RATING_DISPLAY_WITH_TAGS", opinion, tostring(#personal.tags))
end

-- DELETE candidate: no callers in Raidwise/.
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

