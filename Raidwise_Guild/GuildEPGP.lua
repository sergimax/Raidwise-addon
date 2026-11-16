-- Pure balance and priority calculations for the guild page.

local Addon = Raidwise
local EPGP = { DEFAULT_MINIMUM_GP = 500, DEFAULT_BIS_MINIMUM_EP = 4000 }

local function IsNonNegativeNumber(value)
	return type(value) == "number" and value >= 0 and value == value and math.abs(value) < math.huge
end

function EPGP.ParseGuildInfo(text)
	local config = { minimumGP = 500, baseStatus = "default" }
	local inside, markers, base = false, 0, nil
	for line in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line == "-EPGP-" then
			markers = markers + 1; inside = not inside
		elseif inside and line:match("^@BASE_GP") then
			local value = line:match("^@BASE_GP:%s*(%d+)%s*$")
			value = value and tonumber(value)
			if not IsNonNegativeNumber(value) or (base ~= nil and base ~= value) then config.baseStatus = "invalid"
			else base = value end
		end
	end
	if markers ~= 0 and markers ~= 2 then config.baseStatus = "invalid" end
	if config.baseStatus == "invalid" then config.minimumGP = nil
	elseif base ~= nil then config.minimumGP, config.baseStatus = base, "guild" end
	return config
end

function EPGP.Calculate(snapshot, settings)
	if type(snapshot) ~= "table" or type(snapshot.members) ~= "table" then
		return nil, "Invalid resolved guild roster snapshot"
	end
	settings = type(settings) == "table" and settings or {}
	local minimumGP = settings.minimumGP == nil and EPGP.DEFAULT_MINIMUM_GP or settings.minimumGP
	local bisMinimumEP = settings.bisMinimumEP == nil and EPGP.DEFAULT_BIS_MINIMUM_EP or settings.bisMinimumEP
	if (settings.baseStatus ~= "invalid" and not IsNonNegativeNumber(minimumGP)) or not IsNonNegativeNumber(bisMinimumEP) then
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
		local validBalance = balance and IsNonNegativeNumber(balance.ep) and validGP
		local formulaGP = validBalance and settings.baseStatus ~= "invalid" and ((balance.gp or 0) + minimumGP) or nil
		if validBalance then
			row.ep, row.gp, row.effectiveGP = balance.ep, balance.gp or 0, formulaGP
			row.bisEligible, row.bisEligibilityStatus = balance.ep >= bisMinimumEP, "available"
			row.balanceName = balanceOwner.name
			if formulaGP and formulaGP > 0 then row.pr, row.prStatus = balance.ep / formulaGP, "available"
			else row.prStatus, row.prReason = "invalid", settings.baseStatus == "invalid" and "GUILD_REASON_BASE" or "GUILD_REASON_ZERO" end
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
		if not validBalance then row.prReason = "GUILD_REASON_" .. string.upper(member.linkStatus or "missing"):gsub("%-", "_") end
		rows[index] = row
	end
	local result = {}
	for key, value in pairs(snapshot) do if key ~= "members" then result[key] = value end end
	result.members = rows
	result.epgpSettings = { minimumGP = settings.baseStatus ~= "invalid" and minimumGP or nil,
		baseStatus = settings.baseStatus or "default", bisMinimumEP = bisMinimumEP }
	return result
end

Addon.GuildEPGP = EPGP
