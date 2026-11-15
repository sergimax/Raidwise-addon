-- Guild module: live operations and a bounded local journal (WoW 3.3.5a).
local Addon = Raidwise
local Guild = {}
Addon.GuildManagement = Guild
local runtime = { elapsed = 0, lastRequest = -10 }

local function Clock() return GetTime and GetTime() or 0 end
local function Now() return time and time() or 0 end
local function Allowed(api) return type(api) == "function" and api() and true or false end

function Guild.Permissions()
	return { view = Allowed(CanViewOfficerNote), public = Allowed(CanEditPublicNote),
		officer = Allowed(CanEditOfficerNote), promote = Allowed(CanGuildPromote), demote = Allowed(CanGuildDemote) }
end

function Guild.Identity()
	if not Allowed(IsInGuild) or not GetGuildInfo or not GetRealmName then return nil end
	local name = GetGuildInfo("player")
	local realm = GetRealmName()
	if not name or not realm then return nil end
	return #realm .. ":" .. realm .. name
end

local function Store()
	local key = Guild.Identity()
	if not key or not Addon.db then return nil end
	if type(Addon.db.guild) ~= "table" then
		-- The retired guildManagement/epgp roots are intentionally not migrated.
		Addon.db.guild = { limit = 1000, guilds = {} }
	end
	local root = Addon.db.guild
	root.guilds = root.guilds or {}
	root.limit = math.max(100, math.min(10000, math.floor(tonumber(root.limit) or 1000)))
	if not root.guilds[key] then root.guilds[key] = { entries = {}, serverSeen = {}, rollMinimumEP = 4000 } end
	return root.guilds[key], root, key
end

local function Prune(store, limit)
	while #store.entries > limit do table.remove(store.entries, 1) end
end

function Guild.SetLimit(value)
	local store, root = Store()
	value = tonumber(value)
	if not store or not value or value ~= value or value < 100 or value > 10000 then return false end
	root.limit = math.floor(value)
	for _, archive in pairs(root.guilds) do Prune(archive, root.limit) end
	return true
end

function Guild.GetLimit()
	local _, root = Store()
	return root and root.limit or 1000
end

function Guild.RollMinimumEP()
	local store = Store()
	return store and store.rollMinimumEP or 4000
end

function Guild.SetRollMinimumEP(value)
	local store = Store()
	value = tonumber(value)
	if not store or not value or value ~= value or value < 0 or value == math.huge or value % 1 ~= 0 then return false end
	store.rollMinimumEP = value
	if Guild.OnChange then Guild.OnChange() end
	return true
end

function Guild.RaidNames()
	local names = {}
	for index = 1, (GetNumRaidMembers and GetNumRaidMembers() or 0) do
		local name, _, subgroup = GetRaidRosterInfo(index)
		if name and subgroup and subgroup >= 1 and subgroup <= 5 then names[Guild.Fold(name)] = true end
	end
	return names
end

function Guild.Balances()
	local store = Store()
	if not store or not store.snapshot or not Addon.GuildEPGP then return nil end
	local canView, threshold = Guild.Permissions().view, Guild.RollMinimumEP()
	local cached = runtime.balances
	if cached and cached.snapshot == store.snapshot and cached.canView == canView and cached.threshold == threshold then return cached.value end
	local snapshot = { members = {} }
	for index, member in ipairs(store.snapshot.members) do
		snapshot.members[index] = { name = member.name, officerNote = canView and member.officerNote or nil,
			officerNoteStatus = canView and store.snapshot.officer and "available" or "unavailable" }
	end
	local parsed = Addon.GuildRosterParser.ParseGuildRosterSnapshot(snapshot)
	local resolved = Addon.GuildRosterLinks.Resolve(parsed)
	local settings = Addon.GuildEPGP.ParseGuildInfo(store.snapshot.guildInfo)
	settings.bisMinimumEP = threshold
	local value = Addon.GuildEPGP.Calculate(resolved, settings)
	runtime.balances = { snapshot = store.snapshot, canView = canView, threshold = threshold, value = value }
	return value
end

