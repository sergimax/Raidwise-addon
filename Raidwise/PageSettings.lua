-- PageSettings

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 4

local STARTUP_COLS = 4
local STARTUP_RADIO_SIZE = 16
local STARTUP_ROW_H = 22
local STARTUP_GAP = UI.ACTION_BTN_GAP

local CHECK_KEYS = {
	{ key = "hidePersonal", labelKey = "SETTINGS_TIP_HIDE_PERSONAL" },
	{ key = "hidePersonalTags", labelKey = "SETTINGS_TIP_HIDE_PERSONAL_TAGS" },
	{ key = "hideCommunity", labelKey = "SETTINGS_TIP_HIDE_COMMUNITY" },
	{ key = "hideCommunityTags", labelKey = "SETTINGS_TIP_HIDE_COMMUNITY_TAGS" },
}

local function UpdateLocaleButtons(page)
	if not page or not page.enBtn or not page.ruBtn then
		return
	end
	local locale = Addon:GetLocaleId()
	W.SetMenuButtonState(page.enBtn, locale == "enUS", false)
	W.SetMenuButtonState(page.ruBtn, locale == "ruRU", false)
end

-- Exclusive SetChecked on the startup-page radio group (same pattern as profile opinion).
local function UpdateStartupRadios(page)
	if not page or not page.startupRadios then
		return
	end
	local selected = Addon.GetStartupTab and Addon:GetStartupTab() or "cooldowns"
	for index = 1, #page.startupRadios do
		local radio = page.startupRadios[index]
		local checked = radio.tabId == selected
		radio.isUpdating = true
		radio:SetChecked(checked)
		local checkedTexture = radio.GetCheckedTexture and radio:GetCheckedTexture()
		if checkedTexture then
			if checked then
				checkedTexture:Show()
			else
				checkedTexture:Hide()
			end
		end
		if radio.label then
			if radio.labelKey then
				radio.label:SetText(W.T(radio.labelKey))
			end
			W.SetFontColor(radio.label, checked and UI.GOLD or UI.TEXT_IDLE)
		end
		radio.isUpdating = false
	end
end

local function ApplyStartupChoice(page, tabId)
	if Addon.SetStartupTab then
		Addon:SetStartupTab(tabId)
	end
	UpdateStartupRadios(page)
end

local function CreateSettingsCheck(page, nameSuffix, labelKey, dbKey, anchor)
	local check = CreateFrame(
		"CheckButton",
		"RaidwiseSettingsCheck" .. nameSuffix .. "V" .. tostring(LAYOUT_VERSION),
		page,
		"UICheckButtonTemplate"
	)
	check:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
	local tip = Addon:GetTooltipSettings()
	check:SetChecked(tip[dbKey] and true or false)

	local templateCheckText = _G[check:GetName() .. "Text"]
	if templateCheckText then
		templateCheckText:SetText("")
		templateCheckText:Hide()
	end

	local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("LEFT", check, "RIGHT", 4, 0)
	label:SetText(W.T(labelKey))

	local hit = CreateFrame("Button", nil, page)
	hit:SetPoint("LEFT", check, "RIGHT", 0, 0)
	hit:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	hit:SetHeight(UI.OPTIONS_H)
	hit:SetScript("OnClick", function()
		check:Click()
	end)

	check:SetScript("OnClick", function(btn)
		local settings = Addon:GetTooltipSettings()
		settings[dbKey] = btn:GetChecked() and true or false
		if page.RefreshTooltipPreviews then
			page:RefreshTooltipPreviews()
		end
	end)

	return check, label
end

local function FormatPreviewText(layout)
	if not Addon.BuildUnitTooltipRatingLines or not Addon.GetTooltipPreviewSample then
		return ""
	end
	local sample = Addon:GetTooltipPreviewSample()
	local lines = Addon:BuildUnitTooltipRatingLines(
		sample.personal,
		sample.community,
		Addon:GetTooltipSettings(),
		layout
	)
	if #lines == 0 then
		return W.T("SETTINGS_TIP_PREVIEW_EMPTY")
	end
	return table.concat(lines, "\n")
end

local function RefreshTooltipPreviews(page)
	if page.previewCompact then
		page.previewCompact:SetText(FormatPreviewText("compact"))
	end
	if page.previewStacked then
		page.previewStacked:SetText(FormatPreviewText("stacked"))
	end
end

