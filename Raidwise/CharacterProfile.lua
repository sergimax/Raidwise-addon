-- Character profile window (standalone): opinion, tags, notes, history.

local Addon = Raidwise
local W = Addon.Widgets

local function T(key, ...)
	return W.T(key, ...)
end

-- Profile-local sizes (keep in sync with docs/UI-Sizes.md Character profile).
local UI = {
	PAD = 10,
	TITLE_H = 20,
	CLOSE_SIZE = 16,
	CHECK_SIZE = 24,
	ACTION_BTN_H = 28,
	ACTION_BTN_GAP = 8,
	PROFILE_ICON = 24,
	RAID_DETAIL_W = 460,
	RAID_DETAIL_H = 560,
	PROFILE_TAB_H = 26,
	GOLD = { 0.890, 0.729, 0.016 },
	TEXT_IDLE = { 0.80, 0.80, 0.80 },
	PANEL_BG = { 0.15, 0.15, 0.15, 0.96 },
	TITLE_BG = { 0.20, 0.20, 0.20, 1 },
	BTN_IDLE = { 0.18, 0.18, 0.18, 0.95 },
	BTN_HOVER = { 0.28, 0.28, 0.28, 1 },
	BTN_SELECTED = { 0.32, 0.28, 0.12, 1 },
	BTN_DISABLED = { 0.12, 0.12, 0.12, 0.90 },
	TEXT_HOVER = { 1.00, 1.00, 0.40 },
	TEXT_DISABLED = { 0.45, 0.45, 0.45 },
}

local PROFILE_LAYOUT_VERSION = 25

local function GetRatingTagGroups()
	if Addon.RatingTagGroups then
		return Addon:RatingTagGroups()
	end
	return {}
end

local OPINION_LABEL_KEYS = {
	positive = "RATING_OPINION_POSITIVE",
	neutral = "RATING_OPINION_NEUTRAL",
	negative = "RATING_OPINION_NEGATIVE",
}

local function OpinionButtonLabel(opinionId)
	if Addon.RatingOpinionLabel then
		return Addon:RatingOpinionLabel(opinionId)
	end
	local labelKey = OPINION_LABEL_KEYS[opinionId]
	if labelKey then
		return T(labelKey)
	end
	return tostring(opinionId or "")
end

local function RatingUIReady()
	return Addon.RatingTagGroups ~= nil and Addon.GetPersonalRating ~= nil
end

-- Summary + radios + tags heading only (no "Personal note" title).
local PROFILE_OPINION_HEADER_H = 72
local PROFILE_OPINION_RADIO_SIZE = 16
local PROFILE_OPINION_ROW_H = 22

local function ProfileFrameNeedsRebuild(frame)
	if not frame or frame.layoutVersion ~= PROFILE_LAYOUT_VERSION then
		return true
	end
	if not RatingUIReady() then
		return false
	end
	local groups = GetRatingTagGroups()
	if #groups == 0 then
		return false
	end
	if not frame.tagGroups then
		return true
	end
	return #frame.tagGroups ~= #groups
end

local function CreateProfileNotesBox(parent, width, height)
	local host = CreateFrame("Frame", nil, parent)
	host:SetSize(width, height)
	host:SetBackdrop(W.COPY_BACKDROP)
	host:SetBackdropColor(0, 0, 0, 1)
	host:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	local scroll = CreateFrame("ScrollFrame", nil, host, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -24, 6)

	local scrollBar = scroll.ScrollBar or _G["UIPanelScrollFrameTemplateScrollBar"]
	if scrollBar and scrollBar.GetParent and scrollBar:GetParent() == scroll then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", host, "TOPRIGHT", -20, -16)
		scrollBar:SetPoint("BOTTOMLEFT", host, "BOTTOMRIGHT", -20, 16)
	end

	local box = CreateFrame("EditBox", nil, scroll)
	box:SetMultiLine(true)
	box:SetFontObject(ChatFontNormal)
	box:SetAutoFocus(false)
	box:SetWidth(width - 36)
	box:SetHeight(height - 12)
	box:SetTextInsets(0, 0, 3, 3)
	scroll:SetScrollChild(box)

	box:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	box:SetScript("OnCursorChanged", function(self, _, y, _, cursorHeight)
		y = -y
		local offset = scroll:GetVerticalScroll()
		if y < offset then
			scroll:SetVerticalScroll(y)
		else
			y = y + (cursorHeight or W.ChatFontLineHeight()) - scroll:GetHeight()
			if y > offset then
				scroll:SetVerticalScroll(y)
			end
		end
	end)
	host.box = box
	host.scroll = scroll
	return host, box
end

local function ProfileFieldValue(value)
	if value == nil or value == "" then
		return "-"
	end
	return tostring(value)
end

local function ProfileRaceText(race)
	return ProfileFieldValue(race)
end

local function ProfileFactionText(faction)
	if not faction or faction == "" then
		return "-"
	end
	if faction == "Alliance" and FACTION_ALLIANCE then
		return FACTION_ALLIANCE
	end
	if faction == "Horde" and FACTION_HORDE then
		return FACTION_HORDE
	end
	return faction
end


local RACE_ICON_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"
local RACE_ICON_TCOORDS = {
	["HUMAN_MALE"] = { 0, 0.125, 0, 0.25 },
	["DWARF_MALE"] = { 0.125, 0.25, 0, 0.25 },
	["GNOME_MALE"] = { 0.25, 0.375, 0, 0.25 },
	["NIGHTELF_MALE"] = { 0.375, 0.5, 0, 0.25 },
	["TAUREN_MALE"] = { 0, 0.125, 0.25, 0.5 },
	["SCOURGE_MALE"] = { 0.125, 0.25, 0.25, 0.5 },
	["TROLL_MALE"] = { 0.25, 0.375, 0.25, 0.5 },
	["ORC_MALE"] = { 0.375, 0.5, 0.25, 0.5 },
	["HUMAN_FEMALE"] = { 0, 0.125, 0.5, 0.75 },
	["DWARF_FEMALE"] = { 0.125, 0.25, 0.5, 0.75 },
	["GNOME_FEMALE"] = { 0.25, 0.375, 0.5, 0.75 },
	["NIGHTELF_FEMALE"] = { 0.375, 0.5, 0.5, 0.75 },
	["TAUREN_FEMALE"] = { 0, 0.125, 0.75, 1.0 },
	["SCOURGE_FEMALE"] = { 0.125, 0.25, 0.75, 1.0 },
	["TROLL_FEMALE"] = { 0.25, 0.375, 0.75, 1.0 },
	["ORC_FEMALE"] = { 0.375, 0.5, 0.75, 1.0 },
	["BLOODELF_MALE"] = { 0.5, 0.625, 0.25, 0.5 },
	["BLOODELF_FEMALE"] = { 0.5, 0.625, 0.75, 1.0 },
	["DRAENEI_MALE"] = { 0.5, 0.625, 0, 0.25 },
	["DRAENEI_FEMALE"] = { 0.5, 0.625, 0.5, 0.75 },
}

local function ProfileRaceLabel(raceToken)
	if not raceToken or raceToken == "" then
		return "-"
	end
	local localized = _G[raceToken]
	if type(localized) == "string" and localized ~= "" then
		return localized
	end
	return raceToken
end

local function SetProfileRaceIcon(texture, raceToken, gender)
	if not texture then
		return false
	end
	if not raceToken or raceToken == "" then
		texture:Hide()
		return false
	end
	local genderKey = (gender == 3) and "FEMALE" or "MALE"
	local raceKey = strupper(raceToken) .. "_" .. genderKey
	local coords = RACE_ICON_TCOORDS[raceKey]
	if not coords then
		texture:Hide()
		return false
	end
	texture:SetTexture(RACE_ICON_TEXTURE)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	texture:Show()
	return true
end

local PROFILE_TABS = {
	{ id = "history", labelKey = "PROFILE_TAB_HISTORY" },
	{ id = "opinion", labelKey = "PROFILE_TAB_OPINION" },
	{ id = "facts", labelKey = "PROFILE_TAB_FACTS" },
	{ id = "events", labelKey = "PROFILE_TAB_EVENTS" },
	{ id = "notes", labelKey = "PROFILE_TAB_NOTES" },
}

local UpdateProfileEventsPanel
local RefreshProfileFactCheckboxes

local function FormatProfileChangeDetail(change)
	if type(change) ~= "table" then
		return "?"
	end
	if change.kind == "opinion" then
		return T("PROFILE_CHANGE_OPINION", OpinionButtonLabel(change.detail))
	end
	if change.kind == "tags" then
		local detail = change.detail
		if type(detail) ~= "string" or detail == "" then
			detail = T("RATING_TAGS_NONE")
		end
		return T("PROFILE_CHANGE_TAGS", detail)
	end
	if change.kind == "facts" then
		local detail = change.detail
		if type(detail) ~= "string" or detail == "" then
			detail = T("RATING_FACTS_NONE")
		end
		return T("PROFILE_CHANGE_FACTS", detail)
	end
	if change.kind == "event_add" then
		local label = change.detail
		if Addon.EventTypeLabel then
			label = Addon:EventTypeLabel(change.detail)
		end
		return T("PROFILE_CHANGE_EVENT_ADD", label)
	end
	if change.kind == "event_remove" then
		local label = change.detail
		if Addon.EventTypeLabel then
			label = Addon:EventTypeLabel(change.detail)
		end
		return T("PROFILE_CHANGE_EVENT_REMOVE", label)
	end
	if change.kind == "notes" then
		return T("PROFILE_CHANGE_NOTES")
	end
	return change.detail or "?"
