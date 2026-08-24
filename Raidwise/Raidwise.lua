local ADDON_NAME = ...

Raidwise = Raidwise or {}
local Addon = Raidwise

Addon.version = "1.14.0"
-- Filled from ## X-LastUpdated in Raidwise.toc on load.
Addon.lastUpdated = ""

-- Fallback if Locale.lua does not load. Locale.lua replaces Addon.T.
local FallbackChat = {
	CHAT_LOADED = "loaded (v%s). Type /raidwise to open.",
	CHAT_UNKNOWN = "Unknown command. Use /raidwise or /raidwise close.",
}

local function FormatText(text, ...)
	local count = select("#", ...)
	if count <= 0 then
		return text
	end
	local ok, formatted = pcall(string.format, text, ...)
	if ok then
		return formatted
	end
	return text
end

function Addon:T(key, ...)
	return FormatText(FallbackChat[key] or tostring(key or ""), ...)
end

local defaults = {
	enabled = true,
	includeGearNames = true,
	startupTab = "cooldowns",
	characters = {},
	history = {},
	tooltip = {
		hidePersonal = false,
		hidePersonalTags = false,
		hideCommunity = false,
		hideCommunityTags = false,
	},
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
	if not self.db.locale or (self.db.locale ~= "enUS" and self.db.locale ~= "ruRU") then
		self.db.locale = self.DetectClientLocale and self:DetectClientLocale() or "enUS"
	end
	if self.SetLocale then
		self:SetLocale(self.db.locale, true)
	end
	if self.CreateMainFrame then
		local ok, err = pcall(self.CreateMainFrame, self)
		if not ok then
			self:Print("UI failed to load: " .. tostring(err))
		end
	end
	if not self.RatingTagGroups then
		self:Print("Player rating module failed to load. Update PlayerHistory.lua and /reload.")
	end
	self:Print(self:T("CHAT_LOADED", self.version))
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

	if self.RefreshCooldownTable then
		local frame = self.mainFrame
		if self.pendingLockoutTable or (frame and frame:IsShown() and frame.selectedTab == "cooldowns") then
			self.pendingLockoutTable = nil
			self:RefreshCooldownTable()
		end
	end
end

function Addon:OnInspectTalentReadyEvent(_unit) -- _unit unused; event always routes to OnInspectTalentReady()
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
	elseif frame.selectedTab == "composition" and self.RefreshCompositionView then
		self:RefreshCompositionView(false)
	end
end

function Addon:OnGroupRosterUpdated()
	local frame = self.mainFrame
	if frame and frame:IsShown() and (frame.selectedTab == "party" or frame.selectedTab == "raid" or frame.selectedTab == "composition") then
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

-- /raidwise [close] — open or close the main window.
SlashCmdList["RAIDWISE"] = function(msg)
	msg = (msg or ""):match("^%s*(.-)%s*$") or ""
	msg = msg:lower()

	if msg == "" then
		Addon:ShowMainFrame()
		return
	end

	if msg == "close" then
		Addon:HideMainFrame()
		return
	end

	Addon:Print(Addon:T("CHAT_UNKNOWN"))
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
