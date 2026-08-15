-- Simple main window: title + Version / Character Info buttons.

local Addon = MrcExporter

local FRAME_WIDTH = 280
local FRAME_HEIGHT = 160

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

	-- Standard close (X); also Esc via UISpecialFrames.
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	-- Prints Addon.version to chat.
	local versionBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	versionBtn:SetSize(120, 24)
	versionBtn:SetPoint("TOP", title, "BOTTOM", 0, -16)
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
