-- Pure EPGP policy and priority calculations.

local Addon = Raidwise
local EPGP = { DEFAULT_MINIMUM_GP = 500, DEFAULT_BIS_MINIMUM_EP = 4000 }

local function IsNonNegativeNumber(value)
	return type(value) == "number" and value >= 0 and value == value and math.abs(value) < math.huge
end

function EPGP.Calculate(snapshot, settings)
	if type(snapshot) ~= "table" or type(snapshot.members) ~= "table" then
		return nil, "Invalid resolved guild roster snapshot"
	end
	settings = type(settings) == "table" and settings or {}
	local minimumGP = settings.minimumGP == nil and EPGP.DEFAULT_MINIMUM_GP or settings.minimumGP
	local bisMinimumEP = settings.bisMinimumEP == nil and EPGP.DEFAULT_BIS_MINIMUM_EP or settings.bisMinimumEP
	if not IsNonNegativeNumber(minimumGP) or not IsNonNegativeNumber(bisMinimumEP) then
		return nil, "EPGP settings must be non-negative numbers"
	end
	local rows = {}
	for index, member in ipairs(snapshot.members) do
		local row = {}
		for key, value in pairs(member) do row[key] = value end
		local main = member.mainIndex and snapshot.members[member.mainIndex] or nil
		local balanceOwner = main or (member.mainBalance and member or nil)
		row.balanceOwnerIndex = balanceOwner and (member.mainIndex or index) or nil
		local balance = balanceOwner and balanceOwner.mainBalance or nil
		local validGP = balance and (balance.gp == nil or IsNonNegativeNumber(balance.gp))
		local formulaGP = balance and validGP and ((balance.gp or 0) + minimumGP) or nil
		if balance and IsNonNegativeNumber(balance.ep) and validGP and formulaGP > 0 then
			row.ep, row.gp, row.effectiveGP = balance.ep, balance.gp, formulaGP
			row.pr, row.prStatus = balance.ep / formulaGP, "available"
			row.bisEligible, row.bisEligibilityStatus = balance.ep >= bisMinimumEP, "available"
		elseif balance then
			row.prStatus, row.bisEligibilityStatus = "invalid", "unknown"
			row.prWarning = "EP/GP balance contains invalid values"
		elseif member.linkStatus == "unavailable" or member.linkStatus == "ambiguous"
			or member.linkStatus == "unresolved" or member.linkStatus == "invalid"
			or member.linkStatus == "cycle" or member.linkStatus == "invalid-chain" then
			row.prStatus, row.bisEligibilityStatus = "unknown", "unknown"
		else
			row.prStatus, row.bisEligibilityStatus = "missing", "unknown"
		end
		rows[index] = row
	end
	local result = {}
	for key, value in pairs(snapshot) do if key ~= "members" then result[key] = value end end
	result.members = rows
	result.epgpSettings = { minimumGP = minimumGP, bisMinimumEP = bisMinimumEP }
	return result
end

Addon.GuildEPGP = EPGP
