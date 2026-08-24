-- Gear Check catalogs (seeded). Enchant ids are item-link enchant ids, not spell ids.
-- Maintained surface-level lists for WotLK 3.3.5a; expand during Phase 8.

local Addon = Raidwise

-- maxLevel: Northrend (or best-in-slot-ish) enchants. stats used for appropriateness only.
local ENCHANTS = {
	-- Chest
	[3832] = { name = "Powerful Stats", maxLevel = true, stats = { strength = 10, agility = 10, stamina = 10, intellect = 10, spirit = 10 } },
	[3297] = { name = "Super Health", maxLevel = true, stats = { } },
	[3245] = { name = "Exceptional Resilience", maxLevel = true, stats = { resilience = 20 } },
	[3252] = { name = "Super Stats", maxLevel = false, stats = { strength = 8, agility = 8, stamina = 8, intellect = 8, spirit = 8 } },
	[3233] = { name = "Mighty Health", maxLevel = false, stats = {} },
	[3236] = { name = "Greater Defense", maxLevel = false, stats = { defenseRating = 22 } },
	-- Cloak
	[3831] = { name = "Greater Speed", maxLevel = true, stats = { hasteRating = 23 } },
	[3294] = { name = "Wisdom", maxLevel = true, stats = { spirit = 10 } },
	[1951] = { name = "Titanweave", maxLevel = true, stats = { defenseRating = 16 } },
	[3243] = { name = "Major Agility", maxLevel = false, stats = { agility = 22 } },
	[3825] = { name = "Speed", maxLevel = false, stats = { hasteRating = 15 } },
	-- Boots
	[3232] = { name = "Tuskarr's Vitality", maxLevel = true, stats = { stamina = 15 } },
	[3826] = { name = "Icewalker", maxLevel = true, stats = { hitRating = 12, critRating = 12 } },
	[1597] = { name = "Greater Assault", maxLevel = true, stats = { attackPower = 32 } },
	[983] = { name = "Superior Agility", maxLevel = false, stats = { agility = 16 } },
	-- Bracers
	[3850] = { name = "Major Stamina", maxLevel = true, stats = { stamina = 40 } },
	[2332] = { name = "Superior Spellpower", maxLevel = true, stats = { spellPower = 30 } },
	[3845] = { name = "Greater Assault", maxLevel = true, stats = { attackPower = 50 } },
	[2326] = { name = "Major Spirit", maxLevel = false, stats = { spirit = 18 } },
	-- Gloves
	[1603] = { name = "Crusher", maxLevel = true, stats = { attackPower = 44 } },
	[3246] = { name = "Exceptional Spellpower", maxLevel = true, stats = { spellPower = 28 } },
	[3231] = { name = "Expertise", maxLevel = true, stats = { expertiseRating = 15 } },
	[3222] = { name = "Major Agility", maxLevel = false, stats = { agility = 20 } },
	-- Weapon
	[3789] = { name = "Berserking", maxLevel = true, stats = {} },
	[3827] = { name = "Massacre", maxLevel = true, stats = {} },
	[3833] = { name = "Superior Potency", maxLevel = true, stats = { attackPower = 65 } },
	[3834] = { name = "Mighty Spellpower", maxLevel = true, stats = { spellPower = 63 } },
	[3847] = { name = "Rune of the Stoneskin Gargoyle", maxLevel = true, stats = { defenseRating = 25 } },
	[3368] = { name = "Rune of the Fallen Crusader", maxLevel = true, stats = {} },
	[3369] = { name = "Rune of Cinderglacier", maxLevel = true, stats = {} },
	[3370] = { name = "Rune of Razorice", maxLevel = true, stats = {} },
	[3595] = { name = "Rune of Spellbreaking", maxLevel = true, stats = {} },
	[3367] = { name = "Rune of Spellshattering", maxLevel = true, stats = {} },
	[3365] = { name = "Rune of Swordshattering", maxLevel = true, stats = {} },
	[3594] = { name = "Rune of Swordbreaking", maxLevel = true, stats = {} },
	[3883] = { name = "Rune of the Nerubian Carapace", maxLevel = true, stats = { defenseRating = 13 } },
	-- Shield
	[1952] = { name = "Defense", maxLevel = true, stats = { defenseRating = 20 } },
	[1128] = { name = "Greater Intellect", maxLevel = false, stats = { intellect = 25 } },
	-- Legs (spellthread / armor kit often appear as enchants)
	[3325] = { name = "Jormungar Leg Reinforcements", maxLevel = true, stats = { stamina = 55, agility = 22 } },
	[3326] = { name = "Frosthide Leg Armor", maxLevel = true, stats = { attackPower = 75, critRating = 22 } },
	[3853] = { name = "Earthen Leg Armor", maxLevel = true, stats = { stamina = 40, resilience = 28 } },
	[3719] = { name = "Brilliant Spellthread", maxLevel = true, stats = { spellPower = 50, spirit = 20 } },
	[3721] = { name = "Sapphire Spellthread", maxLevel = true, stats = { spellPower = 50, stamina = 30 } },
	-- Head / shoulder (arcanum / inscription) — common ids
	[3820] = { name = "Arcanum of Burning Mysteries", maxLevel = true, stats = { spellPower = 30, critRating = 20 } },
	[3819] = { name = "Arcanum of Blissful Mending", maxLevel = true, stats = { spellPower = 30, mp5 = 10 } },
	[3818] = { name = "Arcanum of the Stalwart Protector", maxLevel = true, stats = { stamina = 37, defenseRating = 20 } },
	[3817] = { name = "Arcanum of Torment", maxLevel = true, stats = { attackPower = 50, critRating = 20 } },
	[3815] = { name = "Arcanum of the Fleeing Shadow", maxLevel = true, stats = { spellPower = 30 } },
	[3816] = { name = "Arcanum of the Savage Gladiator", maxLevel = true, stats = { stamina = 30, resilience = 25 } },
	[3808] = { name = "Greater Inscription of the Axe", maxLevel = true, stats = { attackPower = 40, critRating = 15 } },
	[3809] = { name = "Greater Inscription of the Crag", maxLevel = true, stats = { spellPower = 24, mp5 = 8 } },
	[3810] = { name = "Greater Inscription of the Pinnacle", maxLevel = true, stats = { dodgeRating = 20, defenseRating = 15 } },
	[3811] = { name = "Greater Inscription of the Storm", maxLevel = true, stats = { spellPower = 24, critRating = 15 } },
}

