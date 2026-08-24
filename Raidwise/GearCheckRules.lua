-- Gear Check rules engine (Phase 3): produces findings only. No verdicts yet.

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

local MESSAGES = {
	SPEC_UNKNOWN = "Specialization is unknown; class-only rules are applied.",
	PROFILE_MISSING = "No Gear Check profile is available for this class.",
	ITEM_NOT_CHECKABLE = "Cannot evaluate this item (incomplete or unknown data).",
	ARMOR_FORBIDDEN = "Forbidden armor type for this specialization.",
	ARMOR_DISCOURAGED = "Discouraged armor type for this specialization.",
	ARMOR_NOT_PREFERRED = "Armor type is usable but not preferred for this specialization.",
	WEAPON_FORBIDDEN = "Forbidden weapon type for this specialization.",
	WEAPON_DISCOURAGED = "Discouraged weapon type for this specialization.",
	STAT_FORBIDDEN = "Forbidden stat for this specialization.",
	STAT_DISCOURAGED = "Discouraged stat for this specialization.",
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
	if a.discouraged[armorType] then
		return "discouraged"
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
	if w.discouraged[weaponType] then
		return "discouraged"
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
	if s.discouraged[statId] then
		return "discouraged"
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
		elseif rank == "discouraged" then
			AddFinding(findings, "WEAPON_DISCOURAGED", "soft", "weapon", slot.key, Msg("WEAPON_DISCOURAGED", armorType))
		end
		return
	end
	local rank = RankArmor(profile, armorType)
	if rank == "forbidden" then
		AddFinding(findings, "ARMOR_FORBIDDEN", "hard", "armor", slot.key, Msg("ARMOR_FORBIDDEN", armorType))
	elseif rank == "discouraged" then
		AddFinding(findings, "ARMOR_DISCOURAGED", "soft", "armor", slot.key, Msg("ARMOR_DISCOURAGED", armorType))
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
	elseif rank == "discouraged" then
		AddFinding(findings, "WEAPON_DISCOURAGED", "soft", "weapon", slot.key, Msg("WEAPON_DISCOURAGED", weaponType))
	elseif rank == "unknown" then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", "weapon type"))
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
				elseif rank == "discouraged" then
					AddFinding(findings, "STAT_DISCOURAGED", "soft", "stat", slot.key, Msg("STAT_DISCOURAGED", statId))
				end
			end
		end
	end
end

local function EnchantableSlot(slot)
	if not ENCHANTABLE[slot.key] then
		return false
	end
	local item = slot.item
	if not item then
		return false
	end
	if slot.key == "offHand" then
		return item.category == "weapon" or item.armorType == "shield" or item.armorType == "offhand"
	end
	if slot.key == "ranged" then
		return item.category == "weapon"
	end
	return true
end

local function EvaluateEnchant(findings, profile, slot)
	if not EnchantableSlot(slot) then
		return
	end
	local enchant = slot.item.enchant
	if not enchant or not enchant.present then
		AddFinding(findings, "MISSING_ENCHANT", "soft", "enchant", slot.key, Msg("MISSING_ENCHANT"))
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
	if type(info.stats) == "table" then
		for statId, amount in pairs(info.stats) do
			if tonumber(amount) and tonumber(amount) > 0 then
				if statId == "resilience" then
					AddFinding(findings, "RESILIENCE_PVE", "soft", "enchant", slot.key, Msg("RESILIENCE_PVE", info.name))
				elseif RankStat(profile, statId) == "forbidden" then
					AddFinding(findings, "ENCHANT_BAD_STAT", "hard", "enchant", slot.key, Msg("ENCHANT_BAD_STAT", statId))
				elseif RankStat(profile, statId) == "discouraged" then
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
	local socketTotal = tonumber(sockets.total) or 0
	if socketTotal > #gems then
		AddFinding(
			findings,
			"MISSING_GEM",
			"soft",
			"gem",
			slot.key,
			Msg("MISSING_GEM", string.format("%d/%d", #gems, socketTotal))
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
		if not catalog and not gem.known then
			AddFinding(findings, "GEM_NOT_CHECKABLE", "info", "gem", slot.key, Msg("GEM_NOT_CHECKABLE", tostring(gem.itemId)))
		elseif catalog and catalog.maxLevel ~= true then
			AddFinding(findings, "GEM_LOWER_LEVEL", "soft", "gem", slot.key, Msg("GEM_LOWER_LEVEL", tostring(gem.itemId)))
		elseif not catalog then
			-- Known via GetItemInfo but not in max catalog → treat as lower-level soft.
			AddFinding(findings, "GEM_LOWER_LEVEL", "soft", "gem", slot.key, Msg("GEM_LOWER_LEVEL", tostring(gem.itemId)))
		end
		if type(stats) == "table" then
			for statId, amount in pairs(stats) do
				if tonumber(amount) and tonumber(amount) > 0 then
					if statId == "resilience" then
						AddFinding(findings, "RESILIENCE_PVE", "soft", "gem", slot.key, Msg("RESILIENCE_PVE"))
					elseif RankStat(profile, statId) == "forbidden" then
						AddFinding(findings, "GEM_BAD_STAT", "hard", "gem", slot.key, Msg("GEM_BAD_STAT", statId))
					elseif RankStat(profile, statId) == "discouraged" then
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
	if item.pendingLink or item.infoKnown == false then
		AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE"))
		return
	end
	if type(item.gaps) == "table" then
		for index = 1, #item.gaps do
			local gap = item.gaps[index]
			if gap.code == "STATS_UNAVAILABLE" or gap.code == "ITEM_INFO_UNKNOWN"
				or gap.code == "ARMOR_TYPE_UNKNOWN" or gap.code == "WEAPON_TYPE_UNKNOWN"
			then
				AddFinding(findings, "ITEM_NOT_CHECKABLE", "info", "item", slot.key, Msg("ITEM_NOT_CHECKABLE", gap.code))
				return
			end
		end
	end

	EvaluateItemArmor(findings, profile, slot)
	EvaluateItemWeapon(findings, profile, slot)
	EvaluateItemStats(findings, profile, slot)
	EvaluateEnchant(findings, profile, slot)
	EvaluateGems(findings, profile, slot)
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

	report.findings = findings
	return findings
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

	local passed = 0
	for index = 1, #results do
		if results[index].ok then
			passed = passed + 1
		end
	end
	return results, passed, #results
end
