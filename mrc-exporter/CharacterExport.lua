-- Collect character identity and equipped gear; format as a JSON-like object.

local Addon = MrcExporter

-- Same order as WowSimsExporter (AmmoSlot omitted).
local SLOT_NAMES = {
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

-- Escape a string for JSON output.
local function JsonEscape(value)
	local str = tostring(value or "")
	str = str:gsub("\\", "\\\\")
	str = str:gsub('"', '\\"')
	str = str:gsub("\n", "\\n")
	str = str:gsub("\r", "\\r")
	str = str:gsub("\t", "\\t")
	return str
end

-- Join numbers as a JSON array: [1,2,3]
local function FormatJsonNumberArray(values)
	if #values == 0 then
		return "[]"
	end
	return "[" .. table.concat(values, ",") .. "]"
end

-- Join strings as a JSON array: ["a","b"]
local function FormatJsonStringArray(values)
	if #values == 0 then
		return "[]"
	end
	local parts = {}
	for i = 1, #values do
		parts[i] = '"' .. JsonEscape(values[i]) .. '"'
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

-- Resolve a display name from item cache or the item link.
local function ItemNameFromLink(itemId, itemLink)
	local name = GetItemInfo(itemId)
	if name then
		return name
	end
	if itemLink then
		local fromLink = itemLink:match("%[(.-)%]")
		if fromLink then
			return fromLink
		end
	end
	return tostring(itemId)
end

-- Resolve item id from an item link string.
local function ItemIdFromLink(itemLink)
	if not itemLink then
		return nil
	end
	local parsed = tonumber(itemLink:match("item:(%d+)"))
	if parsed and parsed > 0 then
		return parsed
	end
	return nil
end

-- Resolve item id from inventory API or by parsing the item link.
local function ItemIdFromSlot(slotId, itemLink)
	local itemId = GetInventoryItemID("player", slotId)
	if itemId and itemId > 0 then
		return itemId
	end
	return ItemIdFromLink(itemLink)
end

-- Active talent tree with the most points spent (WotLK dual-spec aware).
local function PrimarySpecName()
	local talentGroup = GetActiveTalentGroup and GetActiveTalentGroup() or 1
	local bestName = ""
	local bestPoints = -1

	for tab = 1, GetNumTalentTabs() do
		local name, _, pointsSpent = GetTalentTabInfo(tab, false, false, talentGroup)
		pointsSpent = tonumber(pointsSpent) or 0
		if pointsSpent > bestPoints then
			bestPoints = pointsSpent
			bestName = name or ""
		end
	end

	return bestName
end

-- Append JSON object lines for { ids[, names] } under the given key.
local function AppendItemListJson(lines, key, items, includeNames, isLast)
	lines[#lines + 1] = '  "' .. key .. '": {'
	local idsLine = '    "ids": ' .. FormatJsonNumberArray(items.ids)
	if includeNames then
		lines[#lines + 1] = idsLine .. ","
		lines[#lines + 1] = '    "names": ' .. FormatJsonStringArray(items.names)
	else
		lines[#lines + 1] = idsLine
	end
	if isLast then
		lines[#lines + 1] = "  }"
	else
		lines[#lines + 1] = "  },"
	end
end

-- JSON true/false from WoW 1/nil flags.
local function FormatJsonBoolean(value)
	if value then
		return "true"
	end
	return "false"
end

-- Append a JSON array of instance lockout objects.
local function AppendLockoutsJson(lines, lockouts, isLast)
	if #lockouts == 0 then
		if isLast then
			lines[#lines + 1] = '  "lockouts": []'
		else
			lines[#lines + 1] = '  "lockouts": [],'
		end
		return
	end

	lines[#lines + 1] = '  "lockouts": ['
	for i = 1, #lockouts do
		local entry = lockouts[i]
		local comma = (i < #lockouts) and "," or ""
		lines[#lines + 1] = "    {"
		lines[#lines + 1] = '      "name": "' .. JsonEscape(entry.name) .. '",'
		lines[#lines + 1] = '      "id": ' .. tostring(entry.id) .. ","
		lines[#lines + 1] = '      "reset": ' .. tostring(entry.reset) .. ","
		lines[#lines + 1] = '      "resetAt": ' .. tostring(entry.resetAt) .. ","
		lines[#lines + 1] = '      "difficulty": ' .. tostring(entry.difficulty) .. ","
		lines[#lines + 1] = '      "difficultyName": "' .. JsonEscape(entry.difficultyName) .. '",'
		lines[#lines + 1] = '      "locked": ' .. FormatJsonBoolean(entry.locked) .. ","
		lines[#lines + 1] = '      "extended": ' .. FormatJsonBoolean(entry.extended) .. ","
		lines[#lines + 1] = '      "isRaid": ' .. FormatJsonBoolean(entry.isRaid) .. ","
		lines[#lines + 1] = '      "maxPlayers": ' .. tostring(entry.maxPlayers)
		lines[#lines + 1] = "    }" .. comma
	end
	if isLast then
		lines[#lines + 1] = "  ]"
	else
		lines[#lines + 1] = "  ],"
	end
end

-- Return equipped gear as { ids = {...}, names = {...} } (empty slots omitted).
function Addon:CollectEquippedGear()
	local ids = {}
	local names = {}

	for _, slotName in ipairs(SLOT_NAMES) do
		local slotId = GetInventorySlotInfo(slotName)
		local itemLink = GetInventoryItemLink("player", slotId)
		if itemLink then
			local itemId = ItemIdFromSlot(slotId, itemLink)
			if itemId then
				ids[#ids + 1] = itemId
				names[#names + 1] = ItemNameFromLink(itemId, itemLink)
			end
		end
	end

	return { ids = ids, names = names }
end

-- Return backpack + bag-slot items as { ids = {...}, names = {...} }.
-- One entry per occupied container slot (stack size ignored). Bags 0-4 only.
function Addon:CollectBagItems()
	local ids = {}
	local names = {}

	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag) or 0
		for slot = 1, numSlots do
			local itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				local itemId = ItemIdFromLink(itemLink)
				if itemId then
					ids[#ids + 1] = itemId
					names[#names + 1] = ItemNameFromLink(itemId, itemLink)
				end
			end
		end
	end

	return { ids = ids, names = names }
end

-- Saved raid/dungeon lockouts (cleared IDs and time until reset).
-- Uses GetSavedInstanceInfo; call RequestRaidInfo() first for fresh data.
function Addon:CollectInstanceLockouts()
	local lockouts = {}
	local now = time()
	local count = GetNumSavedInstances() or 0

	for index = 1, count do
		local name, lockoutId, reset, difficulty, locked, extended, _, isRaid, maxPlayers, difficultyName =
			GetSavedInstanceInfo(index)
		reset = tonumber(reset) or 0
		lockouts[#lockouts + 1] = {
			name = name or "",
			id = tonumber(lockoutId) or 0,
			reset = reset,
			resetAt = now + reset,
			difficulty = tonumber(difficulty) or 0,
			difficultyName = difficultyName or "",
			locked = locked and true or false,
			extended = extended and true or false,
			isRaid = isRaid and true or false,
			maxPlayers = tonumber(maxPlayers) or 0,
		}
	end

	return lockouts
end

-- Current GearScore from the GearScore addon (same value as the character window).
-- Returns nil if GearScore is not loaded or has no score yet.
function Addon:CollectCurrentGearScore()
	local playerName = UnitName("player")
	if not playerName then
		return nil
	end

	-- Ask GearScore to refresh the player record (their calculation, not ours).
	if type(GearScore_GetScore) == "function" then
		pcall(GearScore_GetScore, playerName, "player")
	end

	local realm = GetRealmName()
	local players = GS_Data and realm and GS_Data[realm] and GS_Data[realm].Players
	local record = players and players[playerName]
	if record and record.GearScore ~= nil then
		local score = tonumber(record.GearScore)
		if score then
			return score
		end
	end

	-- Fallback: value shown on the character-frame FontString.
	if PersonalGearScore and PersonalGearScore.GetText then
		local score = tonumber(PersonalGearScore:GetText())
		if score then
			return score
		end
	end

	return nil
end

-- Current character name, english class token, and primary talent tree name.
function Addon:CollectCharacterInfo()
	local name = UnitName("player") or ""
	local _, classToken = UnitClass("player")
	return {
		name = name,
		class = classToken or "",
		spec = PrimarySpecName(),
	}
end

-- JSON-like export: name, class, spec, gearScore, gear, bags, and instance lockouts.
function Addon:FormatEquippedGearExport()
	local info = self:CollectCharacterInfo()
	local gearScore = self:CollectCurrentGearScore()
	local gear = self:CollectEquippedGear()
	local bags = self:CollectBagItems()
	local lockouts = self:CollectInstanceLockouts()
	local includeNames = not self.db or self.db.includeGearNames ~= false

	local lines = {
		"{",
		'  "name": "' .. JsonEscape(info.name) .. '",',
		'  "class": "' .. JsonEscape(info.class) .. '",',
		'  "spec": "' .. JsonEscape(info.spec) .. '",',
	}
	if gearScore ~= nil then
		lines[#lines + 1] = '  "gearScore": ' .. tostring(gearScore) .. ","
	end
	AppendItemListJson(lines, "gear", gear, includeNames, false)
	AppendItemListJson(lines, "bags", bags, includeNames, false)
	AppendLockoutsJson(lines, lockouts, true)
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n")
end
