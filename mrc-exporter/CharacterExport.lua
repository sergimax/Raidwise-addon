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

-- Resolve item id from inventory API or by parsing the item link.
local function ItemIdFromSlot(slotId, itemLink)
	local itemId = GetInventoryItemID("player", slotId)
	if itemId and itemId > 0 then
		return itemId
	end
	if itemLink then
		local parsed = tonumber(itemLink:match("item:(%d+)"))
		if parsed and parsed > 0 then
			return parsed
		end
	end
	return nil
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

-- JSON-like export: name, class, spec, and gear { ids, names }.
function Addon:FormatEquippedGearExport()
	local info = self:CollectCharacterInfo()
	local gear = self:CollectEquippedGear()

	local lines = {
		"{",
		'  "name": "' .. JsonEscape(info.name) .. '",',
		'  "class": "' .. JsonEscape(info.class) .. '",',
		'  "spec": "' .. JsonEscape(info.spec) .. '",',
		'  "gear": {',
		'    "ids": ' .. FormatJsonNumberArray(gear.ids) .. ",",
		'    "names": ' .. FormatJsonStringArray(gear.names),
		"  }",
		"}",
	}
	return table.concat(lines, "\n")
end