local function CreateStartupRadio(page, parent, pageInfo, columnWidth)
	local host = CreateFrame("Frame", nil, parent)
	host:SetSize(columnWidth, STARTUP_ROW_H)

	local radio = CreateFrame("CheckButton", nil, host, "UIRadioButtonTemplate")
	radio:SetSize(STARTUP_RADIO_SIZE, STARTUP_RADIO_SIZE)
	radio:SetPoint("LEFT", 0, 0)
	radio.tabId = pageInfo.id
	radio.labelKey = pageInfo.labelKey

	local label = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", radio, "RIGHT", 4, 0)
	label:SetPoint("RIGHT", host, "RIGHT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(W.T(pageInfo.labelKey))
	W.SetFontColor(label, UI.TEXT_IDLE)
	radio.label = label
	radio.host = host

	-- Label-only hit target; do not cover the radio or call :Click() (exclusive group).
	local hit = CreateFrame("Button", nil, host)
	hit:SetPoint("TOPLEFT", label, "TOPLEFT", 0, 2)
	hit:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, -2)
	hit:SetScript("OnClick", function()
		ApplyStartupChoice(page, radio.tabId)
	end)
	radio.hit = hit

	radio:SetScript("OnClick", function(self)
		if self.isUpdating then
			return
		end
		ApplyStartupChoice(page, self.tabId)
	end)

	return radio
end