local function Append(store, root, entry)
	entry.observedAt = Now()
	store.entries[#store.entries + 1] = entry
	Prune(store, root.limit)
end

-- Explicit Cyrillic folding also works in Lua's C locale.
function Guild.Fold(text)
	text = tostring(text or ""):lower()
	local upper = { "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я" }
	local lower = { "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я" }
	for index, letter in ipairs(upper) do text = text:gsub(letter, lower[index]) end
	return text
end

local function BeginCollection()
	if not Guild.Identity() or not GetNumGuildMembers or not GetGuildRosterInfo
		or not GetGuildRosterShowOffline or not GetGuildRosterShowOffline() then return nil end
	local count = GetNumGuildMembers()
	if not count or count == 0 then return nil end
	local snapshot = { members = {}, at = Now(), key = Guild.Identity(), officer = Guild.Permissions().view,
		guildInfo = GetGuildInfoText and GetGuildInfoText() or nil }
	return { snapshot = snapshot, count = count, index = 1, names = {} }
end

local function ReadMembers(job, budget)
	local snapshot = job.snapshot
	if Guild.Identity() ~= snapshot.key or GetNumGuildMembers() ~= job.count
		or not GetGuildRosterShowOffline() or Guild.Permissions().view ~= snapshot.officer then return "invalid" end
	for index = job.index, math.min(job.count, job.index + budget - 1) do
		local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFile = GetGuildRosterInfo(index)
		if not name or job.names[name] or rankIndex == nil then return "invalid" end
		job.names[name] = true
		snapshot.members[#snapshot.members + 1] = { name = name, rank = rank, rankIndex = rankIndex,
			class = class, classFile = classFile, level = level, online = online and true or false,
			publicNote = note or "", officerNote = snapshot.officer and (officerNote or "") or nil, index = index }
		job.index = index + 1
	end
	if GetNumGuildMembers() ~= job.count or Guild.Identity() ~= snapshot.key
		or Guild.Permissions().view ~= snapshot.officer then return "invalid" end
	return job.index > job.count and "complete" or "working"
end

function Guild.Collect()
	-- Immediate reads are reserved for validating an explicit officer command.
	local job = BeginCollection()
	if job and ReadMembers(job, job.count) == "complete" then return job.snapshot end
end

local function Find(snapshot, name)
	for _, member in ipairs(snapshot and snapshot.members or {}) do
		if member.name == name then return member end
	end
end

local function Notify()
	if Guild.OnChange then Guild.OnChange() end
end

local function SetProgress(phase, current, total)
	runtime.progress = phase and { phase = phase, current = current or 0, total = total,
		finishedAt = phase == "done" and Clock() or nil } or nil
	if Guild.OnProgress then Guild.OnProgress() end
end

function Guild.Progress()
	local progress = runtime.progress
	if progress then return progress.phase, progress.current, progress.total end
end

local function SetStatus(key)
	runtime.status = key
	Notify()
end

function Guild.Status() return runtime.status end
function Guild.Pending() return runtime.pending ~= nil end

function Guild.Accept(snapshot)
	local store, root, key = Store()
	if not store or not snapshot or snapshot.key ~= key then return false end
	local previous = store.snapshot
	if previous then
		for _, member in ipairs(snapshot.members) do
			local old = Find(previous, member.name)
			if old then
				for _, field in ipairs({ "publicNote", "officerNote", "rank" }) do
					if old[field] ~= nil and member[field] ~= nil and old[field] ~= member[field] then
						Append(store, root, { source = "observation", kind = field, name = member.name,
							before = old[field], after = member[field] })
					end
				end
			end
		end
	end
	store.snapshot = snapshot
	local pending = runtime.pending
	if pending and pending.key == key then
		local member = Find(snapshot, pending.name)
		local confirmed = member ~= nil
		for field, value in pairs(pending.values) do
			if not member or member[field] ~= value then confirmed = false end
		end
		if confirmed then
			runtime.pending = nil
			runtime.status = "GUILD_SAVED"
		end
	end
	Notify()
	return true
end

function Guild.Members(query, class, raidOnly, sortKey, descending)
	local store = Store()
	local result, permissions = {}, Guild.Permissions()
	query = Guild.Fold(query)
	local balances = Guild.Balances and Guild.Balances() or nil
	local raidNames = raidOnly and Guild.RaidNames() or nil
	for index, member in ipairs(store and store.snapshot and store.snapshot.members or {}) do
		local haystack = Guild.Fold(member.name .. " " .. member.publicNote .. " " .. (permissions.view and member.officerNote or ""))
		if (not class or class == member.classFile) and (not raidNames or raidNames[Guild.Fold(member.name)])
			and (query == "" or haystack:find(query, 1, true)) then
			local copy = {}
			for field, value in pairs(member) do if field ~= "officerNote" or permissions.view then copy[field] = value end end
			if balances and balances.members[index] then
				local balance = balances.members[index]
				for _, field in ipairs({ "ep", "gp", "effectiveGP", "pr", "bisEligible", "prReason", "balanceName" }) do copy[field] = balance[field] end
			end
			result[#result + 1] = copy
		end
	end
	table.sort(result, function(left, right)
		if sortKey == "ep" or sortKey == "gp" or sortKey == "pr" then
			local leftValue, rightValue = left[sortKey], right[sortKey]
			if leftValue == nil and rightValue ~= nil then return false end
			if rightValue == nil and leftValue ~= nil then return true end
			if leftValue ~= rightValue then
				if descending then return leftValue > rightValue end
				return leftValue < rightValue
			end
		end
		return Guild.Fold(left.name) < Guild.Fold(right.name)
	end)
	return result
end

function Guild.Entries(query, kind)
	local store = Store()
	local result, permissions = {}, Guild.Permissions()
	query = Guild.Fold(query)
	for index = #(store and store.entries or {}), 1, -1 do
		local entry = store.entries[index]
		local matches = Guild.Fold((entry.name or "") .. " " .. (entry.actor or "")):find(query, 1, true)
		if (entry.kind ~= "officerNote" or permissions.view) and (not kind or entry.kind == kind) and matches then
			local copy = {}
			for field, value in pairs(entry) do copy[field] = value end
			result[#result + 1] = copy
		end
	end
	return result
end

local function EventKey(values)
	local parts = {}
	for index = 1, 4 do
		local value = tostring(values[index] or "")
		parts[index] = #value .. ":" .. value
	end
	return table.concat(parts)
end

function Guild.ImportEvents()
	local store, root = Store()
	if not store or not GetNumGuildEvents or not GetGuildEventInfo then return end
	local seen, used, events = {}, {}, {}
	for index = 1, GetNumGuildEvents() do
		local values = { GetGuildEventInfo(index) }
		if values[1] and values[2] then events[#events + 1] = values end
	end
	local function Age(values)
		return (values[5] or 0) * 365 * 86400 + (values[6] or 0) * 30 * 86400
			+ (values[7] or 0) * 86400 + (values[8] or 0) * 3600
	end
	table.sort(events, function(left, right) return Age(left) > Age(right) end)
	for _, values in ipairs(events) do
		local kind, player1, player2, rank = unpack(values)
		if kind and player1 then
			local key = EventKey(values)
			local age, matched = Age(values), false
			for index, previous in ipairs(store.serverSeen) do
				-- Ages have hour precision and drift as time passes. Match occurrences,
				-- not raw age tuples, so an ageing server window is not reimported.
				local tolerance = ((values[5] or 0) > 0 or (values[6] or 0) > 0) and 6 * 86400 or 3700
				if not used[index] and previous.key == key
					and math.abs(age - previous.age - (Now() - previous.at)) <= tolerance then
					used[index], matched = true, true; break
				end
			end
			seen[#seen + 1] = { key = key, age = age, at = Now() }
			if not matched then
				Append(store, root, { source = "server", kind = kind,
					name = player2 or player1, actor = player2 and player1 or nil, after = rank,
					year = values[5], month = values[6], day = values[7], hour = values[8] })
			end
		end
	end
	-- Keep the previous window if a transient reply is empty.
	if next(seen) then store.serverSeen = seen end
	Notify()
end

local function Visible() return Guild.IsVisible and Guild.IsVisible() end

local function RestoreOffline()
	if runtime.offlineOwned and GetGuildRosterShowOffline and GetGuildRosterShowOffline() then
		SetGuildRosterShowOffline(runtime.previousOffline)
	end
	runtime.offlineOwned = nil
end

local function StopPending(status)
	runtime.pending = nil
	runtime.requested = nil
	runtime.collection, runtime.collect = nil, nil
	SetProgress()
	RestoreOffline()
	SetStatus(status)
end

function Guild.Request()
	if not Guild.Identity() then SetStatus("GUILD_NO_GUILD"); return false end
	if not GuildRoster or not SetGuildRosterShowOffline or not GetGuildRosterShowOffline then return false end
	if Clock() - runtime.lastRequest < 2 or runtime.requested then return false end
	Guild.Initialize()
	runtime.lastRequest = Clock()
	runtime.requested = { key = Guild.Identity(), at = Clock() }
	SetProgress("waiting")
	if not GetGuildRosterShowOffline() then
		runtime.previousOffline = false
		runtime.offlineOwned = true
		SetGuildRosterShowOffline(true)
	end
	GuildRoster()
	if QueryGuildEventLog then
		runtime.logKey = Guild.Identity()
		QueryGuildEventLog()
	end
	SetStatus(runtime.pending and "GUILD_PENDING" or "GUILD_LOADING")
	return true
end

function Guild.CanRank(member, direction)
	if not member or not GetGuildInfo or not GuildControlGetNumRanks then return false end
	local _, _, playerRank = GetGuildInfo("player")
	if playerRank == nil then return false end
	local permissions = Guild.Permissions()
	if direction == "promote" then
		return permissions.promote and member.rankIndex > 1 and member.rankIndex > playerRank + 1
	end
	return permissions.demote and member.rankIndex >= 1 and member.rankIndex > playerRank
		and member.rankIndex < GuildControlGetNumRanks() - 1
end

function Guild.Submit(name, original, values, direction)
	if runtime.pending then return false, "GUILD_PENDING" end
	local snapshot = Guild.Collect()
	local member = Find(snapshot, name)
	if not member or not original or original.key ~= Guild.Identity() then return false, "GUILD_STALE" end
	local permissions = Guild.Permissions()
	local changed = {}
	if direction then
		if not Guild.CanRank(member, direction) then return false, "GUILD_DENIED" end
		if member.rankIndex ~= original.rankIndex then return false, "GUILD_CONFLICT" end
		local api = direction == "promote" and GuildPromote or GuildDemote
		if type(api) ~= "function" then return false, "GUILD_DENIED" end
		changed.rankIndex = member.rankIndex + (direction == "promote" and -1 or 1)
		runtime.pending = { key = snapshot.key, name = name, values = changed, at = Clock() }
		api(name)
	else
		-- Validate both edits before sending either command.
		for _, field in ipairs({ "publicNote", "officerNote" }) do
			local value = values and values[field]
			if value ~= nil and value ~= original[field] then
				local allowed = field == "publicNote" and permissions.public or (field == "officerNote" and permissions.view and permissions.officer)
				local api = field == "publicNote" and GuildRosterSetPublicNote or GuildRosterSetOfficerNote
				if not allowed or type(api) ~= "function" then return false, "GUILD_DENIED" end
				if member[field] ~= original[field] then return false, "GUILD_CONFLICT" end
				if type(value) ~= "string" then return false, "GUILD_STALE" end
				changed[field] = value
			end
		end
		if not next(changed) then return false, "GUILD_UNCHANGED" end
		runtime.pending = { key = snapshot.key, name = name, values = changed, at = Clock() }
		-- Resolve index immediately for each command; never use a sorted UI row index.
		for _, field in ipairs({ "publicNote", "officerNote" }) do
			if changed[field] ~= nil then
				local current = Find(Guild.Collect(), name)
				if not current or current[field] ~= original[field] then StopPending("GUILD_CONFLICT"); return false, "GUILD_CONFLICT" end
				local api = field == "publicNote" and GuildRosterSetPublicNote or GuildRosterSetOfficerNote
				api(current.index, changed[field])
			end
		end
	end
	Guild.Initialize()
	SetStatus("GUILD_PENDING")
	Guild.Request()
	return true
end

function Guild.Initialize()
	if runtime.frame then return end
	local frame = CreateFrame("Frame")
	runtime.frame = frame
	frame:RegisterEvent("GUILD_ROSTER_UPDATE")
	frame:RegisterEvent("GUILD_EVENT_LOG_UPDATE")
	frame:RegisterEvent("PLAYER_GUILD_UPDATE")
	frame:RegisterEvent("RAID_ROSTER_UPDATE")
	frame:SetScript("OnEvent", function(_, event)
		if event == "RAID_ROSTER_UPDATE" then
			if Visible() then Notify() end
		elseif event == "PLAYER_GUILD_UPDATE" then
			if runtime.pending and runtime.pending.key ~= Guild.Identity() then StopPending("GUILD_STALE") end
			Notify()
		elseif event == "GUILD_EVENT_LOG_UPDATE" then
			if runtime.logKey == Guild.Identity() and Visible() then Guild.ImportEvents() end
		elseif Visible() or runtime.pending then
			-- Coalesce roster events before reading the game cache.
			runtime.collect = true
		end
	end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		runtime.elapsed = runtime.elapsed + elapsed
		if runtime.elapsed < 0.05 then return end
		runtime.elapsed = 0
		if runtime.pending and runtime.pending.key ~= Guild.Identity() then StopPending("GUILD_STALE") end
		if runtime.requested and runtime.requested.key ~= Guild.Identity() then
			runtime.requested, runtime.collection, runtime.collect = nil, nil, nil
			SetProgress(); RestoreOffline(); SetStatus("GUILD_STALE")
		end
		if runtime.collect then
			runtime.collect = nil
			runtime.collection = (Visible() or runtime.pending) and BeginCollection() or nil
			if (Visible() or runtime.pending) and Guild.Identity() then
				runtime.requested = runtime.requested or { key = Guild.Identity(), at = Clock() }
				SetProgress(runtime.collection and "scanning" or "waiting", 0, runtime.collection and runtime.collection.count)
			else SetProgress() end
		end
		if runtime.collection then
			local job = runtime.collection
			local result = ReadMembers(job, 50)
			if result == "complete" then
				local wasPending = runtime.pending ~= nil
				runtime.collection = nil
				Guild.Accept(job.snapshot)
				runtime.requested = nil
				SetProgress("done", job.count, job.count)
				if not runtime.pending and not wasPending then SetStatus("GUILD_READY") end
				if not Visible() and not runtime.pending then RestoreOffline() end
			elseif result == "working" then SetProgress("scanning", job.index - 1, job.count)
			else runtime.collection = nil; SetProgress("waiting") end
		end
		if runtime.pending and Clock() - runtime.pending.at > 12 then StopPending("GUILD_UNCERTAIN") end
		if runtime.requested and Clock() - runtime.requested.at > 12 then
			runtime.requested, runtime.collection = nil, nil
			SetProgress(); SetStatus("GUILD_UNCERTAIN")
		end
		if runtime.progress and runtime.progress.finishedAt and Clock() - runtime.progress.finishedAt >= 0.75 then SetProgress() end
		if Visible() or runtime.pending then
			if Clock() - runtime.lastRequest >= (runtime.pending and 2 or 30) then Guild.Request() end
			-- Refresh permission-dependent controls even without a roster event.
			local permissions = Guild.Permissions()
			local rights = tostring(permissions.view) .. tostring(permissions.public) .. tostring(permissions.officer)
				.. tostring(permissions.promote) .. tostring(permissions.demote)
			if rights ~= runtime.rights then runtime.rights = rights; Notify() end
		elseif not runtime.pending then
			runtime.collect = nil
			runtime.requested = nil
			runtime.collection = nil
			if runtime.progress then SetProgress() end
			RestoreOffline()
		end
	end)
end

function Guild.Close()
	if not runtime.pending then
		runtime.requested, runtime.collect, runtime.collection = nil, nil, nil
		SetProgress(); RestoreOffline()
	end
end
