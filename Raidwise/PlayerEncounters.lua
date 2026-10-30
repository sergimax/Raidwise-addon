-- Group presence is independent of scans and editable profile events.
local Addon = Raidwise
local GRACE_SECONDS = 5 * 60
local RETENTION_SECONDS = 14 * 24 * 60 * 60
local lastPass = {}

local function Copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = Copy(child) end
	return result
end

local function Observer()
	return type(UnitGUID) == "function" and UnitGUID("player") or nil
end

local function Units()
	local units = {}
	local raidCount = type(GetNumRaidMembers) == "function" and GetNumRaidMembers() or 0
	if raidCount > 0 then
		for index = 1, raidCount do units[#units + 1] = "raid" .. index end
	else
		local partyCount = type(GetNumPartyMembers) == "function" and GetNumPartyMembers() or 0
		for index = 1, partyCount do units[#units + 1] = "party" .. index end
	end
	return units
end

local function Last(rows)
	return rows and rows[#rows]
end

local function AddPlace(encounter, context, now)
	local place
	for _, saved in ipairs(encounter.places) do
		if saved.zoneName == context.zoneName and saved.zoneId == context.zoneId
			and saved.instanceName == context.instanceName and saved.difficulty == context.difficulty then place = saved end
	end
	if not place then
		place = {zoneName=context.zoneName or "", zoneId=context.zoneId,
			instanceName=context.instanceName, difficulty=context.difficulty, firstSeenAt=now}
		encounter.places[#encounter.places + 1] = place
	end
	place.lastSeenAt = now
end

function Addon:GetCharacterEncounters(subjectKey, observerKey)
	local store = self:GetPlayerRecordStore()
	local rows = store and store.encounters[observerKey or Observer()]
	return Copy(rows and rows[subjectKey] or {})
end

function Addon:GetCharacterMeetingStats(subjectKey, observerKey)
	local store = self:GetPlayerRecordStore()
	local rows = store and store.meetingStats[observerKey or Observer()]
	return Copy(rows and rows[subjectKey] or {count=0})
end

function Addon:PruneHistory()
	local store = self:GetPlayerRecordStore()
	if not store then return end
	local now = time()
	for _, subjects in pairs(store.encounters) do
		for key, rows in pairs(subjects) do
			for index = #rows, 1, -1 do
				local encounter = rows[index]
				if not encounter.endedAt and now - encounter.lastSeenAt > GRACE_SECONDS then
					encounter.endedAt = encounter.lastSeenAt
				end
				if encounter.endedAt and encounter.lastSeenAt < now - RETENTION_SECONDS then table.remove(rows, index) end
			end
			if #rows == 0 then subjects[key] = nil end
		end
	end
end

function Addon:UpsertHistoryMember(member)
	if type(member) ~= "table" or not member.guid or member.guid == "" then return nil end
	local entry = self:EnsureHistoryEntryForGuid(member.guid, member)
	if not entry then return nil end
	for _, field in ipairs({"classLabel", "spec", "specIcon", "race", "faction", "gender", "guildName", "guildRank", "gearScore", "averageIlvl"}) do
		if member[field] ~= nil and member[field] ~= "" then entry[field] = member[field] end
	end
	return entry
end

function Addon:RecordTargetScanHistory(report)
	local character = report and report.character
	if not character or character.isSelf then return end
	local member = Copy(character)
	member.class = character.classFile or character.class
	member.classLabel = character.className or character.classLabel
	member.spec = character.specKnown and character.specName or nil
	member.specIcon = character.specKnown and character.specIcon or nil
	local entry = self:UpsertHistoryMember(member)
	if not entry then return end
	entry.lastScannedAt = tonumber(report.collection and report.collection.collectedAt) or time()
	self:PruneHistory()
	if self.RefreshHistoryView then self:RefreshHistoryView() end
end

function Addon:RecordCurrentGroupHistory(refreshGearScore, rosterSnapshot)
	local store = self:GetPlayerRecordStore()
	local observer = Observer()
	if not store or not observer then return end
	local now, present = time(), {}
	local name, realm = UnitName("player")
	if name then self:UpsertPlayerRecordIdentity({guid=observer, name=name, realm=realm}) end
	store.encounters[observer] = store.encounters[observer] or {}
	store.meetingStats[observer] = store.meetingStats[observer] or {}
	local subjects, stats = store.encounters[observer], store.meetingStats[observer]
	local context = self.CaptureEventContext and self:CaptureEventContext() or {zoneName=""}
	for _, unit in ipairs(Units()) do
		local guid = UnitGUID(unit)
		if guid and guid ~= observer and not present[guid] then
			local member = rosterSnapshot and rosterSnapshot.byUnit and rosterSnapshot.byUnit[unit]
			if not member or member.guid ~= guid then
				local unitName, unitRealm = UnitName(unit)
				local classLabel, class
				if type(UnitClass) == "function" then classLabel, class = UnitClass(unit) end
				member = {guid=guid, name=unitName, realm=unitRealm, class=class, classLabel=classLabel}
			end
			local entry = self:UpsertHistoryMember(member)
			if entry then
				local key = entry.guid
				present[key] = true
				local rows = subjects[key] or {}
				local encounter = Last(rows)
				local gap = encounter and (encounter.lastAbsentAt or encounter.lastSeenAt) or 0
				local uninterrupted = lastPass[observer] and now - lastPass[observer] <= GRACE_SECONDS
				if not encounter or (encounter.lastAbsentAt and now - gap > GRACE_SECONDS)
					or (not uninterrupted and now - gap > GRACE_SECONDS) then
					if encounter then encounter.endedAt = encounter.lastSeenAt end
					store.nextId = store.nextId + 1
					encounter = {id=tostring(store.nextId), startedAt=now, lastSeenAt=now, places={}}
					rows[#rows + 1] = encounter
					subjects[key] = rows
					local stat = stats[key] or {count=0, firstMetAt=now}
					stat.count, stat.lastEncounterId = stat.count + 1, encounter.id
					stats[key] = stat
				end
				encounter.lastSeenAt, encounter.lastAbsentAt, encounter.endedAt = now, nil, nil
				stats[key].lastMetAt = now
				AddPlace(encounter, context, now)
			end
		end
	end
	for key, rows in pairs(subjects) do
		local encounter = Last(rows)
		if encounter and not present[key] and not encounter.lastAbsentAt then
			encounter.lastAbsentAt = now
			encounter.endedAt = encounter.lastSeenAt
		end
	end
	lastPass[observer] = now
	self:PruneHistory()
	local frame = self.mainFrame
	if frame and frame:IsShown() and (frame.selectedTab == "history" or frame.selectedTab == "database") and self.RefreshHistoryView then
		self:RefreshHistoryView()
	end
end

local function Project(entry)
	local result = Copy(entry)
	local stat = Addon:GetCharacterMeetingStats(entry.guid)
	local recent = Last(Addon:GetCharacterEncounters(entry.guid))
	result.meetCount, result.metAt = stat.count, stat.firstMetAt or 0
	result.lastSeenAt = recent and recent.lastSeenAt or 0
	local place = recent and Last(recent.places)
	for _, candidate in ipairs(recent and recent.places or {}) do
		if candidate.lastSeenAt > place.lastSeenAt then place = candidate end
	end
	local firstPlace = recent and recent.places[1]
	result.metZone = firstPlace and firstPlace.zoneName or ""
	result.lastSeenZone = place and place.zoneName or ""
	result.metRealm = entry.realm
	return result
end

local oldProfile = Addon.HistoryProfileForMember
function Addon:HistoryProfileForMember(member)
	local result = oldProfile(self, member)
	if type(result) ~= "table" then return result end
	local projection = Project(result)
	for _, field in ipairs({"meetCount", "metAt", "lastSeenAt", "metZone", "lastSeenZone", "metRealm"}) do result[field] = projection[field] end
	return result
end

function Addon:BuildHistoryRoster(database, filters)
	self:PruneHistory()
	filters = filters or {}
	local function Fold(value) return (strlower or string.lower)(tostring(value or "")) end
	local selected = {}
	local store = self:GetPlayerRecordStore()
	for _, identity in pairs(self:HistoryStore()) do
		local entry = Project(identity)
		local profile, note = store.profiles[entry.guid], store.notes[entry.guid]
		local opinion = profile and profile.opinion or "unset"
		local include = database and self:IsPlayerRecordFilled(entry.guid)
			or not database and entry.lastSeenAt > 0 and entry.lastSeenAt >= time() - RETENTION_SECONDS
		for _, field in ipairs({"name", "class", "guildName"}) do
			local value = entry[field]
			if field == "name" then value = self:LinkedCharacterName(entry) end
			if field == "class" then value = (value or "") .. " " .. (entry.classLabel or "") end
			if not Fold(value):find(Fold(filters[field]), 1, true) then include = false end
		end
		if database and filters.opinion and filters.opinion ~= "" and filters.opinion ~= opinion then include = false end
		if include then
			entry.profileAuthor = opinion ~= "unset" and profile.author or nil
			entry.profileUpdatedAt = math.max(profile and profile.updatedAt or 0, note and note.updatedAt or 0)
			selected[#selected + 1] = entry
		end
	end
	table.sort(selected, function(left, right)
		local leftTime = database and left.profileUpdatedAt or left.lastSeenAt
		local rightTime = database and right.profileUpdatedAt or right.lastSeenAt
		if leftTime ~= rightTime then return leftTime > rightTime end
		local leftName, rightName = self:LinkedCharacterName(left), self:LinkedCharacterName(right)
		if leftName ~= rightName then return leftName < rightName end
		return left.guid < right.guid
	end)
	return selected
end

-- Quiet groups still need presence observations; no inspect or gear collection.
local elapsedSincePoll = 0
local timer = CreateFrame("Frame")
timer:SetScript("OnUpdate", function(_, elapsed)
	elapsedSincePoll = elapsedSincePoll + elapsed
	if elapsedSincePoll < 30 then return end
	elapsedSincePoll = 0
	Addon:RecordCurrentGroupHistory(false)
end)
