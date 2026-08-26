-- Gear Check rules: findings, item verdicts (OK / GOOD / REPLACE / BAD), overall status.

local Addon = Raidwise

local ENCHANTABLE = {
	head = true,
	shoulder = true,
	back = true,
	chest = true,
	wrist = true,
	hands = true,
	legs = true,
	feet = true,
	mainHand = true,
	offHand = true,
	ranged = true,
}

-- Profession / optional enchants: evaluate when present, never flag MISSING_ENCHANT.
local ENCHANT_OPTIONAL = {
	waist = true,
	finger1 = true,
	finger2 = true,
}

local MESSAGES = {
	SPEC_UNKNOWN = "Specialization is unknown; class-only rules are applied.",
	PROFILE_MISSING = "No Gear Check profile is available for this class.",
	ITEM_NOT_CHECKABLE = "Cannot evaluate this item (incomplete or unknown data).",
	ARMOR_FORBIDDEN = "Forbidden armor type for this specialization.",
	ARMOR_UNWANTED = "Unwanted armor type for this specialization.",
	ARMOR_NOT_PREFERRED = "Armor type is usable but not preferred for this specialization.",
	WEAPON_FORBIDDEN = "Forbidden weapon type for this specialization.",
	WEAPON_UNWANTED = "Unwanted weapon type for this specialization.",
	WEAPON_SETUP = "Weapon setup does not match this specialization.",
	TRINKET_NOT_PREFERRED = "Trinket is not typically used for this specialization.",
	STAT_FORBIDDEN = "Forbidden stat for this specialization.",
	STAT_UNWANTED = "Unwanted stat for this specialization.",
	RESILIENCE_PVE = "Resilience is a PvP stat and is inappropriate for PvE Gear Check.",
	MISSING_ENCHANT = "Missing enchant.",
	ENCHANT_NOT_CHECKABLE = "Enchant id is unknown to the catalog (not-checkable).",
	ENCHANT_LOWER_LEVEL = "Enchant is below the maximum Northrend level.",
	ENCHANT_BAD_STAT = "Enchant provides an inappropriate stat for this specialization.",
	MISSING_GEM = "Socket is missing a gem.",
	GEM_NOT_CHECKABLE = "Gem id is unknown to the catalog (not-checkable).",
	GEM_LOWER_LEVEL = "Gem is below the maximum Northrend epic level.",
	GEM_BAD_STAT = "Gem provides an inappropriate stat for this specialization.",
	META_MISSING = "Meta socket is missing a meta gem.",
	META_NOT_META = "Meta socket does not contain a meta gem.",
	META_NOT_PREFERRED = "Meta gem is not preferred for this specialization.",
	META_INACTIVE = "Meta gem requirements are not met across equipped gems.",
	META_NOT_CHECKABLE = "Meta gem activation requirements are unknown to the catalog (not-checkable).",
}

local function Msg(code, detail)
	local base = MESSAGES[code] or code
	if detail and detail ~= "" then
		return base .. " (" .. detail .. ")"
	end
	return base
end

local function AddFinding(findings, code, severity, category, slotKey, message)
	findings[#findings + 1] = {
		code = code,
		severity = severity,
		category = category,
		slot = slotKey,
		message = message,
	}
end

local function RankArmor(profile, armorType)
	if not armorType or armorType == "" or armorType == "unknown" then
		return "unknown"
	end
	local a = profile.armor
	if a.forbidden[armorType] then
		return "forbidden"
	end
	if a.unwanted[armorType] then
		return "unwanted"
	end
	if a.preferred[armorType] then
		return "preferred"
	end
	if a.acceptable[armorType] then
		return "acceptable"
	end
	-- Shields / offhands: treat as weapon-side when listed in weapons.
	if armorType == "shield" or armorType == "offhand" then
		return "weaponish"
	end
	return "other"
end

local function RankWeapon(profile, weaponType)
	if not weaponType or weaponType == "" or weaponType == "unknown" then
		return "unknown"
	end
	local w = profile.weapons
	if w.forbidden[weaponType] then
		return "forbidden"
	end
	if w.unwanted[weaponType] then
		return "unwanted"
	end
	if w.preferred[weaponType] then
		return "preferred"
	end
	if w.acceptable[weaponType] then
		return "acceptable"
	end
	return "other"
end

local function RankStat(profile, statId)
	local s = profile.stats
	if s.forbidden[statId] then
		return "forbidden"
	end
	if s.unwanted[statId] then
		return "unwanted"
	end
	if s.preferred[statId] then
		return "preferred"
	end
	if s.acceptable[statId] then
		return "acceptable"
	end
	return "other"
end

local function EvaluateItemArmor(findings, profile, slot)
	local item = slot.item
	if item.category ~= "armor" or item.isRelic then
		return
	end
	-- Cloaks/jewelry use armor item class but are not armor-type constrained.
	if slot.key == "back" or slot.key == "neck" or slot.key == "finger1" or slot.key == "finger2" then
		return
	end
	local armorType = item.armorType
	if not armorType or armorType == "unknown" then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", "armor type"))
		return
	end
	if armorType == "misc" then
		return
	end
	if armorType == "shield" or armorType == "offhand" then
		local rank = RankWeapon(profile, armorType)
		if rank == "forbidden" then
			AddFinding(findings, "WEAPON_FORBIDDEN", "hard", "weapon", slot.key, Msg("WEAPON_FORBIDDEN", armorType))
		elseif rank == "unwanted" then
			AddFinding(findings, "WEAPON_UNWANTED", "soft", "weapon", slot.key, Msg("WEAPON_UNWANTED", armorType))
		end
		return
	end
	local rank = RankArmor(profile, armorType)
	if rank == "forbidden" then
		AddFinding(findings, "ARMOR_FORBIDDEN", "hard", "armor", slot.key, Msg("ARMOR_FORBIDDEN", armorType))
	elseif rank == "unwanted" then
		AddFinding(findings, "ARMOR_UNWANTED", "soft", "armor", slot.key, Msg("ARMOR_UNWANTED", armorType))
	elseif rank == "other" then
		AddFinding(findings, "ARMOR_NOT_PREFERRED", "soft", "armor", slot.key, Msg("ARMOR_NOT_PREFERRED", armorType))
	elseif rank == "unknown" then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", "armor type"))
	end
end

local function EvaluateItemWeapon(findings, profile, slot)
	local item = slot.item
	if item.category ~= "weapon" then
		return
	end
	local weaponType = item.weaponType
	if not weaponType or weaponType == "unknown" then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", "weapon type"))
		return
	end
	local rank = RankWeapon(profile, weaponType)
	if rank == "forbidden" then
		AddFinding(findings, "WEAPON_FORBIDDEN", "hard", "weapon", slot.key, Msg("WEAPON_FORBIDDEN", weaponType))
	elseif rank == "unwanted" then
		AddFinding(findings, "WEAPON_UNWANTED", "soft", "weapon", slot.key, Msg("WEAPON_UNWANTED", weaponType))
	elseif rank == "unknown" then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", "weapon type"))
	end
end

local TWO_HAND = {
	sword2h = true,
	axe2h = true,
	mace2h = true,
	polearm = true,
	staff = true,
}

local function FindEquipmentSlot(equipment, key)
	for index = 1, #equipment do
		if equipment[index].key == key then
			return equipment[index]
		end
	end
	return nil
end

local function SlotHasItem(slot)
	return slot and not slot.empty and slot.item ~= nil
end

local function ItemIsTwoHand(item)
	return item and item.category == "weapon" and item.weaponType and TWO_HAND[item.weaponType]
end

local function ItemIsShield(item)
	return item and item.armorType == "shield"
end

local function ItemIsWeapon(item)
	return item and item.category == "weapon"
end

local function ItemIsHeldOffhand(item)
	return item and item.armorType == "offhand"
end

local function OffhandHasSpiritOrHit(item)
	if not item or type(item.stats) ~= "table" then
		return false
	end
	local spirit = tonumber(item.stats.spirit) or 0
	local hit = tonumber(item.stats.hitRating) or 0
	return spirit > 0 or hit > 0
end

