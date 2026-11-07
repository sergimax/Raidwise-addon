-- Pure note parsing for exported guild roster snapshots.

local Addon = Raidwise
local Parser = {}

local function Trim(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ParseNumber(value)
	if value == "?" then return nil, "unknown" end
	if not value then return nil, "missing" end
	local normalized = value:gsub(",", ".")
	local suffix = normalized:match("[кkK]$")
	if suffix then normalized = normalized:sub(1, -2) end
	if normalized:match("^%d+%.?%d*$") then return tonumber(normalized) * (suffix and 1000 or 1), "known" end
	return nil, "ambiguous"
end

local function ParseSpec(segment, index)
	local original = Trim(segment)
	local spec = { order = index, raw = original, gearScoreStatus = "missing", dpsStatus = "missing" }
	local dpsToken = original:match("%(([^()]*)%)")
	if dpsToken then
		local value, status = ParseNumber(Trim(dpsToken))
		spec.dps, spec.dpsStatus = value, status
		original = Trim(original:gsub("%s*%([^()]*%)", " "))
	end
	local gearToken = original:match("(%d+[.,]?%d*[кkK]?)%s*$")
	if gearToken then
		local value, status = ParseNumber(gearToken)
		spec.gearScore, spec.gearScoreStatus = value, status
		original = Trim(original:sub(1, #original - #gearToken))
	elseif original:match("%?%s*$") then
		spec.gearScoreStatus = "unknown"
		original = Trim(original:gsub("%?%s*$", ""))
	end
	spec.label = original
	if spec.dpsStatus == "known" and original:lower():match("heal") then
		spec.warnings = { "DPS is present for a healing-labeled spec" }
	end
	return spec
end

function Parser.ParsePublicNote(note)
	local raw = tostring(note or "")
	local result = { raw = raw, corrected = nil, specs = {}, warnings = {}, status = "empty" }
	local body = Trim(raw)
	if body == "" then return result end
	local chunks = {}
	for part in body:gmatch("[^/\\]+") do chunks[#chunks + 1] = Trim(part) end
	local separatorCount = select(2, body:gsub("[/\\]", ""))
	if #chunks > 2 then
		result.status = "ambiguous"
		result.warnings[#result.warnings + 1] = "More than two slash-separated segments"
		return result
	end
	local first = chunks[1] or ""
	local prefix, firstSpec = first:match("^(.-)[%.:]%s*(%S.*)$")
	if prefix and (prefix:find("%a") or prefix:find("%d%d%d%d[%.%-/]%d%d?[%.%-/]%d%d?")) then
		result.playerName = Trim(prefix)
		first = firstSpec
	end
	if first ~= "" and not first:match("^[%?%-]+$") then result.specs[#result.specs + 1] = ParseSpec(first, 1) end
	if chunks[2] and chunks[2] ~= "" then result.specs[#result.specs + 1] = ParseSpec(chunks[2], 2) end
	if separatorCount > 0 and #chunks ~= separatorCount + 1 then
		result.status = "ambiguous"
		result.warnings[#result.warnings + 1] = "Empty or malformed spec segment"
	elseif #result.specs == 0 then
		result.status = "partial"
		result.warnings[#result.warnings + 1] = "No spec recognized"
	elseif #result.specs < #chunks then
		result.status = "partial"
	else
		result.status = "parsed"
	end
	for _, spec in ipairs(result.specs) do
		if spec.warnings then
			result.status = "ambiguous"
			for _, warning in ipairs(spec.warnings) do result.warnings[#result.warnings + 1] = warning end
		end
		if spec.gearScoreStatus == "ambiguous" or spec.dpsStatus == "ambiguous" then
			result.status = "ambiguous"
			result.warnings[#result.warnings + 1] = "Unrecognized numeric value"
		end
	end
	return result
end

function Parser.ParseOfficerNote(note)
	local raw = tostring(note or "")
	local value = Trim(raw)
	local result = { raw = raw, status = "missing" }
	if value == "" then return result end
	local ep, gp = value:match("^(%d+)%s*,%s*(%d+)$")
	if ep then
		result.kind, result.ep, result.gp, result.status = "balance", tonumber(ep), tonumber(gp), "parsed"
	else
		result.kind, result.mainReference, result.status = "mainReference", value, "reference"
		if value:match("^%-?%d+[,%.]%d+") or value:match("^%-") then
			result.status = "invalid"
			result.kind = "unknown"
		end
	end
	return result
end

function Parser.ParseGuildRosterSnapshot(snapshot)
	if type(snapshot) ~= "table" or type(snapshot.members) ~= "table" then return nil, "Invalid guild roster snapshot" end
	local parsed = {}
	for index, member in ipairs(snapshot.members) do
		local row = {}
		for key, value in pairs(member) do row[key] = value end
		row.publicNoteParsed = Parser.ParsePublicNote(member.publicNote)
		row.officerNoteParsed = member.officerNoteStatus == "unavailable"
			and { raw = nil, status = "unavailable" } or Parser.ParseOfficerNote(member.officerNote)
		parsed[index] = row
	end
	local output = {}
	for key, value in pairs(snapshot) do if key ~= "members" then output[key] = value end end
	output.members = parsed
	return output
end

Addon.GuildRosterParser = Parser
