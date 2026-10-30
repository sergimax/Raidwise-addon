-- Opt-in local profile core. Existing UI/history APIs remain on the old store.
local Addon = Raidwise
local drafts = setmetatable({}, {__mode = "k"})
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

function Addon:GetPlayerRecordStore()
	local store = self.db and self.db.playerRecords
	return type(store) == "table" and store.schemaVersion == 1 and store or nil
end

function Addon:InitializePlayerRecords()
	if not self.db then return nil, "NO_DATABASE" end
	if self.db.playerRecords ~= nil then
		if not self:GetPlayerRecordStore() then return nil, "UNSUPPORTED_SCHEMA" end
		local current = self:GetPlayerRecordStore()
		for _, section in ipairs(sections) do
			if type(current[section]) ~= "table" then return nil, "INVALID_STORE" end
		end
		if type(current.nextId) ~= "number" or current.nextId < 0 or current.nextId % 1 ~= 0 then return nil, "INVALID_STORE" end
		return self:GetPlayerRecordStore()
	end
	local store = {schemaVersion=1, nextId=0}
	for _, section in ipairs(sections) do store[section] = {} end
	self.db.playerRecords = store
	return store
end

function Addon:GetPlayerRecordEventTypes()
	return Copy(eventTypes)
end

function Addon:GetPlayerRecord(key)
	local store = self:GetPlayerRecordStore()
	if not store then return nil end
	return Copy({identity=store.identities[key], profile=store.profiles[key], note=store.notes[key], changes=store.changes[key] or {}})
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
				changes[#changes + 1] = {id=NextId(store), at=now, actor=Copy(actor), kind=field,
					before=Copy(before[field]), after=Copy(profile[field])}
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
