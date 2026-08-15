-- Simple main window: title, action buttons, and gear export text area.

local Addon = MrcExporter

local FRAME_WIDTH = 320
local FRAME_HEIGHT = 330

-- Build the main frame once; store on Addon.mainFrame.
function Addon:CreateMainFrame()
	if self.mainFrame then
		return self.mainFrame
	end

	local frame = CreateFrame("Frame", "MrcExporterFrame", UIParent)
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
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

	tinsert(UISpecialFrames, "MrcExporterFrame")

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText("mrc-exporter")

	local versionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	versionLabel:SetPoint("TOP", title, "BOTTOM", 0, -4)
	versionLabel:SetText("v" .. tostring(Addon.version))

	-- Standard close (X); also Esc via UISpecialFrames.
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	-- Prints Addon.version to chat.
	local versionBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	versionBtn:SetSize(120, 24)
	versionBtn:SetPoint("TOP", versionLabel, "BOTTOM", 0, -12)
	versionBtn:SetText("Version")
	versionBtn:SetScript("OnClick", function()
		Addon:Print("version " .. tostring(Addon.version))
	end)

	-- Prints local date/time and character name to chat.
	local infoBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	infoBtn:SetSize(200, 24)
	infoBtn:SetPoint("TOP", versionBtn, "BOTTOM", 0, -10)
	infoBtn:SetText("Character Info")
	infoBtn:SetScript("OnClick", function()
		local character = UnitName("player") or "?"
		local stamp = date("%Y-%m-%d %H:%M:%S")
		Addon:Print(string.format("%s | %s", stamp, character))
	end)

	-- Fills the export EditBox with character + gear JSON.
	local exportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	exportBtn:SetSize(200, 24)
	exportBtn:SetPoint("TOP", infoBtn, "BOTTOM", 0, -10)
	exportBtn:SetText("Export Gear")
	exportBtn:SetScript("OnClick", function()
		local exportBox = frame.exportBox
		if not exportBox then
			return
		end
		local text = Addon:FormatEquippedGearExport()
		exportBox:SetText(text)
		exportBox:SetFocus()
		exportBox:HighlightText()
	end)

	-- Persist whether gear names are included in the JSON export.
	local namesCheck = CreateFrame("CheckButton", "MrcExporterIncludeNamesCheck", frame, "UICheckButtonTemplate")
	namesCheck:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", -4, -6)
	namesCheck:SetChecked(Addon.db.includeGearNames ~= false)
	_G[namesCheck:GetName() .. "Text"]:SetText("Include item names")
	namesCheck:SetScript("OnClick", function(self)
		Addon.db.includeGearNames = self:GetChecked() and true or false
	end)

	local exportLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	exportLabel:SetPoint("TOPLEFT", namesCheck, "BOTTOMLEFT", 4, -6)
	exportLabel:SetText("Character export (Ctrl+C to copy)")

	-- Scrollable multiline EditBox for the export result.
	local scroll = CreateFrame("ScrollFrame", "MrcExporterExportScroll", frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", exportLabel, "BOTTOMLEFT", 0, -8)
	scroll:SetPoint("BOTTOMRIGHT", -36, 20)

	local exportBox = CreateFrame("EditBox", "MrcExporterExportBox", scroll)
	exportBox:SetMultiLine(true)
	exportBox:SetFontObject(ChatFontNormal)
	exportBox:SetWidth(FRAME_WIDTH - 60)
	exportBox:SetHeight(140)
	exportBox:SetAutoFocus(false)
	exportBox:EnableMouse(true)
	exportBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	scroll:SetScrollChild(exportBox)

	frame.exportBox = exportBox
	self.mainFrame = frame
	return frame
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
