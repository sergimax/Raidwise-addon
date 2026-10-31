-- Runtime-only catalogs and identity presentation. No legacy profile migrations.
local Addon = Raidwise

function Addon:CanEditCharacterProfile(member, seed)
	local key = type(member) == "table" and member.guid or member
	local entry = type(member) == "table" and member or seed or self:GetHistoryEntry(key)
	if not key or key == "" or key == UnitGUID("player") or entry and entry.isSelf then return false end
	local name, realm = UnitName("player")
	local fold = strlower or string.lower
	if entry and name and fold(entry.name or "") == fold(name) then
		local subjectRealm = fold(entry.realm or GetRealmName()):gsub("%s+", "")
		if subjectRealm == fold(realm or GetRealmName()):gsub("%s+", "") then return false end
	end
	return true
end

function Addon:HistoryProfileForMember(member)
	if type(member) ~= "table" then return member end
	local result = {}
	local saved = self:GetHistoryEntry(member.guid)
	for key, value in pairs(saved or {}) do result[key] = value end
	for key, value in pairs(member) do if value ~= nil and value ~= "" then result[key] = value end end
	result.rating = {personal=self:GetPersonalRating(result)}
	result.events, result.notes, result.changes = self:GetHistoryEvents(result), self:GetProfileNotes(result), self:GetProfileChanges(result)
	return result
end

local OPINION_ORDER = { "positive", "neutral", "negative" }

local OPINIONS = {
	positive = {
		id = "positive",
		labelKey = "RATING_OPINION_POSITIVE",
		symbol = "+",
		icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_03", -- green
		color = { 0.35, 0.90, 0.35 },
	},
	neutral = {
		id = "neutral",
		labelKey = "RATING_OPINION_NEUTRAL",
		symbol = "=",
		icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_01", -- yellow
		color = { 0.90, 0.82, 0.35 },
	},
	negative = {
		id = "negative",
		labelKey = "RATING_OPINION_NEGATIVE",
		symbol = "-",
		icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_02", -- red
		color = { 0.95, 0.35, 0.35 },
	},
}

local FACT_CATALOG = {
	{ id = "raid_leader", labelKey = "RATING_FACT_RAID_LEADER", meta = "fact" },
	{ id = "pug_raid_leader", labelKey = "RATING_FACT_PUG_RAID_LEADER", meta = "fact" },
	{ id = "guild_master", labelKey = "RATING_FACT_GUILD_MASTER", meta = "fact" },
	{ id = "guild_officer", labelKey = "RATING_FACT_GUILD_OFFICER", meta = "fact" },
}

local FACTS_BY_ID = {}
for _, fact in ipairs(FACT_CATALOG) do FACTS_BY_ID[fact.id] = fact end
local MAX_PERSONAL_FACTS = 4

function Addon:NormalizePersonalOpinion(opinion)
	if OPINIONS[opinion] then
		return opinion
	end
	return "neutral"
end

function Addon:IsValidPersonalFact(factId)
	return FACTS_BY_ID[factId] ~= nil
end

function Addon:NormalizePersonalFacts(facts)
	local normalized = {}
	local seen = {}
	if type(facts) ~= "table" then
		return normalized
	end
	for index = 1, #facts do
		local factId = facts[index]
		if self:IsValidPersonalFact(factId) and not seen[factId] then
			seen[factId] = true
			normalized[#normalized + 1] = factId
		end
	end
	table.sort(normalized)
	while #normalized > MAX_PERSONAL_FACTS do
		table.remove(normalized)
	end
	return normalized
end

function Addon:RatingOpinions()
	return OPINION_ORDER, OPINIONS
end

function Addon:FactCatalog()
	return FACT_CATALOG
end

function Addon:MaxPersonalFacts()
	return MAX_PERSONAL_FACTS
end

function Addon:FactById(factId)
	return FACTS_BY_ID[factId]
end

function Addon:FormatHistoryTime(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then
		return "-"
	end
	return date("%Y-%m-%d %H:%M", timestamp)
end

function Addon:CaptureEventContext()
	local context = {
		zoneName = "",
		zoneId = nil,
		instanceId = nil,
		instanceName = "",
		difficulty = nil,
		itemId = nil,
		bossId = nil,
	}
	if type(GetRealZoneText) == "function" then
		context.zoneName = GetRealZoneText() or ""
	elseif type(GetZoneText) == "function" then
		context.zoneName = GetZoneText() or ""
	end
	if type(GetCurrentMapAreaID) == "function" then
		local zoneId = GetCurrentMapAreaID()
		if zoneId and zoneId ~= 0 then
			context.zoneId = zoneId
		end
	end
	if type(GetInstanceInfo) == "function" then
		local name, instanceType, difficultyIndex, difficultyName = GetInstanceInfo()
		if name and name ~= "" and (instanceType == "raid" or instanceType == "party") then
			context.instanceName = name
			if difficultyName and difficultyName ~= "" then
				context.difficulty = difficultyName
			elseif difficultyIndex then
				context.difficulty = difficultyIndex
			end
		end
	end
	return context
end

function Addon:LinkedCharacterName(entry)
	local name = entry and entry.name or "?"
	local realm = entry and (entry.realm or entry.metRealm) or ""
	return realm ~= "" and (name .. "-" .. realm) or name
end

function Addon:BuildLinkedCharacterTooltipLines(member)
	local characters = self:GetLinkedCharacters(member and member.guid)
	if #characters < 2 then return {} end
	local main = characters[1]
	local altsByRealm = {}
	for _, character in ipairs(characters) do
		if character.role == "alt" then
			local realm = character.entry.realm or character.entry.metRealm or ""
			altsByRealm[realm] = altsByRealm[realm] or {}
			altsByRealm[realm][#altsByRealm[realm] + 1] = character
		end
	end
	local realms = {}
	for realm in pairs(altsByRealm) do realms[#realms + 1] = realm end
	table.sort(realms)
	local lines = {}
	for _, realm in ipairs(realms) do
		local alts = altsByRealm[realm]
		local labels = {}
		for _, alt in ipairs(alts) do
			local label = alt.entry.name or "?"
			local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[alt.entry.class]
			if color then label = self:RatingWrapColor(label, { color.r, color.g, color.b }) end
			labels[#labels + 1] = label
		end
		lines[#lines + 1] = self:T("CHAR_LINK_TOOLTIP", main.entry.name or "?", self:T("CHAR_ROLE_MAIN"), realm ~= "" and realm or "?")
		lines[#lines + 1] = table.concat(labels, ", ")
	end
	return lines
end

