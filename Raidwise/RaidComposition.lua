-- Raid composition checklist (Wowhead-style exclusive buff/debuff categories).
-- Keep in sync with docs/Raid-Composition.md.

local Addon = Raidwise

local function Src(class, specTab, race)
	return { class = class, specTab = specTab, race = race }
end

-- specTab 1–3 matches inspect primary tree. Nil specTab = any spec of that class.
local EFFECTS = {
	{
		section = "buffs",
		id = "stats_pct",
		labelKey = "COMP_STATS_PCT",
		spellId = 20217,
		sources = { Src("PALADIN") },
	},
	{
		section = "buffs",
		id = "motw",
		labelKey = "COMP_MOTW",
		spellId = 48470,
		sources = { Src("DRUID") },
	},
	{
		section = "buffs",
		id = "stamina",
		labelKey = "COMP_STAMINA",
		spellId = 48162,
		sources = { Src("PRIEST") },
	},
	{
		section = "buffs",
		id = "intellect",
		labelKey = "COMP_INTELLECT",
		spellId = 43002,
		sources = { Src("MAGE"), Src("WARLOCK", 1) },
	},
	{
		section = "buffs",
		id = "spirit",
		labelKey = "COMP_SPIRIT",
		spellId = 48074,
		sources = { Src("PRIEST"), Src("WARLOCK", 1) },
	},
	{
		section = "buffs",
		id = "attack_power",
		labelKey = "COMP_ATTACK_POWER",
		spellId = 47436,
		sources = { Src("WARRIOR"), Src("PALADIN") },
	},
	{
		section = "buffs",
		id = "str_agi",
		labelKey = "COMP_STR_AGI",
		spellId = 57623,
		sources = { Src("DEATHKNIGHT"), Src("SHAMAN") },
	},
	{
		section = "buffs",
		id = "health",
		labelKey = "COMP_HEALTH",
		spellId = 47440,
		sources = { Src("WARRIOR"), Src("WARLOCK") },
	},
	{
		section = "buffs",
		id = "mp5",
		labelKey = "COMP_MP5",
		spellId = 48936,
		sources = { Src("PALADIN"), Src("SHAMAN") },
	},
	{
		section = "buffs",
		id = "spell_power",
		labelKey = "COMP_SPELL_POWER",
		spellId = 57722,
		sources = { Src("SHAMAN"), Src("WARLOCK", 2) },
	},
	{
		section = "buffs",
		id = "melee_crit",
		labelKey = "COMP_MELEE_CRIT",
		spellId = 17007,
		sources = { Src("DRUID", 2), Src("WARRIOR", 2) },
	},
	{
		section = "buffs",
		id = "spell_crit",
		labelKey = "COMP_SPELL_CRIT",
		spellId = 24907,
		sources = { Src("DRUID", 1), Src("SHAMAN", 1) },
	},
	{
		section = "buffs",
		id = "melee_haste",
		labelKey = "COMP_MELEE_HASTE",
		spellId = 55610,
		sources = { Src("DEATHKNIGHT", 2), Src("SHAMAN") },
	},
	{
		section = "buffs",
		id = "spell_haste",
		labelKey = "COMP_SPELL_HASTE",
		spellId = 3738,
		sources = { Src("SHAMAN") },
	},
	{
		section = "buffs",
		id = "haste_all",
		labelKey = "COMP_HASTE_ALL",
		spellId = 53648,
		sources = { Src("PALADIN", 3), Src("DRUID", 1) },
	},
	{
		section = "buffs",
		id = "damage_pct",
		labelKey = "COMP_DAMAGE_PCT",
		spellId = 31869,
		sources = { Src("PALADIN", 3), Src("HUNTER", 1), Src("MAGE", 1) },
	},
	{
		section = "buffs",
		id = "ap_pct",
		labelKey = "COMP_AP_PCT",
		spellId = 19506,
		sources = { Src("HUNTER", 2), Src("SHAMAN", 2), Src("DEATHKNIGHT", 1) },
	},
	{
		section = "buffs",
		id = "bloodlust",
		labelKey = "COMP_BLOODLUST",
		spellId = 2825,
		sources = { Src("SHAMAN") },
	},
	{
		section = "buffs",
		id = "healing_recv",
		labelKey = "COMP_HEALING_RECV",
		spellId = 33891,
		sources = { Src("DRUID", 3), Src("PALADIN", 1) },
	},
	{
		section = "external",
		id = "focus_magic",
		labelKey = "COMP_FOCUS_MAGIC",
		spellId = 54646,
		sources = { Src("MAGE", 1) },
	},
	{
		section = "aggro",
		id = "misdirection",
		labelKey = "COMP_MISDIRECTION",
		spellId = 34477,
		sources = { Src("HUNTER") },
	},
	{
		section = "aggro",
		id = "tricks",
		labelKey = "COMP_TRICKS",
		spellId = 57934,
		sources = { Src("ROGUE") },
	},
	{
		section = "external",
		id = "unholy_frenzy",
		labelKey = "COMP_UNHOLY_FRENZY",
		spellId = 49016,
		sources = { Src("DEATHKNIGHT", 1) },
	},
	{
		section = "external",
		id = "power_infusion",
		labelKey = "COMP_POWER_INFUSION",
		spellId = 10060,
		sources = { Src("PRIEST", 1) },
	},
	{
		section = "external",
		id = "innervate",
		labelKey = "COMP_INNERVATE",
		spellId = 29166,
		sources = { Src("DRUID") },
	},
	{
		section = "external",
		id = "hand_salvation",
		labelKey = "COMP_HAND_SALVATION",
		spellId = 1038,
		sources = { Src("PALADIN") },
	},
	{
		section = "external",
		id = "hand_sacrifice",
		labelKey = "COMP_HAND_SACRIFICE",
		spellId = 6940,
		sources = { Src("PALADIN") },
	},
	{
		section = "external",
		id = "hand_freedom",
		labelKey = "COMP_HAND_FREEDOM",
		spellId = 1044,
		sources = { Src("PALADIN") },
	},
	{
		section = "external",
		id = "hand_protection",
		labelKey = "COMP_HAND_PROTECTION",
		spellId = 10278,
		sources = { Src("PALADIN") },
	},
	{
		section = "external",
		id = "pain_suppression",
		labelKey = "COMP_PAIN_SUPPRESSION",
		spellId = 33206,
		sources = { Src("PRIEST", 1) },
	},
	{
		section = "external",
		id = "guardian_spirit",
		labelKey = "COMP_GUARDIAN_SPIRIT",
		spellId = 47788,
		sources = { Src("PRIEST", 2) },
	},
	{
		section = "external",
		id = "earth_shield",
		labelKey = "COMP_EARTH_SHIELD",
		spellId = 49284,
		sources = { Src("SHAMAN", 3) },
	},
	{
		section = "external",
		id = "beacon",
		labelKey = "COMP_BEACON",
		spellId = 53563,
		sources = { Src("PALADIN", 1) },
	},
	{
		section = "external",
		id = "sacred_shield",
		labelKey = "COMP_SACRED_SHIELD",
		spellId = 53601,
		hidden = true,
		sources = { Src("PALADIN", 1) },
	},
	{
		section = "external",
		id = "divine_sacrifice",
		labelKey = "COMP_DIVINE_SACRIFICE",
		spellId = 64205,
		sources = { Src("PALADIN", 2) },
	},
	{
		section = "external",
		id = "intervene",
		labelKey = "COMP_INTERVENE",
		spellId = 3411,
		hidden = true,
		sources = { Src("WARRIOR") },
	},
	{
		section = "damage_reduction",
		id = "amz",
		labelKey = "COMP_AMZ",
		spellId = 51052,
		hidden = true,
		sources = { Src("DEATHKNIGHT", 3) },
	},
	{
		section = "damage_reduction",
		id = "divine_guardian",
		labelKey = "COMP_DIVINE_GUARDIAN",
		spellId = 70940,
		sources = { Src("PALADIN", 2) },
	},
	{
		section = "damage_reduction",
		id = "aura_mastery",
		labelKey = "COMP_AURA_MASTERY",
		spellId = 31821,
		sources = { Src("PALADIN") },
	},
	{
		section = "damage_reduction",
		id = "shield_wall",
		labelKey = "COMP_SHIELD_WALL",
		spellId = 871,
		hidden = true,
		sources = { Src("WARRIOR") },
	},
	{
		section = "damage_reduction",
		id = "last_stand",
		labelKey = "COMP_LAST_STAND",
		spellId = 12975,
		hidden = true,
		sources = { Src("WARRIOR", 3) },
	},
	{
		section = "damage_reduction",
		id = "icebound",
		labelKey = "COMP_ICEBOUND",
		spellId = 48792,
		hidden = true,
		sources = { Src("DEATHKNIGHT") },
	},
	{
		section = "damage_reduction",
		id = "vampiric_blood",
		labelKey = "COMP_VAMPIRIC_BLOOD",
		spellId = 55233,
		hidden = true,
		sources = { Src("DEATHKNIGHT", 1) },
	},
	{
		section = "damage_reduction",
		id = "survival_instincts",
		labelKey = "COMP_SURVIVAL_INSTINCTS",
		spellId = 61336,
		hidden = true,
		sources = { Src("DRUID", 2) },
	},
	{
		section = "damage_reduction",
		id = "frenzied_regen",
		labelKey = "COMP_FRENZIED_REGEN",
		spellId = 22842,
		hidden = true,
		sources = { Src("DRUID", 2) },
	},
	{
		section = "damage_reduction",
		id = "dispersion",
		labelKey = "COMP_DISPERSION",
		spellId = 47585,
		hidden = true,
		sources = { Src("PRIEST", 3) },
	},
	{
		section = "damage_reduction",
		id = "divine_protection",
		labelKey = "COMP_DIVINE_PROTECTION",
		spellId = 498,
		hidden = true,
		sources = { Src("PALADIN") },
	},
	{
		section = "damage_reduction",
		id = "divine_shield",
		labelKey = "COMP_DIVINE_SHIELD",
		spellId = 642,
		hidden = true,
		sources = { Src("PALADIN") },
	},
	{
		section = "damage_reduction",
		id = "barkskin",
		labelKey = "COMP_BARKSKIN",
		spellId = 22812,
		hidden = true,
		sources = { Src("DRUID") },
	},
	{
		section = "damage_reduction",
		id = "ice_block",
		labelKey = "COMP_ICE_BLOCK",
		spellId = 45438,
		hidden = true,
		sources = { Src("MAGE") },
	},
	{
		section = "damage_reduction",
		id = "cloak",
		labelKey = "COMP_CLOAK",
		spellId = 31224,
		hidden = true,
		sources = { Src("ROGUE") },
	},
	{
		section = "damage_reduction",
		id = "ams",
		labelKey = "COMP_AMS",
		spellId = 48707,
		hidden = true,
		sources = { Src("DEATHKNIGHT") },
	},
	{
		section = "damage_reduction",
		id = "lay_on_hands",
		labelKey = "COMP_LAY_ON_HANDS",
		spellId = 48788,
		sources = { Src("PALADIN") },
	},
	{
		section = "damage_reduction",
		id = "divine_hymn",
		labelKey = "COMP_DIVINE_HYMN",
		spellId = 64843,
		sources = { Src("PRIEST") },
	},
	{
		section = "damage_reduction",
		id = "tranquility",
		labelKey = "COMP_TRANQUILITY",
		spellId = 48447,
		hidden = true,
		sources = { Src("DRUID", 3) },
	},
	{
		section = "damage_reduction",
		id = "sanctuary_grace",
		labelKey = "COMP_SANCTUARY_GRACE",
		spellId = 20911,
		comboLabel = true,
		sources = { Src("PALADIN", 2), Src("PRIEST", 1) },
	},
	{
		section = "damage_reduction",
		id = "inspiration",
		labelKey = "COMP_INSPIRATION",
		spellId = 15359,
		comboLabel = true,
		sources = { Src("PRIEST", 1), Src("PRIEST", 2), Src("SHAMAN", 3) },
	},
	{
		section = "debuffs",
		id = "armor_major",
		labelKey = "COMP_ARMOR_MAJOR",
		spellId = 7386,
		sources = { Src("WARRIOR"), Src("ROGUE"), Src("HUNTER", 1) },
	},
	{
		section = "debuffs",
		id = "armor_minor",
		labelKey = "COMP_ARMOR_MINOR",
		spellId = 770,
		sources = { Src("DRUID"), Src("WARLOCK"), Src("HUNTER") },
	},
	{
		section = "debuffs",
		id = "bleed",
		labelKey = "COMP_BLEED",
		spellId = 48566,
		sources = { Src("DRUID", 2), Src("WARRIOR", 1), Src("HUNTER", 1) },
	},
	{
		section = "debuffs",
		id = "phys_taken",
		labelKey = "COMP_PHYS_TAKEN",
		spellId = 29859,
		sources = { Src("WARRIOR", 1), Src("ROGUE", 2) },
	},
	{
		section = "debuffs",
		id = "spell_taken",
		labelKey = "COMP_SPELL_TAKEN",
		spellId = 47865,
		sources = { Src("WARLOCK"), Src("DRUID", 1), Src("DEATHKNIGHT", 3) },
	},
	{
		section = "debuffs",
		id = "spell_hit",
		labelKey = "COMP_SPELL_HIT",
		spellId = 33191,
		sources = { Src("PRIEST", 3), Src("DRUID", 1) },
	},
	{
		section = "debuffs",
		id = "crit_taken",
		labelKey = "COMP_CRIT_TAKEN",
		spellId = 20337,
		sources = { Src("PALADIN", 2), Src("PALADIN", 3), Src("SHAMAN", 1), Src("ROGUE", 1) },
	},
	{
		section = "debuffs",
		id = "spell_crit_taken",
		labelKey = "COMP_SPELL_CRIT_TAKEN",
		spellId = 12873,
		sources = { Src("MAGE", 2), Src("MAGE", 3), Src("WARLOCK", 3) },
	},
	{
		section = "debuffs",
		id = "attack_slow",
		labelKey = "COMP_ATTACK_SLOW",
		spellId = 47502,
		sources = { Src("WARRIOR"), Src("DEATHKNIGHT"), Src("DRUID", 2), Src("PALADIN", 2) },
	},
	{
		section = "debuffs",
		id = "ap_down",
		labelKey = "COMP_AP_DOWN",
		spellId = 47437,
		sources = { Src("WARRIOR"), Src("DRUID", 2), Src("WARLOCK"), Src("PALADIN", 2), Src("PALADIN", 3) },
	},
	{
		section = "debuffs",
		id = "healing_reduce",
		labelKey = "COMP_HEALING_REDUCE",
		spellId = 47486,
		sources = { Src("WARRIOR", 1), Src("WARRIOR", 2), Src("HUNTER"), Src("ROGUE") },
	},
	{
		section = "debuffs",
		id = "cast_slow",
		labelKey = "COMP_CAST_SLOW",
		spellId = 11719,
		sources = { Src("WARLOCK"), Src("MAGE", 1), Src("ROGUE"), Src("HUNTER", 1) },
	},
	{
		section = "debuffs",
		id = "melee_hit_down",
		labelKey = "COMP_MELEE_HIT_DOWN",
		spellId = 3043,
		sources = { Src("DRUID", 1), Src("HUNTER") },
	},
	{
		section = "debuffs",
		id = "jol",
		labelKey = "COMP_JOL",
		spellId = 20185,
		hidden = true,
		sources = { Src("PALADIN") },
	},
	{
		section = "debuffs",
		id = "jow",
		labelKey = "COMP_JOW",
		spellId = 20186,
		hidden = true,
		sources = { Src("PALADIN") },
	},
	{
		section = "mana",
		id = "replenishment",
		labelKey = "COMP_REPLENISHMENT",
		spellId = 57669,
		sources = {
			Src("PRIEST", 3),
			Src("HUNTER", 3),
			Src("PALADIN", 3),
			Src("MAGE", 3),
			Src("WARLOCK", 3),
		},
	},
	{
		section = "mana",
		id = "mana_tide",
		labelKey = "COMP_MANA_TIDE",
		spellId = 16190,
		sources = { Src("SHAMAN", 3) },
	},
	{
		section = "mana",
		id = "hymn_of_hope",
		labelKey = "COMP_HYMN_OF_HOPE",
		spellId = 64901,
		sources = { Src("PRIEST") },
	},
	{
		section = "mana",
		id = "innervate_mana",
		labelKey = "COMP_INNERVATE",
		spellId = 29166,
		sources = { Src("DRUID") },
	},
	{
		section = "mana",
		id = "shadowfiend",
		labelKey = "COMP_SHADOWFIEND",
		spellId = 34433,
		hidden = true,
		sources = { Src("PRIEST") },
	},
	{
		section = "mana",
		id = "revitalize",
		labelKey = "COMP_REVITALIZE",
		spellId = 48540,
		sources = { Src("DRUID", 3) },
	},
	{
		section = "mana",
		id = "jow_mana",
		labelKey = "COMP_JOW",
		spellId = 20186,
		sources = { Src("PALADIN") },
	},
	{
		section = "health_regen",
		id = "imp_lotp",
		labelKey = "COMP_IMP_LOTP",
		spellId = 17007,
		comboLabel = true,
		sources = { Src("DRUID", 2) },
	},
	{
		section = "health_regen",
		id = "vampiric_embrace",
		labelKey = "COMP_VAMPIRIC_EMBRACE",
		spellId = 15286,
		sources = { Src("PRIEST", 3) },
	},
	{
		section = "health_regen",
		id = "jol_regen",
		labelKey = "COMP_JOL",
		spellId = 20185,
		sources = { Src("PALADIN") },
	},
	{
		section = "health_regen",
		id = "gift_naaru",
		labelKey = "COMP_GIFT_NAARU",
		spellId = 28880,
		hidden = true,
		sources = { Src(nil, nil, "Draenei") },
	},
}

