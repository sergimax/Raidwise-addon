-- Raid role and raid-buff lookups for the Raid roster view (WotLK 3.3.5a).
-- Role icons match RaidBuffStatus. Buffs are spec/race raid utilities, not every talent rank.

local Addon = Raidwise

local ROLE = {
	TANK = "tank",
	HEALER = "healer",
	MELEE = "melee",
	RANGED = "ranged",
	UNKNOWN = "unknown",
}

local ROLE_ICONS = {
	tank = "Interface\\Icons\\INV_Shield_06",
	healer = "Interface\\Icons\\Spell_Holy_FlashHeal",
	melee = "Interface\\Icons\\INV_ThrowingKnife_03",
	ranged = "Interface\\Icons\\INV_Staff_13",
	unknown = "Interface\\Icons\\INV_Misc_QuestionMark",
}

-- WotLK talent tab (1–3) that is typically tank or healer for that class.
local TANK_TABS = {
	WARRIOR = 3,
	PALADIN = 2,
	DEATHKNIGHT = 1,
}

local HEALER_TABS = {
	PRIEST = { [1] = true, [2] = true },
	PALADIN = { [1] = true },
	SHAMAN = { [3] = true },
	DRUID = { [3] = true },
}

local MELEE_TABS = {
	WARRIOR = { [1] = true, [2] = true },
	PALADIN = { [3] = true },
	ROGUE = { [1] = true, [2] = true, [3] = true },
	DEATHKNIGHT = { [2] = true, [3] = true },
	SHAMAN = { [2] = true },
	DRUID = { [2] = true },
}

local RANGED_TABS = {
	HUNTER = { [1] = true, [2] = true, [3] = true },
	MAGE = { [1] = true, [2] = true, [3] = true },
	WARLOCK = { [1] = true, [2] = true, [3] = true },
	PRIEST = { [3] = true },
	SHAMAN = { [1] = true },
	DRUID = { [1] = true },
}

local CLASS_DEFAULT_ROLE = {
	HUNTER = ROLE.RANGED,
	MAGE = ROLE.RANGED,
	WARLOCK = ROLE.RANGED,
	ROGUE = ROLE.MELEE,
	PRIEST = ROLE.HEALER,
	WARRIOR = ROLE.MELEE,
	DEATHKNIGHT = ROLE.MELEE,
}

function Addon:RaidRoleIcon(role)
	return ROLE_ICONS[role] or ROLE_ICONS.unknown
end

function Addon:RaidRoleLabel(role)
	return self:T(self:RoleLabelKey(role))
end

function Addon:RoleForRaidMember(class, specTab, isMainTank)
	if isMainTank then
		return ROLE.TANK
	end

	specTab = tonumber(specTab) or 0
	class = class or ""

	if specTab > 0 and TANK_TABS[class] == specTab then
		return ROLE.TANK
	end
	if specTab > 0 and HEALER_TABS[class] and HEALER_TABS[class][specTab] then
		return ROLE.HEALER
	end
	if specTab > 0 and MELEE_TABS[class] and MELEE_TABS[class][specTab] then
		return ROLE.MELEE
	end
	if specTab > 0 and RANGED_TABS[class] and RANGED_TABS[class][specTab] then
		return ROLE.RANGED
	end

	return CLASS_DEFAULT_ROLE[class] or ROLE.UNKNOWN
end

local function AddSpellBuff(buffs, spellId)
	if type(GetSpellInfo) ~= "function" then
		return
	end
	local name, _, icon = GetSpellInfo(spellId)
	if not icon or icon == "" then
		return
	end
	buffs[#buffs + 1] = {
		spellId = spellId,
		name = name or "",
		icon = icon,
	}
end

