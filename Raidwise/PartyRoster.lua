-- Party member snapshots for the Party view (GearScore, ilvl, guild, spec via inspect).

local Addon = Raidwise

local INSPECT_SLOTS = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"RangedSlot",
}

local inspectQueue = {}
local inspectPending = nil
local specCache = {}

local function PartyUnitIds()
	local units = { "player" }
	local partyCount = GetNumPartyMembers() or 0
	for index = 1, partyCount do
		units[#units + 1] = "party" .. index
	end
	return units
end

local function SafeCanInspect(unit)
	return type(CanInspect) == "function" and CanInspect(unit)
end

local function SafeNotifyInspect(unit)
	if type(NotifyInspect) ~= "function" then
		return false
	end
	local ok = pcall(NotifyInspect, unit)
	return ok
end

local function ItemLevelFromLink(itemLink)
	if not itemLink then
		return nil
	end
	local itemId = tonumber(itemLink:match("item:(%d+)"))
	if not itemId then
		return nil
	end
	local _, _, _, itemLevel = GetItemInfo(itemId)
	itemLevel = tonumber(itemLevel)
	if itemLevel and itemLevel > 0 then
		return itemLevel
	end
	return nil
end

local function AverageItemLevelForUnit(unit)
	local total = 0
	local count = 0

	for index = 1, #INSPECT_SLOTS do
		local slotId = GetInventorySlotInfo(INSPECT_SLOTS[index])
		if slotId then
			local itemLink = GetInventoryItemLink(unit, slotId)
			local itemLevel = ItemLevelFromLink(itemLink)
			if itemLevel then
				total = total + itemLevel
				count = count + 1
			end
		end
	end

	if count == 0 then
		return nil
	end
	return math.floor(total / count + 0.5)
end

local function GearScoreForUnit(unit, refresh)
	if not UnitExists(unit) then
		return nil
	end

	local name, realm = UnitName(unit)
	if not name then
		return nil
	end

	if refresh and type(GearScore_GetScore) == "function" then
		pcall(GearScore_GetScore, name, unit)
	end

	realm = realm or GetRealmName()
	local players = GS_Data and realm and GS_Data[realm] and GS_Data[realm].Players
	local record = players and players[name]
	if record and record.GearScore ~= nil then
		return tonumber(record.GearScore)
	end

	if unit == "player" and PersonalGearScore and PersonalGearScore.GetText then
		local ok, score = pcall(function()
			return tonumber(PersonalGearScore:GetText())
		end)
		if ok then
			return score
		end
	end

	return nil
end

local function PrimarySpecFromInspect()
	if type(GetInspectUnit) == "function" and not GetInspectUnit() then
		return ""
	end

	local talentGroup = 1
	if type(GetActiveTalentGroup) == "function" then
		talentGroup = GetActiveTalentGroup(true) or 1
	end

	local bestName = ""
	local bestPoints = -1
	local tabCount = 0
	if type(GetNumTalentTabs) == "function" then
		tabCount = GetNumTalentTabs(true) or 0
	end

	for tab = 1, tabCount do
		local name, _, pointsSpent = GetTalentTabInfo(tab, true, false, talentGroup)
		pointsSpent = tonumber(pointsSpent) or 0
		if pointsSpent > bestPoints then
			bestPoints = pointsSpent
			bestName = name or ""
		end
	end

	return bestName
end

local function SpecForUnit(unit)
	if unit == "player" then
		local ok, specName = pcall(Addon.CollectPrimarySpec, Addon)
		if ok and specName and specName ~= "" then
			return specName
		end
		return "-"
	end

	local guid = UnitGUID(unit)
	if guid and specCache[guid] and specCache[guid] ~= "" then
		return specCache[guid]
	end

	if inspectPending == unit and type(GetInspectUnit) == "function" and GetInspectUnit() == unit then
		local specName = PrimarySpecFromInspect()
		if specName ~= "" then
			if guid then
				specCache[guid] = specName
			end
			return specName
		end
	end

	return "-"
end

local function GuildInfoForUnit(unit)
	if not UnitExists(unit) then
		return nil, nil
	end

	local guildName, guildRankName
	if UnitIsUnit(unit, "player") then
		guildName, guildRankName = GetGuildInfo()
	else
		local ok
		ok, guildName, guildRankName = pcall(GetGuildInfo, unit)
		if not ok then
			guildName, guildRankName = nil, nil
		end
	end

	if guildName == "" then
		guildName = nil
	end
	if guildRankName == "" then
		guildRankName = nil
	end
	return guildName, guildRankName
end

local function MinimalPartyMember(unit)
	local name, realm = UnitName(unit)
	local localizedClass, classToken = UnitClass(unit)
	return {
		unit = unit,
		name = name or "?",
		realm = realm or "",
		class = classToken or "",
		classLabel = localizedClass or "",
		spec = "-",
		gearScore = nil,
		averageIlvl = nil,
		guildName = nil,
		guildRank = nil,
	}
end

function Addon:CollectPartyMember(unit, refreshGearScore)
	local name, realm = UnitName(unit)
	local localizedClass, classToken = UnitClass(unit)
	local guildName, guildRankName = GuildInfoForUnit(unit)

	return {
		unit = unit,
		name = name or "?",
		realm = realm or "",
		class = classToken or "",
		classLabel = localizedClass or "",
		spec = SpecForUnit(unit),
		gearScore = GearScoreForUnit(unit, refreshGearScore),
		averageIlvl = AverageItemLevelForUnit(unit),
		guildName = guildName,
		guildRank = guildRankName,
	}
end

function Addon:BuildPartyRoster(refreshGearScore)
	local roster = {}
	for _, unit in ipairs(PartyUnitIds()) do
		if UnitExists(unit) then
			local ok, member = pcall(self.CollectPartyMember, self, unit, refreshGearScore)
			if ok and type(member) == "table" then
				roster[#roster + 1] = member
			else
				roster[#roster + 1] = MinimalPartyMember(unit)
			end
		end
	end

	if #roster == 0 and UnitExists("player") then
		local ok, member = pcall(self.CollectPartyMember, self, "player", refreshGearScore)
		if ok and type(member) == "table" then
			roster[1] = member
		else
			roster[1] = MinimalPartyMember("player")
		end
	end

	return roster
end

function Addon:QueuePartyInspects()
	for index = #inspectQueue, 1, -1 do
		inspectQueue[index] = nil
	end

	for _, unit in ipairs(PartyUnitIds()) do
		if unit ~= "player" and UnitExists(unit) and UnitIsVisible(unit) and SafeCanInspect(unit) then
			inspectQueue[#inspectQueue + 1] = unit
		end
	end

	self:ProcessNextPartyInspect()
end

function Addon:ProcessNextPartyInspect()
	if inspectPending or #inspectQueue == 0 then
		return
	end

	local unit = table.remove(inspectQueue, 1)
	if UnitExists(unit) and SafeCanInspect(unit) then
		inspectPending = unit
		if not SafeNotifyInspect(unit) then
			inspectPending = nil
			self:ProcessNextPartyInspect()
		end
		return
	end

	self:ProcessNextPartyInspect()
end

function Addon:OnInspectReady()
	local unit = type(GetInspectUnit) == "function" and GetInspectUnit() or nil
	if unit and UnitExists(unit) then
		local specName = PrimarySpecFromInspect()
		if specName and specName ~= "" then
			local guid = UnitGUID(unit)
			if guid then
				specCache[guid] = specName
			end
		end
	end

	inspectPending = nil

	if self.RefreshPartyView then
		self:RefreshPartyView(false)
	end

	self:ProcessNextPartyInspect()
end

function Addon:RefreshPartyData(refreshGearScore)
	if refreshGearScore == nil then
		refreshGearScore = true
	end
	if self.RefreshPartyView then
		self:RefreshPartyView(refreshGearScore)
	end
	self:QueuePartyInspects()
end
