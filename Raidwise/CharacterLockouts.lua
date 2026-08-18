-- Account-wide character lockout snapshots for the cooldowns table.

local Addon = Raidwise

-- Unique SavedVariables key for the logged-in character.
local function CurrentCharacterKey()
	local name = UnitName("player") or ""
	local realm = GetRealmName() or ""
	if name == "" then
		return nil, name, realm
	end
	return name .. "-" .. realm, name, realm
end

local function IsHeroicLockout(entry)
	local difficulty = tonumber(entry.difficulty) or 0
	if entry.isRaid then
		return difficulty == 3 or difficulty == 4
	end
	if difficulty == 2 then
		return true
	end
	local label = entry.difficultyName or ""
	return label:find("[Hh]eroic") ~= nil
end

local function IsActiveLockout(entry, now)
	if not entry then
		return false
	end
	local resetAt = tonumber(entry.resetAt) or 0
	if resetAt > now then
		return true
	end
	return (tonumber(entry.reset) or 0) > 0
end

local function LockoutRowKey(entry)
	local kind = entry.isRaid and "R" or "D"
	local size = tonumber(entry.maxPlayers) or 0
	local heroic = IsHeroicLockout(entry) and "H" or "N"
	return (entry.name or "") .. "|" .. kind .. "|" .. tostring(size) .. "|" .. heroic
end

local function TypeLabel(entry)
	local kind = entry.isRaid and "Raid" or "Dungeon"
	local size = tonumber(entry.maxPlayers) or 0
	local sizeText
	if size > 0 then
		sizeText = tostring(size)
		if IsHeroicLockout(entry) then
			sizeText = sizeText .. " Heroic"
		end
	else
		sizeText = entry.difficultyName or ""
		if sizeText == "" then
			sizeText = IsHeroicLockout(entry) and "Heroic" or "Normal"
		end
	end
	return kind .. " / " .. sizeText
end

