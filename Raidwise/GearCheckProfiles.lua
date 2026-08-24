-- Gear Check class/spec profiles (WotLK 3.3.5a). Keys: CLASSFILE or CLASSFILE-specTab.
-- Levels: preferred / acceptable / discouraged / forbidden. Being maintained.

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
local A_MAIL = Armor({ "mail" }, { "leather" }, { "cloth" }, { "plate" })
local A_LEATHER = Armor({ "leather" }, {}, { "cloth", "mail" }, { "plate" })
local A_CLOTH = Armor({ "cloth" }, {}, {}, { "leather", "mail", "plate" })

-- Shared stat templates (resilience is always soft-flagged in the engine for PvE).
local S_PHYS_MELEE = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "expertiseRating", "critRating", "hasteRating", "armorPenetration", "armor" },
	{ "stamina" },
	{ "spirit", "intellect" },
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

local function Profile(name, armor, stats, weapons, metaPreferred)
	return {
		name = name,
		armor = armor,
		stats = stats,
		weapons = weapons,
		metaPreferred = Set(metaPreferred or {}),
	}
end

local PROFILES = {
	-- Class fallbacks (spec unknown).
	WARRIOR = Profile("Warrior", A_PLATE, S_PHYS_MELEE, W_2H_MELEE, { 41398, 41397, 41396 }),
	PALADIN = Profile("Paladin", A_PLATE, S_PHYS_MELEE, W_1H_SHIELD, { 41398, 41395, 41396 }),
	HUNTER = Profile("Hunter", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }),
	ROGUE = Profile("Rogue", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }),
	PRIEST = Profile("Priest", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }),
	DEATHKNIGHT = Profile("Death Knight", A_PLATE, S_PHYS_MELEE, W_DK, { 41398, 41397, 41396 }),
	SHAMAN = Profile("Shaman", A_MAIL, S_CASTER, W_ELE_RESTO_SHAMAN, { 41398, 41395, 41401 }),
	MAGE = Profile("Mage", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),
	WARLOCK = Profile("Warlock", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),
	DRUID = Profile("Druid", A_LEATHER, S_CASTER, W_FERAL, { 41398, 41401, 41376 }),

	-- Warrior
	["WARRIOR-1"] = Profile("Arms", A_PLATE, S_PHYS_MELEE, W_2H_MELEE, { 41398, 41285 }),
	["WARRIOR-2"] = Profile("Fury", A_PLATE, S_PHYS_MELEE, W_DW_MELEE, { 41398, 41285 }),
	["WARRIOR-3"] = Profile("Protection", A_PLATE_TANK, S_PHYS_TANK, W_1H_SHIELD, { 41397, 41396, 41380 }),

	-- Paladin
	["PALADIN-1"] = Profile("Holy", A_PLATE, S_HEALER, W_1H_SHIELD, { 41376, 41401, 41395 }),
	["PALADIN-2"] = Profile("Protection", A_PLATE_TANK, S_PHYS_TANK, W_1H_SHIELD, { 41397, 41396, 41380 }),
	["PALADIN-3"] = Profile("Retribution", A_PLATE, S_PHYS_MELEE, W_2H_MELEE, { 41398, 41285 }),

	-- Hunter
	["HUNTER-1"] = Profile("Beast Mastery", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }),
	["HUNTER-2"] = Profile("Marksmanship", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }),
	["HUNTER-3"] = Profile("Survival", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }),

	-- Rogue
	["ROGUE-1"] = Profile("Assassination", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }),
	["ROGUE-2"] = Profile("Combat", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }),
	["ROGUE-3"] = Profile("Subtlety", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }),

	-- Priest
	["PRIEST-1"] = Profile("Discipline", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }),
	["PRIEST-2"] = Profile("Holy", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }),
	["PRIEST-3"] = Profile("Shadow", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),

	-- Death Knight
	["DEATHKNIGHT-1"] = Profile("Blood", A_PLATE_TANK, S_PHYS_TANK, W_DK, { 41397, 41396, 41380 }),
	["DEATHKNIGHT-2"] = Profile("Frost", A_PLATE, S_PHYS_MELEE, W_DK, { 41398, 41285 }),
	["DEATHKNIGHT-3"] = Profile("Unholy", A_PLATE, S_PHYS_MELEE, W_DK, { 41398, 41285 }),

	-- Shaman
	["SHAMAN-1"] = Profile("Elemental", A_MAIL, S_CASTER, W_ELE_RESTO_SHAMAN, { 41285, 41333, 41401 }),
	["SHAMAN-2"] = Profile("Enhancement", A_MAIL, S_ENHANCE, W_ENHANCE, { 41398, 41285 }),
	["SHAMAN-3"] = Profile("Restoration", A_MAIL, S_HEALER, W_ELE_RESTO_SHAMAN, { 41376, 41401, 41395 }),

	-- Mage
	["MAGE-1"] = Profile("Arcane", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),
	["MAGE-2"] = Profile("Fire", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),
	["MAGE-3"] = Profile("Frost", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),

	-- Warlock
	["WARLOCK-1"] = Profile("Affliction", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),
	["WARLOCK-2"] = Profile("Demonology", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),
	["WARLOCK-3"] = Profile("Destruction", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }),

	-- Druid
	["DRUID-1"] = Profile("Balance", A_LEATHER, S_CASTER, W_FERAL, { 41285, 41333, 41401 }),
	["DRUID-2"] = Profile("Feral", A_LEATHER, S_PHYS_MELEE, W_FERAL, { 41398, 41397, 41285 }),
	["DRUID-3"] = Profile("Restoration", A_LEATHER, S_HEALER, W_FERAL, { 41376, 41401, 41333 }),
}

-- Feral tank lean: still leather preferred; stamina/defense more preferred — keep melee profile for surface check.
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
