local ADDON_NAME = ...

Raidwise = Raidwise or {}
local Addon = Raidwise

Addon.version = "1.0.0"
-- Filled from ## X-LastUpdated in Raidwise.toc on load.
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
	if type(RaidwiseDB) ~= "table" then
		if type(MrcExporterDB) == "table" then
			RaidwiseDB = DeepCopy(MrcExporterDB)
		else
			RaidwiseDB = DeepCopy(defaults)
		end
	end
	for k, v in pairs(defaults) do
		if RaidwiseDB[k] == nil then
			RaidwiseDB[k] = DeepCopy(v)
		end
	end
	Addon.db = RaidwiseDB
end

-- Print a prefixed message to the default chat frame.
function Addon:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffRaidwise|r: " .. tostring(msg))
end

-- Run once when this addon finishes loading.
function Addon:OnInitialize()
	EnsureDB()
	self.lastUpdated = GetAddOnMetadata(ADDON_NAME, "X-LastUpdated") or ""
	self:CreateMainFrame()
	self:Print("loaded (v" .. self.version .. "). Type /raidwise for help.")
end

-- Run when the player is fully in the world (gear, talents, etc.).
function Addon:OnPlayerLogin()
	RequestRaidInfo()
end

-- Refresh saved instance cache when the server answers RequestRaidInfo.
function Addon:OnUpdateInstanceInfo()
	if not self.pendingLockoutExport then
		return
	end
	self.pendingLockoutExport = nil
	if self.FlushExportToWindow then
		self:FlushExportToWindow()
	end
end
-- Slash commands: /raidwise and /rw
SLASH_RAIDWISE1 = "/raidwise"
SLASH_RAIDWISE2 = "/rw"

-- Handle /raidwise and /rw (help, version, status, show/hide UI).
SlashCmdList["RAIDWISE"] = function(msg)
	msg = (msg or ""):match("^%s*(.-)%s*$") or ""
	msg = msg:lower()

	if msg == "" or msg == "help" then
		Addon:Print("/raidwise help    - show this help")
		Addon:Print("/raidwise version - show addon version")
		Addon:Print("/raidwise status  - show addon status")
		Addon:Print("/raidwise show    - open the main window")
		Addon:Print("/raidwise hide    - close the main window")
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

	Addon:Print("Unknown command. Type /raidwise help")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_INSTANCE_INFO")

-- Dispatch ADDON_LOADED and PLAYER_LOGIN to addon lifecycle hooks.
frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		Addon:OnInitialize()
	elseif event == "PLAYER_LOGIN" then
		Addon:OnPlayerLogin()
	elseif event == "UPDATE_INSTANCE_INFO" then
		Addon:OnUpdateInstanceInfo()
	end
end)
