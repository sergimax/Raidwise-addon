-- Main window: export-focused layout with clear actions and a large copy area.

local Addon = Raidwise

-- Keep in sync with docs/UI-Sizes.md
local UI = {
	FRAME_WIDTH = 420,
	FRAME_HEIGHT = 460,
	PAD_X = 20,
	PAD_TOP = 16,
	PAD_BOTTOM = 16,
	TITLE_TO_VERSION = 4,
	VERSION_TO_EXPORT = 14,
	EXPORT_BTN_H = 28,
	EXPORT_TO_OPTIONS = 10,
	CHECK_SIZE = 24,
	OPTIONS_H = 28,
	OPTIONS_TO_STATUS = 6,
	STATUS_TO_LABEL = 10,
	LABEL_TO_INSET = 6,
	INSET_PAD = 8,
	SCROLLBAR_GUTTER = 20,
	INSET_TO_SELECT = 8,
	SELECT_BTN_W = 140,
	SELECT_BTN_H = 24,
	CLOSE_OFFSET = 4,
}

local function ContentWidth()
	return UI.FRAME_WIDTH - (UI.PAD_X * 2)
end

-- Build the main frame once; store on Addon.mainFrame.
function Addon:CreateMainFrame()
	if self.mainFrame then
		return self.mainFrame
	end

	local frame = CreateFrame("Frame", "RaidwiseFrame", UIParent)
	frame:SetSize(UI.FRAME_WIDTH, UI.FRAME_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:SetBackdropColor(0, 0, 0, 1)

	tinsert(UISpecialFrames, "RaidwiseFrame")

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -UI.PAD_TOP)
	title:SetText("Raidwise")

	local versionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	versionLabel:SetPoint("TOP", title, "BOTTOM", 0, -UI.TITLE_TO_VERSION)
	versionLabel:SetText("v" .. tostring(Addon.version))

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -UI.CLOSE_OFFSET, -UI.CLOSE_OFFSET)

	local exportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	exportBtn:SetSize(ContentWidth(), UI.EXPORT_BTN_H)
	exportBtn:SetPoint("TOP", versionLabel, "BOTTOM", 0, -UI.VERSION_TO_EXPORT)
	exportBtn:SetText("Export Character")
	exportBtn:SetScript("OnClick", function()
		Addon:FlushExportToWindow()
		Addon.pendingLockoutExport = true
		RequestRaidInfo()
	end)

	local namesCheck = CreateFrame("CheckButton", "RaidwiseIncludeNamesCheck", frame, "UICheckButtonTemplate")
	namesCheck:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	namesCheck:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -UI.EXPORT_TO_OPTIONS)
	namesCheck:SetChecked(Addon.db.includeGearNames ~= false)
	local templateCheckText = _G[namesCheck:GetName() .. "Text"]
	if templateCheckText then
		templateCheckText:SetText("")
		templateCheckText:Hide()
	end
	namesCheck:SetScript("OnClick", function(btn)
		Addon.db.includeGearNames = btn:GetChecked() and true or false
	end)

	local namesLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	namesLabel:SetPoint("LEFT", namesCheck, "RIGHT", 4, 0)
	namesLabel:SetText("Include item names in JSON")

	-- Clicking the label toggles the checkbox (easier hit target).
	local namesHit = CreateFrame("Button", nil, frame)
	namesHit:SetPoint("LEFT", namesCheck, "RIGHT", 0, 0)
	namesHit:SetPoint("RIGHT", exportBtn, "RIGHT", 0, 0)
	namesHit:SetHeight(UI.OPTIONS_H)
	namesHit:SetScript("OnClick", function()
		namesCheck:Click()
	end)

	local statusLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusLabel:SetPoint("TOPLEFT", namesCheck, "BOTTOMLEFT", 0, -UI.OPTIONS_TO_STATUS)
	statusLabel:SetPoint("RIGHT", exportBtn, "RIGHT", 0, 0)
	statusLabel:SetJustifyH("LEFT")
	statusLabel:SetText("Click Export, then Ctrl+C to copy.")

	local exportLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	exportLabel:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -UI.STATUS_TO_LABEL)
	exportLabel:SetText("Character JSON")

	local selectBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	selectBtn:SetSize(UI.SELECT_BTN_W, UI.SELECT_BTN_H)
	selectBtn:SetPoint("BOTTOM", 0, UI.PAD_BOTTOM)
	selectBtn:SetText("Select All")
	selectBtn:Disable()
	selectBtn:SetScript("OnClick", function()
		Addon:SelectExportText()
	end)

	local inset = CreateFrame("Frame", nil, frame)
	inset:SetPoint("TOPLEFT", exportLabel, "BOTTOMLEFT", 0, -UI.LABEL_TO_INSET)
	inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI.PAD_X, UI.PAD_BOTTOM + UI.SELECT_BTN_H + UI.INSET_TO_SELECT)
	inset:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	inset:SetBackdropColor(0, 0, 0, 0.85)
	inset:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	local scroll = CreateFrame("ScrollFrame", "RaidwiseExportScroll", inset, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", UI.INSET_PAD, -UI.INSET_PAD)
	scroll:SetPoint("BOTTOMRIGHT", -(UI.INSET_PAD + UI.SCROLLBAR_GUTTER), UI.INSET_PAD)

	local exportBox = CreateFrame("EditBox", "RaidwiseExportBox", scroll)
	exportBox:SetMultiLine(true)
	exportBox:SetFontObject(ChatFontNormal)
	exportBox:SetWidth(ContentWidth() - (UI.INSET_PAD * 2) - UI.SCROLLBAR_GUTTER)
	exportBox:SetAutoFocus(false)
	exportBox:EnableMouse(true)
	exportBox:SetTextInsets(2, 2, 2, 2)
	exportBox:SetScript("OnEscapePressed", function(box)
		box:ClearFocus()
	end)
	exportBox:SetScript("OnCursorChanged", function(box, x, y, _, lineHeight)
		local viewportH = scroll:GetHeight()
		local offset = scroll:GetVerticalScroll()
		if y > 0 then
			scroll:SetVerticalScroll(offset - y)
		elseif (-y - lineHeight) > (viewportH - offset) then
			scroll:SetVerticalScroll(offset + (-y - lineHeight - (viewportH - offset)))
		end
	end)
	exportBox:SetScript("OnTextChanged", function(box)
		-- Grow scroll child so long exports remain scrollable.
		local fontHeight = 12
		local lines = 1
		local text = box:GetText() or ""
		for _ in text:gmatch("\n") do
			lines = lines + 1
		end
		box:SetHeight(math.max(180, lines * fontHeight + 8))
	end)
	scroll:SetScrollChild(exportBox)

	frame.exportBox = exportBox
	frame.statusLabel = statusLabel
	frame.selectBtn = selectBtn
	self.mainFrame = frame
	return frame
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
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.statusLabel then
		frame.statusLabel:SetText("Selected — press Ctrl+C to copy.")
	end
end

-- Write the current character export into the main window EditBox.
function Addon:FlushExportToWindow()
	local frame = self.mainFrame
	if not frame or not frame.exportBox then
		return
	end
	local exportBox = frame.exportBox
	local text = self:FormatEquippedGearExport()
	exportBox:SetText(text)
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.selectBtn then
		frame.selectBtn:Enable()
	end
	if frame.statusLabel then
		frame.statusLabel:SetText("Export ready — press Ctrl+C to copy.")
	end
end

-- Show the main window (creates it if needed).
function Addon:ShowMainFrame()
	local frame = self:CreateMainFrame()
	frame:Show()
	frame:Raise()
end

-- Hide the main window if it exists.
function Addon:HideMainFrame()
	if self.mainFrame then
		self.mainFrame:Hide()
	end
end

-- Toggle the main window visibility.
function Addon:ToggleMainFrame()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:HideMainFrame()
	else
		self:ShowMainFrame()
	end
end