function Addon:RaidBuffsForMember(class, specTab, raceToken, faction)
	local buffs = {}
	specTab = tonumber(specTab) or 0
	class = class or ""
	raceToken = raceToken or ""
	faction = faction or ""

	if raceToken == "Draenei" then
		AddSpellBuff(buffs, 28878)
	end

	if class == "WARRIOR" then
		AddSpellBuff(buffs, 47436)
		AddSpellBuff(buffs, 47440)
		if specTab == 3 then
			AddSpellBuff(buffs, 50720)
		end
	elseif class == "PALADIN" then
		AddSpellBuff(buffs, 20217)
		AddSpellBuff(buffs, 19740)
		AddSpellBuff(buffs, 19742)
		if specTab == 1 then
			AddSpellBuff(buffs, 53563)
		elseif specTab == 2 then
			AddSpellBuff(buffs, 20911)
			AddSpellBuff(buffs, 48942)
		elseif specTab == 3 then
			AddSpellBuff(buffs, 31869)
			AddSpellBuff(buffs, 57669)
		end
	elseif class == "HUNTER" then
		AddSpellBuff(buffs, 53338)
		if specTab == 2 then
			AddSpellBuff(buffs, 19506)
		elseif specTab == 3 then
			AddSpellBuff(buffs, 53290)
		end
	elseif class == "PRIEST" then
		if specTab == 3 then
			AddSpellBuff(buffs, 15286)
			AddSpellBuff(buffs, 33191)
			AddSpellBuff(buffs, 57669)
		else
			AddSpellBuff(buffs, 48162)
			AddSpellBuff(buffs, 48074)
			AddSpellBuff(buffs, 48170)
		end
	elseif class == "DEATHKNIGHT" then
		AddSpellBuff(buffs, 57623)
		if specTab == 1 then
			AddSpellBuff(buffs, 53138)
			AddSpellBuff(buffs, 49016)
		elseif specTab == 2 then
			AddSpellBuff(buffs, 55610)
		elseif specTab == 3 then
			AddSpellBuff(buffs, 51099)
		end
	elseif class == "SHAMAN" then
		if faction == "Alliance" then
			AddSpellBuff(buffs, 32182)
		else
			AddSpellBuff(buffs, 2825)
		end
		if specTab == 1 then
			AddSpellBuff(buffs, 57722)
		elseif specTab == 2 then
			AddSpellBuff(buffs, 30809)
		elseif specTab == 3 then
			AddSpellBuff(buffs, 16190)
		end
	elseif class == "MAGE" then
		AddSpellBuff(buffs, 43002)
		if specTab == 1 then
			AddSpellBuff(buffs, 54646)
		elseif specTab == 3 then
			AddSpellBuff(buffs, 44561)
		end
	elseif class == "WARLOCK" then
		AddSpellBuff(buffs, 57567)
		if specTab == 2 then
			AddSpellBuff(buffs, 47240)
		elseif specTab == 1 then
			AddSpellBuff(buffs, 47865)
		end
	elseif class == "DRUID" then
		AddSpellBuff(buffs, 48469)
		if specTab == 1 then
			AddSpellBuff(buffs, 24907)
			AddSpellBuff(buffs, 48511)
		elseif specTab == 2 then
			AddSpellBuff(buffs, 17007)
		elseif specTab == 3 then
			AddSpellBuff(buffs, 33891)
		end
	end

	return buffs
end

-- Party-scoped buffs shown in raid group headers (subgroup-only; not raid-wide totems).
-- WotLK buffing totems (SoE, Mana Spring, Windfury, Wrath of Air, ToW, Flametongue) hit the
-- whole raid within 30 yd and belong on the composition tab, not per-group headers.
local PARTY_BUFF_CATALOG = {
	{ spellId = 28878, matches = function(member)
		return member.race == "Draenei"
	end },
	{ spellId = 15286, matches = function(member)
		return member.class == "PRIEST" and (tonumber(member.specTab) or 0) == 3
	end },
	{ spellId = 16190, matches = function(member)
		return member.class == "SHAMAN" and (tonumber(member.specTab) or 0) == 3
	end },
}

local function ResolvePartyBuffSpellInfo(spellId)
	if type(GetSpellInfo) ~= "function" or not spellId then
		return nil, nil
	end
	local name, _, icon = GetSpellInfo(spellId)
	if not icon or icon == "" then
		return name, nil
	end
	return name, icon
end

