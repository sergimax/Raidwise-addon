-- Transitional API for existing screens. Only playerRecords owns profile data.
local Addon = Raidwise

local function Key(value)
	return type(value) == "table" and value.guid or value
end

local function NoData() return nil end
local function EmptyList() return {} end
Addon.GetCommunityRating = NoData
Addon.GetGlobalKarmaDataset = NoData
Addon.GetGlobalKarmaRecord = NoData
Addon.GetReputationStore = NoData
Addon.EnsureReputationStore = NoData
Addon.GetExchangeProfile = NoData
Addon.GetExchangeProfileSources = EmptyList
Addon.GetReceivedProfileLinks = EmptyList
Addon.MigrateLegacyProfiles = function() end
Addon.SyncLinkedPlayerOpinion = function() end

function Addon:InitializeHistoryStore()
	local store, err = self:InitializePlayerRecords()
	if not store then error("Raidwise playerRecords: " .. tostring(err)) end
	if not store.activated then
		-- Reset only the retired character subsystem, once per account.
		self.db.history, self.db.reputation = nil, nil
		self.db.characterGroups, self.db.localCharacterMains = nil, nil
		self.db.nextCharacterGroupId, self.db.sync = nil, nil
		store.activated = true
	end
	-- Old encounter collectors temporarily keep their identity-shaped interface.
	self.db.history = store.identities
	if self.InitializeCharacterLinks then self:InitializeCharacterLinks() end
	self:PruneHistory()
end

function Addon:HistoryStore()
	local store = self:GetPlayerRecordStore()
	return store and store.identities or {}
end

function Addon:GetHistoryEntry(guid)
	return self:HistoryStore()[guid]
end

function Addon:EnsureHistoryEntryForGuid(guid, seed)
	seed = seed or self:GetHistoryEntry(guid)
	if not seed then return nil end
	local key = self:UpsertPlayerRecordIdentity({guid=not guid:match("^name:") and guid or nil,
		name=seed.name, realm=seed.realm or seed.metRealm, class=seed.class})
	if not key then return nil end
	local entry = self:GetHistoryEntry(key)
	entry.guid = key
	return entry
end

function Addon:PruneHistory()
	-- Retention of individual encounters is introduced in the next stage.
end

function Addon:GetLocalProfile(guid)
	local record = self:GetPlayerRecord(guid)
	if not record or not self:IsPlayerRecordFilled(guid) then return nil end
	return {guid=guid, personal=self:GetPersonalRating({guid=guid}),
		events=self:GetHistoryEvents({guid=guid}), notes=record.note and record.note.text or "",
		changes=record.changes, name=record.identity and record.identity.name}
end

function Addon:EnsureLocalProfile(guid, seed)
	self:EnsureHistoryEntryForGuid(guid, seed)
	return self:GetLocalProfile(guid)
end

function Addon:GetPersonalRating(member)
	local record = self:GetPlayerRecord(Key(member))
	local profile = record and record.profile
	return {opinion=profile and profile.opinion or "neutral", tags={}, facts=profile and profile.facts or {},
		createdAt=profile and profile.createdAt or 0, updatedAt=profile and profile.updatedAt or 0,
		creatorId=profile and profile.author and profile.author.guid or "", hasOpinion=profile and profile.opinion ~= nil or false}
end

function Addon:HasPersonalRatingData(personal)
	return type(personal) == "table" and personal.hasOpinion == true
end

function Addon:GetHistoryEvents(member)
	local record = self:GetPlayerRecord(Key(member))
	return record and record.profile and record.profile.events or {}
end

function Addon:GetProfileNotes(member)
	local record = self:GetPlayerRecord(Key(member))
	return record and record.note and record.note.text or ""
end

function Addon:GetProfileChanges(member)
	local record = self:GetPlayerRecord(Key(member))
	return record and record.changes or {}
end

function Addon:IsCharacterDatabaseEntry(entry)
	return entry ~= nil and self:IsPlayerRecordFilled(entry.guid) or false
end

function Addon:GetCharacterProfileState(entry)
	return self:IsCharacterDatabaseEntry(entry) and "local" or "unset"
end

function Addon:GetCharacterRecordSource(entry)
	return self:IsCharacterDatabaseEntry(entry) and "manual" or "encounter"
end

local function Draft(guid, seed)
	local entry = Addon:EnsureHistoryEntryForGuid(guid, seed)
	return entry and Addon:CreatePlayerRecordDraft(entry.guid), entry
end

function Addon:SavePersonalRatingForGuid(guid, seed, opinion, tags, facts)
	local draft, entry = Draft(guid, seed)
	if not draft then return nil end
	draft.opinion, draft.facts = opinion, facts or draft.facts
	if not self:CommitPlayerRecordDraft(draft) then return nil end
	return entry
end

function Addon:SaveProfileNotesForGuid(guid, seed, notes)
	local draft, entry = Draft(guid, seed)
	if not draft then return nil end
	draft.note = notes
	if not self:CommitPlayerRecordDraft(draft) then return nil end
	return entry
end

function Addon:SaveHistoryEventsForGuid(guid, seed, events)
	local draft, entry = Draft(guid, seed)
	if not draft then return nil end
	local known, selected = {}, {}
	for _, event in ipairs(draft.events) do known[event.id] = event end
	for _, event in ipairs(events or {}) do
		if known[event.id] then
			local saved = known[event.id]
			saved.type = event.type
			selected[#selected + 1] = saved
		else
			local id = self:AddPlayerRecordDraftEvent(draft, event.type)
			if not id then return nil end
			selected[#selected + 1] = draft.events[#draft.events]
		end
	end
	draft.events = selected
	if not self:CommitPlayerRecordDraft(draft) then return nil end
	return entry
end

function Addon:AddHistoryEventForGuid(guid, seed, eventType)
	local draft, entry = Draft(guid, seed)
	if not draft or not self:AddPlayerRecordDraftEvent(draft, eventType) then return nil end
	if self:CommitPlayerRecordDraft(draft) then return entry end
end

function Addon:RemoveHistoryEventForGuid(guid, eventId)
	local draft, entry = Draft(guid)
	if not draft then return nil end
	for index = #draft.events, 1, -1 do
		if draft.events[index].id == eventId then table.remove(draft.events, index) end
	end
	if self:CommitPlayerRecordDraft(draft) then return entry end
end

function Addon:AppendProfileHistoryChange() end

function Addon:DeleteCharacterDatabaseRecords(guids)
	local store = self:GetPlayerRecordStore()
	if not store then return 0 end
	if not guids then
		guids = {}
		for key in pairs(store.identities) do
			if self:IsPlayerRecordFilled(key) then guids[#guids + 1] = key end
		end
	end
	local count = 0
	for _, key in ipairs(guids) do
		if self:IsPlayerRecordFilled(key) then
			store.profiles[key], store.notes[key], store.changes[key] = nil, nil, nil
			store.generations[key] = (store.generations[key] or 0) + 1
			count = count + 1
		end
	end
	return count
end