local SECTIONS = {
	{ id = "aggro", labelKey = "COMP_SECTION_AGGRO" },
	{ id = "buffs", labelKey = "COMP_SECTION_BUFFS" },
	{ id = "external", labelKey = "COMP_SECTION_EXTERNAL" },
	{ id = "damage_reduction", labelKey = "COMP_SECTION_DR" },
	{ id = "debuffs", labelKey = "COMP_SECTION_DEBUFFS" },
	{ id = "mana", labelKey = "COMP_SECTION_MANA" },
	{ id = "health_regen", labelKey = "COMP_SECTION_HP" },
}

local SPEC_KEYS = {
	WARRIOR = { "COMP_SPEC_ARMS", "COMP_SPEC_FURY", "COMP_SPEC_PROTECTION" },
	PALADIN = { "COMP_SPEC_HOLY", "COMP_SPEC_PROTECTION", "COMP_SPEC_RETRIBUTION" },
	HUNTER = { "COMP_SPEC_BM", "COMP_SPEC_MM", "COMP_SPEC_SURVIVAL" },
	ROGUE = { "COMP_SPEC_ASSASSINATION", "COMP_SPEC_COMBAT", "COMP_SPEC_SUBTLETY" },
	PRIEST = { "COMP_SPEC_DISCIPLINE", "COMP_SPEC_HOLY", "COMP_SPEC_SHADOW" },
	DEATHKNIGHT = { "COMP_SPEC_BLOOD", "COMP_SPEC_FROST", "COMP_SPEC_UNHOLY" },
	SHAMAN = { "COMP_SPEC_ELEMENTAL", "COMP_SPEC_ENHANCEMENT", "COMP_SPEC_RESTORATION" },
	MAGE = { "COMP_SPEC_ARCANE", "COMP_SPEC_FIRE", "COMP_SPEC_FROST" },
	WARLOCK = { "COMP_SPEC_AFFLICTION", "COMP_SPEC_DEMONOLOGY", "COMP_SPEC_DESTRUCTION" },
	DRUID = { "COMP_SPEC_BALANCE", "COMP_SPEC_FERAL", "COMP_SPEC_RESTORATION" },
}

