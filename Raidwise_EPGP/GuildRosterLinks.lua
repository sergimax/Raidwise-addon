-- Pure main/alt relationship resolution for parsed guild roster snapshots.

local Addon = Raidwise
local Resolver = {}

local function NormalizeName(name)
	return (tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower())
end

function Resolver.Resolve(snapshot)
	if type(snapshot) ~= "table" or type(snapshot.members) ~= "table" then
		return nil, "Invalid parsed guild roster snapshot"
	end
	local rows, nameIndex = {}, {}
	for index, member in ipairs(snapshot.members) do
		local row = {}
		for key, value in pairs(member) do row[key] = value end
		row.rosterIndex = index
		row.directMainIndex = nil
		row.mainIndex = nil
		row.linkStatus = "main"
		row.linkWarnings = {}
		rows[index] = row
		local key = NormalizeName(member.name)
		if key ~= "" then
			nameIndex[key] = nameIndex[key] or {}
			nameIndex[key][#nameIndex[key] + 1] = index
		end
	end

	for index, row in ipairs(rows) do
		local note = row.officerNoteParsed
		if not note and Addon.GuildRosterParser then note = Addon.GuildRosterParser.ParseOfficerNote(row.officerNote) end
		row.officerNoteParsed = note or { status = "missing" }
		if note and note.status == "reference" then
			local matches = nameIndex[NormalizeName(note.mainReference)] or {}
			if #matches == 0 then
				row.linkStatus = "unresolved"
				row.linkWarnings[#row.linkWarnings + 1] = "Main character was not found"
			elseif #matches > 1 then
				row.linkStatus = "ambiguous"
				row.linkWarnings[#row.linkWarnings + 1] = "Main reference matches duplicate character names"
			elseif matches[1] == index then
				row.linkStatus = "invalid"
				row.linkWarnings[#row.linkWarnings + 1] = "Character references itself as main"
			else
				row.directMainIndex = matches[1]
				row.linkStatus = "linked"
			end
		elseif note and note.status == "parsed" and note.kind == "balance" then
			row.mainBalance = { ep = note.ep, gp = note.gp }
		elseif note and note.status == "invalid" then
			row.linkStatus = "invalid"
			row.linkWarnings[#row.linkWarnings + 1] = "Officer note is invalid"
		end
	end

	local resolving = {}
	local function ResolveMain(index, path)
		local row = rows[index]
		if row.mainIndex then return row.mainIndex end
		if resolving[index] then
			for cycleIndex in pairs(path) do
				rows[cycleIndex].linkStatus = "cycle"
				rows[cycleIndex].linkWarnings[#rows[cycleIndex].linkWarnings + 1] = "Alt-link cycle detected"
			end
			return nil
		end
		if row.linkStatus == "invalid" or row.linkStatus == "ambiguous" or row.linkStatus == "unresolved" then return nil end
		if not row.directMainIndex then
			if row.mainBalance then row.mainIndex = index end
			return row.mainIndex
		end
		resolving[index] = true
		path[index] = true
		local terminal = ResolveMain(row.directMainIndex, path)
		path[index] = nil
		resolving[index] = nil
		if terminal then
			local target = rows[row.directMainIndex]
			if row.mainBalance then
				row.linkStatus = "conflict"
				row.linkWarnings[#row.linkWarnings + 1] = "Linked character also has an EP/GP balance"
			elseif target.directMainIndex then
				row.linkStatus = "chain"
			end
			row.mainIndex = terminal
		elseif row.linkStatus == "linked" then
			row.linkStatus = "invalid-chain"
			row.linkWarnings[#row.linkWarnings + 1] = "Referenced character does not resolve to a main balance"
		end
		return terminal
	end

	for index = 1, #rows do ResolveMain(index, {}) end
	local mains = {}
	for _, row in ipairs(rows) do
		if row.mainIndex then
			mains[row.mainIndex] = mains[row.mainIndex] or { mainIndex = row.mainIndex, memberIndexes = {} }
			mains[row.mainIndex].memberIndexes[#mains[row.mainIndex].memberIndexes + 1] = row.rosterIndex
		end
	end
	local groups = {}
	for _, group in pairs(mains) do groups[#groups + 1] = group end
	table.sort(groups, function(left, right) return left.mainIndex < right.mainIndex end)
	local result = {}
	for key, value in pairs(snapshot) do if key ~= "members" then result[key] = value end end
	result.members, result.characterGroups = rows, groups
	return result
end

Addon.GuildRosterLinks = Resolver
