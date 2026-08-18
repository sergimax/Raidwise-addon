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