local CLASS_NAME_KEYS = {
	WARRIOR = "COMP_CLASS_WARRIOR",
	PALADIN = "COMP_CLASS_PALADIN",
	HUNTER = "COMP_CLASS_HUNTER",
	ROGUE = "COMP_CLASS_ROGUE",
	PRIEST = "COMP_CLASS_PRIEST",
	DEATHKNIGHT = "COMP_CLASS_DEATHKNIGHT",
	SHAMAN = "COMP_CLASS_SHAMAN",
	MAGE = "COMP_CLASS_MAGE",
	WARLOCK = "COMP_CLASS_WARLOCK",
	DRUID = "COMP_CLASS_DRUID",
}

local CLASS_ORDER = {
	"WARRIOR",
	"PALADIN",
	"HUNTER",
	"ROGUE",
	"PRIEST",
	"DEATHKNIGHT",
	"SHAMAN",
	"MAGE",
	"WARLOCK",
	"DRUID",
}

local ROLE_ORDER = { "tank", "healer", "melee", "ranged" }

local function ClassLabel(class)
	if class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] then
		return LOCALIZED_CLASS_NAMES_MALE[class]
	end
	return Addon:T(CLASS_NAME_KEYS[class] or "ROLE_UNKNOWN")
end

local function SpecLabel(class, specTab)
	specTab = tonumber(specTab) or 0
	if specTab < 1 then
		return Addon:T("COMP_SPEC_ANY")
	end
	local keys = SPEC_KEYS[class]
	if keys and keys[specTab] then
		return Addon:T(keys[specTab])
	end
	return Addon:T("COMP_SPEC_ANY")
