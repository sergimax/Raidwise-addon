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

-- JSON-like export: name, class, spec, gear, and bags.
function Addon:FormatEquippedGearExport()
	local info = self:CollectCharacterInfo()
	local gear = self:CollectEquippedGear()
	local bags = self:CollectBagItems()
	local includeNames = not self.db or self.db.includeGearNames ~= false

	local lines = {
		"{",
		'  "name": "' .. JsonEscape(info.name) .. '",',
		'  "class": "' .. JsonEscape(info.class) .. '",',
		'  "spec": "' .. JsonEscape(info.spec) .. '",',
	}
	AppendItemListJson(lines, "gear", gear, includeNames, false)
	AppendItemListJson(lines, "bags", bags, includeNames, true)
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n")
end
