-- Collect equipped gear as item IDs and names (WotLK inventory slots).

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

-- Two-line export: comma-separated IDs, then comma-separated names.
function Addon:FormatEquippedGearExport()
	local gear = self:CollectEquippedGear()
	if #gear.ids == 0 then
		return ""
	end
	return table.concat(gear.ids, ",") .. "\n" .. table.concat(gear.names, ",")
end
