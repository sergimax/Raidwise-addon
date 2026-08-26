-- Gear Check class/spec profiles (WotLK 3.3.5a). Keys: CLASSFILE or CLASSFILE-specTab.
-- Rank gradation (armor / stats / weapons):
--   preferred  — BiS-appropriate; no finding; required (with max enchant/gems) for GOOD
--   acceptable — usable surface choice (offsets, hybrid); no finding; OK by default
--   unwanted   — wrong-for-spec soft waste → soft finding → REPLACE
--   forbidden  — explicitly inappropriate → hard finding → BAD
-- Surface rules distilled from docs/Gear-Check-Surface-From-BiS.md (example BiS lists).

local Addon = Raidwise

local function Set(list)
	local t = {}
	for index = 1, #list do
		t[list[index]] = true
	end
	return t
end

local function Armor(preferred, acceptable, unwanted, forbidden)
	return {
		preferred = Set(preferred or {}),
		acceptable = Set(acceptable or {}),
		unwanted = Set(unwanted or {}),
		forbidden = Set(forbidden or {}),
	}
end

local function Stats(preferred, acceptable, unwanted, forbidden)
	return {
		preferred = Set(preferred or {}),
		acceptable = Set(acceptable or {}),
		unwanted = Set(unwanted or {}),
		forbidden = Set(forbidden or {}),
	}
end