end

local function FormatSource(source)
	if source.race == "Draenei" then
		return Addon:T("COMP_SRC_DRAENEI")
	end
	local className = ClassLabel(source.class)
	if source.specTab then
		return Addon:T("COMP_SRC_SPEC", className, SpecLabel(source.class, source.specTab))
	end
	return Addon:T("COMP_SRC_ANY", className)
end

local function ClientLocaleMatchesAddon()
	if not Addon.GetLocaleId or not GetLocale then
		return false
	end
	return Addon:GetLocaleId() == GetLocale()
end

-- Spell-named rows use the client’s GetSpellInfo when the addon language matches
-- the client, so ruRU/enUS names stay official 3.3.5a strings.
local function EffectLabel(effect)
	if effect.comboLabel then
		return Addon:T(effect.labelKey)
	end
	local section = effect.section
	if section == "external" or section == "aggro" or section == "damage_reduction" or section == "mana" or section == "health_regen" then
		if ClientLocaleMatchesAddon() and type(GetSpellInfo) == "function" and effect.spellId then
			local name = GetSpellInfo(effect.spellId)
			if name and name ~= "" then
				return name
			end
		end
	end
	return Addon:T(effect.labelKey)
end

local function SourceMatches(source, member)
	if source.race then
		return member.race == source.race
	end
	if source.class and source.class ~= member.class then
		return false
	end
	if source.specTab then
		return (tonumber(member.specTab) or 0) == source.specTab
	end
	return true