end

local function UpdateProfileHistoryPanel(frame, member)
	if not frame or not frame.historyText or not member then
		return
	end
	local lines = {}
	local metZone = (member.metZone and member.metZone ~= "") and member.metZone or "-"
	lines[#lines + 1] = T("PROFILE_MET", metZone)
	local metWhen = "-"
	if Addon.FormatHistoryTime and member.metAt then
		metWhen = Addon:FormatHistoryTime(member.metAt) or "-"
	end
	lines[#lines + 1] = T("PROFILE_WHEN", metWhen)
	lines[#lines + 1] = ""

	local changes = member.changes
	if type(changes) ~= "table" or #changes == 0 then
		lines[#lines + 1] = T("PROFILE_HISTORY_EMPTY")
	else
		for index = #changes, 1, -1 do
			local change = changes[index]
			local when = Addon.FormatHistoryTime and Addon:FormatHistoryTime(change.at) or "?"
			lines[#lines + 1] = when .. " — " .. FormatProfileChangeDetail(change)
		end
	end
	frame.historyText:SetText(table.concat(lines, "\n"))
	local textHeight = frame.historyText:GetStringHeight() or 120
	if frame.profilePanels and frame.profilePanels.history then
		frame.profilePanels.history:SetHeight(math.max(120, textHeight + 12))
	end
end

function Addon:SelectProfileTab(tabId)
	local frame = self.raidDetailFrame
	if not frame or not frame.profilePanels then
		return
	end
	frame.selectedProfileTab = tabId
	for id, panel in pairs(frame.profilePanels) do
		if id == tabId then
			panel:Show()
		else
			panel:Hide()
		end
	end
	if frame.profileTabButtons then
		for _, button in ipairs(frame.profileTabButtons) do
			W.SetMenuButtonState(button, button.tabId == tabId, false)
		end
	end
	if tabId == "history" and frame.profileMember then
		UpdateProfileHistoryPanel(frame, frame.profileMember)
	end
	if tabId == "events" and frame.profileMember then
		UpdateProfileEventsPanel(frame, frame.profileMember)
	end
	if tabId == "facts" and frame.profileMember then
		RefreshProfileFactCheckboxes(frame, frame.profileMember, frame.profileMember.guid and frame.profileMember.guid ~= "")
	end
end

local function CreateProfileTabButton(parent, tabId, label, width)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, UI.PROFILE_TAB_H)
	W.ApplyPlainPanel(button, UI.BTN_IDLE)
	button.tabId = tabId

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", 6, 0)
	text:SetPoint("RIGHT", -6, 0)
	text:SetJustifyH("CENTER")
	text:SetText(label)
	button.label = text

	button:SetScript("OnEnter", function(self)
		W.SetMenuButtonState(self, Addon.raidDetailFrame and Addon.raidDetailFrame.selectedProfileTab == tabId, true)
	end)
	button:SetScript("OnLeave", function(self)
		W.SetMenuButtonState(self, Addon.raidDetailFrame and Addon.raidDetailFrame.selectedProfileTab == tabId, false)
	end)
	button:SetScript("OnClick", function()
		Addon:SelectProfileTab(tabId)
	end)
	W.SetMenuButtonState(button, false, false)
	return button
end

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

local function InitProfileDraft(frame, member)
	if not frame then
		return
	end
	local personal = { opinion = "neutral", tags = {}, facts = {} }
	if member and Addon.GetPersonalRating then
		personal = Addon:GetPersonalRating(member)
	end
	frame.draftOpinion = personal.opinion or "neutral"
	frame.draftTags = CopyTagList(personal.tags)
	frame.draftFacts = CopyTagList(personal.facts)
end

local function GetProfileDraft(frame)
	if not frame then
		return "neutral", {}, {}
	end
	return frame.draftOpinion or "neutral", frame.draftTags or {}, frame.draftFacts or {}
end

-- AceConfigDialog / Details radio pattern: exclusive SetChecked on the whole group.
local function RefreshOpinionRadios(frame, selectedOpinion)
	if not frame or not frame.opinionButtons then
		return
	end
	selectedOpinion = selectedOpinion or "neutral"
	for _, radio in ipairs(frame.opinionButtons) do
		local checked = radio.opinionId == selectedOpinion
		radio.isUpdating = true
		radio:SetChecked(checked)
		-- Some clients leave CheckedTexture visible after SetChecked(false); force it.
		local checkedTexture = radio.GetCheckedTexture and radio:GetCheckedTexture()
		if checkedTexture then
			if checked then
				checkedTexture:Show()
			else
				checkedTexture:Hide()
			end
		end
		if radio.label then
			radio.label:SetText(OpinionButtonLabel(radio.opinionId))
			if radio:IsEnabled() then
				W.SetFontColor(radio.label, checked and UI.GOLD or UI.TEXT_IDLE)
			else
				W.SetFontColor(radio.label, UI.TEXT_DISABLED)
			end
		end
		radio.isUpdating = false
	end
end

-- Paint Personal note + Summary from the chosen opinion immediately (same click as radios).
local function PaintOpinionLabels(frame, opinionId, tags, targets)
	if not frame then
		return
	end
	opinionId = opinionId or "neutral"
	tags = tags or {}
	targets = targets or "all"
	local paintHeader = targets == "all" or targets == "header"
	local paintEditor = targets == "all" or targets == "editor"

	local label = OpinionButtonLabel(opinionId)
	local color = UI.TEXT_IDLE
	if Addon.RatingOpinionColor then
		color = Addon:RatingOpinionColor(opinionId)
	end
	if paintHeader and frame.opinionText then
		frame.opinionText:SetText(T("RATING_PROFILE_OPINION", label))
		W.SetFontColor(frame.opinionText, color)
	end
	if paintHeader and frame.tagText then
		local tagSummary = ""
		if Addon.RatingTagColoredSummary then
			tagSummary = Addon:RatingTagColoredSummary(tags, 3) or ""
		end
		if tagSummary ~= "" then
			frame.tagText:SetText(tagSummary)
			W.SetFontColor(frame.tagText, UI.TEXT_IDLE)
		else
			frame.tagText:SetText(T("RATING_TAGS_NONE"))
			W.SetFontColor(frame.tagText, UI.TEXT_DISABLED)
		end
	end
	if paintEditor and frame.ratingSummary then
		local opinionText = label
		if Addon.RatingWrapColor then
			opinionText = Addon:RatingWrapColor(label, color)
		end
		local tagPart = T("RATING_TAGS_NONE")
		if Addon.RatingTagColoredSummary then
			local colored = Addon:RatingTagColoredSummary(tags, 3)
			if colored and colored ~= "" then
				tagPart = colored
			end
		end
		frame.ratingSummary:SetText(T("RATING_PROFILE_SUMMARY", opinionText, tagPart))
	end
end

local function PaintSavedHeaderLabels(frame, member)
	if not frame or not member or not Addon.GetPersonalRating then
		return
	end
	local personal = Addon:GetPersonalRating(member)
	PaintOpinionLabels(frame, personal.opinion, personal.tags, "header")
	if frame.factText then
		local factSummary = ""
		if Addon.FactColoredSummary then
			factSummary = Addon:FactColoredSummary(personal.facts, 3) or ""
		end
		if factSummary ~= "" then
			frame.factText:SetText(T("RATING_PROFILE_FACTS", factSummary))
			W.SetFontColor(frame.factText, UI.TEXT_IDLE)
		else
			frame.factText:SetText(T("RATING_PROFILE_FACTS", T("RATING_FACTS_NONE")))
			W.SetFontColor(frame.factText, UI.TEXT_DISABLED)
		end
	end
end

local function PaintDraftEditorLabels(frame)
	if not frame then
		return
	end
	local opinion, tags = GetProfileDraft(frame)
	PaintOpinionLabels(frame, opinion, tags, "editor")
end

local function ApplyOpinionChoice(opinionId)
	if not opinionId then
		return
	end
	PlaySound("igMainMenuOptionCheckBoxOn")
	local frame = Addon.raidDetailFrame
	if not frame then
		return
	end
	frame.draftOpinion = opinionId
	-- Draft only; CommitProfileRating (Save) persists. Header stays on saved values.
	RefreshOpinionRadios(frame, opinionId)
	PaintDraftEditorLabels(frame)
end

local function CreateOpinionRadio(parent, opinionId, columnWidth)
	local host = CreateFrame("Frame", nil, parent)
	host:SetSize(columnWidth, PROFILE_OPINION_ROW_H)

	-- UIRadioButtonTemplate: engine owns checked texture (DBM / Blizzard options style).
	local radio = CreateFrame("CheckButton", nil, host, "UIRadioButtonTemplate")
	radio:SetSize(PROFILE_OPINION_RADIO_SIZE, PROFILE_OPINION_RADIO_SIZE)
	radio:SetPoint("LEFT", 0, 0)
	radio.opinionId = opinionId

	local label = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", radio, "RIGHT", 4, 0)
	label:SetPoint("RIGHT", host, "RIGHT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(OpinionButtonLabel(opinionId))
	W.SetFontColor(label, UI.TEXT_IDLE)
	radio.label = label
	radio.host = host

	-- Label-only hit target. Do NOT cover the radio or call :Click() — that toggles
	-- one control without clearing siblings on some 3.3.5 clients.
	local hit = CreateFrame("Button", nil, host)
	hit:SetPoint("TOPLEFT", label, "TOPLEFT", 0, 2)
	hit:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, -2)
	hit:SetScript("OnClick", function()
		if radio:IsEnabled() then
			ApplyOpinionChoice(radio.opinionId)
		end
	end)
	radio.hit = hit

	radio:SetScript("OnClick", function(self)
		if self.isUpdating then
			return
		end
		-- Engine already toggled this button; re-apply exclusive group state.
		ApplyOpinionChoice(self.opinionId)
	end)

	return radio
end

local PROFILE_TAG_ROW_H = 22
local PROFILE_TAG_GROUP_HEADING_H = 18
local PROFILE_TAG_GROUP_GAP = 8
local PROFILE_TAG_COL_GAP = 12

local ratingViewRefreshScheduled

local function ScheduleRatingViewRefresh()
	if ratingViewRefreshScheduled then
		return
	end
	ratingViewRefreshScheduled = CreateFrame("Frame")
	ratingViewRefreshScheduled:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		ratingViewRefreshScheduled = nil
		Addon:RefreshRatingViews()
	end)
end

local function CountSelectedTagsInGroup(tags, group)
	if type(tags) ~= "table" or type(group) ~= "table" or type(group.tags) ~= "table" then
		return 0
	end
	local selected = {}
	for index = 1, #tags do
		selected[tags[index]] = true
	end
	local count = 0
	for index = 1, #group.tags do
		if selected[group.tags[index].id] then
			count = count + 1
		end
	end
	return count
end

local function TagCheckboxLabel(tagId)
	if Addon.RatingTagLabel then
		return Addon:RatingTagLabel(tagId)
	end
	return tostring(tagId)
end

local function TagCheckboxColor(tagId)
	local tag = Addon.RatingTagById and Addon:RatingTagById(tagId)
	if tag and Addon.RatingMetaColor then
		return Addon:RatingMetaColor(tag.meta)
	end
	return UI.TEXT_IDLE
end

local function SetProfileTagCheckboxState(checkbox, checked, enabled)
	if not checkbox then
		return
	end
	checkbox.isUpdating = true
	checkbox:SetChecked(checked and true or false)
	if enabled then
		checkbox:Enable()
		checkbox:SetAlpha(1)
		if checkbox.label then
			W.SetFontColor(checkbox.label, checkbox.labelColor or UI.TEXT_IDLE)
		end
		if checkbox.hit then
			checkbox.hit:Enable()
		end
	else
		checkbox:Disable()
		checkbox:SetAlpha(0.55)
		if checkbox.label then
			W.SetFontColor(checkbox.label, UI.TEXT_DISABLED)
		end
		if checkbox.hit then
			checkbox.hit:Disable()
		end
	end
	checkbox.isUpdating = false
end

local function RefreshProfileTagCheckboxes(frame, member, editable)
	if not frame or not frame.tagGroups then
		return
	end

	local selected = {}
	local _, draftTags = GetProfileDraft(frame)
	for index = 1, #draftTags do
		selected[draftTags[index]] = true
	end

	for _, entry in ipairs(frame.tagGroups) do
		if entry.label then
			entry.label:SetText(T(entry.group.labelKey))
		end
		local groupCount = CountSelectedTagsInGroup(draftTags, entry.group)
		for _, checkbox in ipairs(entry.checkboxes) do
			local tagId = checkbox.tagId
			local isSelected = selected[tagId] and true or false
			local canUse = editable and (isSelected or groupCount < 3)
			SetProfileTagCheckboxState(checkbox, isSelected, canUse)
		end
	end
end

RefreshProfileFactCheckboxes = function(frame, member, editable)
	if not frame or not frame.factCheckboxes then
		return
	end
	local selected = {}
	local _, _, draftFacts = GetProfileDraft(frame)
	for index = 1, #draftFacts do
		selected[draftFacts[index]] = true
	end
	local maxFacts = (Addon.MaxPersonalFacts and Addon:MaxPersonalFacts()) or 4
	local selectedCount = #draftFacts
	if frame.factsHint then
		frame.factsHint:SetText(T("RATING_FACTS_HINT", maxFacts))
	end
	if frame.factsHeading then
		frame.factsHeading:SetText(T("RATING_FACTS_TITLE"))
	end
	for _, checkbox in ipairs(frame.factCheckboxes) do
		local factId = checkbox.factId
		local isSelected = selected[factId] and true or false
		local canUse = editable and (isSelected or selectedCount < maxFacts)
		if checkbox.label and Addon.FactLabel then
			checkbox.label:SetText(Addon:FactLabel(factId))
		end
		SetProfileTagCheckboxState(checkbox, isSelected, canUse)
	end
end

local function FormatEventContextSuffix(event)
	if type(event) ~= "table" or type(event.context) ~= "table" then
		return ""
	end
	local context = event.context
	local place = context.instanceName
	if not place or place == "" then
		place = context.zoneName
	end
	if not place or place == "" then
		return ""
	end
	local suffix = place
	if context.difficulty and context.difficulty ~= "" then
		suffix = suffix .. " (" .. tostring(context.difficulty) .. ")"
	end
	return " — " .. suffix
end

UpdateProfileEventsPanel = function(frame, member)
	if not frame or not frame.eventsListContent then
		return
	end
	local events = {}
	if member and Addon.GetHistoryEvents then
		events = Addon:GetHistoryEvents(member)
	elseif member and type(member.events) == "table" then
		events = member.events
	end
	if frame.eventsHeading then
		frame.eventsHeading:SetText(T("PROFILE_TAB_EVENTS"))
	end
	if frame.eventsAddBtn and frame.eventsAddBtn.label then
		frame.eventsAddBtn.label:SetText(T("PROFILE_EVENTS_ADD"))
	end
	if frame.eventsPickLabel then
		frame.eventsPickLabel:SetText(T("PROFILE_EVENTS_PICK_TYPE"))
	end
	if frame.eventTypeButtons then
		for _, button in ipairs(frame.eventTypeButtons) do
			if button.label and button.eventTypeId and Addon.EventTypeLabel then
				button.label:SetText(Addon:EventTypeLabel(button.eventTypeId))
			end
			W.SetMenuButtonState(button, frame.selectedEventType == button.eventTypeId, false)
		end
	end

	if frame.eventRows then
		for _, row in ipairs(frame.eventRows) do
			row:Hide()
			row:SetParent(nil)
		end
	end
	frame.eventRows = {}
	frame.eventRemoveButtons = {}

	local rowHeight = 20
	local contentWidth = (frame.eventsListContent:GetWidth() or 400)
	local y = 0
	if #events == 0 then
		local row = CreateFrame("Frame", nil, frame.eventsListContent)
		row:SetSize(contentWidth, rowHeight)
		row:SetPoint("TOPLEFT", frame.eventsListContent, "TOPLEFT", 0, 0)
		local empty = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		empty:SetPoint("LEFT", 0, 0)
		empty:SetPoint("RIGHT", 0, 0)
		empty:SetJustifyH("LEFT")
		empty:SetText(T("PROFILE_EVENTS_EMPTY"))
		row.label = empty
		frame.eventRows[1] = row
		y = rowHeight
	else
		for index = 1, #events do
			local event = events[index]
			local when = Addon.FormatHistoryTime and Addon:FormatHistoryTime(event.eventAt) or "?"
			local label = Addon.EventTypeLabel and Addon:EventTypeLabel(event.type) or tostring(event.type)
			local line = when .. " — " .. label .. FormatEventContextSuffix(event)

			local row = CreateFrame("Frame", nil, frame.eventsListContent)
			row:SetSize(contentWidth, rowHeight)
			row:SetPoint("TOPLEFT", frame.eventsListContent, "TOPLEFT", 0, -y)

			local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			text:SetPoint("LEFT", 0, 0)
			text:SetPoint("RIGHT", row, "RIGHT", -76, 0)
			text:SetJustifyH("LEFT")
			text:SetJustifyV("MIDDLE")
			text:SetText(line)
			row.label = text

			local button = W.CreatePlainButton(row, 70, 18, T("PROFILE_EVENT_REMOVE"))
			button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
			button.eventId = event.id
			button:SetScript("OnClick", function(self)
				Addon:RemoveProfileEvent(self.eventId)
			end)
			row.removeBtn = button
			frame.eventRemoveButtons[#frame.eventRemoveButtons + 1] = button
			frame.eventRows[#frame.eventRows + 1] = row
			y = y + rowHeight
		end
	end
	frame.eventsListContent:SetHeight(math.max(y, 1))
end

local function CreateProfileFactCheckbox(parent, fact, columnWidth)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	local checkName = check:GetName()
	local templateText = checkName and _G[checkName .. "Text"]
	if templateText then
		templateText:SetText("")
		templateText:Hide()
	end
	check.factId = fact.id

	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", check, "RIGHT", 4, 0)
	label:SetWidth(columnWidth - UI.CHECK_SIZE - 4)
	label:SetJustifyH("LEFT")
	label:SetText(Addon.FactLabel and Addon:FactLabel(fact.id) or fact.id)
	check.labelColor = (Addon.RatingMetaColor and Addon:RatingMetaColor("fact")) or UI.TEXT_IDLE
	W.SetFontColor(label, check.labelColor)
	check.label = label

	local hit = CreateFrame("Button", nil, parent)
	hit:SetPoint("TOPLEFT", check, "TOPLEFT", 0, 0)
	hit:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 0, 0)
	hit:SetScript("OnClick", function()
		if check:IsEnabled() then
			check:Click()
		end
	end)
	check.hit = hit

	check:SetScript("OnClick", function(self)
		if self.isUpdating then
			return
		end
		local wantChecked = self:GetChecked()
		local _, _, draftFacts = GetProfileDraft(Addon.raidDetailFrame)
		if wantChecked then
			local maxFacts = (Addon.MaxPersonalFacts and Addon:MaxPersonalFacts()) or 4
			if #draftFacts >= maxFacts then
				self:SetChecked(false)
				Addon:Print(Addon:T("RATING_FACTS_LIMIT", maxFacts))
				return
			end
		end
		Addon:ToggleProfileFact(self.factId)
	end)

	return check
end

local function CreateProfileTagCheckbox(parent, tag, group, columnWidth)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	local checkName = check:GetName()
	local templateText = checkName and _G[checkName .. "Text"]
	if templateText then
		templateText:SetText("")
		templateText:Hide()
	end
	check.tagId = tag.id
	check.groupId = group.id

	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", check, "RIGHT", 4, 0)
	label:SetWidth(columnWidth - UI.CHECK_SIZE - 4)
	label:SetJustifyH("LEFT")
	label:SetText(TagCheckboxLabel(tag.id))
	check.labelColor = TagCheckboxColor(tag.id)
	W.SetFontColor(label, check.labelColor)
	check.label = label

	local hit = CreateFrame("Button", nil, parent)
	hit:SetPoint("TOPLEFT", check, "TOPLEFT", 0, 0)
	hit:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 0, 0)
	hit:SetScript("OnClick", function()
		if check:IsEnabled() then
			check:Click()
		end
	end)
	check.hit = hit

	check:SetScript("OnClick", function(self)
		if self.isUpdating then
			return
		end
		local wantChecked = self:GetChecked()
		local profileFrame = Addon.raidDetailFrame
		local _, draftTags = GetProfileDraft(profileFrame)
		if wantChecked then
			if CountSelectedTagsInGroup(draftTags, group) >= 3 then
				self:SetChecked(false)
				Addon:Print(Addon:T("RATING_GROUP_LIMIT"))
				return
			end
		end
		Addon:ToggleProfileTag(self.tagId)
	end)

	return check
end

local function ProfileTagGroupHeight(tagCount)
	local rows = math.ceil(tagCount / 2)
	return PROFILE_TAG_GROUP_HEADING_H + (rows * PROFILE_TAG_ROW_H) + PROFILE_TAG_GROUP_GAP
end

local function UpdateProfileOpinionControls(frame, member)
	if not frame or not member then
		return
	end
	local opinion, tags = GetProfileDraft(frame)
	PaintSavedHeaderLabels(frame, member)
	PaintOpinionLabels(frame, opinion, tags, "editor")
	RefreshOpinionRadios(frame, opinion)
end

local function UpdateProfileEditor(frame, member)
	if not frame or not member then
		return
	end
	UpdateProfileOpinionControls(frame, member)
	if frame.tagGroups then
		local editable = member.guid and member.guid ~= ""
		RefreshProfileTagCheckboxes(frame, member, editable)
	end
	if frame.factCheckboxes then
		local editable = member.guid and member.guid ~= ""
		RefreshProfileFactCheckboxes(frame, member, editable)
	end
	UpdateProfileEventsPanel(frame, member)
	if frame.communityHeading then
		frame.communityHeading:SetText(T("RATING_COMMUNITY_TITLE"))
	end
	if frame.communityText then
		frame.communityText:SetText(T("RATING_COMMUNITY_MOCK"))
	end
	UpdateProfileHistoryPanel(frame, member)
end

function Addon:RefreshRatingViews()
	local frame = self.mainFrame
	if frame and frame:IsShown() then
		if frame.selectedTab == "party" and self.RefreshPartyView then
			self:RefreshPartyView(false)
		elseif frame.selectedTab == "raid" and self.RefreshRaidRosterView then
			self:RefreshRaidRosterView(false)
		elseif frame.selectedTab == "history" and self.RefreshHistoryView then
			self:RefreshHistoryView()
		end
	end
end

function Addon:SaveProfilePersonalRating(opinion, tagIds, factIds, options)
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" or not self.SavePersonalRatingForGuid then
		return
	end
	local entry = self:SavePersonalRatingForGuid(member.guid, member, opinion, tagIds, factIds)
	if not entry then
		return
	end
	-- Rebuild from the saved history entry so opinion/tags/facts/changes match the DB.
	frame.profileMember = self:HistoryProfileForMember(entry)
	if type(entry.changes) == "table" then
		frame.profileMember.changes = entry.changes
	end
	if type(entry.events) == "table" then
		frame.profileMember.events = entry.events
	end
	frame.profileMember.rating = {
		personal = self:GetPersonalRating(entry),
	}
	if options and options.opinionOnly then
		UpdateProfileOpinionControls(frame, frame.profileMember)
	elseif options and options.tagsOnly then
		if frame.tagGroups then
			local editable = frame.profileMember.guid and frame.profileMember.guid ~= ""
			RefreshProfileTagCheckboxes(frame, frame.profileMember, editable)
		end
		UpdateProfileOpinionControls(frame, frame.profileMember)
	else
		UpdateProfileEditor(frame, frame.profileMember)
	end
	if options and options.deferViewRefresh then
		ScheduleRatingViewRefresh()
	else
		self:RefreshRatingViews()
	end
end

function Addon:SaveProfileNotes(notes)
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" or not self.SaveProfileNotesForGuid then
		return
	end
	local entry = self:SaveProfileNotesForGuid(member.guid, member, notes)
	if not entry then
		return
	end
	frame.profileMember = self:HistoryProfileForMember(member)
	if frame.notesBox then
		frame.isUpdatingNotes = true
		frame.notesBox:SetText(frame.profileMember.notes or "")
		frame.isUpdatingNotes = false
	end
	self:RefreshRatingViews()
end

function Addon:ResetProfileNotes()
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" then
		return
	end
	if frame.notesBox then
		frame.isUpdatingNotes = true
		frame.notesBox:SetText("")
		frame.notesBox:ClearFocus()
		frame.isUpdatingNotes = false
	end
	self:SaveProfileNotes("")
end

function Addon:SetProfileOpinion(opinion)
	ApplyOpinionChoice(opinion)
end

function Addon:ToggleProfileTag(tagId)
	local frame = self.raidDetailFrame
	if not frame then
		return
	end
	local opinion, draftTags, draftFacts = GetProfileDraft(frame)
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
				self:Print(self:T("RATING_GROUP_LIMIT"))
				return
			end
		end
		nextTags[#nextTags + 1] = tagId
	end
	frame.draftTags = nextTags
	frame.draftOpinion = opinion
	frame.draftFacts = draftFacts
	PaintDraftEditorLabels(frame)
	if frame.tagGroups then
		local member = frame.profileMember
		local editable = member and member.guid and member.guid ~= ""
		RefreshProfileTagCheckboxes(frame, member, editable)
	end
end

function Addon:ToggleProfileFact(factId)
	local frame = self.raidDetailFrame
	if not frame or not factId then
		return
	end
	local opinion, draftTags, draftFacts = GetProfileDraft(frame)
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
			self:Print(self:T("RATING_FACTS_LIMIT", maxFacts))
			return
		end
		nextFacts[#nextFacts + 1] = factId
	end
	frame.draftFacts = nextFacts
	frame.draftOpinion = opinion
	frame.draftTags = draftTags
	if frame.factCheckboxes then
		local member = frame.profileMember
		local editable = member and member.guid and member.guid ~= ""
		RefreshProfileFactCheckboxes(frame, member, editable)
	end
end

function Addon:CommitProfileRating()
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" then
		return
	end
	local opinion, tags, facts = GetProfileDraft(frame)
	self:SaveProfilePersonalRating(opinion, tags, facts, {})
	InitProfileDraft(frame, frame.profileMember)
	UpdateProfileEditor(frame, frame.profileMember)
end

function Addon:AddProfileEvent(eventTypeId)
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" or not eventTypeId or not self.AddHistoryEventForGuid then
		return
	end
	local entry = self:AddHistoryEventForGuid(member.guid, member, eventTypeId)
	if not entry then
		return
	end
	frame.profileMember = self:HistoryProfileForMember(entry)
	if type(entry.changes) == "table" then
		frame.profileMember.changes = entry.changes
	end
	frame.profileMember.events = self:GetHistoryEvents(entry)
	UpdateProfileEventsPanel(frame, frame.profileMember)
	UpdateProfileHistoryPanel(frame, frame.profileMember)
	self:RefreshRatingViews()
end

function Addon:RemoveProfileEvent(eventId)
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" or not eventId or not self.RemoveHistoryEventForGuid then
		return
	end
	local entry = self:RemoveHistoryEventForGuid(member.guid, eventId)
	if not entry then
		return
	end
	frame.profileMember = self:HistoryProfileForMember(entry)
	if type(entry.changes) == "table" then
		frame.profileMember.changes = entry.changes
	end
	frame.profileMember.events = self:GetHistoryEvents(entry)
	UpdateProfileEventsPanel(frame, frame.profileMember)
	UpdateProfileHistoryPanel(frame, frame.profileMember)
	self:RefreshRatingViews()
end

local function CreateRaidCharacterWindow()
	local frame = CreateFrame("Frame", "RaidwiseRaidCharacterFrame", UIParent)
	-- Named frames are reused; drop old children so prior layouts cannot steal clicks.
	W.DetachFrameChildren(frame)
	frame:SetSize(UI.RAID_DETAIL_W, UI.RAID_DETAIL_H)
	frame:SetPoint("CENTER", 40, 20)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:Hide()
	W.ApplyPlainPanel(frame)
	frame.layoutVersion = PROFILE_LAYOUT_VERSION
	frame.opinionButtons = nil
	frame.profileTabButtons = nil
	frame.profilePanels = nil
	frame.tagGroups = nil
	if not frame.rwInSpecialFrames then
		tinsert(UISpecialFrames, "RaidwiseRaidCharacterFrame")
		frame.rwInSpecialFrames = true
	end
	-- Esc / X / Hide: push saved opinion, tags, and notes into the open roster/history tab.
	frame:SetScript("OnHide", function()
		Addon:RefreshRatingViews()
	end)

	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 1, -1)
	titleBar:SetPoint("TOPRIGHT", -1, -1)
	titleBar:SetHeight(UI.TITLE_H)
	W.ApplyPlainPanel(titleBar, UI.TITLE_BG)
	W.AttachDragHandle(titleBar, frame)

	local close = CreateFrame("Button", nil, titleBar)
	close:SetSize(UI.CLOSE_SIZE, UI.CLOSE_SIZE)
	close:SetPoint("RIGHT", -3, 0)
	local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	closeText:SetPoint("CENTER", 1, 1)
	closeText:SetText("X")
	W.SetFontColor(closeText, UI.GOLD)
	close:SetScript("OnEnter", function()
		closeText:SetTextColor(1, 0.25, 0.25)
	end)
	close:SetScript("OnLeave", function()
		W.SetFontColor(closeText, UI.GOLD)
	end)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local layoutVersionText = W.AttachLayoutVersionLabel(titleBar, PROFILE_LAYOUT_VERSION, close)
	frame.layoutVersionText = layoutVersionText

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", 8, 0)
	title:SetPoint("RIGHT", layoutVersionText, "LEFT", -8, 0)
	title:SetJustifyH("LEFT")
	W.SetFontColor(title, UI.GOLD)
	frame.titleText = title

	local body = CreateFrame("Frame", nil, frame)
	body:SetPoint("TOPLEFT", UI.PAD, -(UI.TITLE_H + UI.PAD))
	body:SetPoint("BOTTOMRIGHT", -UI.PAD, UI.PAD)
	frame.body = body

	local bodyWidth = UI.RAID_DETAIL_W - UI.PAD * 2
	local columnGap = 12
	local columnWidth = math.floor((bodyWidth - columnGap) / 2)
	local iconSize = UI.PROFILE_ICON

	local header = CreateFrame("Frame", nil, body)
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)
	header:SetHeight(iconSize + 22)
	frame.headerSection = header

	local classCell = CreateFrame("Frame", nil, header)
	classCell:SetPoint("TOPLEFT", 0, 0)
	classCell:SetSize(columnWidth, iconSize)
	frame.classCell = classCell

	local raceIconHost = CreateFrame("Frame", nil, classCell)
	raceIconHost:SetSize(iconSize, iconSize)
	raceIconHost:SetPoint("TOPLEFT", 0, 0)
	frame.raceIconHost = raceIconHost

	local raceIcon = raceIconHost:CreateTexture(nil, "ARTWORK")
	raceIcon:SetAllPoints(raceIconHost)
	frame.raceIcon = raceIcon
	raceIconHost:EnableMouse(true)
	raceIconHost:SetScript("OnEnter", function(self)
		local member = frame.profileMember
		if not member then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(ProfileRaceLabel(member.race))
		local factionText = ProfileFactionText(member.faction)
		if factionText ~= "-" then
			GameTooltip:AddLine(factionText, 0.8, 0.8, 0.8)
		end
		GameTooltip:Show()
	end)
	raceIconHost:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local classIconHost = CreateFrame("Frame", nil, classCell)
	classIconHost:SetSize(iconSize, iconSize)
	classIconHost:SetPoint("LEFT", raceIconHost, "RIGHT", 2, 0)
	frame.classIconHost = classIconHost

	local classIcon = classIconHost:CreateTexture(nil, "ARTWORK")
	classIcon:SetAllPoints(classIconHost)
	frame.classIcon = classIcon

	local classText = classCell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	classText:SetPoint("TOPLEFT", classIconHost, "TOPRIGHT", 4, 0)
	classText:SetPoint("BOTTOMLEFT", classIconHost, "BOTTOMRIGHT", 4, 0)
	classText:SetPoint("RIGHT", classCell, "RIGHT", 0, 0)
	classText:SetJustifyH("LEFT")
	classText:SetJustifyV("MIDDLE")
	frame.classText = classText

	local specIconHost = CreateFrame("Frame", nil, header)
	specIconHost:SetSize(iconSize, iconSize)
	specIconHost:SetPoint("TOPLEFT", columnWidth + columnGap, 0)
	frame.specIconHost = specIconHost

	local specIcon = specIconHost:CreateTexture(nil, "ARTWORK")
	specIcon:SetAllPoints(specIconHost)
	frame.specIcon = specIcon

	local specText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	specText:SetPoint("TOPLEFT", specIconHost, "TOPRIGHT", 6, 0)
	specText:SetPoint("BOTTOMLEFT", specIconHost, "BOTTOMRIGHT", 6, 0)
	specText:SetPoint("RIGHT", header, "RIGHT", 0, 0)
	specText:SetJustifyH("LEFT")
	specText:SetJustifyV("MIDDLE")
	frame.specText = specText

	local gsText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	gsText:SetPoint("TOPLEFT", classCell, "BOTTOMLEFT", 0, -4)
	gsText:SetWidth(columnWidth)
	gsText:SetJustifyH("LEFT")
	W.SetFontColor(gsText, UI.TEXT_IDLE)
	frame.gsText = gsText

	local ilvlText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ilvlText:SetPoint("TOPLEFT", specIconHost, "BOTTOMLEFT", 0, -4)
	ilvlText:SetWidth(columnWidth)
	ilvlText:SetJustifyH("LEFT")
	W.SetFontColor(ilvlText, UI.TEXT_IDLE)
	frame.ilvlText = ilvlText

	local summary = CreateFrame("Frame", nil, body)
	summary:SetPoint("TOPLEFT", gsText, "BOTTOMLEFT", 0, -4)
	summary:SetPoint("TOPRIGHT", ilvlText, "BOTTOMRIGHT", 0, -4)
	summary:SetHeight(122)
	frame.summarySection = summary

	local function CreateSummaryLine(parent, anchor, topOffset, width)
		local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		if anchor then
			text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, topOffset or -6)
		else
			text:SetPoint("TOPLEFT", 0, 0)
		end
		text:SetWidth(width)
		text:SetJustifyH("LEFT")
		text:SetJustifyV("TOP")
		W.SetFontColor(text, UI.TEXT_IDLE)
		return text
	end

	frame.opinionText = CreateSummaryLine(summary, nil, 0, columnWidth)
	frame.tagText = CreateSummaryLine(summary, frame.opinionText, -6, columnWidth)
	frame.factText = CreateSummaryLine(summary, frame.tagText, -6, columnWidth)
	frame.guildText = CreateSummaryLine(summary, frame.factText, -6, columnWidth)
	frame.guidText = CreateSummaryLine(summary, frame.guildText, -6, columnWidth)
	frame.metRealmText = CreateSummaryLine(summary, frame.guidText, -6, columnWidth)

	local communityHeading = summary:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	communityHeading:SetPoint("TOPLEFT", columnWidth + columnGap, 0)
	communityHeading:SetWidth(columnWidth)
	communityHeading:SetJustifyH("LEFT")
	W.SetFontColor(communityHeading, UI.GOLD)
	frame.communityHeading = communityHeading

	local communityText = summary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	communityText:SetPoint("TOPLEFT", communityHeading, "BOTTOMLEFT", 0, -4)
	communityText:SetWidth(columnWidth)
	communityText:SetJustifyH("LEFT")
	communityText:SetJustifyV("TOP")
	frame.communityText = communityText

	local tabBar = CreateFrame("Frame", nil, body)
	tabBar:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -8)
	tabBar:SetPoint("TOPRIGHT", summary, "BOTTOMRIGHT", 0, -8)
	tabBar:SetHeight(UI.PROFILE_TAB_H)
	frame.tabBar = tabBar

	frame.profileTabButtons = {}
	frame.profilePanels = {}
	local tabGap = 4
	local tabWidth = math.floor((bodyWidth - tabGap * (#PROFILE_TABS - 1)) / #PROFILE_TABS)
	for index = 1, #PROFILE_TABS do
		local tab = PROFILE_TABS[index]
		local button = CreateProfileTabButton(tabBar, tab.id, T(tab.labelKey), tabWidth)
		if index == 1 then
			button:SetPoint("LEFT", 0, 0)
		else
			button:SetPoint("LEFT", frame.profileTabButtons[index - 1], "RIGHT", tabGap, 0)
		end
		frame.profileTabButtons[index] = button
	end

	local tabHost = CreateFrame("Frame", nil, body)
	tabHost:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
	tabHost:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, UI.ACTION_BTN_H + 8)
	frame.tabHost = tabHost

	local updateBtn = W.CreatePlainButton(body, bodyWidth, UI.ACTION_BTN_H, T("BTN_SAVE_AND_UPDATE"))
	updateBtn:SetPoint("BOTTOMLEFT", 0, 0)
	updateBtn:SetPoint("BOTTOMRIGHT", 0, 0)
	updateBtn:SetScript("OnClick", function()
		Addon:CommitProfileRating()
	end)
	frame.ratingUpdateBtn = updateBtn

	local tabContentWidth = bodyWidth
	local tabContent = CreateFrame("Frame", nil, tabHost)
	tabContent:SetPoint("TOPLEFT", 0, 0)
	tabContent:SetPoint("BOTTOMRIGHT", 0, 0)
	frame.tabContent = tabContent

	local opinionPanel = CreateFrame("Frame", nil, tabContent)
	opinionPanel:SetPoint("TOPLEFT", 0, 0)
	opinionPanel:SetPoint("BOTTOMRIGHT", 0, 0)
	frame.profilePanels.opinion = opinionPanel

	-- Solid header above the tag list (radios here; scroll never covers them).
	local opinionHeader = CreateFrame("Frame", nil, opinionPanel)
	opinionHeader:SetPoint("TOPLEFT", 0, 0)
	opinionHeader:SetPoint("TOPRIGHT", 0, 0)
	opinionHeader:SetHeight(PROFILE_OPINION_HEADER_H)
	opinionHeader:EnableMouse(true)
	opinionHeader:SetFrameLevel(opinionPanel:GetFrameLevel() + 40)
	frame.opinionHeader = opinionHeader

	local summaryLine = opinionHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	summaryLine:SetPoint("TOPLEFT", 0, 0)
	summaryLine:SetPoint("RIGHT", opinionHeader, "RIGHT", 0, 0)
	summaryLine:SetHeight(16)
	summaryLine:SetJustifyH("LEFT")
	summaryLine:SetJustifyV("MIDDLE")
	frame.ratingSummary = summaryLine

	-- Mutually exclusive radios (AceConfigDialog style="radio" / Details RadioOnClick).
	local opinionRow = CreateFrame("Frame", nil, opinionHeader)
	opinionRow:SetPoint("TOPLEFT", summaryLine, "BOTTOMLEFT", 0, -6)
	opinionRow:SetPoint("TOPRIGHT", summaryLine, "BOTTOMRIGHT", 0, -6)
	opinionRow:SetHeight(PROFILE_OPINION_ROW_H)
	frame.opinionRow = opinionRow

	frame.opinionButtons = {}
	local opinionOrder = { "positive", "neutral", "negative" }
	local opinionWidth = math.floor((tabContentWidth - UI.ACTION_BTN_GAP * 2) / 3)
	for index = 1, #opinionOrder do
		local opinionId = opinionOrder[index]
		local radio = CreateOpinionRadio(opinionRow, opinionId, opinionWidth)
		if index == 1 then
			radio.host:SetPoint("LEFT", opinionRow, "LEFT", 0, 0)
		else
			radio.host:SetPoint("LEFT", frame.opinionButtons[index - 1].host, "RIGHT", UI.ACTION_BTN_GAP, 0)
		end
		frame.opinionButtons[index] = radio
	end

	local tagsHeading = opinionHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tagsHeading:SetPoint("TOPLEFT", opinionRow, "BOTTOMLEFT", 0, -6)
	tagsHeading:SetPoint("RIGHT", opinionHeader, "RIGHT", 0, 0)
	tagsHeading:SetJustifyH("LEFT")
	tagsHeading:SetText(T("RATING_TAGS_TITLE"))
	W.SetFontColor(tagsHeading, UI.GOLD)
	frame.tagsHeading = tagsHeading

	frame.profileTabContentWidth = tabContentWidth
	frame.tagGroups = {}

	-- Tag list starts strictly below the mouse-blocking header.
	local tagBody = CreateFrame("Frame", nil, opinionPanel)
	tagBody:SetPoint("TOPLEFT", opinionHeader, "BOTTOMLEFT", 0, -2)
	tagBody:SetPoint("BOTTOMRIGHT", opinionPanel, "BOTTOMRIGHT", 0, 0)
	tagBody:SetFrameLevel(opinionPanel:GetFrameLevel() + 1)
	frame.tagBody = tagBody

	local tagScrollName = "RaidwiseProfileTagScrollV" .. tostring(PROFILE_LAYOUT_VERSION)
	local existingScroll = _G[tagScrollName]
	if existingScroll then
		existingScroll:Hide()
		existingScroll:EnableMouse(false)
		existingScroll:SetParent(nil)
	end
	local tagScroll = CreateFrame("ScrollFrame", tagScrollName, tagBody, "UIPanelScrollFrameTemplate")
	tagScroll:SetPoint("TOPLEFT", 0, 0)
	tagScroll:SetPoint("BOTTOMRIGHT", -24, 0)
	frame.tagScroll = tagScroll

	local tagScrollBar = _G[tagScrollName .. "ScrollBar"]
	if tagScrollBar then
		tagScrollBar:ClearAllPoints()
		tagScrollBar:SetPoint("TOPLEFT", tagBody, "TOPRIGHT", -20, -16)
		tagScrollBar:SetPoint("BOTTOMLEFT", tagBody, "BOTTOMRIGHT", -20, 16)
	end

	local tagContent = CreateFrame("Frame", nil, tagScroll)
	tagContent:SetWidth(tabContentWidth - 28)
	tagScroll:SetScrollChild(tagContent)
	frame.tagContent = tagContent

	local currentY = 0
	local groups = GetRatingTagGroups()
	local columnWidth = math.floor((tabContentWidth - PROFILE_TAG_COL_GAP - 28) / 2)
	for groupIndex = 1, #groups do
		local group = groups[groupIndex]
		local label = tagContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", tagContent, "TOPLEFT", 0, -currentY)
		label:SetPoint("RIGHT", tagContent, "RIGHT", 0, 0)
		label:SetJustifyH("LEFT")
		W.SetFontColor(label, UI.TEXT_HOVER)
		label:SetText(T(group.labelKey))

		local checkboxes = {}
		local leftColumn = CreateFrame("Frame", nil, tagContent)
		leftColumn:SetSize(columnWidth, 1)
		leftColumn:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)

		local rightColumn = CreateFrame("Frame", nil, tagContent)
		rightColumn:SetSize(columnWidth, 1)
		rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", PROFILE_TAG_COL_GAP, 0)

		for tagIndex = 1, #group.tags do
			local tag = group.tags[tagIndex]
			local column = (tagIndex % 2 == 0) and rightColumn or leftColumn
			local rowIndex = math.floor((tagIndex - 1) / 2)
			local checkbox = CreateProfileTagCheckbox(column, tag, group, columnWidth)
			checkbox:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -(rowIndex * PROFILE_TAG_ROW_H))
			checkboxes[#checkboxes + 1] = checkbox
		end

		local rows = math.ceil(#group.tags / 2)
		local columnHeight = rows * PROFILE_TAG_ROW_H
		leftColumn:SetHeight(columnHeight)
		rightColumn:SetHeight(columnHeight)

		frame.tagGroups[#frame.tagGroups + 1] = {
			group = group,
			label = label,
			leftColumn = leftColumn,
			rightColumn = rightColumn,
			checkboxes = checkboxes,
		}
		currentY = currentY + ProfileTagGroupHeight(#group.tags)
	end
	tagContent:SetHeight(math.max(currentY, 1))

	-- Facts tab: role / identity checkboxes (draft until Save and Update).
	local factsPanel = CreateFrame("Frame", nil, tabContent)
	factsPanel:SetPoint("TOPLEFT", 0, 0)
	factsPanel:SetPoint("BOTTOMRIGHT", 0, 0)
	factsPanel:Hide()
	frame.profilePanels.facts = factsPanel

	local factsHeading = factsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	factsHeading:SetPoint("TOPLEFT", 0, 0)
	factsHeading:SetPoint("RIGHT", factsPanel, "RIGHT", 0, 0)
	factsHeading:SetJustifyH("LEFT")
	factsHeading:SetText(T("RATING_FACTS_TITLE"))
	W.SetFontColor(factsHeading, UI.GOLD)
	frame.factsHeading = factsHeading

	local factsHint = factsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	factsHint:SetPoint("TOPLEFT", factsHeading, "BOTTOMLEFT", 0, -4)
	factsHint:SetPoint("RIGHT", factsPanel, "RIGHT", 0, 0)
	factsHint:SetJustifyH("LEFT")
	local maxFacts = (Addon.MaxPersonalFacts and Addon:MaxPersonalFacts()) or 4
	factsHint:SetText(T("RATING_FACTS_HINT", maxFacts))
	W.SetFontColor(factsHint, UI.TEXT_IDLE)
	frame.factsHint = factsHint

	frame.factCheckboxes = {}
	local factCatalog = (Addon.FactCatalog and Addon:FactCatalog()) or {}
	local factColumnWidth = math.floor((tabContentWidth - PROFILE_TAG_COL_GAP) / 2)
	local factLeft = CreateFrame("Frame", nil, factsPanel)
	factLeft:SetSize(factColumnWidth, 1)
	factLeft:SetPoint("TOPLEFT", factsHint, "BOTTOMLEFT", 0, -8)
	local factRight = CreateFrame("Frame", nil, factsPanel)
	factRight:SetSize(factColumnWidth, 1)
	factRight:SetPoint("TOPLEFT", factLeft, "TOPRIGHT", PROFILE_TAG_COL_GAP, 0)
	for factIndex = 1, #factCatalog do
		local fact = factCatalog[factIndex]
		local column = (factIndex % 2 == 0) and factRight or factLeft
		local rowIndex = math.floor((factIndex - 1) / 2)
		local checkbox = CreateProfileFactCheckbox(column, fact, factColumnWidth)
		checkbox:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -(rowIndex * PROFILE_TAG_ROW_H))
		frame.factCheckboxes[#frame.factCheckboxes + 1] = checkbox
	end
	local factRows = math.ceil(math.max(#factCatalog, 1) / 2)
	factLeft:SetHeight(factRows * PROFILE_TAG_ROW_H)
	factRight:SetHeight(factRows * PROFILE_TAG_ROW_H)

	-- Events tab: pick type + Add (immediate), list with remove.
	local eventsPanel = CreateFrame("Frame", nil, tabContent)
	eventsPanel:SetPoint("TOPLEFT", 0, 0)
	eventsPanel:SetPoint("BOTTOMRIGHT", 0, 0)
	eventsPanel:Hide()
	frame.profilePanels.events = eventsPanel

	local eventsAddBtn = W.CreatePlainButton(eventsPanel, 110, UI.ACTION_BTN_H, T("PROFILE_EVENTS_ADD"))
	eventsAddBtn:SetPoint("TOPRIGHT", 0, 0)
	eventsAddBtn:SetScript("OnClick", function()
		if frame.selectedEventType then
			Addon:AddProfileEvent(frame.selectedEventType)
		end
	end)
	frame.eventsAddBtn = eventsAddBtn

	local eventsHeading = eventsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	eventsHeading:SetPoint("TOPLEFT", 0, 0)
	eventsHeading:SetPoint("RIGHT", eventsAddBtn, "LEFT", -8, 0)
	eventsHeading:SetJustifyH("LEFT")
	eventsHeading:SetText(T("PROFILE_TAB_EVENTS"))
	W.SetFontColor(eventsHeading, UI.GOLD)
	frame.eventsHeading = eventsHeading

	local eventsPickLabel = eventsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	eventsPickLabel:SetPoint("TOPLEFT", eventsHeading, "BOTTOMLEFT", 0, -4)
	eventsPickLabel:SetPoint("RIGHT", eventsPanel, "RIGHT", 0, 0)
	eventsPickLabel:SetJustifyH("LEFT")
	eventsPickLabel:SetText(T("PROFILE_EVENTS_PICK_TYPE"))
	W.SetFontColor(eventsPickLabel, UI.TEXT_IDLE)
	frame.eventsPickLabel = eventsPickLabel

	local typePickerHost = CreateFrame("Frame", nil, eventsPanel)
	typePickerHost:SetPoint("TOPLEFT", eventsPickLabel, "BOTTOMLEFT", 0, -6)
	typePickerHost:SetPoint("RIGHT", eventsPanel, "RIGHT", 0, 0)
	typePickerHost:SetHeight(96)
	frame.eventTypePickerHost = typePickerHost

	local typeScrollName = "RaidwiseProfileEventTypeScrollV" .. tostring(PROFILE_LAYOUT_VERSION)
	local existingTypeScroll = _G[typeScrollName]
	if existingTypeScroll then
		existingTypeScroll:Hide()
		existingTypeScroll:SetParent(nil)
	end
	local typeScroll = CreateFrame("ScrollFrame", typeScrollName, typePickerHost, "UIPanelScrollFrameTemplate")
	typeScroll:SetPoint("TOPLEFT", 0, 0)
	typeScroll:SetPoint("BOTTOMRIGHT", -24, 0)

	local typeContent = CreateFrame("Frame", nil, typeScroll)
	typeContent:SetWidth(tabContentWidth - 28)
	typeScroll:SetScrollChild(typeContent)
	frame.eventTypeButtons = {}
	frame.selectedEventType = nil
	local eventTypes = (Addon.EventTypes and Addon:EventTypes()) or {}
	local typeBtnWidth = math.floor((tabContentWidth - 28 - PROFILE_TAG_COL_GAP) / 2)
	local typeY = 0
	for typeIndex = 1, #eventTypes do
		local eventType = eventTypes[typeIndex]
		local col = (typeIndex % 2 == 0) and 1 or 0
		local row = math.floor((typeIndex - 1) / 2)
		local button = CreateFrame("Button", nil, typeContent)
		button:SetSize(typeBtnWidth, 20)
		button:SetPoint("TOPLEFT", typeContent, "TOPLEFT", col * (typeBtnWidth + PROFILE_TAG_COL_GAP), -(row * 22))
		W.ApplyPlainPanel(button, UI.BTN_IDLE)
		button.eventTypeId = eventType.id
		local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", 6, 0)
		label:SetPoint("RIGHT", -6, 0)
		label:SetJustifyH("LEFT")
		label:SetText(Addon.EventTypeLabel and Addon:EventTypeLabel(eventType.id) or eventType.id)
		button.label = label
		button:SetScript("OnEnter", function(self)
			W.SetMenuButtonState(self, frame.selectedEventType == self.eventTypeId, true)
		end)
		button:SetScript("OnLeave", function(self)
			W.SetMenuButtonState(self, frame.selectedEventType == self.eventTypeId, false)
		end)
		button:SetScript("OnClick", function(self)
			frame.selectedEventType = self.eventTypeId
			for _, other in ipairs(frame.eventTypeButtons) do
				W.SetMenuButtonState(other, other.eventTypeId == frame.selectedEventType, false)
			end
		end)
		frame.eventTypeButtons[#frame.eventTypeButtons + 1] = button
		typeY = math.max(typeY, (row + 1) * 22)
	end
	typeContent:SetHeight(math.max(typeY, 1))
	if #eventTypes > 0 then
		frame.selectedEventType = eventTypes[1].id
		W.SetMenuButtonState(frame.eventTypeButtons[1], true, false)
	end

	local eventsListHost = CreateFrame("Frame", nil, eventsPanel)
	eventsListHost:SetPoint("TOPLEFT", typePickerHost, "BOTTOMLEFT", 0, -8)
	eventsListHost:SetPoint("BOTTOMRIGHT", eventsPanel, "BOTTOMRIGHT", 0, 0)
	frame.eventsListHost = eventsListHost

	local eventsListScrollName = "RaidwiseProfileEventListScrollV" .. tostring(PROFILE_LAYOUT_VERSION)
	local existingEventListScroll = _G[eventsListScrollName]
	if existingEventListScroll then
		existingEventListScroll:Hide()
		existingEventListScroll:SetParent(nil)
	end
	local eventsListScroll = CreateFrame("ScrollFrame", eventsListScrollName, eventsListHost, "UIPanelScrollFrameTemplate")
	eventsListScroll:SetPoint("TOPLEFT", 0, 0)
	eventsListScroll:SetPoint("BOTTOMRIGHT", -24, 0)
	frame.eventsListScroll = eventsListScroll

	local eventsListContent = CreateFrame("Frame", nil, eventsListScroll)
	eventsListContent:SetWidth(tabContentWidth - 28)
	eventsListScroll:SetScrollChild(eventsListContent)
	frame.eventsListContent = eventsListContent
	frame.eventRows = {}
	frame.eventRemoveButtons = {}

	local notesPanel = CreateFrame("Frame", nil, tabContent)
	notesPanel:SetPoint("TOPLEFT", 0, 0)
	notesPanel:SetPoint("TOPRIGHT", 0, 0)
	notesPanel:SetHeight(190)
	notesPanel:Hide()
	frame.profilePanels.notes = notesPanel

	local notesHeading = notesPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	notesHeading:SetPoint("TOPLEFT", 0, 0)
	notesHeading:SetPoint("RIGHT", notesPanel, "RIGHT", 0, 0)
	notesHeading:SetJustifyH("LEFT")
	notesHeading:SetText(T("PROFILE_NOTES"))
	W.SetFontColor(notesHeading, UI.GOLD)
	frame.notesHeading = notesHeading

	local notesHint = notesPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	notesHint:SetPoint("TOPLEFT", notesHeading, "BOTTOMLEFT", 0, -4)
	notesHint:SetPoint("RIGHT", notesPanel, "RIGHT", 0, 0)
	notesHint:SetJustifyH("LEFT")
	notesHint:SetJustifyV("TOP")
	notesHint:SetText(T("PROFILE_MEMO_HINT"))
	W.SetFontColor(notesHint, UI.TEXT_IDLE)
	frame.notesHint = notesHint

	local notesHost, notesBox = CreateProfileNotesBox(notesPanel, tabContentWidth, 96)
	notesHost:SetPoint("TOPLEFT", notesHint, "BOTTOMLEFT", 0, -8)
	frame.notesHost = notesHost
	frame.notesBox = notesBox

	local notesButtonWidth = math.floor((tabContentWidth - UI.ACTION_BTN_GAP) / 2)
	local notesSaveBtn = W.CreatePlainButton(notesPanel, notesButtonWidth, UI.ACTION_BTN_H, T("BTN_SAVE"))
	notesSaveBtn:SetPoint("TOPLEFT", notesHost, "BOTTOMLEFT", 0, -8)
	notesSaveBtn:SetScript("OnClick", function()
		if frame.notesBox then
			frame.notesBox:ClearFocus()
			Addon:SaveProfileNotes(frame.notesBox:GetText() or "")
		end
	end)
	frame.notesSaveBtn = notesSaveBtn

	local notesResetBtn = W.CreatePlainButton(notesPanel, notesButtonWidth, UI.ACTION_BTN_H, T("BTN_RESET"))
	notesResetBtn:SetPoint("LEFT", notesSaveBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	notesResetBtn:SetScript("OnClick", function()
		Addon:ResetProfileNotes()
	end)
	frame.notesResetBtn = notesResetBtn

	local historyPanel = CreateFrame("Frame", nil, tabContent)
	historyPanel:SetPoint("TOPLEFT", 0, 0)
	historyPanel:SetPoint("TOPRIGHT", 0, 0)
	historyPanel:SetHeight(200)
	historyPanel:Hide()
	frame.profilePanels.history = historyPanel

	local historyText = historyPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	historyText:SetPoint("TOPLEFT", 0, 0)
	historyText:SetPoint("RIGHT", historyPanel, "RIGHT", 0, 0)
	historyText:SetJustifyH("LEFT")
	historyText:SetJustifyV("TOP")
	frame.historyText = historyText

	frame.selectedProfileTab = "opinion"

	return frame
end

function Addon:ShowRaidCharacterWindow(member)
	if not member then
		return
	end

	if self.HistoryProfileForMember then
		member = self:HistoryProfileForMember(member)
	end

	if member.unit and UnitExists(member.unit) and UnitSex then
		member.gender = UnitSex(member.unit)
	end

	if ProfileFrameNeedsRebuild(self.raidDetailFrame) then
		if self.raidDetailFrame then
			self.raidDetailFrame:Hide()
			self.raidDetailFrame:SetParent(nil)
		end
		self.raidDetailFrame = nil
	end

	local frame = self.raidDetailFrame
	if not frame then
		local ok, created = pcall(CreateRaidCharacterWindow)
		if not ok then
			self:Print("Character profile failed to open: " .. tostring(created))
			return
		end
		frame = created
		self.raidDetailFrame = frame
	end

	frame.profileMember = member

	frame.titleText:SetText(T("PROFILE_TITLE", member.name or "?"))
	W.SetSpecOrClassIcon(frame.classIcon, nil, member.class)
	frame.classText:SetText(member.classLabel ~= "" and member.classLabel or "-")
	frame.classText:SetTextColor(W.ClassColor(member.class))

	if member.specIcon and member.specIcon ~= "" then
		W.SetSpecOrClassIcon(frame.specIcon, member.specIcon, member.class)
		frame.specIcon:Show()
	else
		W.SetSpecOrClassIcon(frame.specIcon, nil, member.class)
		frame.specIcon:Show()
	end
	frame.specText:SetText((member.spec and member.spec ~= "") and member.spec or "-")
	W.SetFontColor(frame.specText, UI.TEXT_IDLE)

	if member.gearScore then
		frame.gsText:SetText(T("PROFILE_GS", tostring(member.gearScore)))
		W.SetFontColor(frame.gsText, UI.GOLD)
	else
		frame.gsText:SetText(T("PROFILE_GS", "-"))
		W.SetFontColor(frame.gsText, UI.TEXT_DISABLED)
	end

	if member.averageIlvl then
		frame.ilvlText:SetText(T("PROFILE_ILVL", tostring(member.averageIlvl)))
		W.SetFontColor(frame.ilvlText, UI.TEXT_IDLE)
	else
		frame.ilvlText:SetText(T("PROFILE_ILVL", "-"))
		W.SetFontColor(frame.ilvlText, UI.TEXT_DISABLED)
	end

	if SetProfileRaceIcon(frame.raceIcon, member.race, member.gender) then
		frame.raceIconHost:Show()
		frame.classIconHost:ClearAllPoints()
		frame.classIconHost:SetPoint("LEFT", frame.raceIconHost, "RIGHT", 2, 0)
	else
		frame.raceIconHost:Hide()
		frame.classIconHost:ClearAllPoints()
		frame.classIconHost:SetPoint("TOPLEFT", frame.classCell, "TOPLEFT", 0, 0)
	end

	frame.guildText:SetText(T("PROFILE_GUILD", W.FormatGuildDisplay(member.guildName, member.guildRank)))
	W.SetFontColor(frame.guildText, UI.TEXT_IDLE)

	InitProfileDraft(frame, member)
	PaintSavedHeaderLabels(frame, member)
	PaintDraftEditorLabels(frame)

	if member.guid and member.guid ~= "" then
		frame.guidText:SetText(T("PROFILE_GUID", member.guid))
		W.SetFontColor(frame.guidText, UI.TEXT_IDLE)
	else
		frame.guidText:SetText(T("PROFILE_GUID", "-"))
		W.SetFontColor(frame.guidText, UI.TEXT_DISABLED)
	end

	if member.metRealm and member.metRealm ~= "" then
		frame.metRealmText:SetText(T("PROFILE_REALM", member.metRealm))
		W.SetFontColor(frame.metRealmText, UI.TEXT_IDLE)
	else
		frame.metRealmText:SetText(T("PROFILE_REALM", "-"))
		W.SetFontColor(frame.metRealmText, UI.TEXT_DISABLED)
	end

	if frame.profileTabButtons then
		for index = 1, #PROFILE_TABS do
			local button = frame.profileTabButtons[index]
			local tab = PROFILE_TABS[index]
			if button and button.label and tab then
				button.label:SetText(T(tab.labelKey))
			end
		end
	end

	if frame.tagsHeading then
		frame.tagsHeading:SetText(T("RATING_TAGS_TITLE"))
	end
	if frame.notesHeading then
		frame.notesHeading:SetText(T("PROFILE_NOTES"))
	end
	if frame.notesHint then
		frame.notesHint:SetText(T("PROFILE_MEMO_HINT"))
	end
	if frame.notesBox then
		frame.isUpdatingNotes = true
		frame.notesBox:SetText(member.notes or "")
		frame.isUpdatingNotes = false
	end
	if frame.ratingUpdateBtn then
		frame.ratingUpdateBtn.label:SetText(T("BTN_SAVE_AND_UPDATE"))
	end

	UpdateProfileEditor(frame, member)
	local editable = member.guid and member.guid ~= ""
	local draftOpinion = GetProfileDraft(frame)
	if frame.opinionButtons then
		for _, button in ipairs(frame.opinionButtons) do
			if editable then
				button:Enable()
				if button.hit then
					button.hit:Enable()
				end
			else
				button:Disable()
				if button.hit then
					button.hit:Disable()
				end
			end
		end
		RefreshOpinionRadios(frame, draftOpinion)
	end
	if frame.tagGroups then
		RefreshProfileTagCheckboxes(frame, member, editable)
	end
	if frame.factCheckboxes then
		RefreshProfileFactCheckboxes(frame, member, editable)
	end
	if frame.eventsAddBtn then
		if editable then
			frame.eventsAddBtn:Enable()
		else
			frame.eventsAddBtn:Disable()
		end
	end
	if frame.eventTypeButtons then
		for _, button in ipairs(frame.eventTypeButtons) do
			if editable then
				button:Enable()
			else
				button:Disable()
			end
		end
	end
	if frame.ratingUpdateBtn then
		if editable then
			frame.ratingUpdateBtn:Enable()
		else
			frame.ratingUpdateBtn:Disable()
		end
	end
	if frame.notesBox and frame.notesHost then
		if editable then
			frame.notesBox:EnableMouse(true)
			frame.notesBox:EnableKeyboard(true)
			frame.notesBox:SetTextColor(1, 1, 1)
			frame.notesHost:SetAlpha(1)
		else
			frame.notesBox:ClearFocus()
			frame.notesBox:EnableMouse(false)
			frame.notesBox:EnableKeyboard(false)
			frame.notesBox:SetTextColor(0.6, 0.6, 0.6)
			frame.notesHost:SetAlpha(0.6)
		end
	end
	if frame.notesSaveBtn then
		frame.notesSaveBtn.label:SetText(T("BTN_SAVE"))
		if editable then
			frame.notesSaveBtn:Enable()
		else
			frame.notesSaveBtn:Disable()
		end
	end
	if frame.notesResetBtn then
		frame.notesResetBtn.label:SetText(T("BTN_RESET"))
		if editable then
			frame.notesResetBtn:Enable()
		else
			frame.notesResetBtn:Disable()
		end
	end
	self:SelectProfileTab(frame.selectedProfileTab or "opinion")

	frame:Show()
	frame:Raise()
end