-- Northrend epic (and Nightmare Tear) gems. maxLevel = true means ICC-era epic quality.
local GEMS = {
	-- Meta (Earthsiege / Skyflare). requires = gem colors across the full set (not the meta itself).
	[41380] = { maxLevel = true, color = "meta", stats = {}, requires = { blue = 2 } }, -- Austere
	[41389] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2, yellow = 1 } }, -- Beaming
	[41395] = { maxLevel = true, color = "meta", stats = { spellPower = 21 }, requires = { red = 2 } }, -- Bracing
	[41285] = { maxLevel = true, color = "meta", stats = { critRating = 21 }, requires = { blue = 2 } }, -- Chaotic
	[41307] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2 } }, -- Destructive
	[41377] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2, yellow = 1 } }, -- Impassive
	[41333] = { maxLevel = true, color = "meta", stats = { spellPower = 25 }, requires = { red = 3 } }, -- Ember
	[41335] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2, yellow = 1 } }, -- Enigmatic
	[41396] = { maxLevel = true, color = "meta", stats = { defenseRating = 21 }, requires = { blue = 2 } }, -- Eternal
	[41378] = { maxLevel = true, color = "meta", stats = { spellPower = 25 }, requires = { yellow = 2, red = 1 } }, -- Forlorn
	[41379] = { maxLevel = true, color = "meta", stats = {}, requires = { yellow = 2 } }, -- Mystical
	[41401] = { maxLevel = true, color = "meta", stats = { intellect = 21 }, requires = { red = 1, yellow = 1, blue = 1 } }, -- Insightful
	[41385] = { maxLevel = true, color = "meta", stats = { attackPower = 42 }, requires = { blue = 2 } }, -- Invigorating
	[41381] = { maxLevel = true, color = "meta", stats = { attackPower = 42 }, requires = { yellow = 2, blue = 1 } }, -- Persistent
	[41397] = { maxLevel = true, color = "meta", stats = { stamina = 32 }, requires = { blue = 2 } }, -- Powerful
	[41398] = { maxLevel = true, color = "meta", stats = { agility = 21 }, requires = { red = 1, yellow = 1, blue = 1 } }, -- Relentless
	[41376] = { maxLevel = true, color = "meta", stats = { spellPower = 25 }, requires = { red = 2 } }, -- Revitalizing
	[41339] = { maxLevel = true, color = "meta", stats = { attackPower = 42 }, requires = { yellow = 2, red = 1 } }, -- Swift
	[41400] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 1, yellow = 1, blue = 1 } }, -- Thundering
	[41375] = { maxLevel = true, color = "meta", stats = { spellPower = 25 }, requires = { red = 1, yellow = 1, blue = 1 } }, -- Tireless
	[41382] = { maxLevel = true, color = "meta", stats = { spellPower = 21 }, requires = { red = 1, yellow = 1, blue = 1 } }, -- Trenchant
	-- Prismatic
	[49110] = { maxLevel = true, color = "prismatic", stats = { strength = 10, agility = 10, stamina = 10, intellect = 10, spirit = 10 } },
	-- Sample epic reds / yellows / blues (ICC cut) — enough for maxLevel checks
	[40111] = { maxLevel = true, color = "red", stats = { strength = 20 } },
	[40112] = { maxLevel = true, color = "red", stats = { agility = 20 } },
	[40113] = { maxLevel = true, color = "red", stats = { spellPower = 23 } },
	[40114] = { maxLevel = true, color = "red", stats = { attackPower = 40 } },
	[40115] = { maxLevel = true, color = "red", stats = { expertiseRating = 20 } },
	[40116] = { maxLevel = true, color = "red", stats = { parryRating = 20 } },
	[40117] = { maxLevel = true, color = "red", stats = { armorPenetration = 20 } },
	[40118] = { maxLevel = true, color = "red", stats = { hitRating = 20 } },
	[40119] = { maxLevel = true, color = "blue", stats = { stamina = 30 } },
	[40120] = { maxLevel = true, color = "blue", stats = { spirit = 20 } },
	[40121] = { maxLevel = true, color = "blue", stats = { mp5 = 10 } },
	[40122] = { maxLevel = true, color = "blue", stats = { spellPenetration = 25 } },
	[40123] = { maxLevel = true, color = "yellow", stats = { intellect = 20 } },
	[40124] = { maxLevel = true, color = "yellow", stats = { critRating = 20 } },
	[40125] = { maxLevel = true, color = "yellow", stats = { hitRating = 20 } },
	[40126] = { maxLevel = true, color = "yellow", stats = { defenseRating = 20 } },
	[40127] = { maxLevel = true, color = "yellow", stats = { resilience = 20 } },
	[40128] = { maxLevel = true, color = "yellow", stats = { hasteRating = 20 } },
}

function Addon:GetGearCheckEnchantInfo(enchantId)
	enchantId = tonumber(enchantId)
	if not enchantId or enchantId <= 0 then
		return nil
	end
	return ENCHANTS[enchantId]
end

function Addon:GetGearCheckGemInfo(itemId)
	itemId = tonumber(itemId)
	if not itemId or itemId <= 0 then
		return nil
	end
	return GEMS[itemId]
end

function Addon:IsGearCheckMaxLevelEnchant(enchantId)
	local info = self:GetGearCheckEnchantInfo(enchantId)
	return info and info.maxLevel == true
end

function Addon:IsGearCheckMaxLevelGem(itemId)
	local info = self:GetGearCheckGemInfo(itemId)
	return info and info.maxLevel == true
end
