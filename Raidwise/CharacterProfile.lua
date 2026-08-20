-- Character profile window (standalone): opinion, tags, notes, history.

local Addon = Raidwise

local function T(key, ...)
	if Addon.T then
		return Addon:T(key, ...)
	end
	return tostring(key or "")
end

-- Profile-local sizes/colors (keep in sync with docs/UI-Sizes.md Character profile).
local UI = {
	PAD = 10,
	TITLE_H = 20,
	CLOSE_SIZE = 16,
	CHECK_SIZE = 24,
	ACTION_BTN_H = 28,
	ACTION_BTN_GAP = 8,
	PROFILE_ICON = 24,
	RAID_DETAIL_W = 430,
	RAID_DETAIL_H = 540,
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

local COPY_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 },
}

local function ApplyPlainPanel(frame, color)
	color = color or UI.PANEL_BG
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true,
		tileSize = 16,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)

	if frame.rwBorderTop then
		return
	end

	local function Edge(layerPointA, relA, layerPointB, relB, width, height)
		local tex = frame:CreateTexture(nil, "BORDER")
		tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		tex:SetVertexColor(0, 0, 0, 1)
		tex:SetPoint(layerPointA, frame, relA)
		tex:SetPoint(layerPointB, frame, relB)
		if width then
			tex:SetWidth(width)
		end
		if height then
			tex:SetHeight(height)
		end
		return tex
	end

	frame.rwBorderTop = Edge("TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1)
	frame.rwBorderBottom = Edge("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1)
	frame.rwBorderLeft = Edge("TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil)
	frame.rwBorderRight = Edge("TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil)
end

local function SetFontColor(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function SetPlainButtonState(button, state)
	if state == "selected" then
		button:SetBackdropColor(UI.BTN_SELECTED[1], UI.BTN_SELECTED[2], UI.BTN_SELECTED[3], UI.BTN_SELECTED[4])
		SetFontColor(button.label, UI.GOLD)
	elseif state == "hover" then
		button:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		SetFontColor(button.label, UI.TEXT_HOVER)
	elseif state == "disabled" then
		button:SetBackdropColor(UI.BTN_DISABLED[1], UI.BTN_DISABLED[2], UI.BTN_DISABLED[3], UI.BTN_DISABLED[4])
		SetFontColor(button.label, UI.TEXT_DISABLED)
	else
		button:SetBackdropColor(UI.BTN_IDLE[1], UI.BTN_IDLE[2], UI.BTN_IDLE[3], UI.BTN_IDLE[4])
		SetFontColor(button.label, UI.TEXT_IDLE)
	end
end

local function ActionButtonState(button, hovering)
	if not button:IsEnabled() then
		return "disabled"
	end
	if hovering then
		return "hover"
	end
	return "idle"
end

local function CreatePlainButton(parent, width, height, label)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, height)
	ApplyPlainPanel(button, UI.BTN_IDLE)

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 0)
	text:SetText(label)
	SetFontColor(text, UI.TEXT_IDLE)
	button.label = text

	button:SetScript("OnEnter", function(self)
		SetPlainButtonState(self, ActionButtonState(self, true))
	end)
	button:SetScript("OnLeave", function(self)
		SetPlainButtonState(self, ActionButtonState(self, false))
	end)
	button:SetScript("OnEnable", function(self)
		SetPlainButtonState(self, ActionButtonState(self, false))
	end)
	button:SetScript("OnDisable", function(self)
		SetPlainButtonState(self, "disabled")
	end)

	return button
end

local function SetMenuButtonState(button, selected, hovering)
	if selected then
		SetPlainButtonState(button, "selected")
	elseif hovering then
		SetPlainButtonState(button, "hover")
	else
		SetPlainButtonState(button, "idle")
	end
end

local function AttachDragHandle(handle, target)
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		target:StartMoving()
	end)
	handle:SetScript("OnDragStop", function()
		target:StopMovingOrSizing()
	end)
end

local function ChatFontLineHeight()
	local _, fontSize = ChatFontNormal:GetFont()
	fontSize = tonumber(fontSize) or 14
	return fontSize + 2
end

local function ClassColor(classToken)
	local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
	if color then
		return color.r, color.g, color.b
	end
	return UI.TEXT_IDLE[1], UI.TEXT_IDLE[2], UI.TEXT_IDLE[3]
end

local ICON_TEX_INSET = 0.07
local ICON_TEX_MAX = 1 - ICON_TEX_INSET

local function SetSpecOrClassIcon(texture, specIcon, classToken)
	if specIcon and specIcon ~= "" then
		texture:SetTexture(specIcon)
		texture:SetTexCoord(ICON_TEX_INSET, ICON_TEX_MAX, ICON_TEX_INSET, ICON_TEX_MAX)
		return
	end
	texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
	local coords = CLASS_ICON_TCOORDS and classToken and CLASS_ICON_TCOORDS[classToken]
	if coords then
		texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

local function FormatGuildDisplay(guildName, guildRank)
	if not guildName or guildName == "" then
		return "-"
	end
	if guildRank and guildRank ~= "" then
		return guildName .. " (" .. guildRank .. ")"
	end
	return guildName
end

local function RatingOpinion(member)
	if Addon.GetPersonalRating then
		local rating = Addon:GetPersonalRating(member)
		return rating.opinion, rating.tags
	end
	return "neutral", {}
end

local function RatingOpinionColor(member)
	local opinion = RatingOpinion(member)
	if Addon.RatingOpinionColor then
		return Addon:RatingOpinionColor(opinion)
	end
	return UI.TEXT_IDLE
end

local function FormatOpinionLine(member)
	local opinion = RatingOpinion(member)
	local label = opinion
	if Addon.RatingOpinionLabel then
		label = Addon:RatingOpinionLabel(opinion)
	end
	return T("RATING_PROFILE_OPINION", label)
end

local function FormatTagLine(member)
	local _, tags = RatingOpinion(member)
	if Addon.RatingTagColoredSummary then
		return Addon:RatingTagColoredSummary(tags, 3)
	end
	return ""
end

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

local PROFILE_LAYOUT_VERSION = 21

-- Fixed header above the tag scroll (opinion radios live here; scroll starts below).
local PROFILE_OPINION_HEADER_H = 108
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
	host:SetBackdrop(COPY_BACKDROP)
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
			y = y + (cursorHeight or ChatFontLineHeight()) - scroll:GetHeight()
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
	{ id = "opinion", labelKey = "PROFILE_TAB_OPINION" },
	{ id = "notes", labelKey = "PROFILE_TAB_NOTES" },
	{ id = "history", labelKey = "PROFILE_TAB_HISTORY" },
}

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
			SetMenuButtonState(button, button.tabId == tabId, false)
		end
	end
end

local function CreateProfileTabButton(parent, tabId, label, width)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, UI.PROFILE_TAB_H)
	ApplyPlainPanel(button, UI.BTN_IDLE)
	button.tabId = tabId

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", 6, 0)
	text:SetPoint("RIGHT", -6, 0)
	text:SetJustifyH("CENTER")
	text:SetText(label)
	button.label = text

	button:SetScript("OnEnter", function(self)
		SetMenuButtonState(self, Addon.raidDetailFrame and Addon.raidDetailFrame.selectedProfileTab == tabId, true)
	end)
	button:SetScript("OnLeave", function(self)
		SetMenuButtonState(self, Addon.raidDetailFrame and Addon.raidDetailFrame.selectedProfileTab == tabId, false)
	end)
	button:SetScript("OnClick", function()
		Addon:SelectProfileTab(tabId)
	end)
	SetMenuButtonState(button, false, false)
	return button
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
				SetFontColor(radio.label, checked and UI.GOLD or UI.TEXT_IDLE)
			else
				SetFontColor(radio.label, UI.TEXT_DISABLED)
			end
		end
		radio.isUpdating = false
	end