local function CreateStartupTabRadios(page, anchor)
	local menuPages = Addon.MenuPages or {}
	page.startupRadios = {}
	if #menuPages == 0 then
		return anchor
	end

	local innerWidth = W.ContentInnerWidth()
	local colWidth = math.floor((innerWidth - STARTUP_GAP * (STARTUP_COLS - 1)) / STARTUP_COLS)
	local firstHost = nil
	local lastHost = nil

	for index = 1, #menuPages do
		local pageInfo = menuPages[index]
		local radio = CreateStartupRadio(page, page, pageInfo, colWidth)
		local host = radio.host

		local col = (index - 1) % STARTUP_COLS
		local row = math.floor((index - 1) / STARTUP_COLS)
		if row == 0 and col == 0 then
			host:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
			firstHost = host
		elseif col == 0 then
			host:SetPoint("TOPLEFT", page.startupRadios[index - STARTUP_COLS].host, "BOTTOMLEFT", 0, -STARTUP_GAP)
		else
			host:SetPoint("LEFT", page.startupRadios[index - 1].host, "RIGHT", STARTUP_GAP, 0)
		end

		page.startupRadios[index] = radio
		lastHost = host
	end

	UpdateStartupRadios(page)
	-- Anchor following content under the first cell of the last row (left edge).
	local lastRowStart = ((#menuPages - 1) - ((#menuPages - 1) % STARTUP_COLS)) + 1
	local bottomLeft = page.startupRadios[lastRowStart] and page.startupRadios[lastRowStart].host
	return bottomLeft or lastHost or firstHost or anchor
end

local function CreateSettingsPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	heading:SetPoint("TOPLEFT", 0, 0)
	heading:SetText(W.T("SETTINGS_LANGUAGE"))
	W.SetFontColor(heading, UI.GOLD)
	page.heading = heading

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	hint:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	hint:SetJustifyH("LEFT")
	hint:SetText(W.T("SETTINGS_LANGUAGE_HINT"))
	page.hint = hint

	local enBtn = W.CreatePlainButton(page, 120, UI.ACTION_BTN_H, W.T("LOCALE_EN"))
	enBtn:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
	enBtn.tabId = "enUS"
	enBtn:SetScript("OnEnter", function(self)
		W.SetMenuButtonState(self, Addon:GetLocaleId() == "enUS", true)
	end)
	enBtn:SetScript("OnLeave", function(self)
		W.SetMenuButtonState(self, Addon:GetLocaleId() == "enUS", false)
	end)
	enBtn:SetScript("OnClick", function()
		Addon:SetLocale("enUS")
	end)
	page.enBtn = enBtn

	local ruBtn = W.CreatePlainButton(page, 120, UI.ACTION_BTN_H, W.T("LOCALE_RU"))
	ruBtn:SetPoint("LEFT", enBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	ruBtn.tabId = "ruRU"
	ruBtn:SetScript("OnEnter", function(self)
		W.SetMenuButtonState(self, Addon:GetLocaleId() == "ruRU", true)
	end)
	ruBtn:SetScript("OnLeave", function(self)
		W.SetMenuButtonState(self, Addon:GetLocaleId() == "ruRU", false)
	end)
	ruBtn:SetScript("OnClick", function()
		Addon:SetLocale("ruRU")
	end)
	page.ruBtn = ruBtn

	local startupHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	startupHeading:SetPoint("TOPLEFT", enBtn, "BOTTOMLEFT", 0, -UI.INFO_BLOCK_GAP)
	startupHeading:SetText(W.T("SETTINGS_STARTUP_TAB"))
	W.SetFontColor(startupHeading, UI.GOLD)
	page.startupHeading = startupHeading

	local startupHint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	startupHint:SetPoint("TOPLEFT", startupHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	startupHint:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	startupHint:SetJustifyH("LEFT")
	startupHint:SetText(W.T("SETTINGS_STARTUP_TAB_HINT"))
	page.startupHint = startupHint

	local startupAnchor = CreateStartupTabRadios(page, startupHint)

	local tipHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tipHeading:SetPoint("TOPLEFT", startupAnchor, "BOTTOMLEFT", 0, -UI.INFO_BLOCK_GAP)
	tipHeading:SetText(W.T("SETTINGS_TOOLTIP"))
	W.SetFontColor(tipHeading, UI.GOLD)
	page.tipHeading = tipHeading

	local tipHint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tipHint:SetPoint("TOPLEFT", tipHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	tipHint:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	tipHint:SetJustifyH("LEFT")
	tipHint:SetText(W.T("SETTINGS_TOOLTIP_HINT"))
	page.tipHint = tipHint

	page.tipChecks = {}
	page.tipLabels = {}
	local checkAnchor = tipHint
	for index = 1, #CHECK_KEYS do
		local def = CHECK_KEYS[index]
		local check, label = CreateSettingsCheck(page, tostring(index), def.labelKey, def.key, checkAnchor)
		page.tipChecks[index] = check
		page.tipLabels[index] = label
		checkAnchor = check
	end

	local previewHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	previewHeading:SetPoint("TOPLEFT", checkAnchor, "BOTTOMLEFT", 0, -UI.INFO_BLOCK_GAP)
	previewHeading:SetText(W.T("SETTINGS_TIP_PREVIEW"))
	W.SetFontColor(previewHeading, UI.GOLD)
	page.previewHeading = previewHeading

	local compactLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	compactLabel:SetPoint("TOPLEFT", previewHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	compactLabel:SetText(W.T("SETTINGS_TIP_LAYOUT_COMPACT"))
	W.SetFontColor(compactLabel, UI.TEXT_IDLE)
	page.compactLabel = compactLabel

	local previewCompact = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	previewCompact:SetPoint("TOPLEFT", compactLabel, "BOTTOMLEFT", 0, -4)
	previewCompact:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	previewCompact:SetJustifyH("LEFT")
	previewCompact:SetJustifyV("TOP")
	previewCompact:SetNonSpaceWrap(true)
	page.previewCompact = previewCompact

	local stackedLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	stackedLabel:SetPoint("TOPLEFT", previewCompact, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	stackedLabel:SetText(W.T("SETTINGS_TIP_LAYOUT_STACKED"))
	W.SetFontColor(stackedLabel, UI.TEXT_IDLE)
	page.stackedLabel = stackedLabel

	local previewStacked = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	previewStacked:SetPoint("TOPLEFT", stackedLabel, "BOTTOMLEFT", 0, -4)
	previewStacked:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	previewStacked:SetJustifyH("LEFT")
	previewStacked:SetJustifyV("TOP")
	previewStacked:SetNonSpaceWrap(true)
	page.previewStacked = previewStacked

	page.RefreshTooltipPreviews = RefreshTooltipPreviews
	UpdateLocaleButtons(page)
	RefreshTooltipPreviews(page)
	page.layoutVersion = LAYOUT_VERSION
	return page
end

local function ApplySettingsLocale(page)
	if not page then
		return
	end
	if page.heading then
		page.heading:SetText(W.T("SETTINGS_LANGUAGE"))
	end
	if page.hint then
		page.hint:SetText(W.T("SETTINGS_LANGUAGE_HINT"))
	end
	if page.enBtn then
		page.enBtn.label:SetText(W.T("LOCALE_EN"))
	end
	if page.ruBtn then
		page.ruBtn.label:SetText(W.T("LOCALE_RU"))
	end
	if page.startupHeading then
		page.startupHeading:SetText(W.T("SETTINGS_STARTUP_TAB"))
	end
	if page.startupHint then
		page.startupHint:SetText(W.T("SETTINGS_STARTUP_TAB_HINT"))
	end
	if page.startupRadios then
		for index = 1, #page.startupRadios do
			local radio = page.startupRadios[index]
			if radio.label and radio.labelKey then
				radio.label:SetText(W.T(radio.labelKey))
			end
		end
	end
	if page.tipHeading then
		page.tipHeading:SetText(W.T("SETTINGS_TOOLTIP"))
	end
	if page.tipHint then
		page.tipHint:SetText(W.T("SETTINGS_TOOLTIP_HINT"))
	end
	for index = 1, #CHECK_KEYS do
		local label = page.tipLabels and page.tipLabels[index]
		if label then
			label:SetText(W.T(CHECK_KEYS[index].labelKey))
		end
	end
	if page.previewHeading then
		page.previewHeading:SetText(W.T("SETTINGS_TIP_PREVIEW"))
	end
	if page.compactLabel then
		page.compactLabel:SetText(W.T("SETTINGS_TIP_LAYOUT_COMPACT"))
	end
	if page.stackedLabel then
		page.stackedLabel:SetText(W.T("SETTINGS_TIP_LAYOUT_STACKED"))
	end
	UpdateLocaleButtons(page)
	UpdateStartupRadios(page)
	RefreshTooltipPreviews(page)
end

Addon.Pages.Settings = {
	id = "settings",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateSettingsPage,
	UpdateLocaleButtons = UpdateLocaleButtons,
	UpdateStartupRadios = UpdateStartupRadios,
	ApplyLocale = ApplySettingsLocale,
}
