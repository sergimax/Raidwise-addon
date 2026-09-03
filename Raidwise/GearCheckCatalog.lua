-- Gear Check catalogs (seeded). Enchant ids are item-link enchant ids, not spell ids.
-- WotLK 3.3.5a surface lists; expand when new false positives appear.

local Addon = Raidwise

-- Bump when enchant/gem catalog seeds change materially (saved report dataVersion).
Addon.GEAR_CHECK_DATA_VERSION = "catalog-2026-09-03"

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
	-- Tailoring cloak embroideries (profession-bound)
	[3722] = { name = "Lightweave Embroidery", maxLevel = true, stats = {} },
	[3728] = { name = "Darkglow Embroidery", maxLevel = true, stats = {} },
	[3730] = { name = "Swordguard Embroidery", maxLevel = true, stats = {} },
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
	-- Tailoring permanent profession spellthreads (same stats as consumable kits above)
	[3872] = { name = "Sanctified Spellthread", maxLevel = true, stats = { spellPower = 50, spirit = 20 } },
	[3873] = { name = "Master's Spellthread", maxLevel = true, stats = { spellPower = 50, stamina = 30 } },
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
	-- Spellsurge (BC): mana-restore proc; accepted healer weapon enchant (empty stats = no BAD_STAT).
	[2674] = { name = "Spellsurge", maxLevel = true, stats = {} },
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
	-- Inscription profession shoulder enchants (Master's)
	[3835] = { name = "Master's Inscription of the Axe", maxLevel = true, stats = { attackPower = 120, critRating = 15 } },
	[3836] = { name = "Master's Inscription of the Crag", maxLevel = true, stats = { spellPower = 70, mp5 = 8 } },
	[3837] = { name = "Master's Inscription of the Pinnacle", maxLevel = true, stats = { dodgeRating = 60, defenseRating = 15 } },
	[3838] = { name = "Master's Inscription of the Storm", maxLevel = true, stats = { spellPower = 70, critRating = 15 } },
	-- Leatherworking Fur Lining (bracers, profession-bound)
	[3756] = { name = "Fur Lining - Attack Power", maxLevel = true, stats = { attackPower = 130 } },
	[3757] = { name = "Fur Lining - Stamina", maxLevel = true, stats = { stamina = 102 } },
	[3758] = { name = "Fur Lining - Spell Power", maxLevel = true, stats = { spellPower = 76 } },
}

