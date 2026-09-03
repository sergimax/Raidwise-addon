-- Gear Check trinket pools (WotLK 3.3.5a). Distilled from examples/bis-list-sources.md
-- and docs/Gear-Check-Surface-From-BiS.md §3. Normal + heroic IDs where known.
-- preferred = endgame BiS from example lists (qualifies for A when rest is max).
-- allowed = preferred + ToC / Ulduar / badge progression (no TRINKET_NOT_PREFERRED).

local Addon = Raidwise

local function Ids(...)
	local list = {}
	for index = 1, select("#", ...) do
		local chunk = select(index, ...)
		for itemIndex = 1, #chunk do
			list[#list + 1] = chunk[itemIndex]
		end
	end
	return list
end

-- ICC / Ruby Sanctum
local TR_DBW = { 50362, 50363 }
local TR_SHARPENED = { 54569, 54590 }
local TR_CHARRED = { 54572, 54588 }
local TR_GLOWING = { 54573, 54589 }
local TR_PETRIFIED = { 54571, 54591 }
local TR_PHYLACTERY = { 50360, 50365 }
local TR_DISLODGED = { 50348, 50353 }
local TR_ALTHORS = { 50359, 50366 }
local TR_FANG = { 50361, 50364 }
local TR_SKELETON = { 50356 }
local TR_TINY_ABOM = { 50351, 50706 }
local TR_HERKUML = { 50355 }
local TR_NEEDLE = { 50198 }
local TR_PURIFIED = { 50358 }
local TR_DARK_MATTER_ICC = { 50344 }

-- Trial of the Crusader
local TR_DEATHS_VERDICT = { 47131, 47115, 47303, 47464 }
local TR_REIGN = { 47316, 47182 }
local TR_SOLACE = { 47041, 47059, 47271, 47432 }
local TR_SATRINA = { 47080, 47088 }
local TR_JUGGERNAUT = { 47290, 47451 }
local TR_EITRIGG = { 48021, 47882, 47741, 47949 }

-- Ulduar / earlier raid
-- Mirror of Truth + Brewfest clone Coren's Chromium Coaster: on-use AP, passive crit (starter phys).
local TR_MIRROR = { 40684, 49074 }
-- ToC Triumph badge: on-use AP, passive hit (starter phys).
local TR_MARK_SUPREMACY = { 47734 }
local TR_BANNER = { 47214 }
local TR_BLOOD_OLD_GOD = { 45522 }
local TR_MJOLNIR = { 45931 }
local TR_DARK_MATTER_ULDUAR = { 46038 }
local TR_PYRITE = { 45286 }
local TR_GRIM_TOLL = { 40256 }
local TR_COMET = { 45609 }
local TR_ILLUSTRATION = { 40432 }
local TR_FLARE = { 45518 }
local TR_EYE_BROOD = { 45308 }
local TR_SCALE_FATES = { 45466 }
local TR_METEORITE = { 46051 }

-- Emblems / badges / world
local TR_SUNDIAL = { 40682 }
local TR_VOLATILE = { 47726 }
local TR_JETZE = { 37835 }
local TR_TALISMAN_RESURGENCE = { 48724 }
local TR_SHARD_HEART = { 48722 }
local TR_GLYPH_INDOMITABILITY = { 47735 }
local TR_ICKS_THUMB = { 50235 }
local TR_BLACK_HEART = { 47216 }
local TR_ESSENCE_GOSSAMER = { 37220 }

local P_PHYS = Ids(TR_DBW, TR_SHARPENED)
local A_PHYS = Ids(P_PHYS, TR_DEATHS_VERDICT, TR_NEEDLE, TR_MIRROR, TR_MARK_SUPREMACY, TR_BANNER, TR_BLOOD_OLD_GOD, TR_MJOLNIR, TR_DARK_MATTER_ULDUAR, TR_PYRITE, TR_GRIM_TOLL, TR_COMET)

local P_RET = Ids(P_PHYS, TR_TINY_ABOM)
local A_RET = Ids(A_PHYS, TR_TINY_ABOM)

local P_HUNTER = Ids(TR_DBW, TR_SHARPENED)
local A_HUNTER = Ids(P_HUNTER, TR_DEATHS_VERDICT, TR_NEEDLE, TR_MIRROR, TR_MARK_SUPREMACY, TR_BANNER)

local P_CASTER = Ids(TR_CHARRED, TR_PHYLACTERY, TR_DISLODGED)
local A_CASTER = Ids(P_CASTER, TR_REIGN, TR_SUNDIAL, TR_VOLATILE, TR_JETZE, TR_SHARD_HEART, TR_ILLUSTRATION, TR_FLARE, TR_EYE_BROOD, TR_TALISMAN_RESURGENCE)

local P_HEALER = Ids(TR_GLOWING, TR_ALTHORS, TR_SOLACE, TR_PURIFIED, TR_METEORITE, TR_TALISMAN_RESURGENCE)
local A_HEALER = Ids(P_HEALER, TR_CHARRED, TR_JETZE, TR_SCALE_FATES, TR_SHARD_HEART)

local P_TANK = Ids(TR_FANG, TR_PETRIFIED, TR_SKELETON, TR_SATRINA, TR_JUGGERNAUT, TR_EITRIGG)
local A_TANK = Ids(P_TANK, TR_ICKS_THUMB, TR_GLYPH_INDOMITABILITY, TR_BLACK_HEART, TR_ESSENCE_GOSSAMER, TR_DARK_MATTER_ICC)

local P_ENHANCE = Ids(TR_DBW, TR_SHARPENED, TR_HERKUML, TR_CHARRED, TR_PHYLACTERY)
local A_ENHANCE = Ids(A_PHYS, TR_HERKUML, P_CASTER, TR_NEEDLE)

Addon.GearCheckTrinketPools = {
	phys = { preferred = P_PHYS, allowed = A_PHYS },
	ret = { preferred = P_RET, allowed = A_RET },
	hunter = { preferred = P_HUNTER, allowed = A_HUNTER },
	caster = { preferred = P_CASTER, allowed = A_CASTER },
	healer = { preferred = P_HEALER, allowed = A_HEALER },
	tank = { preferred = P_TANK, allowed = A_TANK },
	enhance = { preferred = P_ENHANCE, allowed = A_ENHANCE },
}
