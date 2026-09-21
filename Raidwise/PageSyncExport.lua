-- Full saved-profile export for Raidwise data exchange.
local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 1

local function Create(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)
	page.layoutVersion = LAYOUT_VERSION
	local width = W.ContentInnerWidth()

	page.desc = W.CreateFontString(page, nil, "OVERLAY", "GameFontHighlight")
	page.desc:SetPoint("TOPLEFT", 0, 0)
	page.desc:SetWidth(width)
	page.desc:SetJustifyH("LEFT")
	page.desc:SetText(W.T("SYNC_EXPORT_DESCRIPTION"))

	local buttonWidth = (width - UI.ACTION_BTN_GAP) / 2
	page.exportButton = W.CreatePlainButton(page, buttonWidth, UI.ACTION_BTN_H, W.T("SYNC_EXPORT_ALL"))
	page.exportButton:SetPoint("TOPLEFT", page.desc, "BOTTOMLEFT", 0, -UI.DESC_TO_CHECK)
	page.exportButton:SetScript("OnClick", function()
		local value, err = Addon:BuildSyncExport()
		if not value then page.status:SetText(W.T(err or "SYNC_INVALID")); return end
		page.copyBox:SetText(value)
		page.copyBox:SetFocus()
		page.copyBox:HighlightText()
		page.selectButton:Enable()
		page.status:SetText(W.T("EXPORT_READY"))
	end)

	page.selectButton = W.CreatePlainButton(page, buttonWidth, UI.ACTION_BTN_H, W.T("BTN_SELECT_ALL"))
	page.selectButton:SetPoint("LEFT", page.exportButton, "RIGHT", UI.ACTION_BTN_GAP, 0)
	page.selectButton:Disable()
	page.selectButton:SetScript("OnClick", function()
		if (page.copyBox:GetText() or "") == "" then return end
		page.copyBox:SetFocus()
		page.copyBox:HighlightText()
		page.status:SetText(W.T("EXPORT_SELECTED"))
	end)

	page.status = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	page.status:SetPoint("TOPLEFT", page.exportButton, "BOTTOMLEFT", 0, -UI.BUTTONS_TO_HINT)
	page.status:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	page.status:SetJustifyH("LEFT")
	page.status:SetText(W.T("EXPORT_HINT"))
	local copyBox, host = W.CreateCopyBox(page, "RaidwiseSyncExportScrollV" .. LAYOUT_VERSION, "RaidwiseSyncExportBoxV" .. LAYOUT_VERSION)
	host:SetPoint("TOPLEFT", page.status, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	host:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	copyBox:SetMaxLetters(Addon.SYNC_MAX_BYTES + 1)
	page.copyBox = copyBox
	return page
end

local function Refresh(page)
	if not page then return end
	page.desc:SetText(W.T("SYNC_EXPORT_DESCRIPTION"))
	page.exportButton.label:SetText(W.T("SYNC_EXPORT_ALL"))
	page.selectButton.label:SetText(W.T("BTN_SELECT_ALL"))
	page.status:SetText((page.copyBox:GetText() or "") ~= "" and W.T("EXPORT_READY") or W.T("EXPORT_HINT"))
end

Addon.Pages.SyncExport = { id = "syncExport", LAYOUT_VERSION = LAYOUT_VERSION, Create = Create, Refresh = Refresh, ApplyLocale = Refresh }
