-- Versioned, read-only Global Karma dataset import and lookup.
local Addon = Raidwise

Addon.KARMA_REPORT_VERSION = 1
local MAX_RECORDS = 10000

local function SafeString(value, maximum)
	return type(value) == "string" and value ~= "" and #value <= maximum and not value:find('[%z\1-\31|]')
end

local function NewerThan(incoming, current)
	if type(current) ~= "table" then return true end
	local incomingRevision, currentRevision = tonumber(incoming.revision) or 0, tonumber(current.revision) or 0
	if incomingRevision ~= currentRevision then return incomingRevision > currentRevision end
	return (tonumber(incoming.publishedAt) or 0) > (tonumber(current.publishedAt) or 0)
end

function Addon:ValidateGlobalKarmaText(text)
	local payload = self:DecodeSyncJSON(text)
	if type(payload) ~= "table" or payload.format ~= "RaidwiseKarma" then return nil, "KARMA_INVALID" end
	if payload.reportVersion ~= self.KARMA_REPORT_VERSION then return nil, "KARMA_VERSION" end
	if not SafeString(payload.datasetId, 120) or type(payload.revision) ~= "number" or payload.revision < 0
		or type(payload.publishedAt) ~= "number" or payload.publishedAt < 0
		or not self:IsSyncJSONArray(payload.characters) or #payload.characters > MAX_RECORDS then return nil, "KARMA_INVALID" end
	local records, seen = {}, {}
	for _, row in ipairs(payload.characters) do
		if type(row) ~= "table" or not SafeString(row.character, 64) or not SafeString(row.characterId, 120)
			or not SafeString(row.race, 32) or not SafeString(row.class, 32) or seen[row.characterId]
			or type(row.level) ~= "number" or row.level < 1 or row.level > 80
			or type(row.rating) ~= "number" or row.rating < 0 or row.rating > 100 then return nil, "KARMA_INVALID" end
		seen[row.characterId] = true
		records[row.characterId] = {character=row.character, characterId=row.characterId, race=row.race,
			level=row.level, class=row.class, rating=row.rating}
	end
	return {datasetId=payload.datasetId, reportVersion=payload.reportVersion, revision=payload.revision,
		publishedAt=payload.publishedAt, recordsByCharacterId=records}
end

function Addon:StageGlobalKarmaImport(text, source)
	if self.globalKarmaReview then return nil, "KARMA_BUSY" end
	local dataset, err = self:ValidateGlobalKarmaText(text)
	if not dataset then return nil, err end
	if not NewerThan(dataset, self:GetGlobalKarmaDataset()) then return nil, "KARMA_NOT_NEWER" end
	dataset.source, dataset.stagedAt = source or "JSON", time()
	self.globalKarmaReview = dataset
	return dataset
end

function Addon:ApplyGlobalKarmaImport()
	local dataset = self.globalKarmaReview
	if not dataset then return nil, "KARMA_NO_REVIEW" end
	if not NewerThan(dataset, self:GetGlobalKarmaDataset()) then self.globalKarmaReview = nil; return nil, "KARMA_NOT_NEWER" end
	dataset.receivedAt = time()
	self:EnsureReputationStore().globalKarma = dataset
	self.globalKarmaReview = nil
	if self.RefreshRatingViews then self:RefreshRatingViews() end
	return dataset
end

function Addon:CancelGlobalKarmaImport()
	self.globalKarmaReview = nil
end

function Addon:GetGlobalKarmaRecord(entryOrMember)
	local dataset = self:GetGlobalKarmaDataset()
	if not dataset or type(dataset.recordsByCharacterId) ~= "table" then return nil end
	local entry = type(entryOrMember) == "table" and entryOrMember or self:GetHistoryEntry(entryOrMember)
	if type(entry) ~= "table" then return nil end
	return dataset.recordsByCharacterId[entry.characterId or entry.guid]
end
