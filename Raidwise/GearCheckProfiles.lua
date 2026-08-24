-- Gear Check class/spec profiles (WotLK 3.3.5a). Keys: CLASSFILE or CLASSFILE-specTab.
-- Levels: preferred / acceptable / discouraged / forbidden. Being maintained.
-- Surface rules distilled from docs/Gear-Check-Surface-From-BiS.md (example BiS lists).

local Addon = Raidwise

local function Set(list)
	local t = {}
	for index = 1, #list do
		t[list[index]] = true
	end
	return t
end

local function Armor(preferred, acceptable, discouraged, forbidden)
	return {
		preferred = Set(preferred or {}),
		acceptable = Set(acceptable or {}),
		discouraged = Set(discouraged or {}),
		forbidden = Set(forbidden or {}),
	}
end

local function Stats(preferred, acceptable, discouraged, forbidden)
	return {
		preferred = Set(preferred or {}),
		acceptable = Set(acceptable or {}),
		discouraged = Set(discouraged or {}),
		forbidden = Set(forbidden or {}),
	}
end

local function Weapons(preferred, acceptable, discouraged, forbidden)
	return {
		preferred = Set(preferred or {}),
		acceptable = Set(acceptable or {}),
		discouraged = Set(discouraged or {}),
		forbidden = Set(forbidden or {}),
	}
end

-- Shared armor templates.
local A_PLATE = Armor({ "plate" }, { "mail" }, { "leather" }, { "cloth" })
local A_PLATE_TANK = Armor({ "plate" }, {}, { "mail", "leather" }, { "cloth" })
-- Plate DPS / Holy: leather/mail offset pieces appear on BiS lists.
local A_PLATE_DPS = Armor({ "plate" }, { "mail", "leather" }, {}, { "cloth" })
local A_MAIL = Armor({ "mail" }, { "leather" }, { "cloth" }, { "plate" })
local A_LEATHER = Armor({ "leather" }, {}, { "cloth", "mail" }, { "plate" })
-- Resto Druid BiS sometimes uses cloth chest.
local A_LEATHER_HEAL = Armor({ "leather" }, { "cloth" }, { "mail" }, { "plate" })
local A_CLOTH = Armor({ "cloth" }, {}, {}, { "leather", "mail", "plate" })

-- Shared stat templates (resilience is always soft-flagged in the engine for PvE).
local S_PHYS_MELEE = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "expertiseRating", "critRating", "hasteRating", "armorPenetration", "armor" },
	{ "stamina" },
	{ "spirit", "intellect" },
	{ "spellPower", "mp5", "spellPenetration" }
)
-- Retribution: intellect rides on many strong temporary mail/leather pieces.
local S_RET = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "expertiseRating", "critRating", "hasteRating", "armorPenetration", "armor" },
	{ "stamina", "intellect" },
	{ "spirit" },
	{ "spellPower", "mp5", "spellPenetration" }
)
local S_PHYS_TANK = Stats(
	{ "stamina", "defenseRating", "dodgeRating", "parryRating", "expertiseRating", "strength", "agility", "hitRating", "blockRating", "blockValue", "armor" },
	{ "critRating", "hasteRating", "attackPower", "armorPenetration" },
	{ "spirit", "intellect" },
	{ "spellPower", "mp5", "spellPenetration" }
)
local S_CASTER = Stats(
	{ "spellPower", "hitRating", "critRating", "hasteRating", "intellect", "spirit", "spellPenetration" },
	{ "stamina", "mp5" },
	{ "strength", "agility", "attackPower", "expertiseRating", "armorPenetration", "defenseRating", "dodgeRating", "parryRating" },
	{}
)
local S_HEALER = Stats(
	{ "spellPower", "critRating", "hasteRating", "intellect", "spirit", "mp5" },
	{ "stamina", "hitRating" },
	{ "strength", "agility", "attackPower", "expertiseRating", "armorPenetration", "defenseRating", "dodgeRating", "parryRating", "spellPenetration" },
	{}
)
local S_HUNTER = Stats(
	{ "agility", "attackPower", "hitRating", "critRating", "hasteRating", "armorPenetration", "intellect" },
	{ "stamina", "strength" },
	{ "spirit", "defenseRating", "dodgeRating", "parryRating" },
	{ "spellPower", "mp5" }
)
-- Enhancement: intellect is a primary mail/hybrid stat (hard to avoid); spellPower is soft waste.
local S_ENHANCE = Stats(
	{ "agility", "attackPower", "hitRating", "expertiseRating", "critRating", "hasteRating", "armorPenetration", "intellect", "strength" },
	{ "stamina" },
	{ "spirit", "spellPower", "defenseRating", "dodgeRating", "parryRating", "mp5", "spellPenetration" },
	{}
)