function Addon:PartyBuffCoverageForGroup(members)
	members = members or {}
	local coverage = {}
	for index = 1, #PARTY_BUFF_CATALOG do
		local entry = PARTY_BUFF_CATALOG[index]
		local providers = {}
		for memberIndex = 1, #members do
			local member = members[memberIndex]
			if member and entry.matches(member) then
				providers[#providers + 1] = member.name or "?"
			end
		end
		local spellId = entry.spellId
		local name, icon = ResolvePartyBuffSpellInfo(spellId)
		coverage[index] = {
			spellId = spellId,
			name = name or "",
			icon = icon,
			present = #providers > 0,
			providers = providers,
		}
	end
	return coverage
end

local function IdSet(ids)
	local set = {}
	for index = 1, #ids do
		set[ids[index]] = true
	end
	return set
end

-- Raid-prep consumables (WotLK 3.3.5a). Flask icon is also satisfied by a battle + guardian elixir pair.
local FLASK_IDS = IdSet({
	53755, 53758, 53760, 54212,
	67016, 67017, 67018, 67019,
	53752, 62380,
	17626, 17627, 17628, 17629,
	28518, 28519, 28520, 28521, 28540, 42735,
	41608, 41609, 41610, 41611, 46837, 46839, 32900,
	40567, 40568, 40572, 40573, 40575, 40576, 32600,
})
local BATTLE_ELIXIR_IDS = IdSet({
	33720, 33721, 33726,
	53746, 53748, 53749,
	28490, 28491, 28497, 38954,
	11406, 17538, 11390, 11474, 17539,
	60340, 60341, 60344, 60345, 60346,
	45373,
})
local GUARDIAN_ELIXIR_IDS = IdSet({
	53747, 53748, 53751, 53763, 53764, 60343,
	28509, 28514,
	39625, 39626, 39627, 39628,
	11348, 11349,
	32062, 32067, 32068,
	3593,
})
local FOOD_IDS = IdSet({
	46899,
	57294, 57325, 57327, 57329, 57332, 57334,
	57356, 57358, 57360, 57365, 57367, 57371,
	53284, 57079, 57097, 57100, 57102, 57107, 57111, 57139,
	65363, 65410, 65412, 65414, 65415, 65416, 66623, 58067,
	35272, 43722, 43764,
})
local FOOD_EATING_IDS = IdSet({ 430, 431, 432, 433 })

local wellFedName
local foodEatingName
local flaskNames
local defaultFlaskIcon
local defaultFoodIcon

local function SpellNameAndIcon(spellId)
	if type(GetSpellInfo) ~= "function" or not spellId then
		return nil, nil
	end
	local name, _, icon = GetSpellInfo(spellId)
	if not name or name == "" then
		return nil, icon
	end
	return name, icon
end

local function EnsureConsumableLookups()
	if wellFedName and defaultFlaskIcon and flaskNames then
		return
	end
	wellFedName, defaultFoodIcon = SpellNameAndIcon(46899)
	if not wellFedName then
		wellFedName, defaultFoodIcon = SpellNameAndIcon(57325)
	end
	foodEatingName = SpellNameAndIcon(433)
	flaskNames = {}
	for spellId in pairs(FLASK_IDS) do
		local name, icon = SpellNameAndIcon(spellId)
		if name then
			flaskNames[name] = true
		end
		if not defaultFlaskIcon and icon then
			defaultFlaskIcon = icon
		end
	end
end

local function ConsumableSlot(present, unknown, name, icon, extra)
	extra = extra or {}
	return {
		present = present and true or false,
		unknown = unknown and true or false,
		name = name or "",
		icon = icon,
		elixirPair = extra.elixirPair and true or false,
		reasonKey = extra.reasonKey,
	}
end

local function UnknownConsumables(reasonKey)
	EnsureConsumableLookups()
	return {
		flask = ConsumableSlot(false, true, "", defaultFlaskIcon, { reasonKey = reasonKey }),
		food = ConsumableSlot(false, true, "", defaultFoodIcon, { reasonKey = reasonKey }),
	}
end

function Addon:UnitConsumableStatus(unit)
	EnsureConsumableLookups()
	if not unit or unit == "" or not UnitExists(unit) then
		return UnknownConsumables("RAID_CONSUMABLE_OUT_OF_RANGE")
	end
	if UnitIsConnected and not UnitIsConnected(unit) then
		return UnknownConsumables("RAID_CONSUMABLE_OFFLINE")
	end
	if UnitIsVisible and not UnitIsVisible(unit) then
		return UnknownConsumables("RAID_CONSUMABLE_OUT_OF_RANGE")
	end

	local flaskName, flaskIcon
	local foodName, foodIcon
	local hasBattle = false
	local hasGuardian = false
	if type(UnitBuff) == "function" then
		for index = 1, 40 do
			local name, _, icon, _, _, _, _, _, _, _, spellId = UnitBuff(unit, index)
			if not name then
				break
			end
			spellId = tonumber(spellId)
			local eating = (spellId and FOOD_EATING_IDS[spellId]) or (foodEatingName and name == foodEatingName)
			if not eating then
				if (spellId and FLASK_IDS[spellId]) or (flaskNames and flaskNames[name]) then
					flaskName = name
					flaskIcon = icon
				elseif (spellId and FOOD_IDS[spellId]) or (wellFedName and name == wellFedName) then
					foodName = name
					foodIcon = icon
				elseif spellId and BATTLE_ELIXIR_IDS[spellId] then
					hasBattle = true
					if GUARDIAN_ELIXIR_IDS[spellId] then
						hasGuardian = true
					end
				elseif spellId and GUARDIAN_ELIXIR_IDS[spellId] then
					hasGuardian = true
				end
			end
			if (flaskName or (hasBattle and hasGuardian)) and foodName then
				break
			end
		end
	end

	local flaskPresent = flaskName ~= nil
	local elixirPair = false
	if not flaskPresent and hasBattle and hasGuardian then
		flaskPresent = true
		elixirPair = true
	end

	return {
		flask = ConsumableSlot(flaskPresent, false, flaskName or "", flaskIcon or defaultFlaskIcon, { elixirPair = elixirPair }),
		food = ConsumableSlot(foodName ~= nil, false, foodName or "", foodIcon or defaultFoodIcon, {}),
	}
end

function Addon:SummarizeRaidConsumables(members)
	local summary = {
		total = 0,
		flaskPresent = 0,
		foodPresent = 0,
		flaskMissing = {},
		foodMissing = {},
		flaskUnknown = {},
		foodUnknown = {},
	}
	if type(members) ~= "table" then
		return summary
	end
	for index = 1, #members do
		local member = members[index]
		if member then
			summary.total = summary.total + 1
			local status = self:UnitConsumableStatus(member.unit)
			local name = member.name or "?"
			local flask = status and status.flask
			if flask and flask.present then
				summary.flaskPresent = summary.flaskPresent + 1
			elseif flask and flask.unknown then
				summary.flaskUnknown[#summary.flaskUnknown + 1] = name
			else
				summary.flaskMissing[#summary.flaskMissing + 1] = name
			end
			local food = status and status.food
			if food and food.present then
				summary.foodPresent = summary.foodPresent + 1
			elseif food and food.unknown then
				summary.foodUnknown[#summary.foodUnknown + 1] = name
			else
				summary.foodMissing[#summary.foodMissing + 1] = name
			end
		end
	end
	return summary
end

local function RoleAverageBucket()
	return { gearScore = nil, averageIlvl = nil, count = 0, gsTotal = 0, gsCount = 0, ilvlTotal = 0, ilvlCount = 0 }
end

local function FinishRoleAverage(bucket)
	if bucket.gsCount > 0 then
		bucket.gearScore = math.floor(bucket.gsTotal / bucket.gsCount + 0.5)
	end
	if bucket.ilvlCount > 0 then
		bucket.averageIlvl = math.floor(bucket.ilvlTotal / bucket.ilvlCount + 0.5)
	end
	bucket.gsTotal = nil
	bucket.gsCount = nil
	bucket.ilvlTotal = nil
	bucket.ilvlCount = nil
	return bucket
end

function Addon:AverageRosterStatsByRole(members)
	local roles = {
		tank = RoleAverageBucket(),
		healer = RoleAverageBucket(),
		melee = RoleAverageBucket(),
		ranged = RoleAverageBucket(),
	}
	local overall = RoleAverageBucket()

	if type(members) ~= "table" then
		return overall, roles
	end

	for index = 1, #members do
		local member = members[index]
		if member then
			overall.count = overall.count + 1
			if member.gearScore then
				overall.gsTotal = overall.gsTotal + member.gearScore
				overall.gsCount = overall.gsCount + 1
			end
			if member.averageIlvl then
				overall.ilvlTotal = overall.ilvlTotal + member.averageIlvl
				overall.ilvlCount = overall.ilvlCount + 1
			end

			local bucket = roles[member.role]
			if bucket then
				bucket.count = bucket.count + 1
				if member.gearScore then
					bucket.gsTotal = bucket.gsTotal + member.gearScore
					bucket.gsCount = bucket.gsCount + 1
				end
				if member.averageIlvl then
					bucket.ilvlTotal = bucket.ilvlTotal + member.averageIlvl
					bucket.ilvlCount = bucket.ilvlCount + 1
				end
			end
		end
	end

	FinishRoleAverage(overall)
	FinishRoleAverage(roles.tank)
	FinishRoleAverage(roles.healer)
	FinishRoleAverage(roles.melee)
	FinishRoleAverage(roles.ranged)
	return overall, roles
end
