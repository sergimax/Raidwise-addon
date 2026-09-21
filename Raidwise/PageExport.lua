-- PageExport

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 3

local function SetSyncExportText(page, text, err)
	if not text then
		page.statusLabel:SetText(W.T(err or "SYNC_INVALID"))
		return
	end
	page.exportBox:SetText(text)
	page.exportBox:SetFocus()
	page.exportBox:HighlightText()
	page.selectBtn:Enable()
	page.statusLabel:SetText(W.T("EXPORT_READY"))
end

local function CreateExportPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local innerW = W.ContentInnerWidth()

	local desc = W.CreateFontString(page, nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 0, 0)
	desc:SetWidth(innerW)
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText(W.T("EXPORT_DESC"))

	local namesCheck = CreateFrame("CheckButton", "RaidwiseIncludeNamesCheckV" .. tostring(LAYOUT_VERSION), page, "UICheckButtonTemplate")
	namesCheck:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	namesCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -UI.DESC_TO_CHECK)
	namesCheck:SetChecked(Addon.db.includeGearNames ~= false)
	local templateCheckText = _G[namesCheck:GetName() .. "Text"]
	if templateCheckText then
		templateCheckText:SetText("")
		templateCheckText:Hide()
	end
	namesCheck:SetScript("OnClick", function(btn)
		Addon.db.includeGearNames = btn:GetChecked() and true or false
	end)

	local namesLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontHighlight")
	namesLabel:SetPoint("LEFT", namesCheck, "RIGHT", 4, 0)
	namesLabel:SetText(W.T("EXPORT_INCLUDE_NAMES"))

	local namesHit = CreateFrame("Button", nil, page)
	namesHit:SetPoint("LEFT", namesCheck, "RIGHT", 0, 0)
	namesHit:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	namesHit:SetHeight(UI.OPTIONS_H)
	namesHit:SetScript("OnClick", function()
		namesCheck:Click()
	end)

	local buttonW = (innerW - UI.ACTION_BTN_GAP) / 2
	local exportBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("BTN_EXPORT_DATA"))
	exportBtn:SetPoint("TOPLEFT", namesCheck, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
	exportBtn:SetScript("OnClick", function()
		Addon:FlushExportToWindow()
		Addon.pendingLockoutExport = true
		RequestRaidInfo()
	end)

	local selectBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("BTN_SELECT_ALL"))
	selectBtn:SetPoint("LEFT", exportBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	selectBtn:Disable()
	selectBtn:SetScript("OnClick", function()
		Addon:SelectExportText()
	end)

	local statusLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	statusLabel:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -UI.BUTTONS_TO_HINT)
	statusLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	statusLabel:SetJustifyH("LEFT")
	statusLabel:SetText(W.T("EXPORT_HINT"))

	local syncDesc = W.CreateFontString(page, nil, "OVERLAY", "GameFontHighlightSmall")
	syncDesc:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -14)
	syncDesc:SetWidth(innerW)
	syncDesc:SetJustifyH("LEFT")
	syncDesc:SetText(W.T("SYNC_EXPORT_DESCRIPTION"))

	local syncSearch, syncSearchHost = W.CreateTextInput(page, innerW)
	syncSearchHost:SetPoint("TOPLEFT", syncDesc, "BOTTOMLEFT", 0, -6)
	syncSearch:SetMaxLetters(150)
	syncSearch:SetScript("OnTextChanged", function() Addon:RefreshExportView() end)
	page.syncMatches = {}
	for index = 1, 3 do
		local row = W.CreatePlainButton(page, innerW, 24, W.T("SYNC_SELECT"))
		row:SetPoint("TOPLEFT", syncSearchHost, "BOTTOMLEFT", 0, -4 - (index - 1) * 25)
		row:SetScript("OnClick", function()
			Addon.syncSelectedGuid = page.syncMatches[index].guid
			Addon:RefreshExportView()
		end)
		page.syncMatches[index] = row
	end
	local syncSelected = W.CreateFontString(page, nil, "OVERLAY", "GameFontHighlightSmall")
	syncSelected:SetPoint("TOPLEFT", syncSearchHost, "BOTTOMLEFT", 0, -82)
	syncSelected:SetWidth(innerW)
	local syncOne = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("SYNC_EXPORT_ONE"))
	syncOne:SetPoint("TOPLEFT", syncSelected, "BOTTOMLEFT", 0, -6)
	syncOne:SetScript("OnClick", function()
		if not Addon.syncSelectedGuid then SetSyncExportText(page, nil, "SYNC_SELECT"); return end
		local value, err = Addon:BuildSyncExport(Addon.syncSelectedGuid)
		SetSyncExportText(page, value, err)
	end)
	local syncAll = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("SYNC_EXPORT_ALL"))
	syncAll:SetPoint("LEFT", syncOne, "RIGHT", UI.ACTION_BTN_GAP, 0)
	syncAll:SetScript("OnClick", function()
		local value, err = Addon:BuildSyncExport()
		SetSyncExportText(page, value, err)
	end)

	local exportBox, copyHost = W.CreateCopyBox(
		page,
		"RaidwiseExportScrollV" .. tostring(LAYOUT_VERSION),
		"RaidwiseExportBoxV" .. tostring(LAYOUT_VERSION)
	)
	copyHost:SetPoint("TOPLEFT", syncOne, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	copyHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	page.exportBox = exportBox
	page.statusLabel = statusLabel
	page.selectBtn = selectBtn
	page.desc = desc
	page.namesLabel = namesLabel
	page.exportBtn = exportBtn
	page.syncDesc = syncDesc
	page.syncSearch = syncSearch
	page.syncSelected = syncSelected
	page.syncOne = syncOne
	page.syncAll = syncAll
	page.layoutVersion = LAYOUT_VERSION
	return page
end
-- Focus the export box and highlight all text for Ctrl+C.
function Addon:SelectExportText()
	local frame = self.mainFrame
	if not frame or not frame.exportBox then
		return
	end
	local exportBox = frame.exportBox
	if (exportBox:GetText() or "") == "" then
		return
	end
	self:SelectTab("export")
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.statusLabel then
		frame.statusLabel:SetText(W.T("EXPORT_SELECTED"))
	end
end

-- Write the current character export into the main window EditBox.
function Addon:FlushExportToWindow()
	local frame = self.mainFrame
	if not frame or not frame.exportBox then
		return
	end
	self:SelectTab("export")
	local exportBox = frame.exportBox
	local text = self:FormatEquippedGearExport()
	exportBox:SetText(text)
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.selectBtn then
		frame.selectBtn:Enable()
	end
	if frame.statusLabel then
		frame.statusLabel:SetText(W.T("EXPORT_READY"))
	end
end

function Addon:RefreshExportView()
	local page = self.mainFrame and self.mainFrame.pages and self.mainFrame.pages.export
	if not page or not page.syncSearch then return end
	local filters = { name = page.syncSearch:GetText() or "" }
	local candidates = self:BuildHistoryRoster(true, filters)
	local seen = {}
	for _, entry in ipairs(candidates) do seen[entry.guid] = true end
	for _, entry in ipairs(self:BuildHistoryRoster(false, filters)) do
		if not seen[entry.guid] then candidates[#candidates + 1] = entry end
	end
	for index, row in ipairs(page.syncMatches) do
		local entry = candidates[index]
		row.guid = entry and entry.guid
		if entry then row.label:SetText(self:LinkedCharacterName(entry)); row:Show() else row:Hide() end
	end
	local selected = self:GetHistoryEntry(self.syncSelectedGuid)
	page.syncSelected:SetText(W.T("SYNC_SELECTED", selected and self:LinkedCharacterName(selected) or W.T("SYNC_SELECT")))
	if selected then page.syncOne:Enable() else page.syncOne:Disable() end
end

local function ApplyLocale(page)
	if page then
		if page.desc then
			page.desc:SetText(W.T("EXPORT_DESC"))
		end
		if page.namesLabel then
			page.namesLabel:SetText(W.T("EXPORT_INCLUDE_NAMES"))
		end
		if page.exportBtn then
			page.exportBtn.label:SetText(W.T("BTN_EXPORT_DATA"))
		end
		if page.selectBtn then
			page.selectBtn.label:SetText(W.T("BTN_SELECT_ALL"))
		end
		if page.statusLabel then
			local exported = page.exportBox and (page.exportBox:GetText() or "") ~= ""
			page.statusLabel:SetText(exported and W.T("EXPORT_READY") or W.T("EXPORT_HINT"))
		end
		if page.syncDesc then page.syncDesc:SetText(W.T("SYNC_EXPORT_DESCRIPTION")) end
		if page.syncOne then page.syncOne.label:SetText(W.T("SYNC_EXPORT_ONE")) end
		if page.syncAll then page.syncAll.label:SetText(W.T("SYNC_EXPORT_ALL")) end
		Addon:RefreshExportView()
	end
end

Addon.Pages.Export = {
	id = "export",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Refresh = ApplyLocale,
	ApplyLocale = ApplyLocale,
	Create = CreateExportPage,
}