-- Surface weapon-setup rules from BiS lists (not BiS scoring).
local function EvaluateWeaponSetup(findings, profile, equipment)
	local setup = profile.weaponSetup
	if not setup or setup == "any" then
		return
	end
	local mh = FindEquipmentSlot(equipment, "mainHand")
	local oh = FindEquipmentSlot(equipment, "offHand")

	if setup == "dw" then
		if not SlotHasItem(mh) or not ItemIsWeapon(mh.item) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "mainHand", Msg("WEAPON_SETUP", "dual-wield needs a main-hand weapon"))
		end
		if not SlotHasItem(oh) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "dual-wield needs an off-hand weapon"))
		elseif ItemIsShield(oh.item) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "shield is not used for dual-wield"))
		elseif not ItemIsWeapon(oh.item) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "dual-wield needs an off-hand weapon"))
		end
	elseif setup == "2h" then
		if SlotHasItem(mh) and ItemIsTwoHand(mh.item) and SlotHasItem(oh) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "two-hand setup should leave off-hand empty"))
		end
	elseif setup == "1h_shield" then
		if SlotHasItem(mh) and ItemIsTwoHand(mh.item) then
			-- Staff / other 2H is a temporary healer variant; off-hand must stay empty.
			if SlotHasItem(oh) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "two-hand setup should leave off-hand empty"))
			end
		else
			if not SlotHasItem(oh) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "expects a shield"))
			elseif not ItemIsShield(oh.item) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "expects a shield"))
			end
		end
	elseif setup == "1h_shield_or_oh" then
		-- Resto Shaman: shield preferred; SP/haste/crit held OH (no spirit/hit) also fine; 2H staff ok.
		if SlotHasItem(mh) and ItemIsTwoHand(mh.item) then
			if SlotHasItem(oh) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "two-hand setup should leave off-hand empty"))
			end
		elseif not SlotHasItem(oh) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "expects a shield or off-hand"))
		elseif ItemIsShield(oh.item) then
			-- ok
		elseif ItemIsHeldOffhand(oh.item) then
			if OffhandHasSpiritOrHit(oh.item) then
				AddFinding(
					findings,
					"WEAPON_SETUP",
					"soft",
					"weapon",
					"offHand",
					Msg("WEAPON_SETUP", "held off-hand with spirit/hit is not preferred; use shield or SP/haste/crit OH")
				)
			end
		elseif not ItemIsWeapon(oh.item) then
			AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "expects a shield or off-hand"))
		end
	elseif setup == "1h_oh" then
		-- 1H+OH preferred; 2H staff is an acceptable temporary healer/caster variant.
		if SlotHasItem(mh) and ItemIsTwoHand(mh.item) then
			if SlotHasItem(oh) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "two-hand setup should leave off-hand empty"))
			end
		else
			if not SlotHasItem(oh) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "expects an off-hand"))
			elseif ItemIsShield(oh.item) then
				AddFinding(findings, "WEAPON_SETUP", "soft", "weapon", "offHand", Msg("WEAPON_SETUP", "shield is not used for this setup"))
			end
		end
	end
end

local function TrinketInSet(setTable, itemId)
	if type(setTable) ~= "table" or not next(setTable) then
		return false
	end
	return setTable[tonumber(itemId)] == true
end

local function EvaluateTrinket(findings, profile, slot)
	if slot.key ~= "trinket1" and slot.key ~= "trinket2" then
		return
	end
	local allowed = profile.trinketsAllowed
	if type(allowed) ~= "table" or not next(allowed) then
		return
	end
	local item = slot.item
	local itemId = item and tonumber(item.itemId)
	if not itemId or itemId <= 0 then
		return
	end
	if not allowed[itemId] then
		AddFinding(
			findings,
			"TRINKET_NOT_PREFERRED",
			"soft",
			"item",
			slot.key,
			Msg("TRINKET_NOT_PREFERRED", tostring(itemId))
		)
	end
end

local function EvaluateItemStats(findings, profile, slot)
	local stats = slot.item.stats
	if type(stats) ~= "table" then
		return
	end
	for statId, amount in pairs(stats) do
		if tonumber(amount) and tonumber(amount) > 0 then
			if statId == "resilience" then
				AddFinding(findings, "RESILIENCE_PVE", "soft", "stat", slot.key, Msg("RESILIENCE_PVE"))
			else
				local rank = RankStat(profile, statId)
				if rank == "forbidden" then
					AddFinding(findings, "STAT_FORBIDDEN", "hard", "stat", slot.key, Msg("STAT_FORBIDDEN", statId))
				elseif rank == "unwanted" then
					AddFinding(findings, "STAT_UNWANTED", "soft", "stat", slot.key, Msg("STAT_UNWANTED", statId))
				end
			end
		end
	end
end

local function EnchantableSlot(slot)
	if not (ENCHANTABLE[slot.key] or ENCHANT_OPTIONAL[slot.key]) then
		return false
	end
	local item = slot.item
	if not item then
		return false
	end
	-- Wands cannot be enchanted in WotLK.
	if item.weaponType == "wand" then
		return false
	end
	if slot.key == "offHand" then
		-- Held-in-off-hand books/orbs (INVTYPE_HOLDABLE) cannot be enchanted; shields and weapons can.
		if item.armorType == "offhand" then
			return false
		end
		return item.category == "weapon" or item.armorType == "shield"
	end
	if slot.key == "ranged" then
		return item.category == "weapon"
	end
	return true
end

local function SlotRequiresEnchantForGood(slot)
	if not ENCHANTABLE[slot.key] then
		return false
	end
	return EnchantableSlot(slot)
end

local function EvaluateEnchant(findings, profile, slot)
	if not EnchantableSlot(slot) then
		return
	end
	local enchant = slot.item.enchant
	local requirePresent = ENCHANTABLE[slot.key] == true
	if not enchant or not enchant.present then
		if requirePresent then
			AddFinding(findings, "MISSING_ENCHANT", "soft", "enchant", slot.key, Msg("MISSING_ENCHANT"))
		end
		return
	end
	local info = Addon:GetGearCheckEnchantInfo(enchant.enchantId)
	if not info then
		AddFinding(findings, "ENCHANT_NOT_CHECKABLE", "info", "enchant", slot.key, Msg("ENCHANT_NOT_CHECKABLE", tostring(enchant.enchantId)))
		return
	end
	if info.maxLevel ~= true then
		AddFinding(findings, "ENCHANT_LOWER_LEVEL", "soft", "enchant", slot.key, Msg("ENCHANT_LOWER_LEVEL", info.name or tostring(enchant.enchantId)))
	end
	if type(info.stats) == "table" and not info.allStats then
		for statId, amount in pairs(info.stats) do
			if tonumber(amount) and tonumber(amount) > 0 then
				if statId == "resilience" then
					AddFinding(findings, "RESILIENCE_PVE", "soft", "enchant", slot.key, Msg("RESILIENCE_PVE", info.name))
				elseif RankStat(profile, statId) == "forbidden" then
					AddFinding(findings, "ENCHANT_BAD_STAT", "hard", "enchant", slot.key, Msg("ENCHANT_BAD_STAT", statId))
				elseif RankStat(profile, statId) == "unwanted" then
					AddFinding(findings, "ENCHANT_BAD_STAT", "soft", "enchant", slot.key, Msg("ENCHANT_BAD_STAT", statId))
				end
			end
		end
	end
end

