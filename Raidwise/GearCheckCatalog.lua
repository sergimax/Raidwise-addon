-- Gear Check catalogs (seeded). Enchant ids are item-link enchant ids, not spell ids.
-- WotLK 3.3.5a surface lists; expand when new false positives appear.

local Addon = Raidwise

-- maxLevel: Northrend (or best-in-slot-ish) enchants. stats used for appropriateness only.
local ENCHANTS = {
	-- Chest
	[3832] = { name = "Powerful Stats", maxLevel = true, allStats = true, stats = { strength = 10, agility = 10, stamina = 10, intellect = 10, spirit = 10 } },
	[3297] = { name = "Super Health", maxLevel = true, stats = { } },
	[3245] = { name = "Exceptional Resilience", maxLevel = true, stats = { resilience = 20 } },
	[3252] = { name = "Super Stats", maxLevel = false, allStats = true, stats = { strength = 8, agility = 8, stamina = 8, intellect = 8, spirit = 8 } },
	[3233] = { name = "Mighty Health", maxLevel = false, stats = {} },
	[3236] = { name = "Greater Defense", maxLevel = false, stats = { defenseRating = 22 } },
	-- Cloak
	[3831] = { name = "Greater Speed", maxLevel = true, stats = { hasteRating = 23 } },
	[1099] = { name = "Major Agility", maxLevel = true, stats = { agility = 22 } },
	[3294] = { name = "Mighty Armor", maxLevel = true, stats = { armor = 225 } },
	[3296] = { name = "Wisdom", maxLevel = true, stats = { spirit = 10 } },
	[1951] = { name = "Titanweave", maxLevel = true, stats = { defenseRating = 16 } },
	[3243] = { name = "Spell Penetration", maxLevel = false, stats = { spellPenetration = 35 } },
	[3825] = { name = "Speed", maxLevel = false, stats = { hasteRating = 15 } },
	-- Boots
	[3232] = { name = "Tuskarr's Vitality", maxLevel = true, stats = { stamina = 15 } },
	[1075] = { name = "Greater Fortitude", maxLevel = true, stats = { stamina = 22 } },
	[3826] = { name = "Icewalker", maxLevel = true, stats = { hitRating = 12, critRating = 12 } },
	[1597] = { name = "Greater Assault", maxLevel = true, stats = { attackPower = 32 } },
	[1147] = { name = "Greater Spirit", maxLevel = true, stats = { spirit = 18 } },
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
	[3253] = { name = "Armsman", maxLevel = true, stats = { expertiseRating = 10 } },
	[3222] = { name = "Major Agility", maxLevel = false, stats = { agility = 20 } },
	-- Weapon
	[3789] = { name = "Berserking", maxLevel = true, stats = {} },
	[3827] = { name = "Massacre", maxLevel = true, stats = {} },
	[3833] = { name = "Superior Potency", maxLevel = true, stats = { attackPower = 65 } },
	[3834] = { name = "Mighty Spellpower", maxLevel = true, stats = { spellPower = 63 } },
	[3854] = { name = "Greater Spellpower (staff)", maxLevel = true, stats = { spellPower = 81 } },
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
	[1071] = { name = "Major Stamina", maxLevel = true, stats = { stamina = 18 } },
	[1952] = { name = "Defense", maxLevel = true, stats = { defenseRating = 20 } },
	[1128] = { name = "Greater Intellect", maxLevel = true, stats = { intellect = 25 } },
	-- Legs (LW kits + Tailoring spellthread; profession permanent reinforcements share stats)
	[3325] = { name = "Jormungar Leg Reinforcements", maxLevel = true, stats = { stamina = 55, agility = 22 } },
	[3326] = { name = "Nerubian Leg Reinforcements", maxLevel = true, stats = { attackPower = 75, critRating = 22 } },
	[3327] = { name = "Jormungar Leg Reinforcements", maxLevel = true, stats = { stamina = 55, agility = 22 } },
	[3328] = { name = "Nerubian Leg Armor", maxLevel = false, stats = { attackPower = 55, critRating = 15 } },
	[3822] = { name = "Frosthide Leg Armor", maxLevel = true, stats = { stamina = 55, agility = 22 } },
	[3823] = { name = "Icescale Leg Armor", maxLevel = true, stats = { attackPower = 75, critRating = 22 } },
	[3853] = { name = "Earthen Leg Armor", maxLevel = true, stats = { stamina = 40, resilience = 28 } },
	[3719] = { name = "Brilliant Spellthread", maxLevel = true, stats = { spellPower = 50, spirit = 20 } },
	[3720] = { name = "Azure Spellthread", maxLevel = false, stats = { spellPower = 35, spirit = 12 } },
	[3721] = { name = "Sapphire Spellthread", maxLevel = true, stats = { spellPower = 50, stamina = 30 } },
	-- Engineering tinkers (appear as permanent enchantId on 3.3.5a links)
	[3603] = { name = "Hand-Mounted Pyro Rocket", maxLevel = true, stats = {} },
	[3604] = { name = "Hyperspeed Accelerators", maxLevel = true, stats = {} },
	[3605] = { name = "Flexweave Underlay", maxLevel = true, stats = {} },
	-- Some 3.3.5a clients / realms report Flexweave as 3859 on the item link.
	-- +23 agi is secondary to the parachute; do not ENCHANT_BAD_STAT from it (all specs use engi cloaks).
	[3859] = { name = "Flexweave Underlay", maxLevel = true, stats = {} },
	[3606] = { name = "Nitro Boosts", maxLevel = true, stats = { critRating = 24 } },
	[3601] = { name = "Frag Belt", maxLevel = true, stats = {} },
	[3860] = { name = "Reticulated Armor Webbing", maxLevel = true, stats = { armor = 885 } },
	-- Extra weapon enchants (melee / caster commons)
	[2673] = { name = "Mongoose", maxLevel = true, stats = {} },
	[3225] = { name = "Executioner", maxLevel = true, stats = {} },
	[3790] = { name = "Black Magic", maxLevel = true, stats = {} },
	[3788] = { name = "Accuracy", maxLevel = true, stats = { hitRating = 25, critRating = 25 } },
	[3869] = { name = "Blade Ward", maxLevel = true, stats = {} },
	[3870] = { name = "Blood Draining", maxLevel = true, stats = {} },
	[3731] = { name = "Titanium Weapon Chain", maxLevel = true, stats = { hitRating = 28 } },
	[3241] = { name = "Lifeward", maxLevel = true, stats = {} },
	[3239] = { name = "Icebreaker", maxLevel = true, stats = {} },
	[3251] = { name = "Giant Slayer", maxLevel = false, stats = {} },
	[1606] = { name = "Greater Potency", maxLevel = false, stats = { attackPower = 50 } },
	[3830] = { name = "Exceptional Spellpower", maxLevel = false, stats = { spellPower = 50 } },
	[3844] = { name = "Exceptional Spirit", maxLevel = true, stats = { spirit = 45 } },
	[1103] = { name = "Exceptional Agility", maxLevel = false, stats = { agility = 26 } },
	-- Rings
	[3839] = { name = "Assault", maxLevel = true, stats = { attackPower = 40 } },
	[3840] = { name = "Greater Spellpower", maxLevel = true, stats = { spellPower = 23 } },
	[3791] = { name = "Stamina", maxLevel = true, stats = { stamina = 30 } },
	-- Head / shoulder (arcanum / inscription) — common ids
	[3820] = { name = "Arcanum of Burning Mysteries", maxLevel = true, stats = { spellPower = 30, critRating = 20 } },
	[3819] = { name = "Arcanum of Blissful Mending", maxLevel = true, stats = { spellPower = 30, mp5 = 10 } },
	[3818] = { name = "Arcanum of the Stalwart Protector", maxLevel = true, stats = { stamina = 37, defenseRating = 20 } },
	[3817] = { name = "Arcanum of Torment", maxLevel = true, stats = { attackPower = 50, critRating = 20 } },
	[3815] = { name = "Arcanum of the Fleeing Shadow", maxLevel = true, stats = { spellPower = 30 } },
	[3816] = { name = "Arcanum of the Savage Gladiator", maxLevel = true, stats = { stamina = 30, resilience = 25 } },
	[3808] = { name = "Greater Inscription of the Axe", maxLevel = true, stats = { attackPower = 40, critRating = 15 } },
	[3809] = { name = "Greater Inscription of the Crag", maxLevel = true, stats = { spellPower = 24, mp5 = 8 } },
	[3810] = { name = "Greater Inscription of the Storm", maxLevel = true, stats = { spellPower = 24, critRating = 15 } },
	[3811] = { name = "Greater Inscription of the Pinnacle", maxLevel = true, stats = { dodgeRating = 20, defenseRating = 15 } },
	[3875] = { name = "Greater Inscription of the Axe", maxLevel = false, stats = { attackPower = 30, critRating = 10 } },
	[3876] = { name = "Greater Inscription of the Crag", maxLevel = false, stats = { spellPower = 18, mp5 = 5 } },
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
	[49110] = { maxLevel = true, color = "prismatic", allStats = true, stats = { strength = 10, agility = 10, stamina = 10, intellect = 10, spirit = 10 } },
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
	-- Epic purple (Dreadstone)
	[40129] = { maxLevel = true, color = "purple", stats = { strength = 10, stamina = 15 } },
	[40130] = { maxLevel = true, color = "purple", stats = { agility = 10, stamina = 15 } },
	[40131] = { maxLevel = true, color = "purple", stats = { parryRating = 10, stamina = 15 } },
	[40132] = { maxLevel = true, color = "purple", stats = { spellPower = 12, stamina = 15 } },
	[40133] = { maxLevel = true, color = "purple", stats = { spellPower = 12, spirit = 10 } },
	[40134] = { maxLevel = true, color = "purple", stats = { attackPower = 20, stamina = 15 } },
	[40135] = { maxLevel = true, color = "purple", stats = { hitRating = 10, stamina = 15 } },
	[40136] = { maxLevel = true, color = "purple", stats = { expertiseRating = 10, stamina = 15 } },
	[40137] = { maxLevel = true, color = "purple", stats = { armorPenetration = 10, stamina = 15 } },
	[40138] = { maxLevel = true, color = "purple", stats = { dodgeRating = 10, stamina = 15 } },
	[40139] = { maxLevel = true, color = "purple", stats = { parryRating = 10, dodgeRating = 10 } },
	[40140] = { maxLevel = true, color = "purple", stats = { armorPenetration = 10, hitRating = 10 } },
	[40141] = { maxLevel = true, color = "purple", stats = { expertiseRating = 10, hitRating = 10 } },
	-- Epic orange (Ametrine)
	[40142] = { maxLevel = true, color = "orange", stats = { strength = 10, critRating = 10 } },
	[40143] = { maxLevel = true, color = "orange", stats = { strength = 10, hitRating = 10 } },
	[40144] = { maxLevel = true, color = "orange", stats = { strength = 10, defenseRating = 10 } },
	[40145] = { maxLevel = true, color = "orange", stats = { strength = 10, resilience = 10 } },
	[40146] = { maxLevel = true, color = "orange", stats = { strength = 10, hasteRating = 10 } },
	[40147] = { maxLevel = true, color = "orange", stats = { agility = 10, critRating = 10 } },
	[40148] = { maxLevel = true, color = "orange", stats = { agility = 10, hitRating = 10 } },
	[40149] = { maxLevel = true, color = "orange", stats = { spellPower = 12, hasteRating = 10 } },
	[40150] = { maxLevel = true, color = "orange", stats = { attackPower = 20, hasteRating = 10 } },
	[40152] = { maxLevel = true, color = "orange", stats = { spellPower = 12, intellect = 10 } },
	[40153] = { maxLevel = true, color = "orange", stats = { attackPower = 20, hitRating = 10 } },
	[40154] = { maxLevel = true, color = "orange", stats = { spellPower = 12, resilience = 10 } },
	[40155] = { maxLevel = true, color = "orange", stats = { spellPower = 12, hasteRating = 10 } }, -- Reckless
	[40157] = { maxLevel = true, color = "orange", stats = { attackPower = 20, critRating = 10 } },
	[40158] = { maxLevel = true, color = "orange", stats = { attackPower = 20, expertiseRating = 10 } },
	[40159] = { maxLevel = true, color = "orange", stats = { agility = 10, hasteRating = 10 } },
	[40160] = { maxLevel = true, color = "orange", stats = { dodgeRating = 10, defenseRating = 10 } },
	[40161] = { maxLevel = true, color = "orange", stats = { parryRating = 10, defenseRating = 10 } },
	[40162] = { maxLevel = true, color = "orange", stats = { expertiseRating = 10, hitRating = 10 } },
	[40163] = { maxLevel = true, color = "orange", stats = { expertiseRating = 10, defenseRating = 10 } },
	-- Epic green (Eye of Zul)
	[40164] = { maxLevel = true, color = "green", stats = { intellect = 10, stamina = 15 } },
	[40165] = { maxLevel = true, color = "green", stats = { critRating = 10, stamina = 15 } },
	[40166] = { maxLevel = true, color = "green", stats = { hitRating = 10, stamina = 15 } },
	[40167] = { maxLevel = true, color = "green", stats = { defenseRating = 10, stamina = 15 } },
	[40168] = { maxLevel = true, color = "green", stats = { resilience = 10, stamina = 15 } },
	[40169] = { maxLevel = true, color = "green", stats = { hasteRating = 10, stamina = 15 } },
	[40170] = { maxLevel = true, color = "green", stats = { intellect = 10, spirit = 10 } },
	[40171] = { maxLevel = true, color = "green", stats = { intellect = 10, hasteRating = 10 } },
	[40172] = { maxLevel = true, color = "green", stats = { hitRating = 10, spirit = 10 } },
	[40173] = { maxLevel = true, color = "green", stats = { spirit = 10, stamina = 15 } },
	[40174] = { maxLevel = true, color = "green", stats = { hasteRating = 10, spirit = 10 } },
	[40175] = { maxLevel = true, color = "green", stats = { intellect = 10, mp5 = 5 } },
	[40176] = { maxLevel = true, color = "green", stats = { critRating = 10, mp5 = 5 } },
	[40177] = { maxLevel = true, color = "green", stats = { hitRating = 10, mp5 = 5 } },
	[40178] = { maxLevel = true, color = "green", stats = { resilience = 10, mp5 = 5 } },
	[40179] = { maxLevel = true, color = "green", stats = { hasteRating = 10, mp5 = 5 } },
	[40180] = { maxLevel = true, color = "green", stats = { critRating = 10, spellPenetration = 13 } },
	[40181] = { maxLevel = true, color = "green", stats = { hitRating = 10, spellPenetration = 13 } },
	[40182] = { maxLevel = true, color = "green", stats = { hasteRating = 10, spellPenetration = 13 } },
	-- Rare Northrend (maxLevel false) — samples for lower-level soft checks
	[39996] = { maxLevel = false, color = "red", stats = { strength = 16 } },
	[39997] = { maxLevel = false, color = "red", stats = { agility = 16 } },
	[40000] = { maxLevel = false, color = "red", stats = { attackPower = 32 } },
	-- Jewelcrafting Dragon's Eye (Unique-Equipped: Jeweler's Gems ×3; JC-only).
	[42142] = { maxLevel = true, color = "red", jcUnique = true, stats = { strength = 34 } }, -- Bold
	[36766] = { maxLevel = true, color = "red", jcUnique = true, stats = { attackPower = 68 } }, -- Bright
	[42148] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { intellect = 34 } }, -- Brilliant
	[42143] = { maxLevel = true, color = "red", jcUnique = true, stats = { agility = 34 } }, -- Delicate
	[42152] = { maxLevel = true, color = "red", jcUnique = true, stats = { parryRating = 34 } }, -- Flashing
	[42153] = { maxLevel = true, color = "red", jcUnique = true, stats = { armorPenetration = 34 } }, -- Fractured
	[42146] = { maxLevel = true, color = "blue", jcUnique = true, stats = { mp5 = 17 } }, -- Lustrous
	[42158] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { resilience = 34 } }, -- Mystic
	[42154] = { maxLevel = true, color = "red", jcUnique = true, stats = { expertiseRating = 34 } }, -- Precise
	[42150] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { hasteRating = 34 } }, -- Quick
	[42156] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { hitRating = 34 } }, -- Rigid
	[42144] = { maxLevel = true, color = "red", jcUnique = true, stats = { spellPower = 39 } }, -- Runed
	[42149] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { critRating = 34 } }, -- Smooth
	[36767] = { maxLevel = true, color = "blue", jcUnique = true, stats = { stamina = 51 } }, -- Solid
	[42145] = { maxLevel = true, color = "blue", jcUnique = true, stats = { spirit = 34 } }, -- Sparkling
	[42155] = { maxLevel = true, color = "blue", jcUnique = true, stats = { spellPenetration = 43 } }, -- Stormy
	[42151] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { dodgeRating = 34 } }, -- Subtle
	[42157] = { maxLevel = true, color = "yellow", jcUnique = true, stats = { defenseRating = 34 } }, -- Thick
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