end

local function EnsureMemberRole(member)
	if not member then
		return
	end
	if member.role and member.role ~= "" and member.role ~= "unknown" then
		return
	end
	if Addon.RoleForRaidMember then
		member.role = Addon:RoleForRaidMember(member.class, member.specTab, false)
	else
		member.role = "unknown"
	end
end

function Addon:CompositionMembers(refreshGearScore)
	local members = {}
	local raidCount = (GetNumRaidMembers and GetNumRaidMembers()) or 0
	if raidCount > 0 and self.BuildRaidGroups then
		local groups = self:BuildRaidGroups(refreshGearScore)
		for groupIndex = 1, 8 do
			local slots = groups[groupIndex]
			if slots then
				for slot = 1, #slots do
					local member = slots[slot]
					if member and member.class and member.class ~= "" then
						members[#members + 1] = member
					end
				end
			end
		end
		return members
	end
	if self.BuildPartyRoster then
		local roster = self:BuildPartyRoster(refreshGearScore)
		for index = 1, #roster do
			local member = roster[index]
			if member and member.class and member.class ~= "" then
				members[#members + 1] = member
			end
		end
		return members
	end
	return members
end

function Addon:AnalyzeRaidComposition(members)
	local roles = {
		tank = { count = 0, names = {} },
		healer = { count = 0, names = {} },
		melee = { count = 0, names = {} },
		ranged = { count = 0, names = {} },
	}
	local classBuckets = {}
	for classIndex = 1, #CLASS_ORDER do
		local classToken = CLASS_ORDER[classIndex]
		classBuckets[classToken] = { count = 0, names = {} }
	end

	members = members or {}
	for index = 1, #members do
		local member = members[index]
		if member and member.class and member.class ~= "" then
			EnsureMemberRole(member)
			local bucket = roles[member.role]
			if bucket then
				bucket.count = bucket.count + 1
				bucket.names[#bucket.names + 1] = member.name or "?"
			end
			local classBucket = classBuckets[member.class]
			if classBucket then
				classBucket.count = classBucket.count + 1
				classBucket.names[#classBucket.names + 1] = member.name or "?"
			end
		end
	end

	local classes = {}
	for classIndex = 1, #CLASS_ORDER do
		local classToken = CLASS_ORDER[classIndex]
		local classBucket = classBuckets[classToken]
		classes[#classes + 1] = {
			class = classToken,
			label = ClassLabel(classToken),
			count = classBucket.count,
			present = classBucket.count > 0,
			names = classBucket.names,
		}
	end

	local sections = {}
	for sectionIndex = 1, #SECTIONS do
		local sectionInfo = SECTIONS[sectionIndex]
		local effects = {}
		for effectIndex = 1, #EFFECTS do
			local effect = EFFECTS[effectIndex]
			if effect.section == sectionInfo.id and not effect.hidden then
				local providers = {}
				for memberIndex = 1, #members do
					local member = members[memberIndex]
					if member and member.class and member.class ~= "" then
						for sourceIndex = 1, #effect.sources do
							if SourceMatches(effect.sources[sourceIndex], member) then
								providers[#providers + 1] = member.name or "?"
								break
							end
						end
					end
				end
				local sourceLabels = {}
				for sourceIndex = 1, #effect.sources do
					sourceLabels[#sourceLabels + 1] = FormatSource(effect.sources[sourceIndex])
				end
				effects[#effects + 1] = {
					id = effect.id,
					labelKey = effect.labelKey,
					label = EffectLabel(effect),
					spellId = effect.spellId,
					count = #providers,
					providers = providers,
					sourceLabels = sourceLabels,
				}
			end
		end
		if #effects > 0 then
			sections[#sections + 1] = {
				id = sectionInfo.id,
				labelKey = sectionInfo.labelKey,
				effects = effects,
			}
		end
	end

	return {
		classes = classes,
		roles = roles,
		roleOrder = ROLE_ORDER,
		sections = sections,
		memberCount = #members,
	}
end