local function Weapons(preferred, acceptable, unwanted, forbidden)
	return {
		preferred = Set(preferred or {}),
		acceptable = Set(acceptable or {}),
		unwanted = Set(unwanted or {}),
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
	{ "agility", "intellect", "attackPower", "hitRating", "critRating", "hasteRating", "armorPenetration" },
	{ "strength", "stamina" },
	{ "defenseRating", "dodgeRating", "parryRating" },
	{ "spirit", "spellPower", "mp5" }
)
-- Enhancement: intellect and spellPower on hybrid mail pieces; mp5 is soft waste.
local S_ENHANCE = Stats(
	{ "agility", "intellect", "attackPower", "spellPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPenetration" },
	{ "stamina" },
	{ "mp5" },
	{ "strength", "spirit", "spellPenetration", "defenseRating", "dodgeRating", "parryRating" }
)
-- Shaman specs: tighter stat gradation than shared caster/healer templates.
local S_SHAMAN_ELEMENTAL = Stats(
	{ "intellect", "spellPower", "hitRating", "critRating", "hasteRating" },
	{ "stamina", "mp5" },
	{ "agility", "spirit", "spellPenetration" },
	{ "strength", "attackPower", "expertiseRating", "armorPenetration", "defenseRating", "dodgeRating", "parryRating" }
)
local S_SHAMAN_RESTO = Stats(
	{ "intellect", "spellPower", "critRating", "hasteRating", "mp5" },
	{ "stamina" },
	{ "agility", "spirit", "hitRating" },
	{ "strength", "attackPower", "expertiseRating", "armorPenetration", "spellPenetration", "defenseRating", "dodgeRating", "parryRating" }
)
-- Druid specs: tighter stat gradation than shared caster/melee/healer templates.
local S_DRUID_BALANCE = Stats(
	{ "intellect", "spirit", "spellPower", "hitRating", "critRating", "hasteRating", "spellPenetration" },
	{ "stamina", "mp5" },
	{ "strength", "agility" },
	{ "attackPower", "expertiseRating", "armorPenetration", "defenseRating", "dodgeRating", "parryRating" }
)
local S_DRUID_FERAL = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPenetration" },
	{ "stamina", "armor" },
	{ "intellect", "spirit" },
	{ "spellPower", "spellPenetration", "mp5" }
)
local S_DRUID_RESTO = Stats(
	{ "intellect", "spirit", "spellPower", "critRating", "hasteRating", "mp5" },
	{ "stamina" },
	{ "attackPower", "spellPenetration" },
	{ "strength", "agility", "hitRating", "expertiseRating", "armorPenetration", "defenseRating", "dodgeRating", "parryRating" }
)
-- Death Knight specs: blood tank vs frost/unholy DPS gradation.
local S_DK_BLOOD = Stats(
	{ "strength", "agility", "stamina", "hitRating", "expertiseRating", "defenseRating", "dodgeRating", "parryRating", "blockRating", "armor" },
	{ "attackPower", "critRating", "hasteRating", "armorPenetration", "blockValue" },
	{},
	{ "intellect", "spirit", "spellPower", "spellPenetration", "mp5" }
)
-- Frost/Unholy: intellect is soft waste (hybrid mail/leather), not a hard BAD.
local S_DK_DPS = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPenetration" },
	{ "stamina", "armor" },
	{ "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue", "intellect" },
	{ "spirit", "spellPower", "spellPenetration", "mp5" }
)
-- Priest specs: disc vs holy vs shadow stat gradation.
local S_PRIEST_DISC = Stats(
	{ "intellect", "spellPower", "critRating", "hasteRating", "mp5" },
	{ "spirit", "stamina" },
	{ "strength", "agility", "hitRating" },
	{ "attackPower", "expertiseRating", "armorPenetration", "spellPenetration", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue" }
)
local S_PRIEST_HOLY = Stats(
	{ "intellect", "spirit", "spellPower", "critRating", "hasteRating", "mp5" },
	{ "stamina" },
	{ "strength", "agility", "hitRating" },
	{ "attackPower", "expertiseRating", "armorPenetration", "spellPenetration", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue" }
)
local S_PRIEST_SHADOW = Stats(
	{ "intellect", "spellPower", "hitRating", "critRating", "hasteRating" },
	{ "spirit", "stamina", "mp5" },
	{ "strength", "agility", "spellPenetration" },
	{ "attackPower", "expertiseRating", "armorPenetration", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue" }
)
-- Rogue specs: pure physical DPS; spell stats forbidden.
local S_ROGUE = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPenetration" },
	{ "stamina", "armor" },
	{},
	{ "intellect", "spirit", "spellPower", "spellPenetration", "mp5" }
)
-- Paladin specs: holy healer vs protection tank vs retribution DPS.
local S_PALADIN_HOLY = Stats(
	{ "intellect", "spirit", "spellPower", "critRating", "hasteRating", "mp5" },
	{ "stamina" },
	{ "strength", "agility", "attackPower", "hitRating" },
	{ "expertiseRating", "armorPenetration", "spellPenetration", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue" }
)
local S_PALADIN_PROT = Stats(
	{ "strength", "agility", "stamina", "hitRating", "expertiseRating", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue", "armor" },
	{ "attackPower", "critRating", "hasteRating", "armorPenetration" },
	{ "intellect", "spirit", "spellPower" },
	{ "spellPenetration", "mp5" }
)
local S_PALADIN_RET = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPenetration" },
	{ "intellect", "stamina", "spellPower", "armor" },
	{ "spirit" },
	{ "spellPenetration", "mp5" }
)
-- Warrior specs: Arms/Fury DPS vs Protection tank.
local S_WARRIOR_DPS = Stats(
	{ "strength", "agility", "attackPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPenetration", "armor" },
	{ "stamina" },
	{ "intellect" },
	{ "spirit", "spellPower", "spellPenetration", "mp5" }
)
local S_WARRIOR_PROT = Stats(
	{ "strength", "agility", "stamina", "hitRating", "expertiseRating", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue", "armor" },
	{ "attackPower", "critRating", "hasteRating", "armorPenetration" },
	{ "intellect" },
	{ "spirit", "spellPower", "spellPenetration", "mp5" }
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

-- Trinket pools: see GearCheckTrinkets.lua (preferred = BiS; allowed = + progression).

local TRINKET_POOLS = Addon.GearCheckTrinketPools or {}

local function ResolveTrinketSets(opts)
	opts = opts or {}
	if opts.trinketPool then
		local pool = TRINKET_POOLS[opts.trinketPool]
		if pool then
			return Set(pool.preferred or {}), Set(pool.allowed or {})
		end
	end
	local legacy = Set(opts.trinkets or {})
	return legacy, legacy
end

local function Profile(name, armor, stats, weapons, metaPreferred, opts)
	opts = opts or {}
	local trinketsPreferred, trinketsAllowed = ResolveTrinketSets(opts)
	return {
		name = name,
		armor = armor,
		stats = stats,
		weapons = weapons,
		metaPreferred = Set(metaPreferred or {}),
		-- dw | 2h | 1h_shield | 1h_shield_or_oh | 1h_oh | any
		weaponSetup = opts.weaponSetup or "any",
		trinketsPreferred = trinketsPreferred,
		trinketsAllowed = trinketsAllowed,
	}
end

local PROFILES = {
	-- Class fallbacks (spec unknown).
	WARRIOR = Profile("Warrior", A_PLATE_DPS, S_PHYS_MELEE, W_2H_MELEE, { 41398, 41397, 41396 }, { weaponSetup = "any", trinketPool = "phys" }),
	PALADIN = Profile("Paladin", A_PLATE_DPS, S_PHYS_MELEE, W_1H_SHIELD, { 41398, 41395, 41396 }, { weaponSetup = "any", trinketPool = "phys" }),
	HUNTER = Profile("Hunter", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "hunter" }),
	ROGUE = Profile("Rogue", A_LEATHER, S_PHYS_MELEE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "phys" }),
	PRIEST = Profile("Priest", A_CLOTH, S_HEALER, W_CASTER, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinketPool = "healer" }),
	DEATHKNIGHT = Profile("Death Knight", A_PLATE_DPS, S_PHYS_MELEE, W_DK, { 41398, 41397, 41396 }, { weaponSetup = "any", trinketPool = "phys" }),
	SHAMAN = Profile("Shaman", A_MAIL, S_CASTER, W_ELE_RESTO_SHAMAN, { 41398, 41395, 41401 }, { weaponSetup = "any", trinketPool = "caster" }),
	MAGE = Profile("Mage", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	WARLOCK = Profile("Warlock", A_CLOTH, S_CASTER, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	DRUID = Profile("Druid", A_LEATHER, S_CASTER, W_FERAL, { 41398, 41401, 41376 }, { weaponSetup = "any", trinketPool = "caster" }),

	-- Warrior
	["WARRIOR-1"] = Profile("Arms", A_PLATE_DPS, S_WARRIOR_DPS, W_2H_MELEE, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "phys" }),
	["WARRIOR-2"] = Profile("Fury", A_PLATE_DPS, S_WARRIOR_DPS, W_FURY, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "phys" }),
	["WARRIOR-3"] = Profile("Protection", A_PLATE_TANK, S_WARRIOR_PROT, W_1H_SHIELD, { 41397, 41396, 41380 }, { weaponSetup = "1h_shield", trinketPool = "tank" }),

	-- Paladin
	["PALADIN-1"] = Profile("Holy", A_PLATE_DPS, S_PALADIN_HOLY, W_1H_SHIELD, { 41376, 41401, 41395 }, { weaponSetup = "1h_shield", trinketPool = "healer" }),
	["PALADIN-2"] = Profile("Protection", A_PLATE_TANK, S_PALADIN_PROT, W_1H_SHIELD, { 41397, 41396, 41380 }, { weaponSetup = "1h_shield", trinketPool = "tank" }),
	["PALADIN-3"] = Profile("Retribution", A_PLATE_DPS, S_PALADIN_RET, W_2H_MELEE, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "ret" }),

	-- Hunter
	["HUNTER-1"] = Profile("Beast Mastery", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "hunter" }),
	["HUNTER-2"] = Profile("Marksmanship", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "hunter" }),
	["HUNTER-3"] = Profile("Survival", A_MAIL, S_HUNTER, W_HUNTER, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "hunter" }),

	-- Rogue
	["ROGUE-1"] = Profile("Assassination", A_LEATHER, S_ROGUE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "phys" }),
	["ROGUE-2"] = Profile("Combat", A_LEATHER, S_ROGUE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "phys" }),
	["ROGUE-3"] = Profile("Subtlety", A_LEATHER, S_ROGUE, W_ROGUE, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "phys" }),

	-- Priest
	["PRIEST-1"] = Profile("Discipline", A_CLOTH, S_PRIEST_DISC, W_CASTER, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinketPool = "healer" }),
	["PRIEST-2"] = Profile("Holy", A_CLOTH, S_PRIEST_HOLY, W_CASTER, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinketPool = "healer" }),
	["PRIEST-3"] = Profile("Shadow", A_CLOTH, S_PRIEST_SHADOW, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),

	-- Death Knight
	["DEATHKNIGHT-1"] = Profile("Blood", A_PLATE_TANK, S_DK_BLOOD, W_DK_2H, { 41397, 41396, 41380 }, { weaponSetup = "2h", trinketPool = "tank" }),
	["DEATHKNIGHT-2"] = Profile("Frost", A_PLATE_DPS, S_DK_DPS, W_DK_DW, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "phys" }),
	["DEATHKNIGHT-3"] = Profile("Unholy", A_PLATE_DPS, S_DK_DPS, W_DK_2H, { 41398, 41285 }, { weaponSetup = "2h", trinketPool = "phys" }),

	-- Shaman
	["SHAMAN-1"] = Profile("Elemental", A_MAIL, S_SHAMAN_ELEMENTAL, W_ELE_RESTO_SHAMAN, { 41285, 41333, 41401 }, { weaponSetup = "1h_shield", trinketPool = "caster" }),
	["SHAMAN-2"] = Profile("Enhancement", A_MAIL, S_ENHANCE, W_ENHANCE, { 41398, 41285 }, { weaponSetup = "dw", trinketPool = "enhance" }),
	["SHAMAN-3"] = Profile("Restoration", A_MAIL, S_SHAMAN_RESTO, W_ELE_RESTO_SHAMAN, { 41376, 41401, 41395 }, { weaponSetup = "1h_shield_or_oh", trinketPool = "healer" }),

	-- Mage
	["MAGE-1"] = Profile("Arcane", A_CLOTH, S_DRUID_BALANCE, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	["MAGE-2"] = Profile("Fire", A_CLOTH, S_DRUID_BALANCE, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	["MAGE-3"] = Profile("Frost", A_CLOTH, S_DRUID_BALANCE, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),

	-- Warlock
	["WARLOCK-1"] = Profile("Affliction", A_CLOTH, S_DRUID_BALANCE, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	["WARLOCK-2"] = Profile("Demonology", A_CLOTH, S_DRUID_BALANCE, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	["WARLOCK-3"] = Profile("Destruction", A_CLOTH, S_DRUID_BALANCE, W_CASTER, { 41285, 41333, 41376 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),

	-- Druid
	["DRUID-1"] = Profile("Balance", A_LEATHER, S_DRUID_BALANCE, W_FERAL, { 41285, 41333, 41401 }, { weaponSetup = "1h_oh", trinketPool = "caster" }),
	["DRUID-2"] = Profile("Feral", A_LEATHER, S_DRUID_FERAL, W_FERAL, { 41398, 41397, 41285 }, { weaponSetup = "2h", trinketPool = "phys" }),
	["DRUID-3"] = Profile("Restoration", A_LEATHER_HEAL, S_DRUID_RESTO, W_FERAL, { 41376, 41401, 41333 }, { weaponSetup = "1h_oh", trinketPool = "healer" }),
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
