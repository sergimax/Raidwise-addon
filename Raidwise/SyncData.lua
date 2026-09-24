-- Versioned profile exchange. Projection excludes private notes and local history.
local Addon = Raidwise
Addon.SYNC_REPORT_VERSION = 1
Addon.SYNC_MAX_BYTES = 262144
local MAX_CHARACTERS = 1000

local function safeString(value, maximum, required)
	return type(value) == "string" and #value <= maximum and (not required or value ~= "")
		and not value:find('[%z\1-\31|]')
end

local function arrayCopy(values)
	local result = Addon:SyncJSONArray()
	for _, value in ipairs(values or {}) do result[#result + 1] = value end
	return result
end

function Addon:BuildSyncExport(guid)
	local entries = guid and {self:GetHistoryEntry(guid)} or self:BuildHistoryRoster(true)
	local characters = self:SyncJSONArray()
	for _, entry in ipairs(entries) do
		if guid or self:IsCharacterDatabaseEntry(entry) then
			local personal = self:GetPersonalRating(entry)
			local events = self:SyncJSONArray()
			for _, event in ipairs(entry.events or {}) do
				if event.type ~= "same_party" then
					events[#events + 1] = {type=event.type, eventAt=event.eventAt or 0, creatorId=event.creatorId or ""}
				end
			end
			local links = self:SyncJSONArray()
			for _, linked in ipairs(self:GetSharedCharacterLinks(entry.guid)) do
				if linked.guid ~= entry.guid then links[#links + 1] = linked.guid end
			end
			characters[#characters + 1] = {
				guid=entry.guid, name=entry.name, realm=entry.realm or entry.metRealm or "",
				class=entry.class or "", opinion=personal.opinion,
				tags=arrayCopy(personal.tags), facts=arrayCopy(personal.facts), events=events, links=links,
				updatedAt=tonumber(personal.updatedAt) or 0,
			}
			local community = entry.rating and entry.rating.community
			if type(community) == "table" and not community.isMock and tonumber(community.positivePercent) then
				characters[#characters].community = {positivePercent=tonumber(community.positivePercent), tags=arrayCopy(community.tags)}
			end
		end
	end
	if #characters == 0 then return nil, "SYNC_EMPTY" end
	if #characters > MAX_CHARACTERS then return nil, "SYNC_LIMIT" end
	table.sort(characters, function(left, right) return left.guid < right.guid end)
	local payload = {format="RaidwiseProfiles", reportVersion=self.SYNC_REPORT_VERSION, exportedAt=time(), characters=characters}
	local text, err = self:EncodeSyncJSON(payload)
	if not text then return nil, err end
	-- Apply the same contract to exports and incoming data.
	local validated, validationError = self:ValidateSyncText(text)
	if not validated then return nil, validationError end
	return text, #characters
end

function Addon:ValidateSyncText(text)
	local payload = self:DecodeSyncJSON(text)
	if type(payload) ~= "table" or payload.format ~= "RaidwiseProfiles" then return nil, "SYNC_INVALID" end
	if payload.reportVersion ~= self.SYNC_REPORT_VERSION then return nil, "SYNC_VERSION" end
	if not self:IsSyncJSONArray(payload.characters) or #payload.characters < 1 or #payload.characters > MAX_CHARACTERS then
		return nil, "SYNC_LIMIT"
	end
	local result, seen, identities = {}, {}, {}
	local function validList(values, normalize, maximum)
		if not Addon:IsSyncJSONArray(values) or #values > maximum then return false end
		local normalized = normalize(Addon, values)
		if #normalized ~= #values then return false end
		return true
	end
	for _, row in ipairs(payload.characters) do
		if type(row) ~= "table" or not safeString(row.guid, 120, true) or not safeString(row.name, 64, true)
			or row.name:find('[%s:%-]') or not safeString(row.realm, 100, false) or not safeString(row.class, 32, false)
			or seen[row.guid] or (row.opinion ~= "positive" and row.opinion ~= "neutral" and row.opinion ~= "negative")
			or not validList(row.tags, self.NormalizePersonalTags, 30)
			or not validList(row.facts, self.NormalizePersonalFacts, 4)
			or not self:IsSyncJSONArray(row.events) or #row.events > 100
			or not self:IsSyncJSONArray(row.links) or #row.links > 100
			or type(row.updatedAt) ~= "number" or row.updatedAt < 0 or row.updatedAt > 100000000000 then
			return nil, "SYNC_INVALID"
		end
		local identity = string.lower(row.name .. "-" .. row.realm:gsub('%s+', ''))
		if identities[identity] then return nil, "SYNC_INVALID" end
		seen[row.guid], identities[identity] = true, true
		local tagCounts = {}
		for _, tagId in ipairs(row.tags) do
			local group = self:RatingTagById(tagId).groupId
			tagCounts[group] = (tagCounts[group] or 0) + 1
			if tagCounts[group] > self:MaxTagsPerGroup() then return nil, "SYNC_INVALID" end
		end
		local community
		if row.community ~= nil then
			local value = row.community
			if type(value) ~= "table" or type(value.positivePercent) ~= "number" or value.positivePercent < 0
				or value.positivePercent > 100 or not validList(value.tags, self.NormalizePersonalTags, 30) then return nil, "SYNC_INVALID" end
			community = {positivePercent=value.positivePercent, tags=self:NormalizePersonalTags(value.tags), isMock=false}
		end
		local events, links, linkSeen = {}, {}, {}
		for _, event in ipairs(row.events) do
			if type(event) ~= "table" or not self:IsValidEventType(event.type) or event.type == "same_party"
				or type(event.eventAt) ~= "number" or event.eventAt < 0 or event.eventAt > 100000000000
				or not safeString(event.creatorId, 120, false) then return nil, "SYNC_INVALID" end
			events[#events + 1] = {type=event.type, eventAt=event.eventAt, creatorId=event.creatorId, context={}}
		end
		for _, link in ipairs(row.links) do
			if not safeString(link, 120, true) or link == row.guid or linkSeen[link] then return nil, "SYNC_INVALID" end
			linkSeen[link] = true; links[#links + 1] = link
		end
		-- Whitelist only. Extra JSON fields never reach SavedVariables.
		result[#result + 1] = {guid=row.guid, name=row.name, realm=row.realm, class=row.class,
			opinion=row.opinion, tags=self:NormalizePersonalTags(row.tags), facts=self:NormalizePersonalFacts(row.facts),
			events=events, links=links, updatedAt=row.updatedAt, community=community}
	end
	return result
end

local function resolve(row)
	local entry = Addon:GetHistoryEntry(row.guid)
	if entry then
		if string.lower(entry.name or "") ~= string.lower(row.name)
			or string.lower((entry.realm or entry.metRealm or ""):gsub('%s+', '')) ~= string.lower(row.realm:gsub('%s+', '')) then
			return entry, "conflict"
		end
		return entry
	end
	for _, saved in pairs(Addon.db and Addon.db.history or {}) do
		if string.lower(saved.name or "") == string.lower(row.name)
			and string.lower((saved.realm or saved.metRealm or ""):gsub('%s+', '')) == string.lower(row.realm:gsub('%s+', '')) then
			return saved
		end
	end
end

local function actionFor(row)
	local entry, conflict = resolve(row)
	if conflict then return "conflict", entry end
	if entry and Addon:GetCharacterProfileState(entry) == "local" then return "protected", entry end
	return entry and "update" or "add", entry
end

function Addon:StageSyncImport(text, sender, source)
	if self.syncReview then return nil, "SYNC_BUSY" end
	local rows, err = self:ValidateSyncText(text)
	if not rows then return nil, err end
	local review = {rows=rows, sender=sender or "JSON", source=source == "user" and "user" or "website", createdAt=time()}
	self.syncReview = review
	if self.RefreshSyncView then self:RefreshSyncView() end
	return review
end

function Addon:GetSyncReviewText()
	local review = self.syncReview
	if not review then return self:T("SYNC_NO_REVIEW") end
	local lines = {self:T("SYNC_REVIEW_FROM", review.sender)}
	local counts = {add=0, update=0, protected=0, conflict=0}
	for index, row in ipairs(review.rows) do
		local action = actionFor(row); counts[action] = counts[action] + 1
		if index <= 12 then
			lines[#lines + 1] = self:T("SYNC_CHANGE_" .. string.upper(action)) .. ": " .. row.name .. "-" .. row.realm
				.. " (" .. self:T("SYNC_CHANGE_DETAIL", self:RatingOpinionLabel(row.opinion), #row.tags, #row.facts, #row.events, #row.links,
					row.community and tostring(row.community.positivePercent) .. "%" or "-") .. ")"
		end
	end
	table.insert(lines, 2, self:T("SYNC_REVIEW_TOTAL", counts.add, counts.update, counts.protected, counts.conflict, #review.rows))
	return table.concat(lines, "\n")
end

function Addon:ApplySyncImport()
	local review = self.syncReview
	if not review then return nil, "SYNC_NO_REVIEW" end
	local imported, changed = {}, 0
	local reputation = self:EnsureReputationStore()
	local sourceId = review.source .. ":" .. string.lower(review.sender or "JSON")
	local source = reputation.exchangeProfilesBySource[sourceId]
	if type(source) ~= "table" then
		source = {sourceId=sourceId, sourceType=review.source, sender=review.sender, profilesByGuid={}}
		reputation.exchangeProfilesBySource[sourceId] = source
	end
	source.sender, source.receivedAt = review.sender, time()
	for _, row in ipairs(review.rows) do
		-- Preserve every sender's payload independently. The legacy history write
		-- below is retained only for the current profile UI until Phase 5.
		source.profilesByGuid[row.guid] = {guid=row.guid, name=row.name, realm=row.realm, class=row.class,
			opinion=row.opinion, tags=row.tags, facts=row.facts, events=row.events, links=row.links,
			updatedAt=row.updatedAt, receivedAt=time()}
		local action, entry = actionFor(row) -- Recheck local edits made after preview.
		if action == "add" or action == "update" then
			entry = entry or self:EnsureHistoryEntryForGuid(row.guid, row)
			entry.name, entry.realm, entry.class = row.name, row.realm, row.class
			entry.rating = entry.rating or {}
			entry.rating.personal = {opinion=row.opinion, tags=row.tags, facts=row.facts,
				createdAt=row.updatedAt, updatedAt=row.updatedAt, creatorId=review.sender, reputationV2=true}
			entry.rating.community = row.community
			-- Preserve automatic encounter events and all private notes.
			local events = {}
			for _, event in ipairs(entry.events or {}) do if event.type == "same_party" then events[#events + 1] = event end end
			for index, event in ipairs(row.events) do event.id = "sync-" .. time() .. "-" .. index; events[#events + 1] = event end
			entry.events = events
			entry.recordSource, entry.recordSourceDetail = review.source, review.sender
			entry.recordUpdatedAt = time()
			imported[row.guid] = entry
			changed = changed + 1
		end
	end
	-- Link only imported, previously ungrouped records. Existing local groups win.
	local groups = self.db.characterGroups or {}; self.db.characterGroups = groups
	self.db.localCharacterMains = self.db.localCharacterMains or {}
	for _, row in ipairs(review.rows) do
		local entry = imported[row.guid]
		if entry and not entry.playerGroupId then
			local members = {[entry.guid]="alt"}; local count = 1
			for _, linkedGuid in ipairs(row.links) do
				local linked = imported[linkedGuid]
				if linked and not linked.playerGroupId and not members[linked.guid] then members[linked.guid]="alt"; count=count+1 end
			end
			if count > 1 then
				self.db.nextCharacterGroupId = (tonumber(self.db.nextCharacterGroupId) or 0) + 1
				local id = "sync-" .. time() .. "-" .. self.db.nextCharacterGroupId
				groups[id] = {members=members}; self.db.localCharacterMains[id] = entry.guid
				for guid in pairs(members) do self:GetHistoryEntry(guid).playerGroupId = id end
			end
		end
	end
	self.syncReview = nil
	if self.RefreshRatingViews then self:RefreshRatingViews() end
	if self.RefreshSyncView then self:RefreshSyncView() end
	return changed
end

function Addon:CancelSyncImport()
	self.syncReview = nil
	if self.RefreshSyncView then self:RefreshSyncView() end
end
