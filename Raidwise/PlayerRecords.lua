-- Active local profile core; screen APIs use this store through PlayerRecordBridge.
local Addon = Raidwise
local drafts = setmetatable({}, {__mode = "k"})
local rejectedStores = setmetatable({}, {__mode = "k"})
local eventTypes = {}
for eventType in string.gmatch("organized_run disrupted_run fulfilled_agreement broke_agreement prepared_for_run followed_instructions late_arrival no_arrival afk left_early rage_quit fair_loot unfair_loot loot_dispute changed_loot_rules helped_player helped_with_gear explained_mechanics handled_role failed_mechanics toxic_behavior scam", "%S+") do
	eventTypes[eventType] = true
end
local factOrder = {"raid_leader", "pug_raid_leader", "guild_master", "guild_officer"}
local sections = {"identities", "profiles", "notes", "changes", "encounters", "meetingStats", "groups", "generations"}

local function Copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = Copy(child) end
	return result
end

local function Equal(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, value in pairs(left) do if not Equal(value, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end
	return true
end

local function Fold(value)
	return (strlower or string.lower)(value)
end

local function Safe(value)
	return type(value) == "string" and value ~= "" and not value:find("[%c|:]")
end

local function Identity(seed)
	if type(seed) ~= "table" or not Safe(seed.name) or seed.name:find("[%s%-]") then return nil end
	local realm = seed.realm
	if not realm or realm == "" then realm = type(GetRealmName) == "function" and GetRealmName() end
	if not Safe(realm) then return nil end
	if seed.guid ~= nil and not Safe(seed.guid) then return nil end
	return {guid=seed.guid, name=seed.name, realm=realm, class=seed.class}
end

local function NamedKey(identity)
	return "name:" .. Fold(identity.realm):gsub("%s+", "") .. ":" .. Fold(identity.name)
end

local function Actor()
	local guid = type(UnitGUID) == "function" and UnitGUID("player")
	local name, realm
	if type(UnitName) == "function" then name, realm = UnitName("player") end
	if not guid then return nil end
	return Identity({guid=guid, name=name, realm=realm})
end

local function NextId(store)
	store.nextId = store.nextId + 1
	return tostring(store.nextId)
end

local function IsList(values)
	if type(values) ~= "table" then return false end
	local count = 0
	for key in pairs(values) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
		count = count + 1
	end
	for index = 1, count do if values[index] == nil then return false end end
	return count == #values
end

local function EventIndex(events)
	if not IsList(events) then return nil end
	local result = {}
	for index, event in ipairs(events) do
		if type(event) ~= "table" or type(event.id) ~= "string" or result[event.id] then return nil end
		result[event.id] = index
	end
	return result
end

-- Positions make deletions/reordering reversible without copying unchanged events.
local function EventDelta(before, after)
	local beforeIndex, afterIndex = EventIndex(before), EventIndex(after)
	if not beforeIndex or not afterIndex then return nil end
	local delta = {}
	for index, event in ipairs(before) do
		local nextIndex = afterIndex[event.id]
		local nextEvent = nextIndex and after[nextIndex]
		local changed = not Equal(event, nextEvent)
		if changed or index ~= nextIndex then
			delta[#delta + 1] = {id=event.id, beforeIndex=index, afterIndex=nextIndex,
				before=changed and Copy(event) or nil, after=changed and Copy(nextEvent) or nil}
		end
	end
	for index, event in ipairs(after) do
		if not beforeIndex[event.id] then
			delta[#delta + 1] = {id=event.id, afterIndex=index, after=Copy(event)}
		end
	end
	return delta
end

local function MigrateJournal(store)
	if store.journalVersion == 2 then return true end
	if store.journalVersion ~= nil and store.journalVersion ~= 1 then return nil, "UNSUPPORTED_JOURNAL" end
	local migrated = {}
	for key, rows in pairs(store.changes) do
		if not IsList(rows) then return nil, "INVALID_JOURNAL" end
		local target, previousEvents = {}, {}
		for _, change in ipairs(rows) do
			if type(change) ~= "table" then return nil, "INVALID_JOURNAL" end
			local result = {}
			for field, value in pairs(change) do
				if change.kind ~= "events" or (field ~= "before" and field ~= "after") then result[field] = Copy(value) end
			end
			if change.kind == "events" then
				local delta = EventDelta(change.before, change.after)
				if not delta then return nil, "INVALID_JOURNAL" end
				-- Preserve an initial snapshot or a gap in imported/historical journals.
				if not Equal(previousEvents, change.before) then result.baseline = Copy(change.before) end
				result.events = delta
				previousEvents = change.after
			end
			target[#target + 1] = result
		end
		migrated[key] = target
	end
	-- Publish only after every row is converted; failures leave the source intact.
	store.changes, store.journalVersion = migrated, 2
	return true
end

local function Number(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function Integer(value)
	return Number(value) and value % 1 == 0
end

local function Fields(value, fields, validate)
	for _, field in ipairs(fields) do
		if value[field] ~= nil and not validate(value[field]) then return false end
	end
	return true
end

local function Text(value) return type(value) == "string" end

local function Plain(value, seen, depth)
	if type(value) ~= "table" then
		return value == nil or Text(value) or type(value) == "boolean" or (type(value) == "number" and value == value and math.abs(value) < math.huge)
	end
	seen, depth = seen or {}, depth or 0
	if seen[value] or depth > 64 then return false end
	seen[value] = true
	for key, child in pairs(value) do
		if (not Text(key) and type(key) ~= "number") or not Plain(child, seen, depth + 1) then return false end
	end
	seen[value] = nil
	return true
end

local function Author(value)
	return type(value) == "table" and Fields(value, {"guid", "name", "realm", "class"}, Text)
end

local function Facts(value)
	if not IsList(value) then return false end
	local seen = {}
	for _, fact in ipairs(value) do
		local valid = false
		for _, known in ipairs(factOrder) do if fact == known then valid = true end end
		if not valid or seen[fact] then return false end
		seen[fact] = true
	end
	return true
end

local function Opinion(value)
	return value == "positive" or value == "neutral" or value == "negative"
end

local function Event(value)
	return type(value) == "table" and Safe(value.id) and eventTypes[value.type] == true
		and Number(value.eventAt) and Number(value.updatedAt) and Author(value.author)
		and type(value.context) == "table" and Text(value.context.zoneName)
		and Fields(value.context, {"instanceName"}, Text)
end

local function Events(value)
	if not EventIndex(value) then return false end
	for _, event in ipairs(value) do if not Event(event) then return false end end
	return true
end

local function Journal(rows, version)
	if not IsList(rows) then return false end
	for _, row in ipairs(rows) do
		if type(row) ~= "table" or not Safe(row.id) or not Number(row.at) or not Author(row.actor) or not Text(row.kind) then return false end
		if row.kind == "events" then
			if version ~= 2 then
				if not Events(row.before) or not Events(row.after) then return false end
			else
				if not IsList(row.events) or (row.baseline ~= nil and not Events(row.baseline)) then return false end
				local seen = {}
				for _, delta in ipairs(row.events) do
					if type(delta) ~= "table" or not Safe(delta.id) or seen[delta.id] then return false end
					seen[delta.id] = true
					if not delta.beforeIndex and not delta.afterIndex then return false end
					if not delta.beforeIndex and not delta.after then return false end
					if not delta.afterIndex and not delta.before then return false end
					for _, field in ipairs({"beforeIndex", "afterIndex"}) do
						if delta[field] ~= nil and (not Integer(delta[field]) or delta[field] < 1) then return false end
					end
					for _, field in ipairs({"before", "after"}) do
						if delta[field] ~= nil and (not Event(delta[field]) or delta[field].id ~= delta.id) then return false end
					end
				end
			end
		elseif row.kind == "opinion" then
			if not Fields(row, {"before", "after"}, Opinion) then return false end
		elseif row.kind == "facts" then
			if not Facts(row.before) or not Facts(row.after) then return false end
		end
		if row.detail ~= nil and not Text(row.detail) and not (type(row.detail) == "table" and Text(row.detail.name)) then return false end
	end
	return true
end

local function ValidEntry(store, section, key, value, observer)
	if not Text(key) or key == "" or not Plain(value) then return false end
	if section == "generations" then return Integer(value) end
	if type(value) ~= "table" then return false end
	if section == "identities" then
		return Identity({name=value.name, realm=value.realm}) ~= nil and Text(value.realm)
			and Fields(value, {"guid", "class", "classLabel", "spec", "specIcon", "race", "faction", "guildName", "guildRank"}, Text)
			and Fields(value, {"gearScore", "averageIlvl", "gender", "lastScannedAt"}, Number)
	elseif section == "profiles" then
		return Facts(value.facts) and Events(value.events) and Integer(value.revision)
			and Fields(value, {"opinion"}, Opinion) and Fields(value, {"author"}, Author)
			and Fields(value, {"createdAt", "updatedAt"}, Number)
	elseif section == "notes" then
		return Text(value.text) and Integer(value.revision) and Fields(value, {"updatedAt"}, Number)
	elseif section == "changes" then return Journal(value, store.journalVersion)
	elseif section == "meetingStats" then
		return Integer(value.count) and Fields(value, {"firstMetAt", "lastMetAt"}, Number)
			and Fields(value, {"lastEncounterId"}, Text)
	elseif section == "encounters" then
		if not IsList(value) then return false end
		for _, row in ipairs(value) do
			if type(row) ~= "table" or not Safe(row.id) or not Number(row.startedAt) or not Number(row.lastSeenAt)
				or not Fields(row, {"endedAt", "lastAbsentAt"}, Number) or not IsList(row.places) then return false end
			for _, place in ipairs(row.places) do
				if type(place) ~= "table" or not Text(place.zoneName) or not Number(place.firstSeenAt) or not Number(place.lastSeenAt)
					or not Fields(place, {"instanceName"}, Text) then return false end
			end
		end
		local stats = store.meetingStats[observer]
		return #value == 0 or (type(stats) == "table" and ValidEntry(store, "meetingStats", key, stats[key]))
	elseif section == "groups" then
		if type(value.members) ~= "table" or not Text(value.mainKey) then return false end
		for member, present in pairs(value.members) do
			if not Text(member) or present ~= true or not store.identities[member] then return false end
		end
		return value.members[value.mainKey] == true
	end
	return false
end

local function IsolateEntries(store)
	local quarantine = store.quarantine or {version=1, entries={}}
	local function Isolate(section, key, value, observer)
		quarantine.entries[#quarantine.entries + 1] = {section=section, key=key, observer=observer,
			value=value, journalVersion=store.journalVersion or 1, reason="INVALID_ENTRY", at=time()}
	end
	-- Validate identities/counters before the groups/encounters that refer to them.
	for _, section in ipairs({"identities", "profiles", "notes", "changes", "generations", "meetingStats", "encounters", "groups"}) do
		for key, value in pairs(store[section]) do
			if section == "meetingStats" or section == "encounters" then
				if not Text(key) or type(value) ~= "table" then
					Isolate(section, key, value); store[section][key] = nil
				else
					for subject, rows in pairs(value) do
						if not ValidEntry(store, section, subject, rows, key) then
							Isolate(section, subject, rows, key); value[subject] = nil
						end
					end
				end
			elseif not ValidEntry(store, section, key, value) then
				Isolate(section, key, value); store[section][key] = nil
				-- Invalidate drafts without changing healthy profile/note contents.
				if section == "profiles" or section == "notes" or section == "generations" or section == "identities" then
					for draft, state in pairs(drafts) do if state.store == store and state.key == key then drafts[draft] = nil end end
				end
			end
		end
	end
	if #quarantine.entries > 0 then store.quarantine = quarantine end
end

function Addon:GetPlayerRecordStore()
	local store = self.db and self.db.playerRecords
	if type(store) ~= "table" or store.schemaVersion ~= 1 or rejectedStores[store] then return nil end
	if store.journalVersion ~= nil and store.journalVersion ~= 1 and store.journalVersion ~= 2 then return nil end
	for _, section in ipairs(sections) do if type(store[section]) ~= "table" then return nil end end
	if not Integer(store.nextId) then return nil end
	return store
end

function Addon:InitializePlayerRecords()
	if not self.db then return nil, "NO_DATABASE" end
	if self.db.playerRecords ~= nil then
		local current = self.db.playerRecords
		if type(current) ~= "table" or current.schemaVersion ~= 1 then return nil, "UNSUPPORTED_SCHEMA" end
		local function Reject(reason) rejectedStores[current] = reason; return nil, reason end
		for _, section in ipairs(sections) do
			if type(current[section]) ~= "table" then return Reject("INVALID_STORE") end
		end
		if not Integer(current.nextId) then return Reject("INVALID_STORE") end
		if current.journalVersion ~= nil and current.journalVersion ~= 1 and current.journalVersion ~= 2 then return Reject("UNSUPPORTED_JOURNAL") end
		if current.quarantine ~= nil and (type(current.quarantine) ~= "table" or current.quarantine.version ~= 1
			or not IsList(current.quarantine.entries)) then return Reject("INVALID_QUARANTINE") end
		IsolateEntries(current)
		local migrated, err = MigrateJournal(current)
		if not migrated then return Reject(err) end
		rejectedStores[current] = nil
		return self:GetPlayerRecordStore()
	end
	local store = {schemaVersion=1, journalVersion=2, nextId=0}
	for _, section in ipairs(sections) do store[section] = {} end
	self.db.playerRecords = store
	return store
end

function Addon:GetPlayerRecordEventTypes()
	return Copy(eventTypes)
end

function Addon:GetPlayerRecordHealth()
	local store = self.db and self.db.playerRecords
	local err = type(store) == "table" and rejectedStores[store]
	if not self:GetPlayerRecordStore() then
		if type(store) ~= "table" or store.schemaVersion ~= 1 then err = "UNSUPPORTED_SCHEMA" end
		return {status="unavailable", reason=err or "INVALID_STORE", quarantined=0}
	end
	local count = 0
	for _, entry in ipairs(store.quarantine and store.quarantine.entries or {}) do
		if type(entry) == "table" and not entry.restored then count = count + 1 end
	end
	return {status=count > 0 and "quarantined" or "healthy", quarantined=count}
end

-- Explicit repair only: retain the original archive, never overwrite live data.
function Addon:RestorePlayerRecordEntry(index, replacement)
	local store = self:GetPlayerRecordStore()
	local entry = store and store.quarantine and store.quarantine.entries[index]
	if type(entry) ~= "table" or entry.restored then return nil, "UNKNOWN_QUARANTINE_ENTRY" end
	local section, key, observer = entry.section, entry.key, entry.observer
	local known = false
	for _, name in ipairs(sections) do if section == name then known = true end end
	if not known or not Text(key) or (observer ~= nil and not Text(observer)) then return nil, "INVALID_REPAIR" end
	if observer and section ~= "encounters" and section ~= "meetingStats" then return nil, "INVALID_REPAIR" end
	local target = store[section]
	if observer then target = target[observer] end
	if target and target[key] ~= nil then return nil, "REPAIR_CONFLICT" end
	local context = {identities=store.identities, meetingStats=store.meetingStats, journalVersion=entry.journalVersion}
	if (section == "encounters" or section == "meetingStats") and not observer then
		if type(replacement) ~= "table" or not Plain(replacement) then return nil, "INVALID_REPAIR" end
		for subject, value in pairs(replacement) do
			if not ValidEntry(context, section, subject, value, key) then return nil, "INVALID_REPAIR" end
		end
	elseif not ValidEntry(context, section, key, replacement, observer) then return nil, "INVALID_REPAIR" end
	local repaired = Copy(replacement)
	if section == "changes" then
		local temporary = {journalVersion=entry.journalVersion, changes={[key]=repaired}}
		local ok, err = MigrateJournal(temporary)
		if not ok then return nil, err end
		repaired = temporary.changes[key]
	end
	if observer and not target then target = {}; store[section][observer] = target end
	target[key] = repaired
	entry.restored = true
	for draft, state in pairs(drafts) do if state.store == store and state.key == key then drafts[draft] = nil end end
	return true
end

function Addon:GetPlayerRecordProfile(key)
	local store = self:GetPlayerRecordStore()
	if not store then return nil end
	return Copy({identity=store.identities[key], profile=store.profiles[key], note=store.notes[key]})
end

function Addon:GetPlayerRecordChanges(key)
	local store = self:GetPlayerRecordStore()
	return Copy(store and store.changes[key] or {})
end

function Addon:GetPlayerRecordChangeCount(key)
	local store = self:GetPlayerRecordStore()
	return #(store and store.changes[key] or {})
end

-- Newest first, bounded copies; callers can use the count to clamp their page.
function Addon:GetPlayerRecordChangePage(key, page)
	local store = self:GetPlayerRecordStore()
	local rows = store and store.changes[key] or {}
	page = math.max(1, math.floor(tonumber(page) or 1))
	local result = {}
	local last = #rows - (page - 1) * 25
	for index = last, math.max(1, last - 24), -1 do result[#result + 1] = Copy(rows[index]) end
	return result
end

-- Compatibility snapshot for explicit whole-record consumers, not UI refreshes.
function Addon:GetPlayerRecord(key)
	local record = self:GetPlayerRecordProfile(key)
	if record then record.changes = self:GetPlayerRecordChanges(key) end
	return record
end

function Addon:IsPlayerRecordFilled(key)
	local store = self:GetPlayerRecordStore()
	if not store then return false end
	local profile, note = store.profiles[key], store.notes[key]
	return profile ~= nil and (profile.opinion ~= nil or #profile.facts > 0 or #profile.events > 0)
		or note ~= nil and note.text:find("%S") ~= nil
end

-- Re-key both dimensions of observer/subject maps, refusing ambiguous merges.
local function CanMoveNested(map, oldKey, newKey)
	if map[oldKey] and map[newKey] then return false end
	for _, rows in pairs(map) do
		if rows[oldKey] and rows[newKey] then return false end
	end
	return true
end

local function MoveNested(map, oldKey, newKey)
	if map[oldKey] then map[newKey], map[oldKey] = map[oldKey], nil end
	for _, rows in pairs(map) do
		if rows[oldKey] then rows[newKey], rows[oldKey] = rows[oldKey], nil end
	end
end

function Addon:UpsertPlayerRecordIdentity(seed)
	local store = self:GetPlayerRecordStore()
	if not store then return nil, "NOT_INITIALIZED" end
	local identity = Identity(seed)
	if not identity then return nil, "INVALID_IDENTITY" end
	local oldKey = NamedKey(identity)
	local key = identity.guid or oldKey
	if not identity.guid then
		for savedKey, saved in pairs(store.identities) do
			if saved.guid and NamedKey(saved) == oldKey then
				if key ~= oldKey and key ~= savedKey then return nil, "IDENTITY_CONFLICT" end
				key = savedKey
			end
		end
	end
	if key ~= oldKey and store.identities[oldKey] then
		local sourceHasData, targetHasData = false, false
		for _, section in ipairs({"profiles", "notes", "changes", "generations"}) do
			if store[section][oldKey] then sourceHasData = true end
			if store[section][key] then targetHasData = true end
		end
		if sourceHasData and targetHasData then return nil, "IDENTITY_CONFLICT" end
		if not CanMoveNested(store.encounters, oldKey, key) or not CanMoveNested(store.meetingStats, oldKey, key) then
			return nil, "IDENTITY_CONFLICT"
		end
		for _, group in pairs(store.groups) do
			if group.members[oldKey] and group.members[key] then return nil, "IDENTITY_CONFLICT" end
		end
		for _, section in ipairs({"profiles", "notes", "changes", "generations"}) do
			if store[section][oldKey] then store[section][key], store[section][oldKey] = store[section][oldKey], nil end
		end
		MoveNested(store.encounters, oldKey, key)
		MoveNested(store.meetingStats, oldKey, key)
		for _, group in pairs(store.groups) do
			if group.members[oldKey] then group.members[key], group.members[oldKey] = group.members[oldKey], nil end
			if group.mainKey == oldKey then group.mainKey = key end
		end
		for draft, state in pairs(drafts) do
			if state.store == store and state.key == oldKey then state.key, draft.key = key, key end
		end
		store.identities[oldKey] = nil
	end
	local previous = store.identities[key] or {}
	for field, value in pairs(identity) do previous[field] = value end
	store.identities[key] = previous
	return key
end

function Addon:CreatePlayerRecordDraft(key)
	local store = self:GetPlayerRecordStore()
	if not store or not store.identities[key] then return nil, "UNKNOWN_CHARACTER" end
	local profile, note = store.profiles[key], store.notes[key]
	local draft = {key=key, opinion=profile and profile.opinion, facts=Copy(profile and profile.facts or {}),
		events=Copy(profile and profile.events or {}), note=note and note.text or ""}
	drafts[draft] = {store=store, key=key, revision=profile and profile.revision or 0,
		noteRevision=note and note.revision or 0, generation=store.generations[key] or 0,
		events=Copy(profile and profile.events or {}), added={}}
	return draft
end

function Addon:AddPlayerRecordDraftEvent(draft, eventType)
	local state = drafts[draft]
	if not state or not eventTypes[eventType] then return nil, "INVALID_EVENT" end
	local actor = Actor()
	if not actor then return nil, "AUTHOR_UNAVAILABLE" end
	local event = {id=NextId(state.store), type=eventType, eventAt=time(), updatedAt=time(),
		context=Copy(self.CaptureEventContext and self:CaptureEventContext() or {zoneName=""}), author=actor}
	state.added[event.id] = Copy(event)
	draft.events[#draft.events + 1] = Copy(event)
	return event.id
end

local function NormalizeFacts(facts)
	if not IsList(facts) then return nil end
	local selected, result = {}, {}
	for key, fact in pairs(facts) do
		if type(key) ~= "number" or key < 1 or key > #facts or key % 1 ~= 0 then return nil end
		if selected[fact] then return nil end
		local found = false
		for _, valid in ipairs(factOrder) do if valid == fact then found = true end end
		if not found then return nil end
		selected[fact] = true
	end
	for _, fact in ipairs(factOrder) do if selected[fact] then result[#result + 1] = fact end end
	return result
end

function Addon:CommitPlayerRecordDraft(draft)
	local state = drafts[draft]
	local store = self:GetPlayerRecordStore()
	if not state or state.store ~= store or draft.key ~= state.key then return nil, "INVALID_DRAFT" end
	local key = state.key
	local previous, note = store.profiles[key], store.notes[key]
	if not store.identities[key] or (store.generations[key] or 0) ~= state.generation
		or (previous and previous.revision or 0) ~= state.revision
		or (note and note.revision or 0) ~= state.noteRevision then return nil, "STALE_DRAFT" end
	if draft.opinion ~= nil and draft.opinion ~= "positive" and draft.opinion ~= "neutral" and draft.opinion ~= "negative" then
		return nil, "INVALID_OPINION"
	end
	local facts = NormalizeFacts(draft.facts)
	if not facts or type(draft.note) ~= "string" or not IsList(draft.events) then return nil, "INVALID_FIELDS" end
	local actor = Actor()
	local events, known, seen = {}, {}, {}
	for _, event in ipairs(state.events) do known[event.id] = event end
	for eventIndex, event in pairs(draft.events) do
		if type(eventIndex) ~= "number" or eventIndex % 1 ~= 0 or eventIndex < 1 or eventIndex > #draft.events then return nil, "INVALID_EVENT" end
		if type(event) ~= "table" or not eventTypes[event.type] or seen[event.id] then return nil, "INVALID_EVENT" end
		local original = known[event.id] or state.added[event.id]
		if not original then return nil, "INVALID_EVENT" end
		local expected = Copy(original)
		expected.type = event.type
		if not Equal(event, expected) then return nil, "IMMUTABLE_EVENT_FIELDS" end
		seen[event.id] = true
	end
	for _, event in ipairs(draft.events) do
		local original = known[event.id] or state.added[event.id]
		local saved = Copy(original)
		if saved.type ~= event.type then saved.type, saved.author, saved.updatedAt = event.type, Copy(actor), time() end
		events[#events + 1] = saved
	end
	local before = previous or {facts={}, events={}}
	local changed = before.opinion ~= draft.opinion or not Equal(before.facts, facts) or not Equal(before.events, events)
	if changed then
		if not actor then return nil, "AUTHOR_UNAVAILABLE" end
		local subject = store.identities[key]
		if key == actor.guid or NamedKey(subject) == NamedKey(actor) then return nil, "SELF_RATING" end
	end
	local noteChanged = (note and note.text or "") ~= draft.note
	if not changed and not noteChanged then return true, false end
	local now = time()
	if changed then
		local profile = {opinion=draft.opinion, facts=facts, events=events, author=Copy(actor),
			createdAt=previous and previous.createdAt or now, updatedAt=now, revision=state.revision + 1}
		store.profiles[key] = profile
		local changes = store.changes[key] or {}
		-- No private text enters the change journal.
		for _, field in ipairs({"opinion", "facts", "events"}) do
			if not Equal(before[field], profile[field]) then
				local change = {id=NextId(store), at=now, actor=Copy(actor), kind=field}
				if field == "events" then
					change.events = EventDelta(before.events, profile.events)
				else
					change.before, change.after = Copy(before[field]), Copy(profile[field])
				end
				changes[#changes + 1] = change
			end
		end
		store.changes[key] = changes
	end
	if noteChanged then store.notes[key] = {text=draft.note, updatedAt=now, revision=state.noteRevision + 1} end
	local fresh = self:CreatePlayerRecordDraft(key)
	for field in pairs(draft) do draft[field] = nil end
	for field, value in pairs(fresh) do draft[field] = value end
	drafts[draft], drafts[fresh] = drafts[fresh], nil
	return true, true
end

-- Display catalog for the local profile; IDs are the saved-data contract.
local profileEventCatalog = {
	{id="organized_run", ru="Организовал совместное прохождение", en="Organized a run"},
	{id="disrupted_run", ru="Сорвал организацию прохождения", en="Disrupted a run"},
	{id="fulfilled_agreement", ru="Выполнил договорённость", en="Kept an agreement"},
	{id="broke_agreement", ru="Нарушил договорённость", en="Broke an agreement"},
	{id="prepared_for_run", ru="Пришёл подготовленным", en="Came prepared"},
	{id="followed_instructions", ru="Выполнил указания в прохождении", en="Followed instructions"},
	{id="late_arrival", ru="Опоздал", en="Arrived late"},
	{id="no_arrival", ru="Не явился по договорённости", en="Did not arrive as agreed"},
	{id="afk", ru="Ушёл AFK во время прохождения", en="Went AFK during a run"},
	{id="left_early", ru="Ушёл до завершения прохождения", en="Left before completion"},
	{id="rage_quit", ru="Покинул группу после конфликта", en="Left after a conflict"},
	{id="fair_loot", ru="Распределил добычу по договорённости", en="Distributed loot as agreed"},
	{id="unfair_loot", ru="Нарушил договорённость о добыче", en="Broke a loot agreement"},
	{id="loot_dispute", ru="Участвовал в споре о добыче", en="Participated in a loot dispute"},
	{id="changed_loot_rules", ru="Изменил правила добычи после начала", en="Changed loot rules after starting"},
	{id="helped_player", ru="Помог игроку", en="Helped a player"},
	{id="helped_with_gear", ru="Помог со снаряжением", en="Helped with gear"},
	{id="explained_mechanics", ru="Объяснил механики", en="Explained mechanics"},
	{id="handled_role", ru="Успешно выполнил свою роль в прохождении", en="Performed their role successfully"},
	{id="failed_mechanics", ru="Не выполнил механику в прохождении", en="Failed a mechanic"},
	{id="toxic_behavior", ru="Оскорблял или провоцировал конфликт", en="Insulted or provoked a conflict"},
	{id="scam", ru="Обманул при обмене или договорённости", en="Deceived in a trade or agreement"},
}

function Addon:GetProfileEventCatalog()
	local result = {}
	for _, entry in ipairs(profileEventCatalog) do
		result[#result + 1] = {id=entry.id, label=self.db and self.db.locale == "ruRU" and entry.ru or entry.en}
	end
	return result
end
