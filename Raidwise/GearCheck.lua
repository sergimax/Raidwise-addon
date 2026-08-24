-- Gear Check: collect equipped gear into a normalized model (schemaVersion 2).
-- Phase 2: no suitability rules. Phase 3+ must use this table only — no WoW API in rules.

local Addon = Raidwise

Addon.GEAR_CHECK_SCHEMA_VERSION = 2

-- Slot order for collection / dump. Policy drives later evaluation skips.
local SLOT_DEFS = {
	{ key = "head", slotName = "HeadSlot", policy = "CHECKED" },
	{ key = "neck", slotName = "NeckSlot", policy = "CHECKED" },
	{ key = "shoulder", slotName = "ShoulderSlot", policy = "CHECKED" },
	{ key = "back", slotName = "BackSlot", policy = "CHECKED" },
	{ key = "chest", slotName = "ChestSlot", policy = "CHECKED" },
	{ key = "shirt", slotName = "ShirtSlot", policy = "IGNORED" },
	{ key = "tabard", slotName = "TabardSlot", policy = "IGNORED" },
	{ key = "wrist", slotName = "WristSlot", policy = "CHECKED" },
	{ key = "hands", slotName = "HandsSlot", policy = "CHECKED" },
	{ key = "waist", slotName = "WaistSlot", policy = "CHECKED" },
	{ key = "legs", slotName = "LegsSlot", policy = "CHECKED" },
	{ key = "feet", slotName = "FeetSlot", policy = "CHECKED" },
	{ key = "finger1", slotName = "Finger0Slot", policy = "CHECKED" },
	{ key = "finger2", slotName = "Finger1Slot", policy = "CHECKED" },
	{ key = "trinket1", slotName = "Trinket0Slot", policy = "PLANNED" },
	{ key = "trinket2", slotName = "Trinket1Slot", policy = "PLANNED" },
	{ key = "mainHand", slotName = "MainHandSlot", policy = "CHECKED" },
	{ key = "offHand", slotName = "SecondaryHandSlot", policy = "CHECKED" },
	{ key = "ranged", slotName = "RangedSlot", policy = "CHECKED" },
}

-- GetItemStats keys → locale-independent stat ids.
local STAT_MAP = {
	ITEM_MOD_STRENGTH_SHORT = "strength",
	ITEM_MOD_AGILITY_SHORT = "agility",
	ITEM_MOD_STAMINA_SHORT = "stamina",
	ITEM_MOD_INTELLECT_SHORT = "intellect",
	ITEM_MOD_SPIRIT_SHORT = "spirit",
	ITEM_MOD_HIT_RATING_SHORT = "hitRating",
	ITEM_MOD_CRIT_RATING_SHORT = "critRating",
	ITEM_MOD_HASTE_RATING_SHORT = "hasteRating",
	ITEM_MOD_EXPERTISE_RATING_SHORT = "expertiseRating",
	ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "armorPenetration",
	ITEM_MOD_SPELL_POWER_SHORT = "spellPower",
	ITEM_MOD_ATTACK_POWER_SHORT = "attackPower",
	ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "feralAttackPower",
	ITEM_MOD_SPELL_PENETRATION_SHORT = "spellPenetration",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "defenseRating",
	ITEM_MOD_DODGE_RATING_SHORT = "dodgeRating",
	ITEM_MOD_PARRY_RATING_SHORT = "parryRating",
	ITEM_MOD_BLOCK_RATING_SHORT = "blockRating",
	ITEM_MOD_BLOCK_VALUE_SHORT = "blockValue",
	ITEM_MOD_RESILIENCE_RATING_SHORT = "resilience",
	ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
	ITEM_MOD_POWER_REGEN0_SHORT = "mp5",
	ITEM_MOD_HEALTH_REGENERATION_SHORT = "hp5",
	RESISTANCE0_NAME = "armor",
}

local SOCKET_MAP = {
	EMPTY_SOCKET_META = "meta",
	EMPTY_SOCKET_RED = "red",
	EMPTY_SOCKET_YELLOW = "yellow",
	EMPTY_SOCKET_BLUE = "blue",
	EMPTY_SOCKET_NO_COLOR = "prismatic",
}

-- GetAuctionItemSubClasses order on 3.3.5a (1-based).
local ARMOR_SUBCLASS_KEYS = {
	"misc", "cloth", "leather", "mail", "plate", "shield", "libram", "idol", "totem", "sigil",
}
local WEAPON_SUBCLASS_KEYS = {
	"axe1h", "axe2h", "bow", "gun", "mace1h", "mace2h", "polearm", "sword1h", "sword2h",
	"staff", "fist", "misc", "dagger", "thrown", "crossbow", "wand", "fishingPole",
}
local GEM_SUBCLASS_KEYS = {
	"red", "blue", "yellow", "purple", "green", "orange", "meta", "simple", "prismatic",
}

local ARMOR_NAME_FALLBACK = {
	cloth = "cloth",
	leather = "leather",
	mail = "mail",
	plate = "plate",
	shield = "shield",
	shields = "shield",
	libram = "libram",
	librams = "libram",
	idol = "idol",
	idols = "idol",
	totem = "totem",
	totems = "totem",
	sigil = "sigil",
	sigils = "sigil",
	miscellaneous = "misc",
}

local WEAPON_NAME_FALLBACK = {
	["one-handed axes"] = "axe1h",
	["two-handed axes"] = "axe2h",
	bows = "bow",
	guns = "gun",
	["one-handed maces"] = "mace1h",
	["two-handed maces"] = "mace2h",
	polearms = "polearm",
	["one-handed swords"] = "sword1h",
	["two-handed swords"] = "sword2h",
	staves = "staff",
	["fist weapons"] = "fist",
	miscellaneous = "misc",
	daggers = "dagger",
	thrown = "thrown",
	crossbows = "crossbow",
	wands = "wand",
	["fishing poles"] = "fishingPole",
}