local W_1H_SHIELD = Weapons(
	{ "sword1h", "axe1h", "mace1h", "shield" },
	{},
	{ "sword2h", "axe2h", "mace2h", "polearm", "staff" },
	{ "bow", "gun", "crossbow", "thrown", "wand", "dagger", "fist", "fishingPole" }
)
local W_DW_MELEE = Weapons(
	{ "sword1h", "axe1h", "mace1h", "fist", "dagger" },
	{},
	{ "sword2h", "axe2h", "mace2h", "polearm", "staff", "shield" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
-- Fury BiS is Titan's Grip dual 2H; 1H remains acceptable.
local W_FURY = Weapons(
	{ "sword2h", "axe2h", "mace2h" },
	{ "sword1h", "axe1h", "mace1h", "fist", "polearm" },
	{ "staff", "shield", "dagger" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
local W_2H_MELEE = Weapons(
	{ "sword2h", "axe2h", "mace2h", "polearm" },
	{ "sword1h", "axe1h", "mace1h" },
	{ "staff", "shield" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
local W_ROGUE = Weapons(
	{ "dagger", "fist", "sword1h", "mace1h", "axe1h" },
	{},
	{ "sword2h", "axe2h", "mace2h", "polearm", "staff", "shield" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
local W_HUNTER = Weapons(
	{ "bow", "gun", "crossbow", "sword2h", "axe2h", "polearm", "staff", "sword1h", "axe1h" },
	{ "fist", "dagger", "mace1h", "mace2h" },
	{ "shield" },
	{ "wand", "fishingPole" }
)
local W_CASTER = Weapons(
	{ "staff", "wand", "sword1h", "dagger", "mace1h", "offhand" },
	{},
	{ "axe1h", "fist" },
	{ "bow", "gun", "crossbow", "thrown", "sword2h", "axe2h", "mace2h", "polearm", "shield", "fishingPole" }
)
local W_ENHANCE = Weapons(
	{ "mace1h", "axe1h", "fist" },
	{ "sword1h", "dagger" },
	{ "mace2h", "axe2h", "staff", "shield" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
local W_ELE_RESTO_SHAMAN = Weapons(
	{ "mace1h", "staff", "shield", "offhand", "dagger" },
	{ "axe1h" },
	{},
	{ "bow", "gun", "crossbow", "wand", "sword2h", "axe2h", "mace2h", "polearm", "fishingPole" }
)
-- Blood / Unholy: 2H preferred; 1H acceptable.
local W_DK_2H = Weapons(
	{ "sword2h", "axe2h", "mace2h", "polearm" },
	{ "sword1h", "axe1h", "mace1h" },
	{ "staff", "shield", "fist", "dagger" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
-- Frost: dual-wield 1H preferred; 2H acceptable.
local W_DK_DW = Weapons(
	{ "sword1h", "axe1h", "mace1h" },
	{ "sword2h", "axe2h", "mace2h", "polearm" },
	{ "staff", "shield", "fist", "dagger" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
local W_DK = Weapons(
	{ "sword2h", "axe2h", "mace2h", "polearm", "sword1h", "axe1h", "mace1h" },
	{},
	{ "staff", "shield", "fist", "dagger" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)
local W_FERAL = Weapons(
	{ "staff", "polearm", "mace2h", "sword2h", "axe2h", "fist", "mace1h" },
	{ "dagger", "sword1h", "axe1h" },
	{ "shield" },
	{ "bow", "gun", "crossbow", "wand", "fishingPole" }
)

-- Trinket allowlists (normal + heroic ICC/RS IDs where known). Absence ≠ BAD; soft not-preferred only.
local T_PHYS = {
	50362, 50363, -- Deathbringer's Will
	54569, 54590, -- Sharpened Twilight Scale
	50706, -- Tiny Abomination in a Jar
	50355, -- Herkuml War Token
	47131, 47464, -- Death's Choice / Verdict (ToC)
	47303, 47115, -- Death's Verdict variants
}
local T_HUNTER = {
	50362, 50363,
	54569, 54590,
	47131, 47464,
}
local T_CASTER = {
	54572, 54588, -- Charred Twilight Scale
	50360, 50365, -- Phylactery of the Nameless Lich
	50348, 50353, -- Dislodged Foreign Object
	47316, 47182, -- Reign of the Dead / Unliving
	-- Entry / mid-tier
	40682, -- Sundial of the Exiled
	47726, -- Talisman of Volatile Power
	37835, -- Je'Tze's Bell
}
local T_HEALER = {
	54573, 54589, -- Glowing Twilight Scale
	50359, 50366, -- Althor's Abacus
	50358, -- Purified Lunar Dust
	47041, 47059, 47271, 47432, -- Solace of the Fallen / Defeated
	48724, -- Talisman of Resurgence
	46051, -- Meteorite Crystal
	54572, 54588, -- Charred (Holy Pal 2nd sometimes)
	-- Entry / mid-tier
	37835, -- Je'Tze's Bell
}
local T_TANK = {
	50361, 50364, -- Sindragosa's Flawless Fang
	54571, 54591, -- Petrified Twilight Scale
	50356, -- Corroded Skeleton Key
	47080, 47088, -- Satrina's Impeding Scarab
	47290, 47451, -- Juggernaut's Vitality
	48021, -- Eitrigg's Oath
	-- Entry / mid-tier
	50235, -- Ick's Rotting Thumb
	47735, -- Glyph of Indomitability
	47216, -- The Black Heart
	37220, -- Essence of Gossamer
	50344, -- Dark Matter
}
-- Enhancement AP + SP lists both appear in sources.
local T_ENHANCE = {
	50362, 50363, 54569, 54590, 50355,
	54572, 54588, 50360, 50365,
}

local function Profile(name, armor, stats, weapons, metaPreferred, opts)
	opts = opts or {}
	return {
		name = name,
		armor = armor,
		stats = stats,
		weapons = weapons,
		metaPreferred = Set(metaPreferred or {}),
		-- dw | 2h | 1h_shield | 1h_oh | any
		weaponSetup = opts.weaponSetup or "any",
		trinketsAllowed = Set(opts.trinkets or {}),
	}
end

local PROFILES = {
	-- Class fallbacks (spec unknown).
	WARRIOR = Profile("Warrior", A_PLATE_DPS, S_PHYS_MELEE, W_2H_MELEE, { 41398, 41397, 41396 }, { weaponSetup = "any", trinkets = T_PHYS }),
	PALADIN = Profile("Paladin", A_PLATE_DPS, S_PHYS_MELEE, W_1H_SHIELD, { 41398, 41395, 41396 }, { weaponSetup = "any", trinkets = T_PHYS }),
	HUNTER = Profile("Hunter", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_HUNTER }),
	ROGUE = Profile("Rogue", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_PHYS }),
	PRIEST = Profile("Priest", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinkets = T_HEALER }),
	DEATHKNIGHT = Profile("Death Knight", A_PLATE_DPS, S_PHYS_MELEE, W_DK, { 41398, 41397, 41396 }, { weaponSetup = "any", trinkets = T_PHYS }),
	SHAMAN = Profile("Shaman", A_MAIL, S_CASTER, W_ELE_RESTO_SHAMAN, { 41398, 41395, 41401 }, { weaponSetup = "any", trinkets = T_CASTER }),
	MAGE = Profile("Mage", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	WARLOCK = Profile("Warlock", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	DRUID = Profile("Druid", A_LEATHER, S_CASTER, W_FERAL, { 41398, 41401, 41376 }, { weaponSetup = "any", trinkets = T_CASTER }),

	-- Warrior
	["WARRIOR-1"] = Profile("Arms", A_PLATE_DPS, S_PHYS_MELEE, W_2H_MELEE, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_PHYS }),
	["WARRIOR-2"] = Profile("Fury", A_PLATE_DPS, S_PHYS_MELEE, W_FURY, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_PHYS }),
	["WARRIOR-3"] = Profile("Protection", A_PLATE_TANK, S_PHYS_TANK, W_1H_SHIELD, { 41397, 41396, 41380 }, { weaponSetup = "1h_shield", trinkets = T_TANK }),

	-- Paladin
	["PALADIN-1"] = Profile("Holy", A_PLATE_DPS, S_HEALER, W_1H_SHIELD, { 41376, 41401, 41395 }, { weaponSetup = "1h_shield", trinkets = T_HEALER }),
	["PALADIN-2"] = Profile("Protection", A_PLATE_TANK, S_PHYS_TANK, W_1H_SHIELD, { 41397, 41396, 41380 }, { weaponSetup = "1h_shield", trinkets = T_TANK }),
	["PALADIN-3"] = Profile("Retribution", A_PLATE_DPS, S_RET, W_2H_MELEE, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_PHYS }),

	-- Hunter
	["HUNTER-1"] = Profile("Beast Mastery", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_HUNTER }),
	["HUNTER-2"] = Profile("Marksmanship", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_HUNTER }),
	["HUNTER-3"] = Profile("Survival", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_HUNTER }),

	-- Rogue
	["ROGUE-1"] = Profile("Assassination", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_PHYS }),
	["ROGUE-2"] = Profile("Combat", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_PHYS }),
	["ROGUE-3"] = Profile("Subtlety", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_PHYS }),

	-- Priest
	["PRIEST-1"] = Profile("Discipline", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinkets = T_HEALER }),
	["PRIEST-2"] = Profile("Holy", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinkets = T_HEALER }),
	["PRIEST-3"] = Profile("Shadow", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),

	-- Death Knight
	["DEATHKNIGHT-1"] = Profile("Blood", A_PLATE_TANK, S_PHYS_TANK, W_DK_2H, { 41397, 41396, 41380 }, { weaponSetup = "2h", trinkets = T_TANK }),
	["DEATHKNIGHT-2"] = Profile("Frost", A_PLATE_DPS, S_PHYS_MELEE, W_DK_DW, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_PHYS }),
	["DEATHKNIGHT-3"] = Profile("Unholy", A_PLATE_DPS, S_PHYS_MELEE, W_DK_2H, { 41398, 41285 }, { weaponSetup = "2h", trinkets = T_PHYS }),

	-- Shaman
	["SHAMAN-1"] = Profile("Elemental", A_MAIL, S_CASTER, W_ELE_RESTO_SHAMAN, { 41285, 41333, 41401 }, { weaponSetup = "1h_shield", trinkets = T_CASTER }),
	["SHAMAN-2"] = Profile("Enhancement", A_MAIL, S_ENHANCE, W_ENHANCE, { 41398, 41285 }, { weaponSetup = "dw", trinkets = T_ENHANCE }),
	["SHAMAN-3"] = Profile("Restoration", A_MAIL, S_HEALER, W_ELE_RESTO_SHAMAN, { 41376, 41401, 41395 }, { weaponSetup = "1h_shield", trinkets = T_HEALER }),

	-- Mage
	["MAGE-1"] = Profile("Arcane", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	["MAGE-2"] = Profile("Fire", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	["MAGE-3"] = Profile("Frost", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),

	-- Warlock
	["WARLOCK-1"] = Profile("Affliction", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	["WARLOCK-2"] = Profile("Demonology", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	["WARLOCK-3"] = Profile("Destruction", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),

	-- Druid
	["DRUID-1"] = Profile("Balance", A_LEATHER, S_CASTER, W_FERAL, { 41285, 41333, 41401 }, { weaponSetup = "1h_oh", trinkets = T_CASTER }),
	["DRUID-2"] = Profile("Feral", A_LEATHER, S_PHYS_MELEE, W_FERAL, { 41398, 41397, 41285 }, { weaponSetup = "2h", trinkets = T_PHYS }),
	["DRUID-3"] = Profile("Restoration", A_LEATHER_HEAL, S_HEALER, W_FERAL, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinkets = T_HEALER }),
}

-- Blood DK tank tab is 1 in RaidRoles.

function Addon:GetGearCheckProfile(classFile, specTab, specKnown)
	classFile = classFile and string.upper(classFile) or nil
	specTab = tonumber(specTab) or 0
	if not classFile then
		return nil, "missing_class"
	end
	if specKnown and specTab > 0 then
		local key = classFile .. "-" .. tostring(specTab)
		if PROFILES[key] then
			return PROFILES[key], "spec"
		end
	end
	if PROFILES[classFile] then
		return PROFILES[classFile], "class"
	end
	return nil, "missing_profile"
end

function Addon:GetGearCheckProfileCount()
	local count = 0
	for _ in pairs(PROFILES) do
		count = count + 1
	end
	return count
end
