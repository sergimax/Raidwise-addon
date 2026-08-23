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

local function InstanceRowKey(entry)
	local kind = entry.isRaid and "R" or "D"
	return (entry.name or "") .. "|" .. kind
end

local function InstanceKindLabel(entry)
	local kind = Addon:T(entry.isRaid and "LOCKOUT_RAID" or "LOCKOUT_DUNGEON")
	return "(" .. kind .. ")"
end

local function FormatVariantTag(entry)
	local size = tonumber(entry.maxPlayers) or 0
	if size > 0 then
		if IsHeroicLockout(entry) then
			return tostring(size) .. "h"
		end
		return tostring(size)
	end
	if IsHeroicLockout(entry) then
		return "h"
	end
	return "n"
end

local function TypeLabel(entry)
	local kind = Addon:T(entry.isRaid and "LOCKOUT_RAID" or "LOCKOUT_DUNGEON")
	local size = tonumber(entry.maxPlayers) or 0
	local sizeText
	if size > 0 then
		sizeText = tostring(size)
		if IsHeroicLockout(entry) then
			sizeText = sizeText .. " " .. Addon:T("LOCKOUT_HEROIC")
		end
	else
		sizeText = entry.difficultyName or ""
		if sizeText == "" then
			sizeText = Addon:T(IsHeroicLockout(entry) and "LOCKOUT_HEROIC" or "LOCKOUT_NORMAL")
		end
	end
	return kind .. " / " .. sizeText
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
		return Addon:T("TIME_DAYS_HOURS", days, hours)
	end
	if hours > 0 then
		return Addon:T("TIME_HOURS_MINUTES", hours, minutes)
	end
	if minutes > 0 then
		return Addon:T("TIME_MINUTES", minutes)
	end
	return Addon:T("TIME_LESS_MINUTE")
end

local function VariantTooltipLine(entry, now)
	local remainingText = FormatRemaining(entry.resetAt, now)
	local label = TypeLabel(entry)
	if remainingText then
		return label .. ": " .. remainingText
	end
	return label
end

local function CompareVariants(a, b)
	if a.maxPlayers ~= b.maxPlayers then
		return a.maxPlayers < b.maxPlayers
	end
	if a.heroic ~= b.heroic then
		return not a.heroic
	end
	return false
end