local GEM_NAME_FALLBACK = {
	red = "red",
	blue = "blue",
	yellow = "yellow",
	purple = "purple",
	green = "green",
	orange = "orange",
	meta = "meta",
	simple = "simple",
	prismatic = "prismatic",
}

local armorSubTypeMap = {}
local weaponSubTypeMap = {}
local gemSubTypeMap = {}
local auctionMapsReady = false

local scanToken = 0
local pendingUnit = nil
local pendingCallback = nil
local retryElapsed = 0
local retryBudget = 0
local lastReport = nil

local retryFrame = CreateFrame("Frame")
retryFrame:Hide()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("INSPECT_TALENT_READY")

local function AddGap(gaps, code, detail)
	gaps[#gaps + 1] = { code = code, detail = detail }
end

local function BuildAuctionMap(classIndex, keys)
	local map = {}
	if type(GetAuctionItemSubClasses) ~= "function" then
		return map
	end
	local ok, names = pcall(function()
		return { GetAuctionItemSubClasses(classIndex) }
	end)
	if not ok or type(names) ~= "table" then
		return map
	end
	for index = 1, #names do
		local name = names[index]
		if type(name) == "string" and name ~= "" and keys[index] then
			map[name] = keys[index]
			map[strlower(name)] = keys[index]
		end
	end
	return map
end

local function EnsureAuctionMaps()
	if auctionMapsReady then
		return
	end
	weaponSubTypeMap = BuildAuctionMap(1, WEAPON_SUBCLASS_KEYS)
	armorSubTypeMap = BuildAuctionMap(2, ARMOR_SUBCLASS_KEYS)
	gemSubTypeMap = {}
	if type(GetAuctionItemClasses) == "function" then
		local ok, classes = pcall(function()
			return { GetAuctionItemClasses() }
		end)
		if ok and type(classes) == "table" then
			for classIndex = 1, #classes do
				local className = classes[classIndex]
				if type(className) == "string" and strlower(className) == "gem" then
					gemSubTypeMap = BuildAuctionMap(classIndex, GEM_SUBCLASS_KEYS)
					break
				end
			end
		end
	end
	auctionMapsReady = true
end

local function LookupMappedName(map, fallback, name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	if map and map[name] then
		return map[name]
	end
	local lower = strlower(name)
	if map and map[lower] then
		return map[lower]
	end
	if fallback and fallback[lower] then
		return fallback[lower]
	end
	return nil
end

local function ClassifyItem(itemType, itemSubType, equipLoc)
	EnsureAuctionMaps()
	local category = "unknown"
	local armorType = nil
	local weaponType = nil
	local isRelic = false

	if equipLoc == "INVTYPE_SHIELD" then
		category = "armor"
		armorType = "shield"
	elseif equipLoc == "INVTYPE_HOLDABLE" then
		category = "armor"
		armorType = "offhand"
	elseif equipLoc == "INVTYPE_RELIC" then
		category = "relic"
		isRelic = true
	elseif equipLoc == "INVTYPE_2HWEAPON"
		or equipLoc == "INVTYPE_WEAPON"
		or equipLoc == "INVTYPE_WEAPONMAINHAND"
		or equipLoc == "INVTYPE_WEAPONOFFHAND"
		or equipLoc == "INVTYPE_RANGED"
		or equipLoc == "INVTYPE_RANGEDRIGHT"
		or equipLoc == "INVTYPE_THROWN"
	then
		category = "weapon"
		weaponType = LookupMappedName(weaponSubTypeMap, WEAPON_NAME_FALLBACK, itemSubType) or "unknown"
	else
		local armor = LookupMappedName(armorSubTypeMap, ARMOR_NAME_FALLBACK, itemSubType)
		if armor then
			category = "armor"
			armorType = armor
			if armor == "libram" or armor == "idol" or armor == "totem" or armor == "sigil" then
				category = "relic"
				isRelic = true
			end
		elseif LookupMappedName(weaponSubTypeMap, WEAPON_NAME_FALLBACK, itemSubType) then
			category = "weapon"
			weaponType = LookupMappedName(weaponSubTypeMap, WEAPON_NAME_FALLBACK, itemSubType)
		elseif type(itemType) == "string" then
			local lowerType = strlower(itemType)
			if lowerType == "armor" then
				category = "armor"
				armorType = "unknown"
			elseif lowerType == "weapon" then
				category = "weapon"
				weaponType = "unknown"
			else
				category = "other"
			end
		end
	end

	if type(itemSubType) == "string" then
		local lower = strlower(itemSubType)
		if lower:find("idol", 1, true) or lower:find("libram", 1, true)
			or lower:find("totem", 1, true) or lower:find("sigil", 1, true)
			or lower:find("relic", 1, true)
		then
			category = "relic"
			isRelic = true
		end
	end

	return category, armorType, weaponType, isRelic
end

local function MapGetItemStatsKey(rawKey)
	if type(rawKey) ~= "string" then
		return nil, nil
	end
	if SOCKET_MAP[rawKey] then
		return "socket", SOCKET_MAP[rawKey]
	end
	if STAT_MAP[rawKey] then
		return "stat", STAT_MAP[rawKey]
	end
	if type(_G) ~= "table" then
		return nil, nil
	end
	for token, color in pairs(SOCKET_MAP) do
		if _G[token] == rawKey then
			return "socket", color
		end
	end
	for token, statId in pairs(STAT_MAP) do
		if _G[token] == rawKey then
			return "stat", statId
		end
	end
	return nil, nil
end

local scanTip

local function EnsureScanTip()
	if scanTip then
		return scanTip
	end
	scanTip = CreateFrame("GameTooltip", "RaidwiseGearCheckScanTip", nil, "GameTooltipTemplate")
	scanTip:Hide()
	return scanTip
end

local function CountEmptySocketsFromTooltip(itemLink)
	local empty = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 0 }
	if type(itemLink) ~= "string" or itemLink == "" then
		return empty
	end
	local tip = EnsureScanTip()
	if not tip then
		return empty
	end
	local ok = pcall(function()
		tip:SetOwner(UIParent, "ANCHOR_NONE")
		tip:ClearLines()
		tip:SetHyperlink(itemLink)
	end)
	if not ok then
		return empty
	end
	local labels = {
		["red socket"] = "red",
		["yellow socket"] = "yellow",
		["blue socket"] = "blue",
		["meta socket"] = "meta",
		["prismatic socket"] = "prismatic",
	}
	if type(_G) == "table" then
		for token, color in pairs(SOCKET_MAP) do
			local text = _G[token]
			if type(text) == "string" and text ~= "" then
				labels[strlower(text)] = color
			end
		end
	end
	local lineCount = tip:NumLines() or 0
	for index = 1, lineCount do
		local fontString = _G["RaidwiseGearCheckScanTipTextLeft" .. index]
		local text = fontString and fontString:GetText()
		if type(text) == "string" and text ~= "" then
			local color = labels[strlower(text)]
			if color then
				empty[color] = (empty[color] or 0) + 1
				empty.total = empty.total + 1
			end
		end
	end
	tip:Hide()
	return empty
end

local function CollectStatsAndSockets(itemLinkOrId)
	local stats = {}
	local sockets = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 0 }
	local gaps = {}
	if type(GetItemStats) ~= "function" or not itemLinkOrId then
		AddGap(gaps, "STATS_UNAVAILABLE")
		return stats, sockets, gaps
	end
	local ok, raw = pcall(GetItemStats, itemLinkOrId)
	if not ok or type(raw) ~= "table" then
		AddGap(gaps, "STATS_UNAVAILABLE")
		return stats, sockets, gaps
	end
	for rawKey, value in pairs(raw) do
		local amount = tonumber(value)
		if amount and amount ~= 0 then
			local kind, mapped = MapGetItemStatsKey(rawKey)
			if kind == "socket" then
				sockets[mapped] = (sockets[mapped] or 0) + amount
				sockets.total = sockets.total + amount
			elseif kind == "stat" then
				stats[mapped] = (stats[mapped] or 0) + amount
			end
		end
	end
	return stats, sockets, gaps
