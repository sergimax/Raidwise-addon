local ADDON_NAME = ...

Raidwise = Raidwise or {}
local Addon = Raidwise

Addon.version = "1.4.0"
-- Filled from ## X-LastUpdated in Raidwise.toc on load.
Addon.lastUpdated = ""

local defaults = {
	enabled = true,
	includeGearNames = true,
	characters = {},
	history = {},
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
	self:SaveCurrentCharacterLockouts()
	RequestRaidInfo()
end

-- Fires on login and /reload; PLAYER_LOGIN does not fire after /reload.
function Addon:OnPlayerEnteringWorld()
	self:SaveCurrentCharacterLockouts()
	RequestRaidInfo()
	if self.RecordCurrentGroupHistory then
		self:RecordCurrentGroupHistory(false)
	end
end

-- Refresh saved instance cache when the server answers RequestRaidInfo.
function Addon:OnUpdateInstanceInfo()
	self:SaveCurrentCharacterLockouts()

	if self.pendingLockoutExport then
		self.pendingLockoutExport = nil
		if self.FlushExportToWindow then
			self:FlushExportToWindow()
		end
	end

	if self.pendingCooldownExport then
		self.pendingCooldownExport = nil
		if self.FlushCooldownExportToWindow then
			self:FlushCooldownExportToWindow()
		end
	end

	if self.RefreshCooldownTable then
		local frame = self.mainFrame
		if self.pendingLockoutTable or (frame and frame:IsShown() and frame.selectedTab == "cooldowns") then
			self.pendingLockoutTable = nil
			self:RefreshCooldownTable()
		end
	end
end

function Addon:OnInspectTalentReadyEvent(unit)
	if self.OnInspectTalentReady then
		self:OnInspectTalentReady()
	end
end

function Addon:OnGuildInfoUpdated()
	local frame = self.mainFrame
	if not frame then
		return
	end
	if frame.selectedTab == "party" and self.RefreshPartyView then
		self:RefreshPartyView(false)
	elseif frame.selectedTab == "raid" and self.RefreshRaidRosterView then
		self:RefreshRaidRosterView(false)
	end
end

function Addon:OnGroupRosterUpdated()
	local frame = self.mainFrame
	if frame and frame:IsShown() and (frame.selectedTab == "party" or frame.selectedTab == "raid") then
		self:RefreshPartyData(false)
		return
	end
	if self.RecordCurrentGroupHistory then
		self:RecordCurrentGroupHistory(false)
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
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_INSTANCE_INFO")
frame:RegisterEvent("INSPECT_TALENT_READY")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")

-- Dispatch ADDON_LOADED and PLAYER_LOGIN to addon lifecycle hooks.
frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		Addon:OnInitialize()
	elseif event == "PLAYER_LOGIN" then
		Addon:OnPlayerLogin()
	elseif event == "PLAYER_ENTERING_WORLD" then
		Addon:OnPlayerEnteringWorld()
	elseif event == "UPDATE_INSTANCE_INFO" then
		Addon:OnUpdateInstanceInfo()
	elseif event == "INSPECT_TALENT_READY" then
		Addon:OnInspectTalentReadyEvent(arg1)
	elseif event == "PLAYER_GUILD_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
		Addon:OnGuildInfoUpdated()
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		Addon:OnGroupRosterUpdated()
	end
end)