local function FinalizeLockoutCell(cellData)
	if not cellData or type(cellData.variants) ~= "table" or #cellData.variants == 0 then
		return nil
	end
	table.sort(cellData.variants, CompareVariants)
	local tags = {}
	local tooltipLines = {}
	for index = 1, #cellData.variants do
		local variant = cellData.variants[index]
		tags[#tags + 1] = variant.tag
		tooltipLines[#tooltipLines + 1] = variant.tooltipLine
	end
	return {
		displayText = table.concat(tags, " "),
		tooltipLines = tooltipLines,
	}
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

local function BuildCurrencyCell(currency)
	if type(currency) ~= "table" or type(currency.entries) ~= "table" then
		return nil
	end
	local source = currency.entries
	if #source == 0 then
		return nil
	end

	local entries = {}
	local tooltipLines = {}
	local hasValue = false
	for index = 1, #source do
		local entry = source[index]
		local displayCount = entry.displayCount or tostring(entry.count or 0)
		local tooltipCount = entry.tooltipCount or displayCount
		local entryId = entry.id
		if entryId == nil and Addon.GetCurrencyEntryIdAt then
			entryId = Addon:GetCurrencyEntryIdAt(index)
		end
		local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
		if Addon.ResolveCurrencyIcon then
			icon = Addon:ResolveCurrencyIcon(entryId)
		elseif type(entry.icon) == "string" and entry.icon ~= "" then
			icon = entry.icon
		end
		entries[#entries + 1] = {
			id = entryId,
			icon = icon,
			displayCount = displayCount,
			label = entry.label or "?",
		}
		tooltipLines[#tooltipLines + 1] = (entry.label or "?") .. ": " .. tooltipCount
		if (tonumber(entry.count) or 0) > 0 then
			hasValue = true
		end
	end

	return {
		entries = entries,
		tooltipLines = tooltipLines,
		hasValue = hasValue,
	}
end

local function AppendCurrencyRow(rows, characters, charList)
	local entryLabels = {}
	if Addon.GetCurrencyEntryLabels then
		entryLabels = Addon:GetCurrencyEntryLabels() or {}
	end

	local totals = {}
	local entryIds = {}
	local maxEntries = #entryLabels
	for charIndex = 1, #charList do
		local character = characters[charList[charIndex].key]
		local currency = character and character.currency
		local entries = currency and currency.entries
		if type(entries) == "table" then
			if #entries > maxEntries then
				maxEntries = #entries
			end
			for entryIndex = 1, #entries do
				local entry = entries[entryIndex]
				totals[entryIndex] = (totals[entryIndex] or 0) + (tonumber(entry.count) or 0)
				if not entryIds[entryIndex] then
					entryIds[entryIndex] = entry.id
				end
			end
		end
	end

	local entrySummaries = {}
	for entryIndex = 1, maxEntries do
		local label = entryLabels[entryIndex] or "?"
		local total = totals[entryIndex] or 0
		local displayTotal = tostring(total)
		if Addon.FormatCurrencyCount then
			displayTotal = Addon:FormatCurrencyCount(entryIds[entryIndex], total)
		end
		entrySummaries[entryIndex] = {
			label = label,
			total = total,
			displayTotal = displayTotal,
			text = label .. "  " .. displayTotal,
		}
	end

	local row = {
		kind = "currency",
		key = "currency",
		name = Addon:T("CD_CURRENCY"),
		typeLabel = "",
		entryLabels = entryLabels,
		entrySummaries = entrySummaries,
		cells = {},
	}
	for charIndex = 1, #charList do
		local characterKey = charList[charIndex].key
		local character = characters[characterKey]
		if character and character.currency then
			row.cells[characterKey] = BuildCurrencyCell(character.currency)
		end
	end
	rows[#rows + 1] = row
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
	if self.CollectCharacterCurrency then
		record.currency = self:CollectCharacterCurrency()
	end
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
	return a.name < b.name
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

-- Rows are unique instance (raid/dungeon); columns are stored account characters.
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
				local rowKey = InstanceRowKey(entry)
				local row = rowsByKey[rowKey]
				if not row then
					row = {
						key = rowKey,
						name = entry.name or "",
						isRaid = entry.isRaid and true or false,
						typeLabel = InstanceKindLabel(entry),
						cells = {},
					}
					rowsByKey[rowKey] = row
					rows[#rows + 1] = row
				end
				local cellData = row.cells[key]
				if not cellData then
					cellData = { variants = {} }
					row.cells[key] = cellData
				end
				cellData.variants[#cellData.variants + 1] = {
					maxPlayers = tonumber(entry.maxPlayers) or 0,
					heroic = IsHeroicLockout(entry),
					tag = FormatVariantTag(entry),
					tooltipLine = VariantTooltipLine(entry, now),
				}
			end
		end
	end

	table.sort(charList, CompareCharacters)
	for index = 1, #charList do
		charList[index].displayName = CharacterDisplayName(charList[index], charList)
	end
	table.sort(rows, CompareRows)
	for rowIndex = 1, #rows do
		local row = rows[rowIndex]
		if row.kind ~= "currency" then
			for characterKey, cellData in pairs(row.cells) do
				row.cells[characterKey] = FinalizeLockoutCell(cellData)
			end
		end
	end
	local lockoutRowCount = #rows
	AppendCurrencyRow(rows, characters, charList)

	return {
		characters = charList,
		rows = rows,
		lockoutRowCount = lockoutRowCount,
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
		local currency = character.currency
		if type(currency) == "table" and type(currency.entries) == "table" then
			local entries = currency.entries
			lines[#lines + 1] = '      "currency": {'
			lines[#lines + 1] = '        "entries": ['
			for entryIndex = 1, #entries do
				local entry = entries[entryIndex]
				local entryComma = (entryIndex < #entries) and "," or ""
				lines[#lines + 1] = "          {"
				lines[#lines + 1] = '            "id": "' .. JsonEscape(tostring(entry.id or "")) .. '",'
				lines[#lines + 1] = '            "label": "' .. JsonEscape(entry.label or "") .. '",'
				lines[#lines + 1] = '            "icon": "' .. JsonEscape(entry.icon or "") .. '",'
				lines[#lines + 1] = '            "count": ' .. tostring(tonumber(entry.count) or 0)
				lines[#lines + 1] = "          }" .. entryComma
			end
			lines[#lines + 1] = "        ]"
			lines[#lines + 1] = "      },"
		end
		AppendLockoutObjectsJson(lines, lockouts, "      ")
		lines[#lines + 1] = "    }" .. comma
	end

	lines[#lines + 1] = "  ]"
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n")
end