end

local function SplitColonFields(payload)
	local fields = {}
	local start = 1
	while true do
		local colon = payload:find(":", start, true)
		if not colon then
			fields[#fields + 1] = payload:sub(start)
			break
		end
		fields[#fields + 1] = payload:sub(start, colon - 1)
		start = colon + 1
	end
	return fields
end

local function ParseItemLinkParts(itemLink)
	if type(itemLink) ~= "string" or itemLink == "" then
		return nil
	end
	local payload = itemLink:match("[Hh]?item:([^|]+)")
	if not payload then
		return nil
	end
	local fields = SplitColonFields(payload)
	local itemId = tonumber(fields[1])
	if not itemId or itemId <= 0 then
		return nil
	end
	return {
		itemId = itemId,
		enchantId = tonumber(fields[2]) or 0,
		gemIdsFromLink = {
			tonumber(fields[3]) or 0,
			tonumber(fields[4]) or 0,
			tonumber(fields[5]) or 0,
			tonumber(fields[6]) or 0,
		},
	}
end

local function CollectGemItemIds(itemLink, parsed)
	local gems = {}
	if type(GetItemGem) == "function" and itemLink then
		for index = 1, 4 do
			local _, gemLink = GetItemGem(itemLink, index)
			if gemLink then
				local gemId = tonumber(gemLink:match("item:(%d+)"))
				if gemId and gemId > 0 then
					gems[#gems + 1] = {
						socketIndex = index,
						itemId = gemId,
						link = gemLink,
					}
				end
			end
		end
	end
	if #gems == 0 and parsed and parsed.gemIdsFromLink then
		for index = 1, 4 do
			local gemId = parsed.gemIdsFromLink[index]
			if gemId and gemId > 0 then
				gems[#gems + 1] = {
					socketIndex = index,
					itemId = gemId,
					link = nil,
				}
			end
		end
	end
	return gems
end

local function NormalizeEnchant(enchantId)
	enchantId = tonumber(enchantId) or 0
	local enchant = {
		enchantId = enchantId,
		present = enchantId > 0,
		known = enchantId == 0,
		gaps = {},
	}
	if enchant.present then
		local info = Addon.GetGearCheckEnchantInfo and Addon:GetGearCheckEnchantInfo(enchantId)
		if info then
			enchant.known = true
		else
			AddGap(enchant.gaps, "ENCHANT_UNMAPPED")
		end
	end
	return enchant
end

local function NormalizeGem(rawGem)
	EnsureAuctionMaps()
	local gaps = {}
	local gem = {
		socketIndex = rawGem.socketIndex,
		itemId = rawGem.itemId,
		present = true,
		known = false,
		isMeta = false,
		color = "unknown",
		name = nil,
		stats = {},
		gaps = gaps,
	}
	local name, itemType, itemSubType
	local ok = pcall(function()
		name, _, _, _, _, itemType, itemSubType = GetItemInfo(rawGem.link or rawGem.itemId)
	end)
	local catalog = Addon.GetGearCheckGemInfo and Addon:GetGearCheckGemInfo(rawGem.itemId)
	if catalog then
		gem.known = true
		if catalog.color then
			gem.color = catalog.color
			gem.isMeta = catalog.color == "meta"
		end
		if type(catalog.stats) == "table" then
			gem.stats = catalog.stats
		end
	end
	if ok and type(name) == "string" and name ~= "" then
		gem.name = name
		gem.known = true
		local color = LookupMappedName(gemSubTypeMap, GEM_NAME_FALLBACK, itemSubType)
		if color then
			gem.color = color
			gem.isMeta = color == "meta"
		elseif type(itemSubType) == "string" and strlower(itemSubType):find("meta", 1, true) then
			gem.color = "meta"
			gem.isMeta = true
		end
		if rawGem.link then
			local stats = CollectStatsAndSockets(rawGem.link)
			if type(stats) == "table" and next(stats) then
				gem.stats = stats
			end
		end
	elseif not catalog then
		AddGap(gaps, "GEM_INFO_UNKNOWN", tostring(rawGem.itemId))
	end
	return gem
end

local function ItemInfoBundle(itemId, itemLink)
	local name, link, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture
	local ok = pcall(function()
		name, link, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture = GetItemInfo(itemLink or itemId)
	end)
	if not ok or not name then
		ok = pcall(function()
			name, link, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture = GetItemInfo(itemId)
		end)
	end
	if type(itemLink) == "string" and (not name or name == "") then
		name = itemLink:match("%[(.-)%]")
	end
	return {
		name = name,
		link = link or itemLink,
		quality = tonumber(quality),
		itemLevel = tonumber(itemLevel),
		itemType = itemType,
		itemSubType = itemSubType,
		equipLoc = equipLoc,
		texture = texture,
		infoKnown = name ~= nil and name ~= "",
	}
end

local function NormalizeItem(parsed, itemLink, info)
	local gaps = {}
	local stats, sockets, statGaps = CollectStatsAndSockets(itemLink or parsed.itemId)
	for index = 1, #statGaps do
		gaps[#gaps + 1] = statGaps[index]
	end

	local category, armorType, weaponType, isRelic = ClassifyItem(info.itemType, info.itemSubType, info.equipLoc)
	if not info.infoKnown then
		AddGap(gaps, "ITEM_INFO_UNKNOWN", tostring(parsed.itemId))
		category = "unknown"
	elseif category == "armor" and armorType == "unknown" then
		AddGap(gaps, "ARMOR_TYPE_UNKNOWN")
	elseif category == "weapon" and weaponType == "unknown" then
		AddGap(gaps, "WEAPON_TYPE_UNKNOWN")
	end

	local rawGems = CollectGemItemIds(itemLink, parsed)
	local gems = {}
	local metaGemId = nil
	for index = 1, #rawGems do
		local gem = NormalizeGem(rawGems[index])
		gems[#gems + 1] = gem
		if gem.isMeta then
			metaGemId = gem.itemId
		end
	end

	-- Resolve socket totals carefully:
	-- On many 3.3.5a clients GetItemStats EMPTY_SOCKET_* is the item's socket
	-- *layout* (still reported when gems are present), not remaining empties.
	-- Tooltip "Red Socket" / etc. lines are the reliable remaining-empty signal.
	local fromStats = sockets.total
	local fromTip = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 0 }
	if itemLink then
		fromTip = CountEmptySocketsFromTooltip(itemLink)
	end

	local remainingEmpty = fromTip.total
	if remainingEmpty == 0 and #gems == 0 and fromStats > 0 then
		-- No gems and tip found nothing — treat stats as empty sockets.
		remainingEmpty = fromStats
	end

	local socketTotal = #gems + remainingEmpty
	if fromStats > socketTotal then
		-- Stats look like a full layout larger than gems+tip empties.
		socketTotal = fromStats
		remainingEmpty = math.max(remainingEmpty, fromStats - #gems)
	end

	if fromTip.total > 0 and fromStats == 0 then
		sockets.meta = fromTip.meta
		sockets.red = fromTip.red
		sockets.yellow = fromTip.yellow
		sockets.blue = fromTip.blue
		sockets.prismatic = fromTip.prismatic
	end
	sockets.total = socketTotal
	sockets.empty = remainingEmpty

	return {
		itemId = parsed.itemId,
		link = itemLink,
		name = info.name,
		quality = info.quality,
		itemLevel = info.itemLevel,
		equipLoc = info.equipLoc,
		itemType = info.itemType,
		itemSubType = info.itemSubType,
		texture = info.texture,
		category = category,
		armorType = armorType,
		weaponType = weaponType,
		isRelic = isRelic and true or false,
		stats = stats,
		sockets = sockets,
		enchant = NormalizeEnchant(parsed.enchantId),
		gems = gems,
		metaGemId = metaGemId,
		infoKnown = info.infoKnown,
		pendingLink = false,
		gaps = gaps,
	}
end

local function CollectSlot(unit, def)
	local slotId = GetInventorySlotInfo(def.slotName)
	local gaps = {}
	local entry = {
		key = def.key,
		slotName = def.slotName,
		slotId = slotId,
		policy = def.policy,
		policyNote = nil,
		empty = true,
		item = nil,
		gaps = gaps,
	}

	if def.policy == "PLANNED" then
		entry.policyNote = "planned"
	elseif def.policy == "IGNORED" then
		entry.policyNote = "ignored"
	end

	if not slotId or not unit then
		AddGap(gaps, "SLOT_UNAVAILABLE")
		return entry
	end

	local itemLink = GetInventoryItemLink(unit, slotId)
	if not itemLink then
		local itemId = GetInventoryItemID and GetInventoryItemID(unit, slotId)
		if itemId and itemId > 0 then
			entry.empty = false
			AddGap(gaps, "ITEM_LINK_PENDING")
			entry.item = {
				itemId = itemId,
				link = nil,
				name = nil,
				quality = nil,
				itemLevel = nil,
				equipLoc = nil,
				itemType = nil,
				itemSubType = nil,
				texture = nil,
				category = "unknown",
				armorType = nil,
				weaponType = nil,
				isRelic = false,
				stats = {},
				sockets = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 0 },
				enchant = NormalizeEnchant(0),
				gems = {},
				metaGemId = nil,
				infoKnown = false,
				pendingLink = true,
				gaps = { { code = "ITEM_LINK_PENDING" } },
			}
		end
		return entry
	end

	local parsed = ParseItemLinkParts(itemLink)
	if not parsed then
		AddGap(gaps, "ITEM_LINK_INVALID")
		return entry
	end

	local info = ItemInfoBundle(parsed.itemId, itemLink)
	local item = NormalizeItem(parsed, itemLink, info)

	if entry.policy == "CHECKED" and item.isRelic then
		entry.policy = "IGNORED"
		entry.policyNote = "relic"
	end

	entry.empty = false
	entry.item = item
	return entry
end

local function CollectClassSpec(unit)
	local className, classFile = UnitClass(unit)
	local specName, specIcon, specTab = "", "", 0
	local specKnown = false
	local gaps = {}

	if UnitIsUnit(unit, "player") and Addon.CollectPrimarySpec then
		specName, specIcon, specTab = Addon:CollectPrimarySpec()
	else
		local isInspect = true
		local talentGroup = 1
		if type(GetActiveTalentGroup) == "function" then
			talentGroup = GetActiveTalentGroup(isInspect) or 1
		end
		local tabCount = 3
		if type(GetNumTalentTabs) == "function" then
			tabCount = GetNumTalentTabs(isInspect) or 3
		end
		local bestPoints = -1
		for tab = 1, tabCount do
			local name, icon, pointsSpent = GetTalentTabInfo(tab, isInspect, nil, talentGroup)
			pointsSpent = tonumber(pointsSpent) or 0
			if pointsSpent > bestPoints then
				bestPoints = pointsSpent
				specName = name or ""
				specIcon = icon or ""
				specTab = tab
			end
		end
	end

	if (specName and specName ~= "") or (specTab and specTab > 0) then
		specKnown = true
	else
		AddGap(gaps, "SPEC_UNKNOWN")
	end

	return {
		className = className,
		classFile = classFile,
		specName = specName or "",
		specIcon = specIcon or "",
		specTab = tonumber(specTab) or 0,
		specKnown = specKnown,
		gaps = gaps,
	}
end

local function CountFilledCheckedSlots(slots)
	local filled = 0
	local checked = 0
	for index = 1, #slots do
		local slot = slots[index]
		if slot.policy == "CHECKED" then
			checked = checked + 1
			if not slot.empty and slot.item and slot.item.itemId then
				filled = filled + 1
			end
		end
	end
	return filled, checked
end

local function FormatStatsBrief(stats)
	if type(stats) ~= "table" then
		return "-"
	end
	local keys = {}
	for key in pairs(stats) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	if #keys == 0 then
		return "-"
	end
	local parts = {}
	for index = 1, #keys do
		local key = keys[index]
		parts[#parts + 1] = key .. "=" .. tostring(stats[key])
	end
	return table.concat(parts, ", ")
end

local function FormatGapsBrief(gaps)
	if type(gaps) ~= "table" or #gaps == 0 then
		return nil
	end
	local parts = {}
	for index = 1, #gaps do
		local gap = gaps[index]
		if gap.detail then
			parts[#parts + 1] = tostring(gap.code) .. "(" .. tostring(gap.detail) .. ")"
		else
			parts[#parts + 1] = tostring(gap.code)
		end
	end
	return table.concat(parts, ", ")
end

function Addon:ResolveGearCheckUnit()
	if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
		return "target"
	end
	return "player"
end

function Addon:GetLastGearCheckReport()
	return lastReport
end

local function AttachFindings(report)
	if report and Addon.EvaluateGearCheck then
		Addon:EvaluateGearCheck(report)
	end
	return report
end

function Addon:CollectGearCheck(unit)
	unit = unit or self:ResolveGearCheckUnit()
	if not unit or not UnitExists(unit) then
		return nil
	end

	local name, realm = UnitName(unit)
	local identity = CollectClassSpec(unit)
	local equipment = {}
	for index = 1, #SLOT_DEFS do
		equipment[#equipment + 1] = CollectSlot(unit, SLOT_DEFS[index])
	end

	local filled, checked = CountFilledCheckedSlots(equipment)
	local characterGaps = {}
	for index = 1, #identity.gaps do
		characterGaps[#characterGaps + 1] = identity.gaps[index]
	end

	local isSelf = UnitIsUnit(unit, "player") and true or false
	local inspect = {
		needed = not isSelf,
		canInspect = false,
		notified = false,
		complete = isSelf and true or false,
	}
	if inspect.needed then
		if type(CanInspect) == "function" then
			inspect.canInspect = CanInspect(unit) and true or false
		end
		if inspect.canInspect and type(CheckInteractDistance) == "function" then
			if not CheckInteractDistance(unit, 4) then
				inspect.canInspect = false
				inspect.tooFar = true
			end
		end
	end

	local report = {
		schemaVersion = Addon.GEAR_CHECK_SCHEMA_VERSION,
		character = {
			unit = unit,
			isSelf = isSelf,
			name = name,
			realm = realm,
			guid = UnitGUID(unit),
			className = identity.className,
			classFile = identity.classFile,
			specName = identity.specName,
			specIcon = identity.specIcon,
			specTab = identity.specTab,
			specKnown = identity.specKnown,
			gaps = characterGaps,
		},
		equipment = equipment,
		gaps = {},
		collection = {
			collectedAt = time(),
			scanStatus = nil,
			inspect = inspect,
			counts = {
				checkedSlots = checked,
				filledCheckedSlots = filled,
			},
		},
		phase = 5,
		name = name,
		isSelf = isSelf,
		specKnown = identity.specKnown,
		inspect = inspect,
		stats = {
			checkedSlots = checked,
			filledCheckedSlots = filled,
		},
		slots = equipment,
	}

	lastReport = report
	return AttachFindings(report)
end

function Addon:FormatGearCheckDump(report)
	if not report then
		return "No Gear Check data."
	end

	local character = report.character or {}
	local collection = report.collection or {}
	local inspect = collection.inspect or report.inspect or {}
	local counts = collection.counts or report.stats or {}
	local equipment = report.equipment or report.slots or {}
	local findings = report.findings or {}
	local profile = report.profile
	local verdicts = report.verdicts
	local overall = report.overall
	local meta = report.meta
	local sets = report.sets

	local lines = {}
	lines[#lines + 1] = "Raidwise Gear Check — Phase 5 snapshot (overall + meta + sets)"
	lines[#lines + 1] = "schemaVersion=" .. tostring(report.schemaVersion or "?")
	lines[#lines + 1] = "Overall is worst-wins of item verdicts (GOOD < OK < REPLACE < BAD); Resilience 1→REPLACE, 2+→BAD. Set counts are informational."
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format(
		"Unit: %s (%s)%s",
		tostring(character.unit or "?"),
		tostring(character.name or report.name or "?"),
		(character.isSelf or report.isSelf) and " [self]" or ""
	)
	if character.realm and character.realm ~= "" then
		lines[#lines + 1] = "Realm: " .. tostring(character.realm)
	end
	lines[#lines + 1] = string.format(
		"Class: %s (%s)",
		tostring(character.className or "?"),
		tostring(character.classFile or "?")
	)
	if character.specKnown then
		lines[#lines + 1] = string.format(
			"Spec: %s (tab %d)",
			tostring(character.specName ~= "" and character.specName or "?"),
			tonumber(character.specTab) or 0
		)
	else
		lines[#lines + 1] = "Spec: unknown (class-only rules will apply; gap SPEC_UNKNOWN)"
	end
	if profile then
		lines[#lines + 1] = string.format(
			"Profile: %s (source=%s)",
			tostring(profile.name or "?"),
			tostring(profile.source or "?")
		)
	end
	local charGaps = FormatGapsBrief(character.gaps)
	if charGaps then
		lines[#lines + 1] = "Character gaps: " .. charGaps
	end
	lines[#lines + 1] = string.format(
		"Checked slots filled: %d / %d",
		counts.filledCheckedSlots or 0,
		counts.checkedSlots or 0
	)
	if inspect.tooFar then
		lines[#lines + 1] = "Inspect: too far"
	elseif inspect.needed and not inspect.canInspect then
		lines[#lines + 1] = "Inspect: not available"
	elseif inspect.needed and not inspect.complete then
		lines[#lines + 1] = "Inspect: pending / incomplete"
	elseif inspect.needed then
		lines[#lines + 1] = "Inspect: ok"
	end
	if verdicts then
		lines[#lines + 1] = string.format(
			"Item verdicts: GOOD=%d  OK=%d  REPLACE=%d  BAD=%d  (skipped=%d)",
			verdicts.good or 0,
			verdicts.ok or 0,
			verdicts.replace or 0,
			verdicts.bad or 0,
			verdicts.skipped or 0
		)
	end
	if overall then
		lines[#lines + 1] = string.format(
			"Overall: %s — %s",
			tostring(overall.status or "?"),
			tostring(overall.summary or "")
		)
		local issues = overall.issues or {}
		lines[#lines + 1] = string.format(
			"Issues: items=%d  enchants=%d  gems=%d  meta=%s  resilienceItems=%d",
			issues.items or 0,
			issues.enchants or 0,
			issues.gems or 0,
			(issues.meta or 0) == 0 and "OK" or tostring(issues.meta),
			overall.resilienceItems or 0
		)
	end
	if meta and meta.present then
		local activeText = "unknown"
		if meta.active == true then
			activeText = "yes"
		elseif meta.active == false then
			activeText = "no"
		end
		lines[#lines + 1] = string.format(
			"Meta: id=%s slot=%s active=%s",
			tostring(meta.itemId or "?"),
			tostring(meta.slot or "?"),
			activeText
		)
	end
	if sets and #sets > 0 then
		local setParts = {}
		for index = 1, #sets do
			local row = sets[index]
			setParts[#setParts + 1] = string.format("%s: %d/%d", row.key, row.equipped or 0, row.pieces or 5)
		end
		lines[#lines + 1] = "Sets (informational): " .. table.concat(setParts, ", ")
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Equipment:"

	for index = 1, #equipment do
		local slot = equipment[index]
		local policy = slot.policy or "?"
		local note = slot.policyNote and (" / " .. slot.policyNote) or ""
		if slot.empty or not slot.item then
			lines[#lines + 1] = string.format(
				"  [%s%s] %s — empty",
				policy,
				note,
				slot.slotName
			)
		else
			local item = slot.item
			local name = item.name or (item.pendingLink and "(link pending)" or "unknown")
			local ilvl = item.itemLevel and tostring(item.itemLevel) or "-"
			local verdict = slot.verdict and ("  verdict=" .. slot.verdict) or ""
			lines[#lines + 1] = string.format(
				"  [%s%s] %s — id=%s  ilvl=%s  %s%s",
				policy,
				note,
				slot.slotName,
				tostring(item.itemId),
				ilvl,
				name,
				verdict
			)
			lines[#lines + 1] = string.format(
				"      category=%s  armorType=%s  weaponType=%s  relic=%s  equipLoc=%s",
				tostring(item.category or "-"),
				tostring(item.armorType or "-"),
				tostring(item.weaponType or "-"),
				item.isRelic and "yes" or "no",
				tostring(item.equipLoc or "-")
			)
			lines[#lines + 1] = "      stats: " .. FormatStatsBrief(item.stats)
			local sockets = item.sockets or {}
			lines[#lines + 1] = string.format(
				"      sockets: total=%s empty=%s meta=%s red=%s yellow=%s blue=%s prismatic=%s",
				tostring(sockets.total or 0),
				tostring(sockets.empty or 0),
				tostring(sockets.meta or 0),
				tostring(sockets.red or 0),
				tostring(sockets.yellow or 0),
				tostring(sockets.blue or 0),
				tostring(sockets.prismatic or 0)
			)
			local enchant = item.enchant or {}
			lines[#lines + 1] = string.format(
				"      enchant: id=%s present=%s known=%s",
				tostring(enchant.enchantId or 0),
				enchant.present and "yes" or "no",
				enchant.known and "yes" or "no"
			)
			if item.gems and #item.gems > 0 then
				local gemParts = {}
				for g = 1, #item.gems do
					local gem = item.gems[g]
					gemParts[#gemParts + 1] = string.format(
						"#%d=%s %s%s",
						gem.socketIndex or g,
						tostring(gem.itemId),
						tostring(gem.color or "unknown"),
						gem.isMeta and " meta" or ""
					)
				end
				lines[#lines + 1] = "      gems: " .. table.concat(gemParts, ", ")
			else
				lines[#lines + 1] = "      gems: (none detected)"
			end
			if item.metaGemId then
				lines[#lines + 1] = "      metaGemId=" .. tostring(item.metaGemId)
			end
			local itemGaps = FormatGapsBrief(item.gaps)
			if itemGaps then
				lines[#lines + 1] = "      gaps: " .. itemGaps
			end
			local slotGaps = FormatGapsBrief(slot.gaps)
			if slotGaps then
				lines[#lines + 1] = "      slotGaps: " .. slotGaps
			end
			local enchantGaps = FormatGapsBrief(enchant.gaps)
			if enchantGaps then
				lines[#lines + 1] = "      enchantGaps: " .. enchantGaps
			end
		end
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("Findings (%d):", #findings)
	if #findings == 0 then
		lines[#lines + 1] = "  (none)"
	else
		for index = 1, #findings do
			local finding = findings[index]
			lines[#lines + 1] = string.format(
				"  [%s/%s] %s%s — %s",
				tostring(finding.severity or "?"),
				tostring(finding.category or "?"),
				tostring(finding.code or "?"),
				finding.slot and (" @" .. finding.slot) or "",
				tostring(finding.message or "")
			)
		end
	end

	return table.concat(lines, "\n")
end

function Addon:FormatGearCheckPhase1Dump(report)
	return self:FormatGearCheckDump(report)
end

local function FinishScan(report, status)
	if report then
		report.scanStatus = status
		if report.collection then
			report.collection.scanStatus = status
		end
	end
	lastReport = report
	local callback = pendingCallback
	pendingCallback = nil
	pendingUnit = nil
	retryFrame:Hide()
	retryElapsed = 0
	retryBudget = 0
	if callback then
		callback(report, status)
	end
end

local function TryCollectPending(forceComplete)
	if not pendingUnit then
		return
	end
	local report = Addon:CollectGearCheck(pendingUnit)
	if not report then
		FinishScan(nil, "missing")
		return
	end
	if report.character and report.character.isSelf then
		FinishScan(report, "ok")
		return
	end
	local filled = (report.collection and report.collection.counts and report.collection.counts.filledCheckedSlots) or 0
	local specKnown = report.character and report.character.specKnown
	if filled > 0 and (specKnown or forceComplete) then
		if report.inspect then
			report.inspect.complete = true
		end
		FinishScan(report, "ok")
		return
	end
	if forceComplete then
		if report.inspect then
			report.inspect.complete = filled > 0
		end
		FinishScan(report, filled > 0 and "ok" or "empty")
	end
end

retryFrame:SetScript("OnUpdate", function(_, elapsed)
	if not pendingUnit then
		retryFrame:Hide()
		return
	end
	retryElapsed = retryElapsed + elapsed
	retryBudget = retryBudget - elapsed
	if retryElapsed >= 0.25 then
		retryElapsed = 0
		TryCollectPending(false)
		if not pendingUnit then
			return
		end
	end
	if retryBudget <= 0 then
		TryCollectPending(true)
		if pendingUnit then
			local report = Addon:CollectGearCheck(pendingUnit)
			if report and report.inspect then
				report.inspect.complete = false
				report.inspect.timedOut = true
			end
			FinishScan(report, "timeout")
		end
	end
end)

eventFrame:SetScript("OnEvent", function(_, event)
	if event ~= "INSPECT_TALENT_READY" then
		return
	end
	if pendingUnit then
		TryCollectPending(true)
	end
end)

function Addon:StartGearCheckScan(callback)
	pendingCallback = callback
	scanToken = scanToken + 1
	local unit = self:ResolveGearCheckUnit()
	local report = self:CollectGearCheck(unit)
	if not report then
		FinishScan(nil, "missing")
		return
	end

	if report.character and report.character.isSelf then
		FinishScan(report, "ok")
		return
	end

	local inspect = report.inspect or {}
	if not inspect.canInspect then
		FinishScan(report, inspect.tooFar and "too_far" or "cannot_inspect")
		return
	end

	pendingUnit = unit
	retryElapsed = 0
	retryBudget = 2.5
	if type(NotifyInspect) == "function" then
		local ok = pcall(NotifyInspect, unit)
		inspect.notified = ok and true or false
	end
	TryCollectPending(false)
	if pendingUnit then
		retryFrame:Show()
	end
end

-- Phase 7: self-chat reports only (DEFAULT_CHAT_FRAME). Finding text stays English.
local CHAT_ITEM_CATEGORIES = {
	item = true,
	armor = true,
	weapon = true,
	stat = true,
}
local CHAT_MAX_DETAIL = 15

local function ChatPlayerName(report)
	local character = report.character or {}
	return character.name or report.name or "?"
end

local function ChatSlotShort(report, slotKey)
	if not slotKey then
		return "Gear"
	end
	local equipment = report.equipment or report.slots or {}
	for index = 1, #equipment do
		local slot = equipment[index]
		if slot.key == slotKey then
			return slot.slotName or slotKey
		end
	end
	return tostring(slotKey)
end

local function ChatFindingMatches(finding, mode)
	local category = finding.category
	if mode == "items" then
		return CHAT_ITEM_CATEGORIES[category] == true
	end
	if mode == "enchants" then
		return category == "enchant"
	end
	if mode == "gems" then
		return category == "gem" or category == "meta"
	end
	return false
end

local function ChatDetailLines(report, mode)
	local findings = report.findings or {}
	local lines = {}
	local bySlot = {}
	local order = {}

	for index = 1, #findings do
		local finding = findings[index]
		if ChatFindingMatches(finding, mode) and (finding.severity == "hard" or finding.severity == "soft") then
			local key = finding.slot or "_gear"
			local bucket = bySlot[key]
			if not bucket then
				bucket = {}
				bySlot[key] = bucket
				order[#order + 1] = key
			end
			bucket[#bucket + 1] = finding.message or finding.code or "?"
		end
	end

	for index = 1, #order do
		local key = order[index]
		local messages = bySlot[key]
		local slotName = ChatSlotShort(report, key ~= "_gear" and key or nil)
		lines[#lines + 1] = string.format("%s: %s", slotName, table.concat(messages, "; "))
	end
	return lines
end

function Addon:FormatGearCheckChatReport(report, mode)
	mode = mode or "summary"
	if mode == "report" then
		mode = "summary"
	end
	local lines = {}
	if not report then
		return lines
	end

	local name = ChatPlayerName(report)
	local overall = report.overall or {}
	local status = overall.status or "OK"
	local issues = overall.issues or {}
	local verdicts = report.verdicts or {}

	if mode == "summary" then
		lines[#lines + 1] = string.format("%s — %s", name, status)
		local parts = {}
		local bad = verdicts.bad or 0
		local replace = verdicts.replace or 0
		local enchantN = issues.enchants or 0
		local gemN = issues.gems or 0
		local metaN = issues.meta or 0
		if bad > 0 then
			parts[#parts + 1] = string.format("%d bad item%s", bad, bad == 1 and "" or "s")
		end
		if replace > 0 then
			parts[#parts + 1] = string.format("%d REPLACE", replace)
		end
		local good = verdicts.good or 0
		local ok = verdicts.ok or 0
		if good > 0 then
			parts[#parts + 1] = string.format("%d GOOD", good)
		end
		if ok > 0 then
			parts[#parts + 1] = string.format("%d OK", ok)
		end
		if enchantN > 0 then
			parts[#parts + 1] = string.format("%d enchant issue%s", enchantN, enchantN == 1 and "" or "s")
		end
		if gemN > 0 then
			parts[#parts + 1] = string.format("%d gem issue%s", gemN, gemN == 1 and "" or "s")
		end
		if metaN > 0 then
			parts[#parts + 1] = string.format("%d meta issue%s", metaN, metaN == 1 and "" or "s")
		elseif report.meta and report.meta.present and report.meta.active == true then
			parts[#parts + 1] = "meta OK"
		end
		if #parts == 0 then
			parts[1] = "no significant issues"
		end
		lines[#lines + 1] = table.concat(parts, ", ") .. "."
		if overall.resilienceItems and overall.resilienceItems > 0 then
			lines[#lines + 1] = string.format("Resilience items: %d.", overall.resilienceItems)
		end
		return lines
	end

	local title = mode
	if mode == "items" then
		title = "Items"
	elseif mode == "enchants" then
		title = "Enchants"
	elseif mode == "gems" then
		title = "Gems"
	end
	lines[#lines + 1] = string.format("%s — %s:", name, title)

	local details = ChatDetailLines(report, mode)
	if #details == 0 then
		lines[#lines + 1] = "No issues in this category."
		return lines
	end
	local limit = math.min(#details, CHAT_MAX_DETAIL)
	for index = 1, limit do
		lines[#lines + 1] = details[index]
	end
	if #details > CHAT_MAX_DETAIL then
		lines[#lines + 1] = string.format("… and %d more.", #details - CHAT_MAX_DETAIL)
	end
	return lines
end

function Addon:PrintGearCheckReport(mode, report)
	report = report or self:GetLastGearCheckReport()
	if not report then
		self:Print(self:T("CHAT_GEARCHECK_NO_REPORT"))
		return false
	end
	local lines = self:FormatGearCheckChatReport(report, mode)
	for index = 1, #lines do
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[GearCheck]|r " .. lines[index])
	end
	return true
end

-- Print a report mode; scan first when no cached report exists.
function Addon:RunGearCheckChatReport(mode, openUi)
	mode = mode or "summary"
	if openUi ~= false and self.OpenGearCheckTarget then
		self:ShowMainFrame()
		self:SelectTab("geartarget")
	end
	local report = self:GetLastGearCheckReport()
	if report then
		self:PrintGearCheckReport(mode, report)
		if openUi ~= false and self.RefreshGearCheckTargetView then
			self:RefreshGearCheckTargetView(false)
		end
		return
	end
	if not self.StartGearCheckScan then
		self:Print(self:T("GEAR_CHECK_STATUS_FAIL"))
		return
	end
	self:Print(self:T("CHAT_GEARCHECK_SCANNING"))
	self:StartGearCheckScan(function(scanned)
		if openUi ~= false and self.RefreshGearCheckTargetView then
			self:RefreshGearCheckTargetView(false)
		end
		if scanned then
			self:PrintGearCheckReport(mode, scanned)
		else
			self:Print(self:T("CHAT_GEARCHECK_NO_REPORT"))
		end
	end)
end
