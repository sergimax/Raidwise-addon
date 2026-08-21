-- PageSettings

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 1

local function UpdateLocaleButtons(page)
	if not page or not page.enBtn or not page.ruBtn then
		return
	end
	local locale = Addon:GetLocaleId()
	W.SetMenuButtonState(page.enBtn, locale == "enUS", false)
	W.SetMenuButtonState(page.ruBtn, locale == "ruRU", false)
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

	UpdateLocaleButtons(page)
	page.layoutVersion = LAYOUT_VERSION
	return page
end

Addon.Pages.Settings = {
	id = "settings",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateSettingsPage,
	UpdateLocaleButtons = UpdateLocaleButtons,
}
