-- Plain profile draft state; no frames, rendering, or persistence writes.
local Addon = Raidwise

local function CopyTagList(tags)
	local copy = {}
	if type(tags) ~= "table" then
		return copy
	end
	for index = 1, #tags do
		copy[index] = tags[index]
	end
	return copy
end

local function CopyEventList(events)
	local copy = {}
	if type(events) ~= "table" then
		return copy
	end
	for index = 1, #events do
		local event = events[index]
		if type(event) == "table" then
			local context = {}
			if type(event.context) == "table" then
				for key, value in pairs(event.context) do
					context[key] = value
				end
			end
			copy[#copy + 1] = {
				id = event.id,
				type = event.type,
				creatorId = event.creatorId,
				eventAt = event.eventAt,
				context = context,
			}
		end
	end
	return copy
end

local function SortEventsNewestFirst(events)
	local sorted = CopyEventList(events)
	table.sort(sorted, function(left, right)
		return (tonumber(left.eventAt) or 0) > (tonumber(right.eventAt) or 0)
	end)
	return sorted
end

function Addon:CreateProfileDraft(member)
	local draft = {}
	local personal = { opinion = "neutral", tags = {}, facts = {} }
	if member and Addon.GetPersonalRating then
		personal = Addon:GetPersonalRating(member)
	end
	draft.draftOpinion = personal.opinion or "neutral"
	draft.draftTags = CopyTagList(personal.tags)
	draft.draftFacts = CopyTagList(personal.facts)
	local events = {}
	if member and Addon.GetHistoryEvents then
		events = Addon:GetHistoryEvents(member)
	elseif member and type(member.events) == "table" then
		events = member.events
	end
	draft.draftEvents = SortEventsNewestFirst(events)
	draft.draftEventSeq = 0
	return draft
end

Addon.ProfileDraft = { CopyEvents = CopyEventList, SortEvents = SortEventsNewestFirst }

function Addon:ToggleProfileDraftTag(draft, tagId)
	local opinion, draftTags, draftFacts = draft.draftOpinion or "neutral", draft.draftTags or {}, draft.draftFacts or {}
	local tag = self.RatingTagById and self:RatingTagById(tagId) or nil
	local nextTags = {}
	local seen = false
	for index = 1, #draftTags do
		local current = draftTags[index]
		if current ~= tagId then
			nextTags[#nextTags + 1] = current
		else
			seen = true
		end
	end
	if not seen then
		if tag and tag.groupId then
			local selectedCount = 0
			for index = 1, #draftTags do
				local currentTag = self:RatingTagById(draftTags[index])
				if currentTag and currentTag.groupId == tag.groupId then
					selectedCount = selectedCount + 1
				end
			end
			if selectedCount >= 3 then
				return false, "RATING_GROUP_LIMIT"
			end
		end
		nextTags[#nextTags + 1] = tagId
	end
	draft.draftTags = nextTags
	draft.draftOpinion = opinion
	draft.draftFacts = draftFacts
	return true
end

function Addon:ToggleProfileDraftFact(draft, factId)
	local opinion, draftTags, draftFacts = draft.draftOpinion or "neutral", draft.draftTags or {}, draft.draftFacts or {}
	local nextFacts = {}
	local seen = false
	for index = 1, #draftFacts do
		local current = draftFacts[index]
		if current ~= factId then
			nextFacts[#nextFacts + 1] = current
		else
			seen = true
		end
	end
	if not seen then
		local maxFacts = (self.MaxPersonalFacts and self:MaxPersonalFacts()) or 4
		if #draftFacts >= maxFacts then
			return false, "RATING_FACTS_LIMIT", maxFacts
		end
		nextFacts[#nextFacts + 1] = factId
	end
	draft.draftFacts = nextFacts
	draft.draftOpinion = opinion
	draft.draftTags = draftTags
	return true
end

function Addon:AddProfileDraftEvent(draft, eventTypeId)
	if self.IsValidEventType and not self:IsValidEventType(eventTypeId) then
		return
	end
	if type(draft.draftEvents) ~= "table" then
		draft.draftEvents = {}
	end
	draft.draftEventSeq = (draft.draftEventSeq or 0) + 1
	local creatorId = ""
	if type(UnitGUID) == "function" then
		creatorId = UnitGUID("player") or ""
	end
	local event = {
		id = string.format("draft-%d-%d", time(), draft.draftEventSeq),
		type = eventTypeId,
		creatorId = creatorId,
		eventAt = time(),
		context = (self.CaptureEventContext and self:CaptureEventContext()) or {},
	}
	table.insert(draft.draftEvents, 1, event)
end

function Addon:RemoveProfileDraftEvent(draft, eventId)
	local events = draft.draftEvents or {}
	local nextEvents = {}
	for index = 1, #events do
		local event = events[index]
		if type(event) == "table" and event.id ~= eventId then
			nextEvents[#nextEvents + 1] = event
		end
	end
	draft.draftEvents = nextEvents
end
