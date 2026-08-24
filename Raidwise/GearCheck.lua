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
			local socketColor = SOCKET_MAP[rawKey]
			if socketColor then
				sockets[socketColor] = (sockets[socketColor] or 0) + amount
				sockets.total = sockets.total + amount
			else
				local mapped = STAT_MAP[rawKey]
				if mapped then
					stats[mapped] = (stats[mapped] or 0) + amount
				end
			end
		end
	end
	return stats, sockets, gaps
end

local function ParseItemLinkParts(itemLink)
	if type(itemLink) ~= "string" or itemLink == "" then
		return nil
	end
	local itemId, enchantId, gem1, gem2, gem3, gem4 = itemLink:match(
		"item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)"
	)
	itemId = tonumber(itemId)
	if not itemId or itemId <= 0 then
		return nil
	end
	return {
		itemId = itemId,
		enchantId = tonumber(enchantId) or 0,
		gemIdsFromLink = {
			tonumber(gem1) or 0,
			tonumber(gem2) or 0,
			tonumber(gem3) or 0,
			tonumber(gem4) or 0,
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
		phase = 3,
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

	local lines = {}
	lines[#lines + 1] = "Raidwise Gear Check — Phase 3 snapshot (findings; no OK/REPLACE/BAD yet)"
	lines[#lines + 1] = "schemaVersion=" .. tostring(report.schemaVersion or "?")
	lines[#lines + 1] = "Rules produce findings only. Item level is informational and must not affect verdicts."
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
			lines[#lines + 1] = string.format(
				"  [%s%s] %s — id=%s  ilvl=%s  %s",
				policy,
				note,
				slot.slotName,
				tostring(item.itemId),
				ilvl,
				name
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
				"      sockets: total=%s meta=%s red=%s yellow=%s blue=%s prismatic=%s",
				tostring(sockets.total or 0),
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