end

-- Paint Personal note + Summary from the chosen opinion immediately (same click as radios).
local function PaintOpinionLabels(frame, opinionId, tags)
	if not frame then
		return
	end
	opinionId = opinionId or "neutral"
	tags = tags or {}
	local label = OpinionButtonLabel(opinionId)
	local color = UI.TEXT_IDLE
	if Addon.RatingOpinionColor then
		color = Addon:RatingOpinionColor(opinionId)
	end
	if frame.karmaText then
		frame.karmaText:SetText(T("RATING_PROFILE_OPINION", label))
		SetFontColor(frame.karmaText, color)
	end
	if frame.tagText then
		local tagSummary = ""
		if Addon.RatingTagColoredSummary then
			tagSummary = Addon:RatingTagColoredSummary(tags, 3) or ""
		end
		if tagSummary ~= "" then
			frame.tagText:SetText(tagSummary)
			SetFontColor(frame.tagText, UI.TEXT_IDLE)
		else
			frame.tagText:SetText(T("RATING_TAGS_NONE"))
			SetFontColor(frame.tagText, UI.TEXT_DISABLED)
		end
	end
	if frame.ratingSummary then
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

local function ApplyOpinionChoice(opinionId)
	if not opinionId then
		return
	end
	PlaySound("igMainMenuOptionCheckBoxOn")
	local frame = Addon.raidDetailFrame
	local tags = {}
	if frame and frame.profileMember and Addon.GetPersonalRating then
		tags = Addon:GetPersonalRating(frame.profileMember).tags
	end
	-- Paint exclusivity + labels first (Details RadioOnClick: UI then persist).
	RefreshOpinionRadios(frame, opinionId)
	PaintOpinionLabels(frame, opinionId, tags)
	if frame and frame.profileMember then
		frame.profileMember.rating = frame.profileMember.rating or {}
		frame.profileMember.rating.personal = {
			opinion = opinionId,
			tags = tags,
			updatedAt = time(),
		}
	end
	Addon:SetProfileOpinion(opinionId)
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
	SetFontColor(label, UI.TEXT_IDLE)
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