local function FilterActiveLockouts(lockouts, now)
	local kept = {}
	if type(lockouts) ~= "table" then
		return kept
	end
	for index = 1, #lockouts do
		local entry = lockouts[index]
		if IsActiveLockout(entry, now) then
			kept[#kept + 1] = entry
		end
	end
	return kept
end

local function FormatRemaining(resetAt, now)
	local remaining = (tonumber(resetAt) or 0) - now
	if remaining <= 0 then
		return nil
	end
	local days = math.floor(remaining / 86400)
	remaining = remaining - days * 86400
	local hours = math.floor(remaining / 3600)
	remaining = remaining - hours * 3600
	local minutes = math.floor(remaining / 60)
	if days > 0 then
		return days .. "d " .. hours .. "h"
	end
	if hours > 0 then
		return hours .. "h " .. minutes .. "m"
	end
	if minutes > 0 then
		return minutes .. "m"
	end
	return "<1m"
end

local function EnsureCharactersTable()
	if not Addon.db then
		return nil
	end
	if type(Addon.db.characters) ~= "table" then
		Addon.db.characters = {}
	end
	return Addon.db.characters
end

-- Drop expired lockouts from every stored character.
function Addon:PruneExpiredCharacterLockouts()
	local characters = EnsureCharactersTable()
	if not characters then
		return
	end
	local now = time()
	for _, character in pairs(characters) do
		character.lockouts = FilterActiveLockouts(character.lockouts, now)
	end
end

-- Create or update the logged-in character's identity without touching lockouts.
function Addon:EnsureCurrentCharacterRecord()
	local characters = EnsureCharactersTable()
	local key, name, realm = CurrentCharacterKey()
	if not characters or not key then
		return
	end

	local record = characters[key]
	if not record then
		record = {
			name = name,
			realm = realm,
			class = "",
			spec = "",
			specIcon = "",
			updatedAt = time(),
			lockouts = {},
		}
		characters[key] = record
	end

	local info = self:CollectCharacterInfo()
	local specName, specIcon = self:CollectPrimarySpec()
	record.name = info.name ~= "" and info.name or name
	record.realm = realm
	if info.class ~= "" then
		record.class = info.class
	end
	if specName ~= "" then
		record.spec = specName
	end
	if specIcon ~= "" then
		record.specIcon = specIcon
	end
	record.updatedAt = time()
end

-- Snapshot current lockouts into account SavedVariables. Call after UPDATE_INSTANCE_INFO.
function Addon:SaveCurrentCharacterLockouts()
	self:EnsureCurrentCharacterRecord()
	local characters = EnsureCharactersTable()
	local key = CurrentCharacterKey()
	if not characters or not key then
		return
	end

	local record = characters[key]
	if not record then
		return
	end

	local now = time()
	record.lockouts = FilterActiveLockouts(self:CollectInstanceLockouts(), now)
	record.updatedAt = now
	self:PruneExpiredCharacterLockouts()
end

local function CompareCharacters(a, b)
	local currentKey = CurrentCharacterKey()
	if a.key == currentKey and b.key ~= currentKey then
		return true
	end
	if b.key == currentKey and a.key ~= currentKey then
		return false
	end
	if a.name ~= b.name then
		return a.name < b.name
	end
	return (a.realm or "") < (b.realm or "")
end

local function CompareRows(a, b)
	if a.isRaid ~= b.isRaid then
		return a.isRaid
	end
	if a.name ~= b.name then
		return a.name < b.name
	end
	if a.maxPlayers ~= b.maxPlayers then
		return a.maxPlayers < b.maxPlayers
	end
	if a.heroic ~= b.heroic then
		return not a.heroic
	end
	return a.key < b.key
end

local function CharacterDisplayName(character, characters)
	local sameName = 0
	for index = 1, #characters do
		if characters[index].name == character.name then
			sameName = sameName + 1
		end
	end
	if sameName > 1 and character.realm and character.realm ~= "" then
		return character.name .. "-" .. character.realm
	end
	return character.name
end

-- Rows are unique instance+difficulty; columns are stored account characters.
function Addon:BuildCooldownTable()
	self:PruneExpiredCharacterLockouts()
	local characters = EnsureCharactersTable() or {}
	local now = time()
	local charList = {}
	local rowsByKey = {}
	local rows = {}

	for key, character in pairs(characters) do
		charList[#charList + 1] = {
			key = key,
			name = character.name or key,
			realm = character.realm or "",
			class = character.class or "",
			spec = character.spec or "",
			specIcon = character.specIcon or "",
			updatedAt = tonumber(character.updatedAt) or 0,
		}
		local lockouts = character.lockouts or {}
		for index = 1, #lockouts do
			local entry = lockouts[index]
			if IsActiveLockout(entry, now) then
				local rowKey = LockoutRowKey(entry)
				local row = rowsByKey[rowKey]
				if not row then
					row = {
						key = rowKey,
						name = entry.name or "",
						isRaid = entry.isRaid and true or false,
						maxPlayers = tonumber(entry.maxPlayers) or 0,
						heroic = IsHeroicLockout(entry),
						typeLabel = TypeLabel(entry),
						cells = {},
					}
					rowsByKey[rowKey] = row
					rows[#rows + 1] = row
				end
				row.cells[key] = {
					resetAt = entry.resetAt,
					remainingText = FormatRemaining(entry.resetAt, now),
					difficultyName = entry.difficultyName or "",
				}
			end
		end
	end

	table.sort(charList, CompareCharacters)
	for index = 1, #charList do
		charList[index].displayName = CharacterDisplayName(charList[index], charList)
	end
	table.sort(rows, CompareRows)

	return {
		characters = charList,
		rows = rows,
	}
end

local function JsonEscape(value)
	local str = tostring(value or "")
	str = str:gsub("\\", "\\\\")
	str = str:gsub('"', '\\"')
	str = str:gsub("\n", "\\n")
	str = str:gsub("\r", "\\r")
	str = str:gsub("\t", "\\t")
	return str
end

local function FormatJsonBoolean(value)
	if value then
		return "true"
	end
	return "false"
end

local function AppendLockoutObjectsJson(lines, lockouts, baseIndent)
	baseIndent = baseIndent or "      "
	local entryIndent = baseIndent .. "  "
	local fieldIndent = entryIndent .. "  "

	if #lockouts == 0 then
		lines[#lines + 1] = baseIndent .. '"lockouts": []'
		return
	end

	lines[#lines + 1] = baseIndent .. '"lockouts": ['
	for index = 1, #lockouts do
		local entry = lockouts[index]
		local comma = (index < #lockouts) and "," or ""
		lines[#lines + 1] = entryIndent .. "{"
		lines[#lines + 1] = fieldIndent .. '"name": "' .. JsonEscape(entry.name) .. '",'
		lines[#lines + 1] = fieldIndent .. '"id": ' .. tostring(entry.id) .. ","
		lines[#lines + 1] = fieldIndent .. '"reset": ' .. tostring(entry.reset) .. ","
		lines[#lines + 1] = fieldIndent .. '"resetAt": ' .. tostring(entry.resetAt) .. ","
		lines[#lines + 1] = fieldIndent .. '"difficulty": ' .. tostring(entry.difficulty) .. ","
		lines[#lines + 1] = fieldIndent .. '"difficultyName": "' .. JsonEscape(entry.difficultyName) .. '",'
		lines[#lines + 1] = fieldIndent .. '"locked": ' .. FormatJsonBoolean(entry.locked) .. ","
		lines[#lines + 1] = fieldIndent .. '"extended": ' .. FormatJsonBoolean(entry.extended) .. ","
		lines[#lines + 1] = fieldIndent .. '"isRaid": ' .. FormatJsonBoolean(entry.isRaid) .. ","
		lines[#lines + 1] = fieldIndent .. '"maxPlayers": ' .. tostring(entry.maxPlayers)
		lines[#lines + 1] = entryIndent .. "}" .. comma
	end
	lines[#lines + 1] = baseIndent .. "]"
end

local function SortedCharacterKeys(characters)
	local keys = {}
	for key in pairs(characters) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

-- JSON export of every stored character and their current lockouts.
function Addon:FormatCooldownsExport()
	self:SaveCurrentCharacterLockouts()
	self:PruneExpiredCharacterLockouts()

	local characters = EnsureCharactersTable() or {}
	local keys = SortedCharacterKeys(characters)
	local now = time()
	local lines = {
		"{",
		'  "exportedAt": ' .. tostring(now) .. ",",
		'  "characters": [',
	}

	for index = 1, #keys do
		local key = keys[index]
		local character = characters[key]
		local lockouts = FilterActiveLockouts(character.lockouts, now)
		local comma = (index < #keys) and "," or ""
		lines[#lines + 1] = "    {"
		lines[#lines + 1] = '      "key": "' .. JsonEscape(key) .. '",'
		lines[#lines + 1] = '      "name": "' .. JsonEscape(character.name or key) .. '",'
		lines[#lines + 1] = '      "realm": "' .. JsonEscape(character.realm or "") .. '",'
		lines[#lines + 1] = '      "class": "' .. JsonEscape(character.class or "") .. '",'
		lines[#lines + 1] = '      "spec": "' .. JsonEscape(character.spec or "") .. '",'
		lines[#lines + 1] = '      "updatedAt": ' .. tostring(tonumber(character.updatedAt) or 0) .. ","
		AppendLockoutObjectsJson(lines, lockouts, "      ")
		lines[#lines + 1] = "    }" .. comma
	end

	lines[#lines + 1] = "  ]"
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n")
end