local function EvaluateGems(findings, profile, slot)
	local item = slot.item
	local sockets = item.sockets or {}
	local gems = item.gems or {}
	if sockets.gemDataUncertain then
		AddFinding(
			findings,
			"GEM_NOT_CHECKABLE",
			"info",
			"gem",
			slot.key,
			Msg("GEM_NOT_CHECKABLE", "inspect socket data unavailable")
		)
		return
	end
	local socketTotal = tonumber(sockets.total) or 0
	local emptySockets = tonumber(sockets.empty)
	if emptySockets == nil then
		emptySockets = math.max(0, socketTotal - #gems)
	end
	if emptySockets > 0 and sockets.emptyConfirmed then
		AddFinding(
			findings,
			"MISSING_GEM",
			"soft",
			"gem",
			slot.key,
			Msg("MISSING_GEM", string.format("%d/%d", #gems, math.max(socketTotal, #gems + emptySockets)))
		)
	end

	local metaSockets = tonumber(sockets.meta) or 0
	local hasMetaGem = false
	for index = 1, #gems do
		local gem = gems[index]
		if gem.isMeta then
			hasMetaGem = true
		end
		local catalog = Addon:GetGearCheckGemInfo(gem.itemId)
		local stats = gem.stats
		if catalog and type(catalog.stats) == "table" and (not stats or not next(stats)) then
			stats = catalog.stats
		end
		if not catalog then
			-- Unknown ids stay not-checkable (info). Never invent GEM_LOWER_LEVEL.
			AddFinding(findings, "GEM_NOT_CHECKABLE", "info", "gem", slot.key, Msg("GEM_NOT_CHECKABLE", tostring(gem.itemId)))
		elseif catalog.maxLevel ~= true then
			AddFinding(findings, "GEM_LOWER_LEVEL", "soft", "gem", slot.key, Msg("GEM_LOWER_LEVEL", tostring(gem.itemId)))
		end
		if type(stats) == "table" and not (catalog and catalog.allStats) then
			for statId, amount in pairs(stats) do
				if tonumber(amount) and tonumber(amount) > 0 then
					if statId == "resilience" then
						AddFinding(findings, "RESILIENCE_PVE", "soft", "gem", slot.key, Msg("RESILIENCE_PVE", tostring(gem.itemId)))
					elseif RankStat(profile, statId) == "forbidden" then
						AddFinding(findings, "GEM_BAD_STAT", "hard", "gem", slot.key, Msg("GEM_BAD_STAT", statId))
					elseif RankStat(profile, statId) == "unwanted" then
						AddFinding(findings, "GEM_BAD_STAT", "soft", "gem", slot.key, Msg("GEM_BAD_STAT", statId))
					end
				end
			end
		end
		if gem.isMeta and profile.metaPreferred and next(profile.metaPreferred) then
			if not profile.metaPreferred[gem.itemId] then
				AddFinding(findings, "META_NOT_PREFERRED", "soft", "meta", slot.key, Msg("META_NOT_PREFERRED", tostring(gem.itemId)))
			end
		end
	end

	if metaSockets > 0 then
		if not hasMetaGem then
			if #gems >= metaSockets then
				AddFinding(findings, "META_NOT_META", "hard", "meta", slot.key, Msg("META_NOT_META"))
			else
				AddFinding(findings, "META_MISSING", "soft", "meta", slot.key, Msg("META_MISSING"))
			end
		end
	end
end

local function EvaluateSlot(findings, profile, slot)
	if slot.policy ~= "CHECKED" then
		return
	end
	if slot.empty or not slot.item then
		return
	end
	local item = slot.item
	if item.pendingLink then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE"))
		return
	end
	local skipTypeAndStats = item.infoKnown == false
	if type(item.gaps) == "table" then
		for index = 1, #item.gaps do
			local gap = item.gaps[index]
			if gap.code == "STATS_UNAVAILABLE" or gap.code == "ITEM_INFO_UNKNOWN"
				or gap.code == "ARMOR_TYPE_UNKNOWN" or gap.code == "WEAPON_TYPE_UNKNOWN"
			then
				AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", gap.code))
				skipTypeAndStats = true
				break
			end
		end
	end

	if not skipTypeAndStats then
		if slot.key == "trinket1" or slot.key == "trinket2" then
			EvaluateTrinket(findings, profile, slot)
			EvaluateItemStats(findings, profile, slot)
		else
			EvaluateItemArmor(findings, profile, slot)
			EvaluateItemWeapon(findings, profile, slot)
			EvaluateItemStats(findings, profile, slot)
		end
	elseif slot.key == "trinket1" or slot.key == "trinket2" then
		EvaluateTrinket(findings, profile, slot)
	end
	if slot.key ~= "trinket1" and slot.key ~= "trinket2" then
		EvaluateEnchant(findings, profile, slot)
		EvaluateGems(findings, profile, slot)
	end
end

local COLOR_MATCH = {
	red = { red = true, orange = true, purple = true, prismatic = true },
	yellow = { yellow = true, orange = true, green = true, prismatic = true },
	blue = { blue = true, purple = true, green = true, prismatic = true },
}

local function GemColor(gem)
	if gem.isMeta then
		return "meta"
	end
	if gem.color and gem.color ~= "unknown" then
		return gem.color
	end
	local catalog = Addon:GetGearCheckGemInfo(gem.itemId)
	if catalog and catalog.color then
		return catalog.color
	end
	return gem.color or "unknown"
end

local function CountMatchingGems(equipment)
	local have = { red = 0, yellow = 0, blue = 0 }
	for index = 1, #equipment do
		local slot = equipment[index]
		if slot.policy == "CHECKED" and slot.item and slot.item.gems then
			local gems = slot.item.gems
			for g = 1, #gems do
				local gem = gems[g]
				if not gem.isMeta then
					local color = GemColor(gem)
					if COLOR_MATCH.red[color] then
						have.red = have.red + 1
					end
					if COLOR_MATCH.yellow[color] then
						have.yellow = have.yellow + 1
					end
					if COLOR_MATCH.blue[color] then
						have.blue = have.blue + 1
					end
				end
			end
		end
	end
	return have
end

local function FormatRequireBrief(requires, have)
	local parts = {}
	local order = { "red", "yellow", "blue" }
	for index = 1, #order do
		local color = order[index]
		local need = requires[color]
		if need and need > 0 then
			parts[#parts + 1] = string.format("%s %d/%d", color, have[color] or 0, need)
		end
	end
	return table.concat(parts, ", ")
end

local function EvaluateMetaActivation(findings, report, equipment)
	local have = CountMatchingGems(equipment)
	local metaInfo = {
		present = false,
		active = nil,
		known = false,
		itemId = nil,
		slot = nil,
		requires = nil,
		have = have,
	}
	for index = 1, #equipment do
		local slot = equipment[index]
		if slot.policy == "CHECKED" and slot.item and slot.item.gems then
			local gems = slot.item.gems
			for g = 1, #gems do
				local gem = gems[g]
				if gem.isMeta or GemColor(gem) == "meta" then
					metaInfo.present = true
					metaInfo.itemId = gem.itemId
					metaInfo.slot = slot.key
					local catalog = Addon:GetGearCheckGemInfo(gem.itemId)
					local requires = catalog and catalog.requires
					if type(requires) ~= "table" or not next(requires) then
						metaInfo.known = false
						AddFinding(
							findings,
							"META_NOT_CHECKABLE",
							"info",
							"meta",
							slot.key,
							Msg("META_NOT_CHECKABLE", tostring(gem.itemId))
						)
					else
						metaInfo.known = true
						metaInfo.requires = requires
						local ok = true
						for color, need in pairs(requires) do
							if (have[color] or 0) < (tonumber(need) or 0) then
								ok = false
								break
							end
						end
						metaInfo.active = ok
						if not ok then
							AddFinding(
								findings,
								"META_INACTIVE",
								"soft",
								"meta",
								slot.key,
								Msg("META_INACTIVE", FormatRequireBrief(requires, have))
							)
						end
					end
				end
			end
		end
	end
	report.meta = metaInfo
end

local function CollectSetCounts(equipment)
	local counts = {}
	local seenKeys = {}
	for index = 1, #equipment do
		local slot = equipment[index]
		if slot.item and slot.item.itemId and Addon.GetGearCheckSetInfo then
			local info = Addon:GetGearCheckSetInfo(slot.item.itemId)
			if info then
				local bucket = counts[info.key]
				if not bucket then
					bucket = { key = info.key, equipped = 0, pieces = info.pieces or 5 }
					counts[info.key] = bucket
					seenKeys[#seenKeys + 1] = info.key
				end
				bucket.equipped = bucket.equipped + 1
			end
		end
	end
	table.sort(seenKeys)
	local list = {}
	for index = 1, #seenKeys do
		list[#list + 1] = counts[seenKeys[index]]
	end
	return list
end

local ITEM_ISSUE_CATEGORIES = {
	armor = true,
	weapon = true,
	stat = true,
	item = true,
}

local function CountUnique(map)
	local n = 0
	for _ in pairs(map) do
		n = n + 1
	end
	return n
end

local function CountIssueGroups(findings)
	local items, enchants, gems, meta = {}, {}, {}, {}
	for index = 1, #findings do
		local finding = findings[index]
		if finding.severity == "hard" or finding.severity == "soft" then
			local key = finding.slot or "_gear"
			if finding.category == "enchant" then
				enchants[key] = true
			elseif finding.category == "gem" then
				gems[key] = true
			elseif finding.category == "meta" then
				meta[key] = true
			elseif ITEM_ISSUE_CATEGORIES[finding.category] then
				items[key] = true
			end
		end
	end
	return {
		items = CountUnique(items),
		enchants = CountUnique(enchants),
		gems = CountUnique(gems),
		meta = CountUnique(meta),
	}
end

local function CountResilienceItems(findings)
	local slots = {}
	for index = 1, #findings do
		local finding = findings[index]
		if finding.code == "RESILIENCE_PVE" and finding.slot then
			slots[finding.slot] = true
		end
	end
	return CountUnique(slots)
end

function Addon:EvaluateGearCheck(report)
	local findings = {}
	if not report or not report.character then
		return findings
	end

	local character = report.character
	local profile, source = self:GetGearCheckProfile(character.classFile, character.specTab, character.specKnown)
	if source == "class" or not character.specKnown then
		AddFinding(findings, "SPEC_UNKNOWN", "info", "character", nil, Msg("SPEC_UNKNOWN"))
	end
	if not profile then
		AddFinding(findings, "PROFILE_MISSING", "info", "character", nil, Msg("PROFILE_MISSING"))
		report.findings = findings
		report.sets = CollectSetCounts(report.equipment or report.slots or {})
		self:AggregateGearCheckVerdicts(report)
		self:AggregateGearCheckOverall(report)
		return findings
	end

	report.profile = {
		name = profile.name,
		source = source,
	}

	local equipment = report.equipment or report.slots or {}
	for index = 1, #equipment do
		EvaluateSlot(findings, profile, equipment[index])
	end
	EvaluateWeaponSetup(findings, profile, equipment)
	EvaluateMetaActivation(findings, report, equipment)
	report.sets = CollectSetCounts(equipment)

	report.findings = findings
	self:AggregateGearCheckVerdicts(report)
	self:AggregateGearCheckOverall(report)
	return findings
end

-- Promote clean OK slots to GOOD when the piece looks highly appropriate (not BiS).
-- Blocked by any hard/soft finding, or by info findings that mean incomplete data.
local GOOD_BLOCKING_INFO = {
	ITEM_NOT_CHECKABLE = true,
	ENCHANT_NOT_CHECKABLE = true,
	GEM_NOT_CHECKABLE = true,
	META_NOT_CHECKABLE = true,
}

local function SlotHasBlockingInfo(findings, slotKey)
	for index = 1, #findings do
		local finding = findings[index]
		if finding.slot == slotKey and finding.severity == "info" and GOOD_BLOCKING_INFO[finding.code] then
			return true
		end
	end
	return false
end

local function EnchantIsMaxLevel(enchant)
	if not enchant or not enchant.present then
		return false
	end
	local info = Addon.GetGearCheckEnchantInfo and Addon:GetGearCheckEnchantInfo(enchant.enchantId)
	return info and info.maxLevel == true
end

local function GemsQualifyForGood(item)
	local sockets = item.sockets or {}
	local gems = item.gems or {}
	if sockets.gemDataUncertain then
		return false
	end
	local socketTotal = tonumber(sockets.total) or 0
	local empty = tonumber(sockets.empty)
	if empty == nil then
		empty = math.max(0, socketTotal - #gems)
	end
	if empty > 0 and sockets.emptyConfirmed then
		return false
	end
	if socketTotal <= 0 and #gems == 0 then
		return true
	end
	for index = 1, #gems do
		local gem = gems[index]
		local catalog = Addon.GetGearCheckGemInfo and Addon:GetGearCheckGemInfo(gem.itemId)
		if not catalog then
			return false
		end
		if catalog.maxLevel ~= true and not catalog.allStats then
			return false
		end
	end
	return true
end

-- BiS lists often use lower armor on wrist/hands/waist/feet (plate DPS leather/mail;
-- Enhancement/Hunter leather bracers/boots; etc.). Acceptable there still qualifies for GOOD.
local GOOD_OFFSET_SLOTS = {
	wrist = true,
	hands = true,
	waist = true,
	feet = true,
}

local function TypeQualifiesForGood(profile, slot)
	local item = slot.item
	if slot.key == "trinket1" or slot.key == "trinket2" then
		local itemId = item and tonumber(item.itemId)
		local preferred = profile.trinketsPreferred
		if type(preferred) == "table" and next(preferred) then
			return TrinketInSet(preferred, itemId)
		end
		local allowed = profile.trinketsAllowed
		if type(allowed) == "table" and next(allowed) then
			return TrinketInSet(allowed, itemId)
		end
		return true
	end
	if slot.key == "back" or slot.key == "neck" or slot.key == "finger1" or slot.key == "finger2" then
		return true
	end
	if item.category == "armor" and not item.isRelic then
		local armorType = item.armorType
		if armorType == "misc" then
			return true
		end
		if armorType == "shield" or armorType == "offhand" then
			return RankWeapon(profile, armorType) == "preferred"
		end
		local rank = RankArmor(profile, armorType)
		if rank == "preferred" then
			return true
		end
		-- Acceptable offset pieces (e.g. Umbrage Armbands on Ret) still qualify for GOOD.
		-- Acceptable cloth (Resto Druid BiS chests) also qualifies — only A_LEATHER_HEAL lists cloth.
		if rank == "acceptable" and (GOOD_OFFSET_SLOTS[slot.key] or armorType == "cloth") then
			return true
		end
		return false
	end
	if item.category == "weapon" then
		local rank = RankWeapon(profile, item.weaponType)
		return rank == "preferred" or rank == "acceptable"
	end
	return true
end

local function CollectNotGoodReasons(profile, slot, findings)
	local reasons = {}
	local item = slot and slot.item
	if not profile or not item then
		reasons[#reasons + 1] = "Cannot confirm GOOD without a profile or item data."
		return reasons
	end
	if SlotHasBlockingInfo(findings, slot.key) then
		for index = 1, #findings do
			local finding = findings[index]
			if finding.slot == slot.key and finding.severity == "info" and GOOD_BLOCKING_INFO[finding.code] then
				reasons[#reasons + 1] = finding.message or finding.code
			end
		end
		if #reasons == 0 then
			reasons[#reasons + 1] = "Incomplete or unknown data blocks GOOD."
		end
		return reasons
	end
	if not TypeQualifiesForGood(profile, slot) then
		if slot.key == "trinket1" or slot.key == "trinket2" then
			local itemId = item and tonumber(item.itemId)
			if TrinketInSet(profile.trinketsAllowed, itemId) then
				reasons[#reasons + 1] = "Trinket is in progression pool, not endgame BiS."
			else
				reasons[#reasons + 1] = "Trinket is not preferred for this specialization."
			end
		elseif item.category == "armor" and item.armorType and item.armorType ~= "misc" then
			reasons[#reasons + 1] = string.format(
				"Armor type %s is not preferred for this specialization.",
				tostring(item.armorType)
			)
		elseif item.category == "weapon" then
			reasons[#reasons + 1] = string.format(
				"Weapon type %s is not preferred for this specialization.",
				tostring(item.weaponType or "?")
			)
		else
			reasons[#reasons + 1] = "Item type is not preferred for this specialization."
		end
	end
	if SlotRequiresEnchantForGood(slot) then
		if not item.enchant or not item.enchant.present then
			reasons[#reasons + 1] = "Missing a max-level enchant (required for GOOD)."
		elseif not EnchantIsMaxLevel(item.enchant) then
			reasons[#reasons + 1] = "Enchant is not a recognized max-level enchant."
		end
	elseif ENCHANT_OPTIONAL[slot.key] and item.enchant and item.enchant.present then
		if not EnchantIsMaxLevel(item.enchant) then
			reasons[#reasons + 1] = "Optional enchant is present but not max-level."
		end
	end
	if not GemsQualifyForGood(item) then
		local sockets = item.sockets or {}
		local gems = item.gems or {}
		if sockets.gemDataUncertain then
			reasons[#reasons + 1] = "Gem socket data was not fully available from inspect."
		else
			local empty = tonumber(sockets.empty)
			if empty == nil then
				empty = math.max(0, (tonumber(sockets.total) or 0) - #gems)
			end
			if empty > 0 and sockets.emptyConfirmed then
				reasons[#reasons + 1] = "Empty sockets block GOOD."
			else
				reasons[#reasons + 1] = "One or more gems are not recognized as max-level."
			end
		end
	end
	return reasons
end

local function SlotQualifiesForGood(profile, slot, findings)
	return #CollectNotGoodReasons(profile, slot, findings) == 0
end

--- Reasons a CHECKED slot stayed OK instead of GOOD (empty if not OK / already GOOD).
function Addon:ExplainGearCheckNotGood(report, slot)
	local reasons = {}
	if not report or not slot or slot.verdict ~= "OK" or not slot.item then
		return reasons
	end
	local profile = nil
	if report.character then
		profile = self:GetGearCheckProfile(
			report.character.classFile,
			report.character.specTab,
			report.character.specKnown
		)
	end
	return CollectNotGoodReasons(profile, slot, report.findings or {})
end

-- Aggregate per-slot findings → BAD / REPLACE / OK / GOOD.
-- info-only findings do not demote an item (unknown stays OK, never false BAD).
-- GOOD requires preferred type + max-level enchant (when required) + max-level gems.
function Addon:AggregateGearCheckVerdicts(report)
	local summary = { good = 0, ok = 0, replace = 0, bad = 0, skipped = 0 }
	if not report then
		return summary
	end

	local bySlot = {}
	local findings = report.findings or {}
	for index = 1, #findings do
		local finding = findings[index]
		local slotKey = finding.slot
		if slotKey then
			local bucket = bySlot[slotKey]
			if not bucket then
				bucket = { hard = false, soft = false, count = 0 }
				bySlot[slotKey] = bucket
			end
			bucket.count = bucket.count + 1
			if finding.severity == "hard" then
				bucket.hard = true
			elseif finding.severity == "soft" then
				bucket.soft = true
			end
		end
	end

	local profile = nil
	if report.character then
		profile = self:GetGearCheckProfile(
			report.character.classFile,
			report.character.specTab,
			report.character.specKnown
		)
	end

	local equipment = report.equipment or report.slots or {}
	for index = 1, #equipment do
		local slot = equipment[index]
		slot.verdict = nil
		if slot.policy ~= "CHECKED" or slot.empty or not slot.item then
			summary.skipped = summary.skipped + 1
		else
			local bucket = bySlot[slot.key]
			local verdict = "OK"
			if bucket then
				if bucket.hard then
					verdict = "BAD"
				elseif bucket.soft then
					verdict = "REPLACE"
				end
			end
			if verdict == "OK" and SlotQualifiesForGood(profile, slot, findings) then
				verdict = "GOOD"
			end
			slot.verdict = verdict
			if verdict == "BAD" then
				summary.bad = summary.bad + 1
			elseif verdict == "REPLACE" then
				summary.replace = summary.replace + 1
			elseif verdict == "GOOD" then
				summary.good = summary.good + 1
			else
				summary.ok = summary.ok + 1
			end
		end
	end

	report.verdicts = summary
	return summary
end

-- Overall status: worst item verdict, then Resilience count (1 → REPLACE, 2+ → BAD).
-- Set-piece counts are informational and must not change this result.
-- Overall GOOD only when every filled checked slot is GOOD (and no soft/hard issues).
function Addon:AggregateGearCheckOverall(report)
	local overall = {
		status = "OK",
		reason = "clean",
		summary = "No significant issues.",
		issues = { items = 0, enchants = 0, gems = 0, meta = 0 },
		resilienceItems = 0,
	}
	if not report then
		return overall
	end

	local findings = report.findings or {}
	local verdicts = report.verdicts or { good = 0, ok = 0, replace = 0, bad = 0 }
	local issues = CountIssueGroups(findings)
	local resilienceItems = CountResilienceItems(findings)
	overall.issues = issues
	overall.resilienceItems = resilienceItems

	local status = "OK"
	local reason = "clean"
	if (verdicts.bad or 0) > 0 then
		status = "BAD"
		reason = "item_bad"
	else
		for index = 1, #findings do
			if findings[index].severity == "hard" then
				status = "BAD"
				reason = "hard_finding"
				break
			end
		end
	end
	if status == "OK" then
		if (verdicts.replace or 0) > 0 then
			status = "REPLACE"
			reason = "item_replace"
		else
			for index = 1, #findings do
				if findings[index].severity == "soft" then
					status = "REPLACE"
					reason = "soft_finding"
					break
				end
			end
		end
	end

	if resilienceItems >= 2 then
		status = "BAD"
		reason = "resilience"
	elseif resilienceItems == 1 and (status == "OK" or status == "GOOD") then
		status = "REPLACE"
		reason = "resilience"
	end

	if status == "OK" then
		local good = verdicts.good or 0
		local ok = verdicts.ok or 0
		if good > 0 and ok == 0 then
			status = "GOOD"
			reason = "all_good"
		end
	end

	overall.status = status
	overall.reason = reason
	if status == "BAD" then
		if reason == "resilience" then
			overall.summary = string.format("%d items have Resilience (PvE: 2+ is BAD).", resilienceItems)
		else
			overall.summary = string.format("%d item(s) are BAD.", verdicts.bad or 0)
		end
	elseif status == "REPLACE" then
		if reason == "resilience" then
			overall.summary = "1 item has Resilience (PvE: REPLACE)."
		else
			overall.summary = string.format("%d item(s) are REPLACE.", verdicts.replace or 0)
		end
	elseif status == "GOOD" then
		overall.summary = string.format("%d item(s) are GOOD.", verdicts.good or 0)
	end

	report.overall = overall
	return overall
end

local function MakeSlot(key, slotName, item)
	return {
		key = key,
		slotName = slotName,
		policy = "CHECKED",
		empty = item == nil,
		item = item,
		gaps = {},
	}
end

local function MakeItem(fields)
	fields.enchant = fields.enchant or { enchantId = 0, present = false, known = true, gaps = {} }
	fields.gems = fields.gems or {}
	fields.stats = fields.stats or {}
	fields.sockets = fields.sockets or { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 0 }
	fields.infoKnown = fields.infoKnown ~= false
	fields.pendingLink = fields.pendingLink == true
	fields.isRelic = fields.isRelic == true
	fields.gaps = fields.gaps or {}
	return fields
end

-- Offline fixtures for `/rw gearcheck test`.
function Addon:GearCheckRulesSelfTest()
	local results = {}
	local function Check(name, ok, detail)
		results[#results + 1] = { name = name, ok = ok and true or false, detail = detail }
	end

	local function HasCode(findings, code)
		for index = 1, #findings do
			if findings[index].code == code then
				return true
			end
		end
		return false
	end

	local function HasCodeOnSlot(findings, code, slotKey)
		for index = 1, #findings do
			local finding = findings[index]
			if finding.code == code and finding.slot == slotKey then
				return true
			end
		end
		return false
	end

	-- Cloth on Protection Warrior → ARMOR_FORBIDDEN
	local clothProt = {
		character = { classFile = "WARRIOR", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 1,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 10 },
				enchant = { enchantId = 3832, present = true, known = false, gaps = {} },
			})),
		},
	}
	local f1 = self:EvaluateGearCheck(clothProt)
	Check("cloth on prot warrior → ARMOR_FORBIDDEN", HasCode(f1, "ARMOR_FORBIDDEN"))
	Check("cloth on prot warrior → chest BAD", clothProt.equipment[1].verdict == "BAD")

	-- Resilience ring → RESILIENCE_PVE
	local resRing = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("finger1", "Finger0Slot", MakeItem({
				itemId = 2,
				category = "armor",
				armorType = "misc",
				stats = { resilience = 50, stamina = 20 },
			})),
		},
	}
	local f2 = self:EvaluateGearCheck(resRing)
	Check("resilience ring → RESILIENCE_PVE", HasCode(f2, "RESILIENCE_PVE"))
	Check("resilience ring → finger1 REPLACE", resRing.equipment[1].verdict == "REPLACE")

	-- Missing chest enchant → MISSING_ENCHANT
	local missing = {
		character = { classFile = "MAGE", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 3,
				category = "armor",
				armorType = "cloth",
				stats = { spellPower = 100 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local f3 = self:EvaluateGearCheck(missing)
	Check("missing chest enchant → MISSING_ENCHANT", HasCode(f3, "MISSING_ENCHANT"))
	Check("missing chest enchant → chest REPLACE", missing.equipment[1].verdict == "REPLACE")

	-- Spell Power on Fury → STAT_FORBIDDEN
	local spFury = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 4,
				category = "armor",
				armorType = "plate",
				stats = { spellPower = 80, stamina = 50 },
				enchant = { enchantId = 3832, present = true, known = false, gaps = {} },
			})),
		},
	}
	local f4 = self:EvaluateGearCheck(spFury)
	Check("spell power on fury → STAT_FORBIDDEN", HasCode(f4, "STAT_FORBIDDEN"))
	Check("spell power on fury → chest BAD", spFury.equipment[1].verdict == "BAD")

	-- Clean plate chest on Arms → GOOD (preferred plate + max-level enchant)
	local clean = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 5,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(clean)
	Check("clean plate chest → GOOD", clean.equipment[1].verdict == "GOOD")
	Check("clean plate chest → overall GOOD", clean.overall and clean.overall.status == "GOOD")

	-- Acceptable-but-not-preferred stays OK (mail on Arms with max enchant)
	local mailArms = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 5,
				category = "armor",
				armorType = "mail",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(mailArms)
	Check("mail on arms (acceptable) → OK not GOOD", mailArms.equipment[1].verdict == "OK")
	Check("mail on arms → overall OK", mailArms.overall and mailArms.overall.status == "OK")

	-- Info-only (unknown enchant) → still OK
	local unmapped = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 6,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 999999, present = true, known = false, gaps = {} },
			})),
		},
	}
	local fInfo = self:EvaluateGearCheck(unmapped)
	Check("unknown enchant → ENCHANT_NOT_CHECKABLE", HasCode(fInfo, "ENCHANT_NOT_CHECKABLE"))
	Check("unknown enchant → still OK (no false BAD)", unmapped.equipment[1].verdict == "OK")
	Check("unknown enchant → overall OK", unmapped.overall and unmapped.overall.status == "OK")

	Check("cloth on prot → overall BAD", clothProt.overall and clothProt.overall.status == "BAD")
	Check("one resilience ring → overall REPLACE", resRing.overall and resRing.overall.status == "REPLACE")

	-- Two resilience items → overall BAD (locked PvE rule)
	local twoRes = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("finger1", "Finger0Slot", MakeItem({
				itemId = 7,
				category = "armor",
				armorType = "misc",
				stats = { resilience = 40, stamina = 20 },
			})),
			MakeSlot("finger2", "Finger1Slot", MakeItem({
				itemId = 8,
				category = "armor",
				armorType = "misc",
				stats = { resilience = 40, stamina = 20 },
			})),
		},
	}
	self:EvaluateGearCheck(twoRes)
	Check("two resilience rings → items REPLACE", twoRes.equipment[1].verdict == "REPLACE" and twoRes.equipment[2].verdict == "REPLACE")
	Check("two resilience rings → overall BAD", twoRes.overall and twoRes.overall.status == "BAD")
	Check("two resilience rings → resilienceItems=2", twoRes.overall and twoRes.overall.resilienceItems == 2)

	-- Chaotic Skyflare (2 blue) without blues → META_INACTIVE
	local noBlue = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 9,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
				sockets = { meta = 1, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 41285, present = true, known = true, isMeta = true, color = "meta", stats = { critRating = 21 }, gaps = {} },
				},
			})),
		},
	}
	local fMeta = self:EvaluateGearCheck(noBlue)
	Check("meta without blues → META_INACTIVE", HasCode(fMeta, "META_INACTIVE"))
	Check("meta without blues → head REPLACE", noBlue.equipment[1].verdict == "REPLACE")
	Check("meta without blues → overall REPLACE", noBlue.overall and noBlue.overall.status == "REPLACE")

	-- Same meta with 2 blue gems elsewhere → active
	local withBlue = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 9,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
				sockets = { meta = 1, red = 0, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 41285, present = true, known = true, isMeta = true, color = "meta", stats = { critRating = 21 }, gaps = {} },
				},
			})),
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 10,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 2, prismatic = 0, total = 2 },
				gems = {
					{ socketIndex = 1, itemId = 40119, present = true, known = true, isMeta = false, color = "blue", stats = { stamina = 30 }, gaps = {} },
					{ socketIndex = 2, itemId = 40119, present = true, known = true, isMeta = false, color = "blue", stats = { stamina = 30 }, gaps = {} },
				},
			})),
		},
	}
	local fBlue = self:EvaluateGearCheck(withBlue)
	Check("meta with 2 blues → not META_INACTIVE", not HasCode(fBlue, "META_INACTIVE"))
	Check("meta with 2 blues → meta.active", withBlue.meta and withBlue.meta.active == true)

	-- T10 counts are informational and must not create verdicts
	local t10 = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 50832,
				category = "armor",
				armorType = "mail",
				stats = { agility = 50, attackPower = 80 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
			})),
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 50834,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 70 },
				enchant = { enchantId = 3808, present = true, known = true, gaps = {} },
			})),
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 50830,
				category = "armor",
				armorType = "mail",
				stats = { agility = 50, attackPower = 80 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
			MakeSlot("hands", "HandsSlot", MakeItem({
				itemId = 50831,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 70 },
				enchant = { enchantId = 1603, present = true, known = true, gaps = {} },
			})),
		},
	}
	self:EvaluateGearCheck(t10)
	local t10Count = 0
	if t10.sets then
		for index = 1, #t10.sets do
			if t10.sets[index].key == "T10" then
				t10Count = t10.sets[index].equipped
			end
		end
	end
	Check("T10 seed → 4/5 equipped", t10Count == 4)
	Check("T10 counts do not force BAD", t10.overall and t10.overall.status ~= "BAD")

	-- Phase 8: Enhancement intellect is preferred (not unwanted)
	local enhInt = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 20,
				category = "armor",
				armorType = "mail",
				stats = { intellect = 40, agility = 50, attackPower = 80, stamina = 60 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fEnh = self:EvaluateGearCheck(enhInt)
	Check("enhancement intellect → not STAT_UNWANTED", not HasCode(fEnh, "STAT_UNWANTED"))
	Check("enhancement intellect chest → GOOD", enhInt.equipment[1].verdict == "GOOD")

	-- Retribution: leather offset + intellect on mail pieces are acceptable
	local retLeather = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 30,
				category = "armor",
				armorType = "leather",
				stats = { agility = 40, attackPower = 50, critRating = 30, stamina = 40 },
				enchant = { enchantId = 3845, present = true, known = true, gaps = {} },
			})),
			MakeSlot("hands", "HandsSlot", MakeItem({
				itemId = 31,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, attackPower = 50, intellect = 30, stamina = 40 },
				enchant = { enchantId = 1603, present = true, known = true, gaps = {} },
			})),
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 32,
				category = "armor",
				armorType = "cloth",
				stats = { strength = 40, stamina = 40, critRating = 30 },
				enchant = { enchantId = 1099, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fRet = self:EvaluateGearCheck(retLeather)
	Check("ret leather wrist → not ARMOR_UNWANTED", not HasCode(fRet, "ARMOR_UNWANTED"))
	Check("ret mail intellect → not STAT_UNWANTED", not HasCode(fRet, "STAT_UNWANTED"))
	Check("ret cloak Major Agility → not ENCHANT_NOT_CHECKABLE", not HasCode(fRet, "ENCHANT_NOT_CHECKABLE"))
	Check("ret cloak Major Agility → not ENCHANT_LOWER_LEVEL", not HasCode(fRet, "ENCHANT_LOWER_LEVEL"))
	Check("ret leather wrist → GOOD (BiS offset)", retLeather.equipment[1].verdict == "GOOD")

	-- Enhancement: Umbrage Armbands (leather wrist) are BiS offsets on mail
	local enhLeather = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 53126,
				category = "armor",
				armorType = "leather",
				stats = { agility = 96, attackPower = 96, critRating = 64, hasteRating = 64, stamina = 96 },
				enchant = { enchantId = 3845, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 40118, color = "red", isMeta = false } },
			})),
		},
	}
	local fEnhWrist = self:EvaluateGearCheck(enhLeather)
	Check("enh leather wrist → not ARMOR_UNWANTED", not HasCode(fEnhWrist, "ARMOR_UNWANTED"))
	Check("enh leather wrist → GOOD (BiS offset)", enhLeather.equipment[1].verdict == "GOOD")

	-- Resto Druid: cloth chest is BiS-acceptable and should be GOOD
	local restoCloth = {
		character = { classFile = "DRUID", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 51379,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 80, spellPower = 100, spirit = 60, hasteRating = 50 },
				enchant = { enchantId = 3832, present = true, known = true, gaps = {} },
			})),
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 37835,
				category = "armor",
				armorType = "misc",
				stats = { spellPower = 74 },
			})),
		},
	}
	local fResto = self:EvaluateGearCheck(restoCloth)
	Check("resto cloth chest → not ARMOR_UNWANTED", not HasCode(fResto, "ARMOR_UNWANTED"))
	Check("resto cloth chest → GOOD", restoCloth.equipment[1].verdict == "GOOD")
	Check("resto Je'Tze's Bell → not TRINKET_NOT_PREFERRED", not HasCode(fResto, "TRINKET_NOT_PREFERRED"))

	-- Blood DK: Pinnacle shoulders + armor cloak/gloves must not false-flag
	local bloodTank = {
		character = { classFile = "DEATHKNIGHT", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 40,
				category = "armor",
				armorType = "plate",
				stats = { stamina = 80, defenseRating = 40, dodgeRating = 30, strength = 40 },
				enchant = { enchantId = 3811, present = true, known = true, gaps = {} },
			})),
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 41,
				category = "armor",
				armorType = "cloth",
				stats = { stamina = 60, defenseRating = 40, strength = 30 },
				enchant = { enchantId = 3294, present = true, known = true, gaps = {} },
			})),
			MakeSlot("hands", "HandsSlot", MakeItem({
				itemId = 42,
				category = "armor",
				armorType = "plate",
				stats = { stamina = 70, defenseRating = 40, strength = 35 },
				enchant = { enchantId = 3860, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fBlood = self:EvaluateGearCheck(bloodTank)
	Check("blood Pinnacle → not ENCHANT_BAD_STAT", not HasCode(fBlood, "ENCHANT_BAD_STAT"))
	Check("blood Mighty Armor cloak → not ENCHANT_BAD_STAT", not HasCode(fBlood, "ENCHANT_BAD_STAT"))
	Check("blood Armor Webbing → not ENCHANT_NOT_CHECKABLE", not HasCode(fBlood, "ENCHANT_NOT_CHECKABLE"))

	-- Phase 8: unknown gem → not-checkable (info), not false GEM_LOWER_LEVEL
	local unkGem = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 21,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 999001, present = true, known = true, isMeta = false, color = "red", stats = { strength = 20 }, gaps = {} },
				},
			})),
		},
	}
	local fGem = self:EvaluateGearCheck(unkGem)
	Check("unknown gem → GEM_NOT_CHECKABLE", HasCode(fGem, "GEM_NOT_CHECKABLE"))
	Check("unknown gem → not GEM_LOWER_LEVEL", not HasCode(fGem, "GEM_LOWER_LEVEL"))
	Check("unknown gem → still OK (no false REPLACE)", unkGem.equipment[1].verdict == "OK")

	-- Catalogued epic gem is max-level
	local epicGem = {
		character = { classFile = "WARRIOR", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 22,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3297, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 40111, present = true, known = true, isMeta = false, color = "red", stats = { strength = 20 }, gaps = {} },
				},
			})),
		},
	}
	local fEpic = self:EvaluateGearCheck(epicGem)
	Check("epic catalog gem → not GEM_LOWER_LEVEL", not HasCode(fEpic, "GEM_LOWER_LEVEL"))

	-- JC Dragon's Eye (Bold) is catalogued max-level, not unknown
	local jcGem = {
		character = { classFile = "DEATHKNIGHT", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 24,
				category = "armor",
				armorType = "plate",
				stats = { strength = 40, stamina = 50 },
				enchant = { enchantId = 3817, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1 },
				gems = {
					{ socketIndex = 1, itemId = 42142, present = true, known = true, isMeta = false, color = "red", stats = {}, gaps = {} },
				},
			})),
		},
	}
	local fJc = self:EvaluateGearCheck(jcGem)
	Check("JC Bold Dragon's Eye → not GEM_NOT_CHECKABLE", not HasCode(fJc, "GEM_NOT_CHECKABLE"))
	Check("JC Bold Dragon's Eye → not GEM_LOWER_LEVEL", not HasCode(fJc, "GEM_LOWER_LEVEL"))

	-- Engineering Nitro Boosts on feet is max-level
	local nitro = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("feet", "FeetSlot", MakeItem({
				itemId = 23,
				category = "armor",
				armorType = "mail",
				stats = { agility = 40, intellect = 30, attackPower = 60 },
				enchant = { enchantId = 3606, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fNitro = self:EvaluateGearCheck(nitro)
	Check("nitro boots → not ENCHANT_NOT_CHECKABLE", not HasCode(fNitro, "ENCHANT_NOT_CHECKABLE"))
	Check("nitro boots → not ENCHANT_LOWER_LEVEL", not HasCode(fNitro, "ENCHANT_LOWER_LEVEL"))

	-- Icescale leg armor recognized
	local iceLeg = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("legs", "LegsSlot", MakeItem({
				itemId = 24,
				category = "armor",
				armorType = "mail",
				stats = { agility = 50, intellect = 40, attackPower = 80 },
				enchant = { enchantId = 3823, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fLeg = self:EvaluateGearCheck(iceLeg)
	Check("icescale legs → not ENCHANT_NOT_CHECKABLE", not HasCode(fLeg, "ENCHANT_NOT_CHECKABLE"))
	Check("icescale legs → not ENCHANT_LOWER_LEVEL", not HasCode(fLeg, "ENCHANT_LOWER_LEVEL"))

	-- +10 all stats chest enchant / Nightmare Tear: spirit is packaged, not a bad pick
	local allStats = {
		character = { classFile = "SHAMAN", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("chest", "ChestSlot", MakeItem({
				itemId = 25,
				category = "armor",
				armorType = "mail",
				stats = { agility = 80, intellect = 50, attackPower = 100 },
				enchant = { enchantId = 3832, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 0, prismatic = 1, total = 1, empty = 0 },
				gems = {
					{ socketIndex = 1, itemId = 49110, present = true, known = true, isMeta = false, color = "prismatic", stats = { strength = 10, agility = 10, stamina = 10, intellect = 10, spirit = 10 }, gaps = {} },
				},
			})),
		},
	}
	local fAll = self:EvaluateGearCheck(allStats)
	Check("powerful stats chest → not ENCHANT_BAD_STAT", not HasCode(fAll, "ENCHANT_BAD_STAT"))
	Check("nightmare tear → not GEM_BAD_STAT", not HasCode(fAll, "GEM_BAD_STAT"))

	-- BiS surface: Fury dual-wield expects off-hand; leather offset OK; 2H preferred
	local furyOh = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 50,
				category = "weapon",
				weaponType = "axe2h",
				stats = { strength = 80, stamina = 80 },
				enchant = { enchantId = 3789, present = true, known = true, gaps = {} },
			})),
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 51,
				category = "armor",
				armorType = "leather",
				stats = { strength = 40, stamina = 40, attackPower = 50 },
				enchant = { enchantId = 3845, present = true, known = true, gaps = {} },
			})),
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 50362,
				category = "armor",
				armorType = "misc",
				stats = {},
			})),
			MakeSlot("trinket2", "Trinket1Slot", MakeItem({
				itemId = 54573,
				category = "armor",
				armorType = "misc",
				stats = { spellPower = 100 },
			})),
		},
	}
	local fFury = self:EvaluateGearCheck(furyOh)
	Check("fury missing OH → WEAPON_SETUP", HasCode(fFury, "WEAPON_SETUP"))
	Check("fury leather wrist → not ARMOR_UNWANTED", not HasCode(fFury, "ARMOR_UNWANTED"))
	Check("fury axe2h → not WEAPON_UNWANTED", not HasCode(fFury, "WEAPON_UNWANTED"))
	Check("fury DBW trinket → not TRINKET_NOT_PREFERRED", not HasCodeOnSlot(fFury, "TRINKET_NOT_PREFERRED", "trinket1"))
	Check("fury glowing scale → TRINKET_NOT_PREFERRED", HasCodeOnSlot(fFury, "TRINKET_NOT_PREFERRED", "trinket2"))

	local furyToC = {
		character = { classFile = "WARRIOR", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 47464,
				category = "armor",
				armorType = "misc",
				stats = {},
			})),
		},
	}
	local fFuryToC = self:EvaluateGearCheck(furyToC)
	Check("fury Death's Choice → not TRINKET_NOT_PREFERRED", not HasCode(fFuryToC, "TRINKET_NOT_PREFERRED"))
	Check("fury Death's Choice → OK not GOOD", furyToC.equipment[1].verdict == "OK")

	local retAbom = {
		character = { classFile = "PALADIN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("trinket1", "Trinket0Slot", MakeItem({
				itemId = 50706,
				category = "armor",
				armorType = "misc",
				stats = {},
			})),
		},
	}
	local fRetAbom = self:EvaluateGearCheck(retAbom)
	Check("ret Tiny Abom → not TRINKET_NOT_PREFERRED", not HasCode(fRetAbom, "TRINKET_NOT_PREFERRED"))

	-- Tank leather stays unwanted
	local tankLeather = {
		character = { classFile = "WARRIOR", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("wrist", "WristSlot", MakeItem({
				itemId = 52,
				category = "armor",
				armorType = "leather",
				stats = { stamina = 50, defenseRating = 30 },
				enchant = { enchantId = 3850, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 53,
				category = "armor",
				armorType = "shield",
				stats = { stamina = 80, blockRating = 40 },
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 54,
				category = "weapon",
				weaponType = "axe1h",
				stats = { strength = 50, stamina = 50 },
				enchant = { enchantId = 3789, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fTank = self:EvaluateGearCheck(tankLeather)
	Check("prot leather wrist → ARMOR_UNWANTED", HasCode(fTank, "ARMOR_UNWANTED"))

	-- Disc priest: Reckless Ametrine (SP+haste), Greater Spirit boots, Lunar Dust,
	-- staff Greater Spellpower, wand without enchant.
	local discFix = {
		character = { classFile = "PRIEST", specTab = 1, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("waist", "WaistSlot", MakeItem({
				itemId = 60,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, spirit = 30 },
				sockets = { meta = 0, red = 0, yellow = 1, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 40155, color = "orange", isMeta = false } },
			})),
			MakeSlot("feet", "FeetSlot", MakeItem({
				itemId = 61,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, spirit = 30 },
				enchant = { enchantId = 1147, present = true, known = true, gaps = {} },
			})),
			MakeSlot("trinket2", "Trinket1Slot", MakeItem({
				itemId = 50358,
				category = "armor",
				armorType = "misc",
				stats = { spellPower = 179 },
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 62,
				category = "weapon",
				weaponType = "staff",
				stats = { intellect = 80, spellPower = 200, spirit = 60 },
				enchant = { enchantId = 3854, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 2, yellow = 0, blue = 0, prismatic = 0, total = 2, empty = 0 },
				gems = {
					{ itemId = 40155, color = "orange", isMeta = false },
					{ itemId = 40155, color = "orange", isMeta = false },
				},
			})),
			MakeSlot("ranged", "RangedSlot", MakeItem({
				itemId = 63,
				category = "weapon",
				weaponType = "wand",
				stats = { intellect = 20, spellPower = 40, spirit = 20 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local fDisc = self:EvaluateGearCheck(discFix)
	Check("disc Reckless Ametrine → not GEM_BAD_STAT", not HasCode(fDisc, "GEM_BAD_STAT"))
	Check("disc Greater Spirit boots → not ENCHANT_NOT_CHECKABLE", not HasCode(fDisc, "ENCHANT_NOT_CHECKABLE"))
	Check("disc Purified Lunar Dust → not TRINKET_NOT_PREFERRED", not HasCode(fDisc, "TRINKET_NOT_PREFERRED"))
	Check("disc staff Greater Spellpower → not ENCHANT_NOT_CHECKABLE", not HasCodeOnSlot(fDisc, "ENCHANT_NOT_CHECKABLE", "mainHand"))
	Check("disc wand → not MISSING_ENCHANT", not HasCodeOnSlot(fDisc, "MISSING_ENCHANT", "ranged"))
	Check("disc wand → GOOD (no enchant required)", discFix.equipment[5].verdict == "GOOD")

	-- Resto Shaman: Flexweave cloak ok; held OH (no spirit/hit) ok and unenchantable
	local restoSham = {
		character = { classFile = "SHAMAN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 70,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 40, spellPower = 60, hasteRating = 30 },
				enchant = { enchantId = 3859, present = true, known = true, gaps = {} },
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 71,
				category = "weapon",
				weaponType = "mace1h",
				stats = { intellect = 50, spellPower = 400 },
				enchant = { enchantId = 3834, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 50309,
				category = "armor",
				armorType = "offhand",
				stats = { intellect = 34, spellPower = 78, critRating = 51, hasteRating = 50, stamina = 54 },
				enchant = { enchantId = 0, present = false, known = true, gaps = {} },
			})),
		},
	}
	local fRestoSham = self:EvaluateGearCheck(restoSham)
	Check("resto sham Flexweave → not ENCHANT_BAD_STAT", not HasCode(fRestoSham, "ENCHANT_BAD_STAT"))
	Check("resto sham held OH → not MISSING_ENCHANT", not HasCodeOnSlot(fRestoSham, "MISSING_ENCHANT", "offHand"))
	Check("resto sham held OH (no spirit/hit) → not WEAPON_SETUP", not HasCode(fRestoSham, "WEAPON_SETUP"))
	Check("resto sham held OH → GOOD", restoSham.equipment[3].verdict == "GOOD")

	-- Resto Shaman: Royal Dreadstone (+12 SP / +5 mp5) and Spellsurge weapon enchant are healer-ok
	local restoShamCatalog = {
		character = { classFile = "SHAMAN", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("shoulder", "ShoulderSlot", MakeItem({
				itemId = 51194,
				category = "armor",
				armorType = "mail",
				stats = { intellect = 92, spellPower = 132, hasteRating = 72 },
				enchant = { enchantId = 3809, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 0, blue = 1, prismatic = 0, total = 1, empty = 0 },
				gems = {
					{ itemId = 40134, color = "purple", isMeta = false },
				},
			})),
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 50428,
				category = "weapon",
				weaponType = "mace1h",
				stats = { intellect = 71, spellPower = 792 },
				enchant = { enchantId = 2674, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", MakeItem({
				itemId = 49976,
				category = "armor",
				armorType = "shield",
				stats = { intellect = 69, spellPower = 106 },
				enchant = { enchantId = 1128, present = true, known = true, gaps = {} },
			})),
		},
	}
	local fRestoCat = self:EvaluateGearCheck(restoShamCatalog)
	Check("resto sham Royal Dreadstone → not GEM_BAD_STAT", not HasCode(fRestoCat, "GEM_BAD_STAT"))
	Check("resto sham Spellsurge → not ENCHANT_NOT_CHECKABLE", not HasCode(fRestoCat, "ENCHANT_NOT_CHECKABLE"))
	Check("resto sham Spellsurge → not ENCHANT_BAD_STAT", not HasCode(fRestoCat, "ENCHANT_BAD_STAT"))
	Check("resto sham Royal/Spellsurge shoulder → GOOD", restoShamCatalog.equipment[1].verdict == "GOOD")

	-- Fire Mage: Veiled Ametrine (+12 SP / +10 hit) and Sanctified Spellthread (tailoring legs)
	local fireMageCatalog = {
		character = { classFile = "MAGE", specTab = 2, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("back", "BackSlot", MakeItem({
				itemId = 47552,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 74, spellPower = 105, critRating = 65, hasteRating = 57 },
				enchant = { enchantId = 3722, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = {
					{ itemId = 40153, color = "orange", isMeta = false },
				},
			})),
			MakeSlot("legs", "LegsSlot", MakeItem({
				itemId = 51282,
				category = "armor",
				armorType = "cloth",
				stats = { intellect = 139, spellPower = 195, critRating = 122, hitRating = 106 },
				enchant = { enchantId = 3872, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 0, yellow = 1, blue = 1, prismatic = 0, total = 2, empty = 0 },
				gems = {
					{ itemId = 40133, color = "purple", isMeta = false },
					{ itemId = 40152, color = "orange", isMeta = false },
				},
			})),
		},
	}
	local fFireCat = self:EvaluateGearCheck(fireMageCatalog)
	Check("fire mage Veiled Ametrine → not GEM_BAD_STAT", not HasCode(fFireCat, "GEM_BAD_STAT"))
	Check("fire mage Sanctified Spellthread → not ENCHANT_NOT_CHECKABLE", not HasCode(fFireCat, "ENCHANT_NOT_CHECKABLE"))
	Check("fire mage Sanctified Spellthread → not ENCHANT_BAD_STAT", not HasCode(fFireCat, "ENCHANT_BAD_STAT"))
	Check("fire mage Veiled cloak → GOOD", fireMageCatalog.equipment[1].verdict == "GOOD")

	-- Cardinal Ruby Subtle/Precise stats (not expertise/hit swapped)
	local subtleRuby = {
		character = { classFile = "WARRIOR", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("head", "HeadSlot", MakeItem({
				itemId = 1,
				category = "armor",
				armorType = "plate",
				stats = { strength = 50, stamina = 50, dodgeRating = 40, defenseRating = 40 },
				enchant = { enchantId = 3818, present = true, known = true, gaps = {} },
				sockets = { meta = 0, red = 1, yellow = 0, blue = 0, prismatic = 0, total = 1, empty = 0 },
				gems = { { itemId = 40115, color = "red", isMeta = false } },
			})),
		},
	}
	local fSubtle = self:EvaluateGearCheck(subtleRuby)
	Check("prot warrior Subtle Cardinal Ruby → not GEM_BAD_STAT", not HasCode(fSubtle, "GEM_BAD_STAT"))

	-- Resto Druid: 2H staff with empty OH is an acceptable temporary variant
	local restoStaff = {
		character = { classFile = "DRUID", specTab = 3, specKnown = true, gaps = {} },
		equipment = {
			MakeSlot("mainHand", "MainHandSlot", MakeItem({
				itemId = 54806,
				category = "weapon",
				weaponType = "staff",
				stats = { intellect = 92, spellPower = 550, critRating = 80, hasteRating = 80 },
				enchant = { enchantId = 3854, present = true, known = true, gaps = {} },
			})),
			MakeSlot("offHand", "SecondaryHandSlot", nil),
		},
	}
	local fRestoStaff = self:EvaluateGearCheck(restoStaff)
	Check("resto druid 2H staff → not WEAPON_SETUP", not HasCode(fRestoStaff, "WEAPON_SETUP"))
	Check("resto druid 2H staff → GOOD", restoStaff.equipment[1].verdict == "GOOD")

	local profileCount = 0
	if self.GetGearCheckProfileCount then
		profileCount = self:GetGearCheckProfileCount() or 0
	end
	Check("profiles cover 30 specs + 10 class fallbacks", profileCount == 40)

	if self.GearCheckSavedReportsSelfTest then
		local savedResults = self:GearCheckSavedReportsSelfTest()
		for index = 1, #savedResults do
			results[#results + 1] = savedResults[index]
		end
	end

	local passed = 0
	for index = 1, #results do
		if results[index].ok then
			passed = passed + 1
		end
	end
	return results, passed, #results
end