-- Northrend epic (and Nightmare Tear) gems. maxLevel = true means ICC-era epic quality.
local GEMS = {
	-- Meta (Earthsiege / Skyflare). requires = gem colors across the full set (not the meta itself).
	[41380] = { maxLevel = true, color = "meta", stats = {}, requires = { blue = 2 } }, -- Austere
	[41389] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2, yellow = 1 } }, -- Beaming
	[41395] = { maxLevel = true, color = "meta", stats = { spellPower = 21 }, requires = { red = 2 } }, -- Bracing
	[41285] = { maxLevel = true, color = "meta", stats = { critRating = 21 }, requires = { blue = 2 } }, -- Chaotic
	[41307] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2 } }, -- Destructive
	[41377] = { maxLevel = true, color = "meta", stats = { stamina = 32 }, requires = { blue = 2, red = 1 } }, -- Effulgent (later Shielded)
	[41333] = { maxLevel = true, color = "meta", stats = { spellPower = 25 }, requires = { red = 3 } }, -- Ember
	[41335] = { maxLevel = true, color = "meta", stats = {}, requires = { red = 2, yellow = 1 } }, -- Enigmatic
	[41396] = { maxLevel = true, color = "meta", stats = { defenseRating = 21 }, requires = { blue = 2 } }, -- Eternal
	[41378] = { maxLevel = true, color = "meta", stats = { spellPower = 25 }, requires = { yellow = 2, red = 1 } }, -- Forlorn
	[41379] = { maxLevel = true, color = "meta", stats = { critRating = 21 }, requires = { red = 2, blue = 1 } }, -- Impassive
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
	-- Epic red (Cardinal Ruby) / blue (Majestic Zircon) / yellow (King's Amber)
	[40111] = { maxLevel = true, color = "red", stats = { strength = 20 } }, -- Bold
	[40112] = { maxLevel = true, color = "red", stats = { agility = 20 } }, -- Delicate
	[40113] = { maxLevel = true, color = "red", stats = { spellPower = 23 } }, -- Runed
	[40114] = { maxLevel = true, color = "red", stats = { attackPower = 40 } }, -- Bright
	[40115] = { maxLevel = true, color = "red", stats = { dodgeRating = 20 } }, -- Subtle
	[40116] = { maxLevel = true, color = "red", stats = { parryRating = 20 } }, -- Flashing
	[40117] = { maxLevel = true, color = "red", stats = { armorPenetration = 20 } }, -- Fractured
	[40118] = { maxLevel = true, color = "red", stats = { expertiseRating = 20 } }, -- Precise
	[40119] = { maxLevel = true, color = "blue", stats = { stamina = 30 } }, -- Solid
	[40120] = { maxLevel = true, color = "blue", stats = { spirit = 20 } }, -- Sparkling
	[40121] = { maxLevel = true, color = "blue", stats = { mp5 = 10 } }, -- Lustrous
	[40122] = { maxLevel = true, color = "blue", stats = { spellPenetration = 25 } }, -- Stormy
	[40123] = { maxLevel = true, color = "yellow", stats = { intellect = 20 } }, -- Brilliant
	[40124] = { maxLevel = true, color = "yellow", stats = { critRating = 20 } }, -- Smooth
	[40125] = { maxLevel = true, color = "yellow", stats = { hitRating = 20 } }, -- Rigid
	[40126] = { maxLevel = true, color = "yellow", stats = { defenseRating = 20 } }, -- Thick
	[40127] = { maxLevel = true, color = "yellow", stats = { resilience = 20 } }, -- Mystic
	[40128] = { maxLevel = true, color = "yellow", stats = { hasteRating = 20 } }, -- Quick
	-- Epic Stormjewel (Dalaran fishing dailies; same stats as Cardinal Ruby / King's Amber / Majestic Zircon)
	[45862] = { maxLevel = true, color = "red", stats = { strength = 20 } }, -- Bold
	[45879] = { maxLevel = true, color = "red", stats = { agility = 20 } }, -- Delicate
	[45883] = { maxLevel = true, color = "red", stats = { spellPower = 23 } }, -- Runed
	[45882] = { maxLevel = true, color = "yellow", stats = { intellect = 20 } }, -- Brilliant
	[45987] = { maxLevel = true, color = "yellow", stats = { hitRating = 20 } }, -- Rigid
	[45880] = { maxLevel = true, color = "blue", stats = { stamina = 30 } }, -- Solid
	[45881] = { maxLevel = true, color = "blue", stats = { spirit = 20 } }, -- Sparkling
	-- Epic purple (Dreadstone) — ids verified vs WotLK tooltips
	[40129] = { maxLevel = true, color = "purple", stats = { strength = 10, stamina = 15 } }, -- Sovereign
	[40130] = { maxLevel = true, color = "purple", stats = { agility = 10, stamina = 15 } }, -- Shifting
	[40131] = { maxLevel = true, color = "purple", stats = { agility = 10, mp5 = 5 } }, -- Tenuous
	[40132] = { maxLevel = true, color = "purple", stats = { spellPower = 12, stamina = 15 } }, -- Glowing
	[40133] = { maxLevel = true, color = "purple", stats = { spellPower = 12, spirit = 10 } }, -- Purified
	[40134] = { maxLevel = true, color = "purple", stats = { spellPower = 12, mp5 = 5 } }, -- Royal
	[40135] = { maxLevel = true, color = "purple", stats = { spellPower = 12, spellPenetration = 13 } }, -- Mysterious
	[40136] = { maxLevel = true, color = "purple", stats = { attackPower = 20, stamina = 15 } }, -- Balanced
	[40137] = { maxLevel = true, color = "purple", stats = { attackPower = 20, mp5 = 5 } }, -- Infused
	[40138] = { maxLevel = true, color = "purple", stats = { dodgeRating = 10, stamina = 15 } }, -- Regal
	[40139] = { maxLevel = true, color = "purple", stats = { parryRating = 10, stamina = 15 } }, -- Defender's
	[40140] = { maxLevel = true, color = "purple", stats = { armorPenetration = 10, stamina = 15 } }, -- Puissant
	[40141] = { maxLevel = true, color = "purple", stats = { expertiseRating = 10, stamina = 15 } }, -- Guardian's
	-- Epic orange (Ametrine) — ids verified vs WotLK tooltips
	[40142] = { maxLevel = true, color = "orange", stats = { strength = 10, critRating = 10 } }, -- Inscribed
	[40143] = { maxLevel = true, color = "orange", stats = { strength = 10, hitRating = 10 } }, -- Etched
	[40144] = { maxLevel = true, color = "orange", stats = { strength = 10, defenseRating = 10 } }, -- Champion's
	[40145] = { maxLevel = true, color = "orange", stats = { strength = 10, resilience = 10 } }, -- Resplendent
	[40146] = { maxLevel = true, color = "orange", stats = { strength = 10, hasteRating = 10 } }, -- Fierce
	[40147] = { maxLevel = true, color = "orange", stats = { agility = 10, critRating = 10 } }, -- Deadly
	[40148] = { maxLevel = true, color = "orange", stats = { agility = 10, hitRating = 10 } }, -- Glinting
	[40149] = { maxLevel = true, color = "orange", stats = { agility = 10, resilience = 10 } }, -- Lucent
	[40150] = { maxLevel = true, color = "orange", stats = { agility = 10, hasteRating = 10 } }, -- Deft
	[40151] = { maxLevel = true, color = "orange", stats = { spellPower = 12, intellect = 10 } }, -- Luminous
	[40152] = { maxLevel = true, color = "orange", stats = { spellPower = 12, critRating = 10 } }, -- Potent
	[40153] = { maxLevel = true, color = "orange", stats = { spellPower = 12, hitRating = 10 } }, -- Veiled
	[40154] = { maxLevel = true, color = "orange", stats = { spellPower = 12, resilience = 10 } }, -- Durable
	[40155] = { maxLevel = true, color = "orange", stats = { spellPower = 12, hasteRating = 10 } }, -- Reckless
	[40156] = { maxLevel = true, color = "orange", stats = { attackPower = 20, critRating = 10 } }, -- Wicked
	[40157] = { maxLevel = true, color = "orange", stats = { attackPower = 20, hitRating = 10 } }, -- Pristine
	[40158] = { maxLevel = true, color = "orange", stats = { attackPower = 20, resilience = 10 } }, -- Empowered
	[40159] = { maxLevel = true, color = "orange", stats = { attackPower = 20, hasteRating = 10 } }, -- Stark
	[40160] = { maxLevel = true, color = "orange", stats = { dodgeRating = 10, defenseRating = 10 } }, -- Stalwart
	[40161] = { maxLevel = true, color = "orange", stats = { parryRating = 10, defenseRating = 10 } }, -- Glimmering
	[40162] = { maxLevel = true, color = "orange", stats = { expertiseRating = 10, hitRating = 10 } }, -- Accurate
	[40163] = { maxLevel = true, color = "orange", stats = { expertiseRating = 10, defenseRating = 10 } }, -- Resolute
	-- Epic green (Eye of Zul) — ids verified vs WotLK tooltips
	[40164] = { maxLevel = true, color = "green", stats = { intellect = 10, stamina = 15 } }, -- Timeless
	[40165] = { maxLevel = true, color = "green", stats = { critRating = 10, stamina = 15 } }, -- Jagged
	[40166] = { maxLevel = true, color = "green", stats = { hitRating = 10, stamina = 15 } }, -- Vivid
	[40167] = { maxLevel = true, color = "green", stats = { defenseRating = 10, stamina = 15 } }, -- Enduring
	[40168] = { maxLevel = true, color = "green", stats = { resilience = 10, stamina = 15 } }, -- Steady
	[40169] = { maxLevel = true, color = "green", stats = { hasteRating = 10, stamina = 15 } }, -- Forceful
	[40170] = { maxLevel = true, color = "green", stats = { intellect = 10, spirit = 10 } }, -- Seer's
	[40171] = { maxLevel = true, color = "green", stats = { critRating = 10, spirit = 10 } }, -- Misty
	[40172] = { maxLevel = true, color = "green", stats = { hitRating = 10, spirit = 10 } }, -- Shining
	[40173] = { maxLevel = true, color = "green", stats = { resilience = 10, spirit = 10 } }, -- Turbid
	[40174] = { maxLevel = true, color = "green", stats = { hasteRating = 10, spirit = 10 } }, -- Intricate
	[40175] = { maxLevel = true, color = "green", stats = { intellect = 10, mp5 = 5 } }, -- Dazzling
	[40176] = { maxLevel = true, color = "green", stats = { critRating = 10, mp5 = 5 } }, -- Sundered
	[40177] = { maxLevel = true, color = "green", stats = { hitRating = 10, mp5 = 5 } }, -- Lambent
	[40178] = { maxLevel = true, color = "green", stats = { resilience = 10, mp5 = 5 } }, -- Opaque
	[40179] = { maxLevel = true, color = "green", stats = { hasteRating = 10, mp5 = 5 } }, -- Energized
	[40180] = { maxLevel = true, color = "green", stats = { critRating = 10, spellPenetration = 13 } }, -- Radiant
	[40181] = { maxLevel = true, color = "green", stats = { hitRating = 10, spellPenetration = 13 } }, -- Tense
	[40182] = { maxLevel = true, color = "green", stats = { hasteRating = 10, spellPenetration = 13 } }, -- Shattered
	-- Uncommon Northrend (maxLevel false) — tooltip-verified Bloodstone/Sun/Chalcedony/Citrine/Shadow/Dark Jade
	[39900] = { maxLevel = false, color = "red", stats = { strength = 12 } }, -- Bold Bloodstone
	[39905] = { maxLevel = false, color = "red", stats = { agility = 12 } }, -- Delicate Bloodstone
	[39906] = { maxLevel = false, color = "red", stats = { attackPower = 24 } }, -- Bright Bloodstone
	[39907] = { maxLevel = false, color = "red", stats = { dodgeRating = 12 } }, -- Subtle Bloodstone
	[39908] = { maxLevel = false, color = "red", stats = { parryRating = 12 } }, -- Flashing Bloodstone
	[39909] = { maxLevel = false, color = "red", stats = { armorPenetration = 12 } }, -- Fractured Bloodstone
	[39910] = { maxLevel = false, color = "red", stats = { expertiseRating = 12 } }, -- Precise Bloodstone
	[39911] = { maxLevel = false, color = "red", stats = { spellPower = 14 } }, -- Runed Bloodstone
	[39912] = { maxLevel = false, color = "yellow", stats = { intellect = 12 } }, -- Brilliant Sun Crystal
	[39914] = { maxLevel = false, color = "yellow", stats = { critRating = 12 } }, -- Smooth Sun Crystal
	[39915] = { maxLevel = false, color = "yellow", stats = { hitRating = 12 } }, -- Rigid Sun Crystal
	[39916] = { maxLevel = false, color = "yellow", stats = { defenseRating = 12 } }, -- Thick Sun Crystal
	[39917] = { maxLevel = false, color = "yellow", stats = { resilience = 12 } }, -- Mystic Sun Crystal
	[39918] = { maxLevel = false, color = "yellow", stats = { hasteRating = 12 } }, -- Quick Sun Crystal
	[39919] = { maxLevel = false, color = "blue", stats = { stamina = 18 } }, -- Solid Chalcedony
	[39920] = { maxLevel = false, color = "blue", stats = { spirit = 12 } }, -- Sparkling Chalcedony
	[39927] = { maxLevel = false, color = "blue", stats = { mp5 = 6 } }, -- Lustrous Chalcedony
	[39932] = { maxLevel = false, color = "blue", stats = { spellPenetration = 15 } }, -- Stormy Chalcedony
	[39933] = { maxLevel = false, color = "purple", stats = { armorPenetration = 6, stamina = 9 } }, -- Puissant Shadow Crystal
	[39934] = { maxLevel = false, color = "purple", stats = { strength = 6, stamina = 9 } }, -- Sovereign Shadow Crystal
	[39935] = { maxLevel = false, color = "purple", stats = { agility = 6, stamina = 9 } }, -- Shifting Shadow Crystal
	[39936] = { maxLevel = false, color = "purple", stats = { spellPower = 7, stamina = 9 } }, -- Glowing Shadow Crystal
	[39937] = { maxLevel = false, color = "purple", stats = { attackPower = 12, stamina = 9 } }, -- Balanced Shadow Crystal
	[39938] = { maxLevel = false, color = "purple", stats = { dodgeRating = 6, stamina = 9 } }, -- Regal Shadow Crystal
	[39939] = { maxLevel = false, color = "purple", stats = { parryRating = 6, stamina = 9 } }, -- Defender's Shadow Crystal
	[39940] = { maxLevel = false, color = "purple", stats = { expertiseRating = 6, stamina = 9 } }, -- Guardian's Shadow Crystal
	[39941] = { maxLevel = false, color = "purple", stats = { spellPower = 7, spirit = 6 } }, -- Purified Shadow Crystal
	[39942] = { maxLevel = false, color = "purple", stats = { agility = 6, mp5 = 3 } }, -- Tenuous Shadow Crystal
	[39943] = { maxLevel = false, color = "purple", stats = { spellPower = 7, mp5 = 3 } }, -- Royal Shadow Crystal
	[39944] = { maxLevel = false, color = "purple", stats = { attackPower = 12, mp5 = 3 } }, -- Infused Shadow Crystal
	[39945] = { maxLevel = false, color = "purple", stats = { spellPower = 7, spellPenetration = 8 } }, -- Mysterious Shadow Crystal
	[39946] = { maxLevel = false, color = "orange", stats = { spellPower = 7, intellect = 6 } }, -- Luminous Huge Citrine
	[39947] = { maxLevel = false, color = "orange", stats = { strength = 6, critRating = 6 } }, -- Inscribed Huge Citrine
	[39948] = { maxLevel = false, color = "orange", stats = { strength = 6, hitRating = 6 } }, -- Etched Huge Citrine
	[39949] = { maxLevel = false, color = "orange", stats = { strength = 6, defenseRating = 6 } }, -- Champion's Huge Citrine
	[39950] = { maxLevel = false, color = "orange", stats = { strength = 6, resilience = 6 } }, -- Resplendent Huge Citrine
	[39951] = { maxLevel = false, color = "orange", stats = { strength = 6, hasteRating = 6 } }, -- Fierce Huge Citrine
	[39952] = { maxLevel = false, color = "orange", stats = { agility = 6, critRating = 6 } }, -- Deadly Huge Citrine
	[39953] = { maxLevel = false, color = "orange", stats = { agility = 6, hitRating = 6 } }, -- Glinting Huge Citrine
	[39954] = { maxLevel = false, color = "orange", stats = { agility = 6, resilience = 6 } }, -- Lucent Huge Citrine
	[39955] = { maxLevel = false, color = "orange", stats = { agility = 6, hasteRating = 6 } }, -- Deft Huge Citrine
	[39956] = { maxLevel = false, color = "orange", stats = { spellPower = 7, critRating = 6 } }, -- Potent Huge Citrine
	[39957] = { maxLevel = false, color = "orange", stats = { spellPower = 7, hitRating = 6 } }, -- Veiled Huge Citrine
	[39958] = { maxLevel = false, color = "orange", stats = { spellPower = 7, resilience = 6 } }, -- Durable Huge Citrine
	[39959] = { maxLevel = false, color = "orange", stats = { spellPower = 7, hasteRating = 6 } }, -- Reckless Huge Citrine
	[39960] = { maxLevel = false, color = "orange", stats = { attackPower = 12, critRating = 6 } }, -- Wicked Huge Citrine
	[39961] = { maxLevel = false, color = "orange", stats = { attackPower = 12, hitRating = 6 } }, -- Pristine Huge Citrine
	[39962] = { maxLevel = false, color = "orange", stats = { attackPower = 12, resilience = 6 } }, -- Empowered Huge Citrine
	[39963] = { maxLevel = false, color = "orange", stats = { attackPower = 12, hasteRating = 6 } }, -- Stark Huge Citrine
	[39964] = { maxLevel = false, color = "orange", stats = { dodgeRating = 6, defenseRating = 6 } }, -- Stalwart Huge Citrine
	[39965] = { maxLevel = false, color = "orange", stats = { parryRating = 6, defenseRating = 6 } }, -- Glimmering Huge Citrine
	[39966] = { maxLevel = false, color = "orange", stats = { expertiseRating = 6, hitRating = 6 } }, -- Accurate Huge Citrine
	[39967] = { maxLevel = false, color = "orange", stats = { expertiseRating = 6, defenseRating = 6 } }, -- Resolute Huge Citrine
	[39968] = { maxLevel = false, color = "green", stats = { intellect = 6, stamina = 9 } }, -- Timeless Dark Jade
	[39974] = { maxLevel = false, color = "green", stats = { critRating = 6, stamina = 9 } }, -- Jagged Dark Jade
	[39975] = { maxLevel = false, color = "green", stats = { hitRating = 6, stamina = 9 } }, -- Vivid Dark Jade
	[39976] = { maxLevel = false, color = "green", stats = { defenseRating = 6, stamina = 9 } }, -- Enduring Dark Jade
	[39977] = { maxLevel = false, color = "green", stats = { resilience = 6, stamina = 9 } }, -- Steady Dark Jade
	[39978] = { maxLevel = false, color = "green", stats = { hasteRating = 6, stamina = 9 } }, -- Forceful Dark Jade
	[39979] = { maxLevel = false, color = "green", stats = { intellect = 6, spirit = 6 } }, -- Seer's Dark Jade
	[39980] = { maxLevel = false, color = "green", stats = { critRating = 6, spirit = 6 } }, -- Misty Dark Jade
	[39981] = { maxLevel = false, color = "green", stats = { hitRating = 6, spirit = 6 } }, -- Shining Dark Jade
	[39982] = { maxLevel = false, color = "green", stats = { resilience = 6, spirit = 6 } }, -- Turbid Dark Jade
	[39983] = { maxLevel = false, color = "green", stats = { hasteRating = 6, spirit = 6 } }, -- Intricate Dark Jade
	[39984] = { maxLevel = false, color = "green", stats = { intellect = 6, mp5 = 3 } }, -- Dazzling Dark Jade
	[39985] = { maxLevel = false, color = "green", stats = { critRating = 6, mp5 = 3 } }, -- Sundered Dark Jade
	[39986] = { maxLevel = false, color = "green", stats = { hitRating = 6, mp5 = 3 } }, -- Lambent Dark Jade
	[39988] = { maxLevel = false, color = "green", stats = { resilience = 6, mp5 = 3 } }, -- Opaque Dark Jade
	[39989] = { maxLevel = false, color = "green", stats = { hasteRating = 6, mp5 = 3 } }, -- Energized Dark Jade
	[39990] = { maxLevel = false, color = "green", stats = { critRating = 6, spellPenetration = 8 } }, -- Radiant Dark Jade
	[39991] = { maxLevel = false, color = "green", stats = { hitRating = 6, spellPenetration = 8 } }, -- Tense Dark Jade
	[39992] = { maxLevel = false, color = "green", stats = { hasteRating = 6, spellPenetration = 8 } }, -- Shattered Dark Jade
	-- Rare Northrend (maxLevel false) — full AtlasLoot Scarlet/Monarch/Twilight/Forest/Autumn/Sky set
	[39996] = { maxLevel = false, color = "red", stats = { strength = 16 } }, -- Bold Scarlet Ruby
	[39997] = { maxLevel = false, color = "red", stats = { agility = 16 } }, -- Delicate Scarlet Ruby
	[39998] = { maxLevel = false, color = "red", stats = { spellPower = 19 } }, -- Runed Scarlet Ruby
	[39999] = { maxLevel = false, color = "red", stats = { attackPower = 32 } }, -- Bright Scarlet Ruby
	[40000] = { maxLevel = false, color = "red", stats = { dodgeRating = 16 } }, -- Subtle Scarlet Ruby
	[40001] = { maxLevel = false, color = "red", stats = { parryRating = 16 } }, -- Flashing Scarlet Ruby
	[40002] = { maxLevel = false, color = "red", stats = { armorPenetration = 16 } }, -- Fractured Scarlet Ruby
	[40003] = { maxLevel = false, color = "red", stats = { expertiseRating = 16 } }, -- Precise Scarlet Ruby
	[40008] = { maxLevel = false, color = "blue", stats = { stamina = 24 } }, -- Solid Sky Sapphire
	[40009] = { maxLevel = false, color = "blue", stats = { spirit = 16 } }, -- Sparkling Sky Sapphire
	[40010] = { maxLevel = false, color = "blue", stats = { mp5 = 8 } }, -- Lustrous Sky Sapphire
	[40011] = { maxLevel = false, color = "blue", stats = { spellPenetration = 20 } }, -- Stormy Sky Sapphire
	[40012] = { maxLevel = false, color = "yellow", stats = { intellect = 16 } }, -- Brilliant Autumn's Glow
	[40013] = { maxLevel = false, color = "yellow", stats = { critRating = 16 } }, -- Smooth Autumn's Glow
	[40014] = { maxLevel = false, color = "yellow", stats = { hitRating = 16 } }, -- Rigid Autumn's Glow
	[40015] = { maxLevel = false, color = "yellow", stats = { defenseRating = 16 } }, -- Thick Autumn's Glow
	[40016] = { maxLevel = false, color = "yellow", stats = { resilience = 16 } }, -- Mystic Autumn's Glow
	[40017] = { maxLevel = false, color = "yellow", stats = { hasteRating = 16 } }, -- Quick Autumn's Glow
	[40022] = { maxLevel = false, color = "purple", stats = { strength = 8, stamina = 12 } }, -- Sovereign Twilight Opal
	[40023] = { maxLevel = false, color = "purple", stats = { agility = 8, stamina = 12 } }, -- Shifting Twilight Opal
	[40024] = { maxLevel = false, color = "purple", stats = { agility = 8, mp5 = 4 } }, -- Tenuous Twilight Opal
	[40025] = { maxLevel = false, color = "purple", stats = { spellPower = 9, stamina = 12 } }, -- Glowing Twilight Opal
	[40026] = { maxLevel = false, color = "purple", stats = { spellPower = 9, spirit = 8 } }, -- Purified Twilight Opal
	[40027] = { maxLevel = false, color = "purple", stats = { spellPower = 9, mp5 = 4 } }, -- Royal Twilight Opal
	[40028] = { maxLevel = false, color = "purple", stats = { spellPower = 9, spellPenetration = 10 } }, -- Mysterious Twilight Opal
	[40029] = { maxLevel = false, color = "purple", stats = { attackPower = 16, stamina = 12 } }, -- Balanced Twilight Opal
	[40030] = { maxLevel = false, color = "purple", stats = { attackPower = 16, mp5 = 4 } }, -- Infused Twilight Opal
	[40031] = { maxLevel = false, color = "purple", stats = { dodgeRating = 8, stamina = 12 } }, -- Regal Twilight Opal
	[40032] = { maxLevel = false, color = "purple", stats = { parryRating = 8, stamina = 12 } }, -- Defender's Twilight Opal
	[40033] = { maxLevel = false, color = "purple", stats = { armorPenetration = 8, stamina = 12 } }, -- Puissant Twilight Opal
	[40034] = { maxLevel = false, color = "purple", stats = { expertiseRating = 8, stamina = 12 } }, -- Guardian's Twilight Opal
	[40037] = { maxLevel = false, color = "orange", stats = { strength = 8, critRating = 8 } }, -- Inscribed Monarch Topaz
	[40038] = { maxLevel = false, color = "orange", stats = { strength = 8, hitRating = 8 } }, -- Etched Monarch Topaz
	[40039] = { maxLevel = false, color = "orange", stats = { strength = 8, defenseRating = 8 } }, -- Champion's Monarch Topaz
	[40040] = { maxLevel = false, color = "orange", stats = { strength = 8, resilience = 8 } }, -- Resplendent Monarch Topaz
	[40041] = { maxLevel = false, color = "orange", stats = { strength = 8, hasteRating = 8 } }, -- Fierce Monarch Topaz
	[40043] = { maxLevel = false, color = "orange", stats = { agility = 8, critRating = 8 } }, -- Deadly Monarch Topaz
	[40044] = { maxLevel = false, color = "orange", stats = { agility = 8, hitRating = 8 } }, -- Glinting Monarch Topaz
	[40045] = { maxLevel = false, color = "orange", stats = { agility = 8, resilience = 8 } }, -- Lucent Monarch Topaz
	[40046] = { maxLevel = false, color = "orange", stats = { agility = 8, hasteRating = 8 } }, -- Deft Monarch Topaz
	[40047] = { maxLevel = false, color = "orange", stats = { spellPower = 9, intellect = 8 } }, -- Luminous Monarch Topaz
	[40048] = { maxLevel = false, color = "orange", stats = { spellPower = 9, critRating = 8 } }, -- Potent Monarch Topaz
	[40049] = { maxLevel = false, color = "orange", stats = { spellPower = 9, hitRating = 8 } }, -- Veiled Monarch Topaz
	[40050] = { maxLevel = false, color = "orange", stats = { spellPower = 9, resilience = 8 } }, -- Durable Monarch Topaz
	[40051] = { maxLevel = false, color = "orange", stats = { spellPower = 9, hasteRating = 8 } }, -- Reckless Monarch Topaz
	[40052] = { maxLevel = false, color = "orange", stats = { attackPower = 16, critRating = 8 } }, -- Wicked Monarch Topaz
	[40053] = { maxLevel = false, color = "orange", stats = { attackPower = 16, hitRating = 8 } }, -- Pristine Monarch Topaz
	[40054] = { maxLevel = false, color = "orange", stats = { attackPower = 16, resilience = 8 } }, -- Empowered Monarch Topaz
	[40055] = { maxLevel = false, color = "orange", stats = { attackPower = 16, hasteRating = 8 } }, -- Stark Monarch Topaz
	[40056] = { maxLevel = false, color = "orange", stats = { dodgeRating = 8, defenseRating = 8 } }, -- Stalwart Monarch Topaz
	[40057] = { maxLevel = false, color = "orange", stats = { parryRating = 8, defenseRating = 8 } }, -- Glimmering Monarch Topaz
	[40058] = { maxLevel = false, color = "orange", stats = { expertiseRating = 8, hitRating = 8 } }, -- Accurate Monarch Topaz
	[40059] = { maxLevel = false, color = "orange", stats = { expertiseRating = 8, defenseRating = 8 } }, -- Resolute Monarch Topaz
	[40085] = { maxLevel = false, color = "green", stats = { intellect = 8, stamina = 12 } }, -- Timeless Forest Emerald
	[40086] = { maxLevel = false, color = "green", stats = { critRating = 8, stamina = 12 } }, -- Jagged Forest Emerald
	[40088] = { maxLevel = false, color = "green", stats = { hitRating = 8, stamina = 12 } }, -- Vivid Forest Emerald
	[40089] = { maxLevel = false, color = "green", stats = { defenseRating = 8, stamina = 12 } }, -- Enduring Forest Emerald
	[40090] = { maxLevel = false, color = "green", stats = { resilience = 8, stamina = 12 } }, -- Steady Forest Emerald
	[40091] = { maxLevel = false, color = "green", stats = { hasteRating = 8, stamina = 12 } }, -- Forceful Forest Emerald
	[40092] = { maxLevel = false, color = "green", stats = { intellect = 8, spirit = 8 } }, -- Seer's Forest Emerald
	[40094] = { maxLevel = false, color = "green", stats = { intellect = 8, mp5 = 4 } }, -- Dazzling Forest Emerald
	[40095] = { maxLevel = false, color = "green", stats = { critRating = 8, spirit = 8 } }, -- Misty Forest Emerald
	[40096] = { maxLevel = false, color = "green", stats = { critRating = 8, mp5 = 4 } }, -- Sundered Forest Emerald
	[40098] = { maxLevel = false, color = "green", stats = { critRating = 8, spellPenetration = 10 } }, -- Radiant Forest Emerald
	[40099] = { maxLevel = false, color = "green", stats = { hitRating = 8, spirit = 8 } }, -- Shining Forest Emerald
	[40100] = { maxLevel = false, color = "green", stats = { hitRating = 8, mp5 = 4 } }, -- Lambent Forest Emerald
	[40101] = { maxLevel = false, color = "green", stats = { hitRating = 8, spellPenetration = 10 } }, -- Tense Forest Emerald
	[40102] = { maxLevel = false, color = "green", stats = { resilience = 8, spirit = 8 } }, -- Turbid Forest Emerald
	[40103] = { maxLevel = false, color = "green", stats = { resilience = 8, mp5 = 4 } }, -- Opaque Forest Emerald
	[40104] = { maxLevel = false, color = "green", stats = { hasteRating = 8, spirit = 8 } }, -- Intricate Forest Emerald
	[40105] = { maxLevel = false, color = "green", stats = { hasteRating = 8, mp5 = 4 } }, -- Energized Forest Emerald
	[40106] = { maxLevel = false, color = "green", stats = { hasteRating = 8, spellPenetration = 10 } }, -- Shattered Forest Emerald
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