local function CountSelectedTagsInGroup(personal, group)
	if type(personal) ~= "table" or type(group) ~= "table" or type(group.tags) ~= "table" then
		return 0
	end
	local selected = {}
	for index = 1, #personal.tags do
		selected[personal.tags[index]] = true
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
			SetFontColor(checkbox.label, checkbox.labelColor or UI.TEXT_IDLE)
		end
		if checkbox.hit then
			checkbox.hit:Enable()
		end
	else
		checkbox:Disable()
		checkbox:SetAlpha(0.55)
		if checkbox.label then
			SetFontColor(checkbox.label, UI.TEXT_DISABLED)
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
	local personal
	if member and Addon.GetPersonalRating then
		personal = Addon:GetPersonalRating(member)
		for index = 1, #personal.tags do
			selected[personal.tags[index]] = true
		end
	end

	for _, entry in ipairs(frame.tagGroups) do
		if entry.label then
			entry.label:SetText(T(entry.group.labelKey))
		end
		local groupCount = personal and CountSelectedTagsInGroup(personal, entry.group) or 0
		for _, checkbox in ipairs(entry.checkboxes) do
			local tagId = checkbox.tagId
			local isSelected = selected[tagId] and true or false
			local canUse = editable and (isSelected or groupCount < 3)
			SetProfileTagCheckboxState(checkbox, isSelected, canUse)
		end
	end
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
	SetFontColor(label, check.labelColor)
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
		if wantChecked then
			local profileFrame = Addon.raidDetailFrame
			local profileMember = profileFrame and profileFrame.profileMember
			if profileMember and Addon.GetPersonalRating then
				local currentPersonal = Addon:GetPersonalRating(profileMember)
				if CountSelectedTagsInGroup(currentPersonal, group) >= 3 then
					self:SetChecked(false)
					Addon:Print(Addon:T("RATING_GROUP_LIMIT"))
					return
				end
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
	if frame.karmaText then
		frame.karmaText:SetText(FormatOpinionLine(member))
		SetFontColor(frame.karmaText, RatingOpinionColor(member))
	end
	if frame.tagText then
		local tagSummary = FormatTagLine(member)
		if tagSummary ~= "" then
			frame.tagText:SetText(tagSummary)
			SetFontColor(frame.tagText, UI.TEXT_IDLE)
		else
			frame.tagText:SetText(T("RATING_TAGS_NONE"))
			SetFontColor(frame.tagText, UI.TEXT_DISABLED)
		end
	end
	if frame.ratingSummary and Addon.RatingProfileSummary then
		frame.ratingSummary:SetText(Addon:RatingProfileSummary(member))
	end
	if frame.opinionButtons then
		local opinion = "neutral"
		if Addon.GetPersonalRating then
			opinion = Addon:GetPersonalRating(member).opinion
		end
		RefreshOpinionRadios(frame, opinion)
	end
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

