-- Collect character identity and equipped gear; format as a JSON-like object.

local Addon = Raidwise

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
-- Returns name, icon texture path.
function Addon:CollectPrimarySpec()
	local talentGroup = GetActiveTalentGroup and GetActiveTalentGroup() or 1
	local bestName = ""
	local bestIcon = ""
	local bestTab = 0
	local bestPoints = -1

	for tab = 1, GetNumTalentTabs() or 0 do
		local name, icon, pointsSpent = GetTalentTabInfo(tab, false, false, talentGroup)
		pointsSpent = tonumber(pointsSpent) or 0
		if pointsSpent > bestPoints then
			bestPoints = pointsSpent
			bestName = name or ""
			bestIcon = icon or ""
			bestTab = tab
		end
	end

	return bestName, bestIcon, bestTab
end

local function PrimarySpecName()
	local name = Addon:CollectPrimarySpec()
	return name
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

-- WotLK 3.3.5 currency entries in Currency-tab order: gold, raid emblems, PvP, other tokens.
local GOLD_ICON = "Interface\\Icons\\INV_Misc_Coin_01"

-- Hardcoded icons so badges show even when item cache is cold.
local CURRENCY_ENTRY_DEFS = {
	{ kind = "gold", icon = GOLD_ICON, labelKey = "CD_CURRENCY_GOLD" },
	{ kind = "item", itemId = 49426, icon = "Interface\\Icons\\INV_Misc_FrostEmblem_01", labelKey = "CD_CURRENCY_FROST" },
	{ kind = "item", itemId = 47241, icon = "Interface\\Icons\\INV_Misc_Trophy_Argent", labelKey = "CD_CURRENCY_TRIUMPH" },
	{ kind = "honor", labelKey = "CD_CURRENCY_HONOR" },
	{ kind = "arena", labelKey = "CD_CURRENCY_ARENA" },
	{ kind = "item", itemId = 40753, icon = "Interface\\Icons\\Spell_Holy_ProclaimChampion_02", labelKey = "CD_CURRENCY_HEROISM" },
	{ kind = "item", itemId = 40752, icon = "Interface\\Icons\\Spell_Holy_ProclaimChampion", labelKey = "CD_CURRENCY_VALOR" },
	{ kind = "item", itemId = 45624, icon = "Interface\\Icons\\INV_Misc_Coin_17", labelKey = "CD_CURRENCY_CONQUEST" },
	{ kind = "item", itemId = 44990, icon = "Interface\\Icons\\Ability_Paladin_ArtofWar", labelKey = "CD_CURRENCY_CHAMPION" },
}

