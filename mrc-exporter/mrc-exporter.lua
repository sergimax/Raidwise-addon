local ADDON_NAME = ...

MrcExporter = MrcExporter or {}
local Addon = MrcExporter

Addon.version = "0.3.0"
-- Filled from ## X-LastUpdated in mrc-exporter.toc on load.
Addon.lastUpdated = ""

local defaults = {
	enabled = true,
	includeGearNames = true,
}

-- Recursively copy a value (tables become independent copies).
local function DeepCopy(src)
	if type(src) ~= "table" then
		return src
	end
	local dst = {}
	for k, v in pairs(src) do
		dst[k] = DeepCopy(v)
	end
	return dst
end

-- Create or migrate SavedVariables, then bind Addon.db.
local function EnsureDB()
	if type(MrcExporterDB) ~= "table" then
		MrcExporterDB = DeepCopy(defaults)
	end
	for k, v in pairs(defaults) do
		if MrcExporterDB[k] == nil then
			MrcExporterDB[k] = DeepCopy(v)
		end
	end
	Addon.db = MrcExporterDB
end

-- Print a prefixed message to the default chat frame.
function Addon:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffmrc-exporter|r: " .. tostring(msg))
end

-- Run once when this addon finishes loading.
function Addon:OnInitialize()
	EnsureDB()
	self.lastUpdated = GetAddOnMetadata(ADDON_NAME, "X-LastUpdated") or ""
	self:CreateMainFrame()
	self:Print("loaded (v" .. self.version .. "). Type /mrc for help.")
end

-- Run when the player is fully in the world (gear, talents, etc.).
function Addon:OnPlayerLogin()
	-- Hook character-ready logic here.
end

-- Slash commands: /mrc and /mrcexporter
SLASH_MRCEXPORTER1 = "/mrc"
SLASH_MRCEXPORTER2 = "/mrcexporter"

-- Handle /mrc and /mrcexporter (help, version, status, show/hide UI).
SlashCmdList["MRCEXPORTER"] = function(msg)
	msg = (msg or ""):match("^%s*(.-)%s*$") or ""
	msg = msg:lower()

	if msg == "" or msg == "help" then
		Addon:Print("/mrc help    - show this help")
		Addon:Print("/mrc version - show addon version")
		Addon:Print("/mrc status  - show addon status")
		Addon:Print("/mrc show    - open the main window")
		Addon:Print("/mrc hide    - close the main window")
		return
	end

	if msg == "version" then
		Addon:Print("version " .. tostring(Addon.version))
		return
	end

	if msg == "status" then
		Addon:Print(string.format(
			"v%s | updated=%s | enabled=%s | player=%s",
			Addon.version,
			tostring(Addon.lastUpdated),
			tostring(Addon.db and Addon.db.enabled),
			UnitName("player") or "?"
		))
		return
	end

	if msg == "show" or msg == "ui" then
		Addon:ShowMainFrame()
		return
	end

	if msg == "hide" then
		Addon:HideMainFrame()
		return
	end

	Addon:Print("Unknown command. Type /mrc help")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

-- Dispatch ADDON_LOADED and PLAYER_LOGIN to addon lifecycle hooks.
frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		Addon:OnInitialize()
	elseif event == "PLAYER_LOGIN" then
		Addon:OnPlayerLogin()
	end
end)