function Addon:SaveProfilePersonalRating(opinion, tagIds, options)
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member or not member.guid or member.guid == "" or not self.SavePersonalRatingForGuid then
		return
	end
	local entry = self:SavePersonalRatingForGuid(member.guid, member, opinion, tagIds)
	if not entry then
		return
	end
	-- Rebuild from the saved history entry so opinion/tags match the DB on first click.
	frame.profileMember = self:HistoryProfileForMember(entry)
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
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member then
		return
	end
	local personal = self:GetPersonalRating(member)
	self:SaveProfilePersonalRating(opinion, personal.tags, { opinionOnly = true, deferViewRefresh = true })
end

function Addon:ToggleProfileTag(tagId)
	local frame = self.raidDetailFrame
	local member = frame and frame.profileMember
	if not member then
		return
	end
	local personal = self:GetPersonalRating(member)
	local tag = self.RatingTagById and self:RatingTagById(tagId) or nil
	local nextTags = {}
	local seen = false
	for index = 1, #personal.tags do
		local current = personal.tags[index]
		if current ~= tagId then
			nextTags[#nextTags + 1] = current
		else
			seen = true
		end
	end
	if not seen then
		if tag and tag.groupId then
			local selectedCount = 0
			for index = 1, #personal.tags do
				local currentTag = self:RatingTagById(personal.tags[index])
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
	self:SaveProfilePersonalRating(personal.opinion, nextTags, { deferViewRefresh = true, tagsOnly = true })
end

local function AttachLayoutVersionLabel(titleBar, version)
	-- Reusable title-bar badge for view layout versions (profile first; other windows later).
	local label = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("RIGHT", -(UI.CLOSE_SIZE + 8), 0)
	label:SetJustifyH("RIGHT")
	label:SetText("v" .. tostring(version))
	SetFontColor(label, UI.TEXT_DISABLED)
	titleBar.layoutVersionText = label
	return label
end

local function DetachFrameChildren(frame)
	if not frame or not frame.GetChildren then
		return
	end
	local children = { frame:GetChildren() }
	for index = 1, #children do
		local child = children[index]
		child:Hide()
		if child.EnableMouse then
			child:EnableMouse(false)
		end
		if child.EnableMouseWheel then
			child:EnableMouseWheel(false)
		end
		child:SetParent(nil)
	end
end

local function CreateRaidCharacterWindow()
	local frame = CreateFrame("Frame", "RaidwiseRaidCharacterFrame", UIParent)
	-- Named frames are reused; drop old children so prior layouts cannot steal clicks.
	DetachFrameChildren(frame)
	frame:SetSize(UI.RAID_DETAIL_W, UI.RAID_DETAIL_H)
	frame:SetPoint("CENTER", 40, 20)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:Hide()
	ApplyPlainPanel(frame)
	frame.layoutVersion = PROFILE_LAYOUT_VERSION
	frame.opinionButtons = nil
	frame.profileTabButtons = nil
	frame.profilePanels = nil
	frame.tagGroups = nil
	if not frame.rwInSpecialFrames then
		tinsert(UISpecialFrames, "RaidwiseRaidCharacterFrame")
		frame.rwInSpecialFrames = true
	end

	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 1, -1)
	titleBar:SetPoint("TOPRIGHT", -1, -1)
	titleBar:SetHeight(UI.TITLE_H)
	ApplyPlainPanel(titleBar, UI.TITLE_BG)
	AttachDragHandle(titleBar, frame)

	local close = CreateFrame("Button", nil, titleBar)
	close:SetSize(UI.CLOSE_SIZE, UI.CLOSE_SIZE)
	close:SetPoint("RIGHT", -3, 0)
	local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	closeText:SetPoint("CENTER", 1, 1)
	closeText:SetText("X")
	SetFontColor(closeText, UI.GOLD)
	close:SetScript("OnEnter", function()
		closeText:SetTextColor(1, 0.25, 0.25)
	end)
	close:SetScript("OnLeave", function()
		SetFontColor(closeText, UI.GOLD)
	end)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local layoutVersionText = AttachLayoutVersionLabel(titleBar, PROFILE_LAYOUT_VERSION)
	frame.layoutVersionText = layoutVersionText

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", 8, 0)
	title:SetPoint("RIGHT", layoutVersionText, "LEFT", -8, 0)
	title:SetJustifyH("LEFT")
	SetFontColor(title, UI.GOLD)
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
	SetFontColor(gsText, UI.TEXT_IDLE)
	frame.gsText = gsText

	local ilvlText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	ilvlText:SetPoint("TOPLEFT", specIconHost, "BOTTOMLEFT", 0, -4)
	ilvlText:SetWidth(columnWidth)
	ilvlText:SetJustifyH("LEFT")
	SetFontColor(ilvlText, UI.TEXT_IDLE)
	frame.ilvlText = ilvlText

	local summary = CreateFrame("Frame", nil, body)
	summary:SetPoint("TOPLEFT", gsText, "BOTTOMLEFT", 0, -4)
	summary:SetPoint("TOPRIGHT", ilvlText, "BOTTOMRIGHT", 0, -4)
	summary:SetHeight(104)
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
		SetFontColor(text, UI.TEXT_IDLE)
		return text
	end

	frame.karmaText = CreateSummaryLine(summary, nil, 0, columnWidth)
	frame.tagText = CreateSummaryLine(summary, frame.karmaText, -6, columnWidth)
	frame.guildText = CreateSummaryLine(summary, frame.tagText, -6, columnWidth)
	frame.guidText = CreateSummaryLine(summary, frame.guildText, -6, columnWidth)
	frame.metRealmText = CreateSummaryLine(summary, frame.guidText, -6, columnWidth)

	local communityHeading = summary:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	communityHeading:SetPoint("TOPLEFT", columnWidth + columnGap, 0)
	communityHeading:SetWidth(columnWidth)
	communityHeading:SetJustifyH("LEFT")
	SetFontColor(communityHeading, UI.GOLD)
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
	local tabWidth = math.floor((bodyWidth - 16) / #PROFILE_TABS)
	for index = 1, #PROFILE_TABS do
		local tab = PROFILE_TABS[index]
		local button = CreateProfileTabButton(tabBar, tab.id, T(tab.labelKey), tabWidth)
		if index == 1 then
			button:SetPoint("LEFT", 0, 0)
		else
			button:SetPoint("LEFT", frame.profileTabButtons[index - 1], "RIGHT", 8, 0)
		end
		frame.profileTabButtons[index] = button
	end

	local tabHost = CreateFrame("Frame", nil, body)
	tabHost:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
	tabHost:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
	frame.tabHost = tabHost

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

	local ratingHeading = opinionHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ratingHeading:SetPoint("TOPLEFT", 0, 0)
	ratingHeading:SetPoint("RIGHT", opinionHeader, "RIGHT", 0, 0)
	ratingHeading:SetJustifyH("LEFT")
	ratingHeading:SetText(T("RATING_PERSONAL_OPINION_TITLE"))
	SetFontColor(ratingHeading, UI.GOLD)
	frame.ratingHeading = ratingHeading

	local summaryLine = opinionHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	summaryLine:SetPoint("TOPLEFT", ratingHeading, "BOTTOMLEFT", 0, -6)
	summaryLine:SetPoint("RIGHT", opinionHeader, "RIGHT", 0, 0)
	summaryLine:SetHeight(16)
	summaryLine:SetJustifyH("LEFT")
	summaryLine:SetJustifyV("MIDDLE")
	frame.ratingSummary = summaryLine

	-- Mutually exclusive radios (AceConfigDialog style="radio" / Details RadioOnClick).
	local opinionRow = CreateFrame("Frame", nil, opinionHeader)
	opinionRow:SetPoint("TOPLEFT", summaryLine, "BOTTOMLEFT", 0, -8)
	opinionRow:SetPoint("TOPRIGHT", summaryLine, "BOTTOMRIGHT", 0, -8)
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
	tagsHeading:SetPoint("TOPLEFT", opinionRow, "BOTTOMLEFT", 0, -12)
	tagsHeading:SetPoint("RIGHT", opinionHeader, "RIGHT", 0, 0)
	tagsHeading:SetJustifyH("LEFT")
	tagsHeading:SetText(T("RATING_TAGS_TITLE"))
	SetFontColor(tagsHeading, UI.GOLD)
	frame.tagsHeading = tagsHeading

	frame.profileTabContentWidth = tabContentWidth
	frame.tagGroups = {}

	-- Tag list starts strictly below the mouse-blocking header.
	local tagBody = CreateFrame("Frame", nil, opinionPanel)
	tagBody:SetPoint("TOPLEFT", opinionHeader, "BOTTOMLEFT", 0, -4)
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
		SetFontColor(label, UI.TEXT_HOVER)
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

	local notesPanel = CreateFrame("Frame", nil, tabContent)
	notesPanel:SetPoint("TOPLEFT", 0, 0)
	notesPanel:SetPoint("TOPRIGHT", 0, 0)
	notesPanel:SetHeight(140)
	notesPanel:Hide()
	frame.profilePanels.notes = notesPanel

	local notesHeading = notesPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	notesHeading:SetPoint("TOPLEFT", 0, 0)
	notesHeading:SetPoint("RIGHT", notesPanel, "RIGHT", 0, 0)
	notesHeading:SetJustifyH("LEFT")
	notesHeading:SetText(T("PROFILE_NOTES"))
	SetFontColor(notesHeading, UI.GOLD)
	frame.notesHeading = notesHeading

	local notesHost, notesBox = CreateProfileNotesBox(notesPanel, tabContentWidth, 96)
	notesHost:SetPoint("TOPLEFT", notesHeading, "BOTTOMLEFT", 0, -8)
	frame.notesHost = notesHost
	frame.notesBox = notesBox

	local notesButtonWidth = math.floor((tabContentWidth - UI.ACTION_BTN_GAP) / 2)
	local notesSaveBtn = CreatePlainButton(notesPanel, notesButtonWidth, UI.ACTION_BTN_H, T("BTN_SAVE"))
	notesSaveBtn:SetPoint("TOPLEFT", notesHost, "BOTTOMLEFT", 0, -8)
	notesSaveBtn:SetScript("OnClick", function()
		if frame.notesBox then
			frame.notesBox:ClearFocus()
			Addon:SaveProfileNotes(frame.notesBox:GetText() or "")
		end
	end)
	frame.notesSaveBtn = notesSaveBtn

	local notesResetBtn = CreatePlainButton(notesPanel, notesButtonWidth, UI.ACTION_BTN_H, T("BTN_RESET"))
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
	SetSpecOrClassIcon(frame.classIcon, nil, member.class)
	frame.classText:SetText(member.classLabel ~= "" and member.classLabel or "-")
	frame.classText:SetTextColor(ClassColor(member.class))

	if member.specIcon and member.specIcon ~= "" then
		SetSpecOrClassIcon(frame.specIcon, member.specIcon, member.class)
		frame.specIcon:Show()
	else
		SetSpecOrClassIcon(frame.specIcon, nil, member.class)
		frame.specIcon:Show()
	end
	frame.specText:SetText((member.spec and member.spec ~= "") and member.spec or "-")
	SetFontColor(frame.specText, UI.TEXT_IDLE)

	if member.gearScore then
		frame.gsText:SetText(T("PROFILE_GS", tostring(member.gearScore)))
		SetFontColor(frame.gsText, UI.GOLD)
	else
		frame.gsText:SetText(T("PROFILE_GS", "-"))
		SetFontColor(frame.gsText, UI.TEXT_DISABLED)
	end

	if member.averageIlvl then
		frame.ilvlText:SetText(T("PROFILE_ILVL", tostring(member.averageIlvl)))
		SetFontColor(frame.ilvlText, UI.TEXT_IDLE)
	else
		frame.ilvlText:SetText(T("PROFILE_ILVL", "-"))
		SetFontColor(frame.ilvlText, UI.TEXT_DISABLED)
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

	frame.guildText:SetText(T("PROFILE_GUILD", FormatGuildDisplay(member.guildName, member.guildRank)))
	SetFontColor(frame.guildText, UI.TEXT_IDLE)
	frame.karmaText:SetText(FormatOpinionLine(member))
	SetFontColor(frame.karmaText, RatingOpinionColor(member))

	local tags = FormatTagLine(member)
	if tags ~= "" then
		frame.tagText:SetText(tags)
		SetFontColor(frame.tagText, UI.TEXT_IDLE)
	else
		frame.tagText:SetText(T("RATING_TAGS_NONE"))
		SetFontColor(frame.tagText, UI.TEXT_DISABLED)
	end

	if member.guid and member.guid ~= "" then
		frame.guidText:SetText(T("PROFILE_GUID", member.guid))
		SetFontColor(frame.guidText, UI.TEXT_IDLE)
	else
		frame.guidText:SetText(T("PROFILE_GUID", "-"))
		SetFontColor(frame.guidText, UI.TEXT_DISABLED)
	end

	if member.metRealm and member.metRealm ~= "" then
		frame.metRealmText:SetText(T("PROFILE_REALM", member.metRealm))
		SetFontColor(frame.metRealmText, UI.TEXT_IDLE)
	else
		frame.metRealmText:SetText(T("PROFILE_REALM", "-"))
		SetFontColor(frame.metRealmText, UI.TEXT_DISABLED)
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

	if frame.ratingHeading then
		frame.ratingHeading:SetText(T("RATING_PERSONAL_OPINION_TITLE"))
	end
	if frame.tagsHeading then
		frame.tagsHeading:SetText(T("RATING_TAGS_TITLE"))
	end
	if frame.notesHeading then
		frame.notesHeading:SetText(T("PROFILE_NOTES"))
	end
	if frame.notesBox then
		frame.isUpdatingNotes = true
		frame.notesBox:SetText(member.notes or "")
		frame.isUpdatingNotes = false
	end

	UpdateProfileEditor(frame, member)
	local editable = member.guid and member.guid ~= ""
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
		local opinion = "neutral"
		if self.GetPersonalRating then
			opinion = self:GetPersonalRating(member).opinion
		end
		RefreshOpinionRadios(frame, opinion)
	end
	if frame.tagGroups then
		RefreshProfileTagCheckboxes(frame, member, editable)
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