local function PvpCurrencyIcon(kind)
	local faction = (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
	-- 3.3.5a PvP frame textures (PVPCurrency-* icon names are not reliable on all clients).
	if kind == "honor" then
		if faction == "Horde" then
			return "Interface\\PVPFrame\\PVP-Currency-Horde"
		end
		return "Interface\\PVPFrame\\PVP-Currency-Alliance"
	end
	return "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
end

local function FormatMoneyShort(copper)
	copper = math.floor(tonumber(copper) or 0)
	local gold = math.floor(copper / 10000)
	if gold >= 100000 then
		return string.format("%.0fkg", gold / 1000)
	end
	if gold >= 10000 then
		return string.format("%.1fkg", gold / 1000)
	end
	return tostring(gold) .. "g"
end

local function FormatMoneyLong(copper)
	copper = math.floor(tonumber(copper) or 0)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	local coin = copper % 100
	return string.format("%dg %ds %dc", gold, silver, coin)
end

local function FormatBadgeCount(count)
	count = tonumber(count) or 0
	if count >= 100000 then
		return string.format("%.0fk", count / 1000)
	end
	if count >= 10000 then
		return string.format("%.1fk", count / 1000)
	end
	return tostring(count)
end

local function ResolveEntryLabel(def, itemName)
	if def.labelKey then
		return Addon:T(def.labelKey)
	end
	if def.kind == "gold" then
		return Addon:T("CD_CURRENCY_GOLD")
	end
	if def.kind == "honor" then
		return Addon:T("CD_CURRENCY_HONOR")
	end
	if def.kind == "arena" then
		return Addon:T("CD_CURRENCY_ARENA")
	end
	if itemName and itemName ~= "" then
		return itemName
	end
	return tostring(def.itemId or "?")
end

local function ResolveEntryCount(def)
	if def.kind == "gold" then
		local copper = (type(GetMoney) == "function" and GetMoney()) or 0
		return copper, FormatMoneyShort(copper), FormatMoneyLong(copper)
	end
	if def.kind == "honor" then
		local honor = (type(GetHonorCurrency) == "function" and GetHonorCurrency()) or 0
		return honor, FormatBadgeCount(honor), tostring(honor)
	end
	if def.kind == "arena" then
		local arena = (type(GetArenaCurrency) == "function" and GetArenaCurrency()) or 0
		return arena, FormatBadgeCount(arena), tostring(arena)
	end
	if def.kind == "item" and def.itemId then
		local count = 0
		if type(GetItemCount) == "function" then
			count = GetItemCount(def.itemId, true) or 0
		end
		return count, FormatBadgeCount(count), tostring(count)
	end
	return 0, "0", "0"
end

local function ResolveEntryIcon(def)
	if def.kind == "honor" or def.kind == "arena" then
		return PvpCurrencyIcon(def.kind)
	end
	if def.icon and def.icon ~= "" then
		return def.icon
	end
	-- GetItemInfo: texture is the 10th return on 3.3.5a (3rd is quality).
	if def.kind == "item" and def.itemId and type(GetItemInfo) == "function" then
		local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(def.itemId)
		if type(texture) == "string" and texture ~= "" then
			return texture
		end
	end
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function EntryIdForDef(def)
	if def.kind == "item" then
		return def.itemId
	end
	return def.kind
end

-- Always prefer catalog icons so stale SavedVariables (wrong GetItemInfo returns) never show red squares.
function Addon:ResolveCurrencyIcon(entryId)
	if entryId == nil then
		return "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	if entryId == "honor" or entryId == "arena" then
		return PvpCurrencyIcon(entryId)
	end
	for index = 1, #CURRENCY_ENTRY_DEFS do
		local def = CURRENCY_ENTRY_DEFS[index]
		if EntryIdForDef(def) == entryId or tostring(EntryIdForDef(def)) == tostring(entryId) then
			return ResolveEntryIcon(def)
		end
	end
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Gold, emblems, honor/arena, and quest tokens for the logged-in character (Currency tab).
function Addon:CollectCharacterCurrency()
	local entries = {}
	for index = 1, #CURRENCY_ENTRY_DEFS do
		local def = CURRENCY_ENTRY_DEFS[index]
		local itemName
		if def.kind == "item" and def.itemId and type(GetItemInfo) == "function" then
			itemName = GetItemInfo(def.itemId)
		end
		local count, displayCount, tooltipCount = ResolveEntryCount(def)
		entries[#entries + 1] = {
			id = def.kind == "item" and def.itemId or def.kind,
			label = ResolveEntryLabel(def, itemName),
			icon = ResolveEntryIcon(def),
			count = count,
			displayCount = displayCount,
			tooltipCount = tooltipCount,
		}
	end
	return { entries = entries }
end

-- Catalog entry id at a 1-based index (same order as CollectCharacterCurrency).
function Addon:GetCurrencyEntryIdAt(index)
	local def = CURRENCY_ENTRY_DEFS[index]
	if not def then
		return nil
	end
	return EntryIdForDef(def)
end

-- Format a summed currency count for the cooldowns label column.
function Addon:FormatCurrencyCount(entryId, count)
	count = tonumber(count) or 0
	if entryId == "gold" then
		return FormatMoneyShort(count)
	end
	return FormatBadgeCount(count)
end

-- Short labels for the currency row in the cooldowns table (same order as entries).
function Addon:GetCurrencyEntryLabels()
	local labels = {}
	for index = 1, #CURRENCY_ENTRY_DEFS do
		local def = CURRENCY_ENTRY_DEFS[index]
		local itemName
		if def.kind == "item" and def.itemId and type(GetItemInfo) == "function" then
			itemName = GetItemInfo(def.itemId)
		end
		labels[index] = ResolveEntryLabel(def, itemName)
	end
	return labels
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
	if self.SaveCurrentCharacterLockouts then
		self:SaveCurrentCharacterLockouts()
	end
	return table.concat(lines, "\n")
end
