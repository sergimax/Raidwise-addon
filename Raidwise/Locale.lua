-- English / Russian strings. Active locale is RaidwiseDB.locale, else the client locale.

local Addon = Raidwise

local Translations = {
	enUS = {
		TAB_COOLDOWNS = "Character cooldowns",
		TAB_EXPORT = "Export gear and CDs",
		TAB_PARTY = "Party roster",
		TAB_RAID = "Raid roster",
		TAB_HISTORY = "History",
		TAB_SETTINGS = "Settings",
		TAB_INFO = "Info",
		MENU = "Menu",

		BTN_REFRESH = "Refresh",
		BTN_SELECT_ALL = "Select all",
		BTN_EXPORT_DATA = "Export character data",

		EXPORT_DESC = "Export this character's gear, bags, and raid lockouts as JSON.",
		EXPORT_INCLUDE_NAMES = "Include item names",
		EXPORT_HINT = "After export, press Ctrl+C to copy.",
		EXPORT_READY = "Export ready — press Ctrl+C to copy.",
		EXPORT_SELECTED = "Selected — press Ctrl+C to copy.",

		INFO_ABOUT = "About",
		INFO_BODY = "Raidwise is a raid-prep addon for Wrath of the Lich King 3.3.5a: party and raid rosters, meeting history, account-wide lockouts, and character export.\n\n"
			.. "Character cooldowns shows raid and dungeon lockouts for every character saved on this account, "
			.. "including when each character was last checked. "
			.. "Log in on each alt to record their lockouts.\n\n"
			.. "Party roster lists the current 5-player party with spec, raid-buff icons, GearScore, average item level, guild, karma, and tags. "
			.. "Raid roster shows raid groups 1–5 and 6–8 as player cards (class, role, spec, raid-buff icons, GearScore, iLvl). "
			.. "Click a filled card to open Character profile.\n\n"
			.. "History keeps party and raid players you have grouped with, including where and when you met them. "
			.. "That list is saved on this account and stays after logout.\n\n"
			.. "Export gear and CDs builds JSON with name, class, spec, equipped gear, bag items, and raid or dungeon lockouts. "
			.. "Turn on Include item names to add display names next to item ids. "
			.. "If the GearScore addon is loaded, the current score is included.\n\n"
			.. "Settings changes the interface language (English or Russian). The choice is saved on this account.\n\n"
			.. "Slash commands: /raidwise or /rw (help, version, status, show, hide).",
		INFO_GITHUB = "GitHub",
		INFO_REPO_HINT = "Select the URL, then press Ctrl+C to copy.",
		INFO_REPO_SELECTED = "Selected — press Ctrl+C to copy.",

		CD_HINT = "Lockouts for every character saved on this account.",
		CD_EMPTY = "Log in on each character to record raid and dungeon lockouts.",
		CD_NO_ROWS = "No current lockouts.",
		CD_INSTANCE = "Raid / Dungeon",
		CD_LAST_CHECK = "Last check: %s",
		CD_LAST_CHECK_NONE = "Last check: -",
		CD_SAVED_RESETS = "Saved - resets in %s",
		CD_NOT_SAVED = "Not saved",
		LOCKOUT_RAID = "Raid",
		LOCKOUT_DUNGEON = "Dungeon",
		LOCKOUT_HEROIC = "Heroic",
		LOCKOUT_NORMAL = "Normal",
		TIME_DAYS_HOURS = "%dd %dh",
		TIME_HOURS_MINUTES = "%dh %dm",
		TIME_MINUTES = "%dm",
		TIME_LESS_MINUTE = "<1m",

		PARTY_HINT = "Current party (5 players max). Refresh after gear or spec changes.",
		PARTY_FAIL = "Party module failed to load. Reload UI (/reload).",
		RAID_HINT = "Raid groups 1–5 and 6–8. Refresh after gear or spec changes.",
		RAID_FAIL = "Raid roster module failed to load. Reload UI (/reload).",
		HISTORY_HINT = "Players from your parties and raids. Saved on this account.",
		HISTORY_FAIL = "History module failed to load. Reload UI (/reload).",

		COL_NAME = "Name",
		COL_CLASS = "Class",
		COL_SPEC = "Spec",
		COL_BUFFS = "Buffs",
		COL_GS = "GS",
		COL_ILVL = "iLvl",
		COL_KARMA = "Karma",
		COL_TAGS = "Tags",
		COL_GUILD = "Guild",
		COL_ZONE = "Met in",
		COL_WHEN = "When",

		AVG_ILVL_GS = "Average iLvl: %s     Average GS: %s",
		AVG_GS = "Average GS: %s",
		ROLE_SUMMARY = "%s: %s (%s gs)",
		ROLE_TANK = "Tank",
		ROLE_HEALER = "Healer",
		ROLE_MELEE = "Melee DPS",
		ROLE_RANGED = "Ranged DPS",
		ROLE_UNKNOWN = "Unknown",
		ROLE_TANKS = "Tanks",
		ROLE_HEALERS = "Healers",
		ROLE_MELEE_SHORT = "Melee",
		ROLE_RANGE = "Range",
		KARMA_LINE = "%s Karma",
		STATS_GS = "%sgs",
		STATS_ILVL = "%silvl",

		PROFILE_TITLE = "%s - Character profile",
		PROFILE_GS = "GearScore: %s",
		PROFILE_ILVL = "iLvl: %s",
		PROFILE_GUILD = "Guild: %s",
		PROFILE_MET = "Met: %s",
		PROFILE_WHEN = "When: %s",
		PROFILE_REALM = "Realm: %s",
		PROFILE_GUID = "GUID: %s",

		SETTINGS_LANGUAGE = "Language",
		SETTINGS_LANGUAGE_HINT = "Interface language. Saved on this account.",
		LOCALE_EN = "English",
		LOCALE_RU = "Русский",

		CHAT_LOADED = "loaded (v%s). Type /raidwise for help.",
		CHAT_HELP_HELP = "/raidwise help    - show this help",
		CHAT_HELP_VERSION = "/raidwise version - show addon version",
		CHAT_HELP_STATUS = "/raidwise status  - show addon status",
		CHAT_HELP_SHOW = "/raidwise show    - open the main window",
		CHAT_HELP_HIDE = "/raidwise hide    - close the main window",
		CHAT_VERSION = "version %s",
		CHAT_STATUS = "v%s | updated=%s | enabled=%s | player=%s",
		CHAT_UNKNOWN = "Unknown command. Type /raidwise help",

		MONTH_1 = "Jan",
		MONTH_2 = "Feb",
		MONTH_3 = "Mar",
		MONTH_4 = "Apr",
		MONTH_5 = "May",
		MONTH_6 = "Jun",
		MONTH_7 = "Jul",
		MONTH_8 = "Aug",
		MONTH_9 = "Sep",
		MONTH_10 = "Oct",
		MONTH_11 = "Nov",
		MONTH_12 = "Dec",
	},
	ruRU = {
		TAB_COOLDOWNS = "КД персонажей",
		TAB_EXPORT = "Экспорт экип. и КД",
		TAB_PARTY = "Состав группы",
		TAB_RAID = "Состав рейда",
		TAB_HISTORY = "История",
		TAB_SETTINGS = "Настройки",
		TAB_INFO = "Справка",
		MENU = "Меню",

		BTN_REFRESH = "Обновить",
		BTN_SELECT_ALL = "Выделить всё",
		BTN_EXPORT_DATA = "Экспорт персонажа",

		EXPORT_DESC = "Экспорт экипировки, сумок и КД этого персонажа в JSON.",
		EXPORT_INCLUDE_NAMES = "Включать названия предметов",
		EXPORT_HINT = "После экспорта нажмите Ctrl+C, чтобы скопировать.",
		EXPORT_READY = "Экспорт готов — нажмите Ctrl+C, чтобы скопировать.",
		EXPORT_SELECTED = "Выделено — нажмите Ctrl+C, чтобы скопировать.",

		INFO_ABOUT = "Об аддоне",
		INFO_BODY = "Raidwise — аддон для подготовки к рейду в Wrath of the Lich King 3.3.5a: составы группы и рейда, история встреч, КД на аккаунте и экспорт персонажа.\n\n"
			.. "КД персонажей показывает рейдовые и подземельные блокировки всех сохранённых персонажей, "
			.. "включая время последней проверки. "
			.. "Зайдите на каждого альта, чтобы записать его КД.\n\n"
			.. "Состав группы — текущая группа из 5 игроков: спек, иконки рейд-баффов, GearScore, средний iLvl, гильдия, карма и теги. "
			.. "Состав рейда — группы 1–5 и 6–8 карточками (класс, роль, спек, рейд-баффы, GearScore, iLvl). "
			.. "Клик по заполненной карточке открывает профиль персонажа.\n\n"
			.. "История хранит игроков, с которыми вы были в группе или рейде, включая место и время встречи. "
			.. "Список сохраняется на аккаунте и остаётся после выхода.\n\n"
			.. "Экспорт экипировки и КД собирает JSON: имя, класс, спек, надетые вещи, сумки и блокировки. "
			.. "Включите «Включать названия предметов», чтобы добавить имена рядом с id. "
			.. "Если установлен аддон GearScore, в экспорт попадает текущий счёт.\n\n"
			.. "В Настройках можно сменить язык интерфейса (English или Русский). Выбор сохраняется на аккаунте.\n\n"
			.. "Команды: /raidwise или /rw (help, version, status, show, hide).",
		INFO_GITHUB = "GitHub",
		INFO_REPO_HINT = "Выделите URL, затем нажмите Ctrl+C, чтобы скопировать.",
		INFO_REPO_SELECTED = "Выделено — нажмите Ctrl+C, чтобы скопировать.",

		CD_HINT = "КД всех персонажей, сохранённых на этом аккаунте.",
		CD_EMPTY = "Зайдите на каждого персонажа, чтобы записать рейдовые и подземельные КД.",
		CD_NO_ROWS = "Нет текущих КД.",
		CD_INSTANCE = "Рейд / Подземелье",
		CD_LAST_CHECK = "Проверка: %s",
		CD_LAST_CHECK_NONE = "Проверка: -",
		CD_SAVED_RESETS = "Сохранён — сброс через %s",
		CD_NOT_SAVED = "Не сохранён",
		LOCKOUT_RAID = "Рейд",
		LOCKOUT_DUNGEON = "Подземелье",
		LOCKOUT_HEROIC = "Героический",
		LOCKOUT_NORMAL = "Обычный",
		TIME_DAYS_HOURS = "%dд %dч",
		TIME_HOURS_MINUTES = "%dч %dм",
		TIME_MINUTES = "%dм",
		TIME_LESS_MINUTE = "<1м",

		PARTY_HINT = "Текущая группа (до 5 игроков). Обновите после смены экипировки или спека.",
		PARTY_FAIL = "Модуль группы не загрузился. Перезагрузите интерфейс (/reload).",
		RAID_HINT = "Рейдовые группы 1–5 и 6–8. Обновите после смены экипировки или спека.",
		RAID_FAIL = "Модуль состава рейда не загрузился. Перезагрузите интерфейс (/reload).",
		HISTORY_HINT = "Игроки из ваших групп и рейдов. Сохраняется на этом аккаунте.",
		HISTORY_FAIL = "Модуль истории не загрузился. Перезагрузите интерфейс (/reload).",

		COL_NAME = "Имя",
		COL_CLASS = "Класс",
		COL_SPEC = "Спек",
		COL_BUFFS = "Баффы",
		COL_GS = "GS",
		COL_ILVL = "iLvl",
		COL_KARMA = "Карма",
		COL_TAGS = "Теги",
		COL_GUILD = "Гильдия",
		COL_ZONE = "Где встретили",
		COL_WHEN = "Когда",

		AVG_ILVL_GS = "Средний iLvl: %s     Средний GS: %s",
		AVG_GS = "Средний GS: %s",
		ROLE_SUMMARY = "%s: %s (%s gs)",
		ROLE_TANK = "Танк",
		ROLE_HEALER = "Лекарь",
		ROLE_MELEE = "Ближний бой",
		ROLE_RANGED = "Дальний бой",
		ROLE_UNKNOWN = "Неизвестно",
		ROLE_TANKS = "Танки",
		ROLE_HEALERS = "Лекари",
		ROLE_MELEE_SHORT = "МДД",
		ROLE_RANGE = "РДД",
		KARMA_LINE = "%s Карма",
		STATS_GS = "%sgs",
		STATS_ILVL = "%silvl",

		PROFILE_TITLE = "%s - Профиль персонажа",
		PROFILE_GS = "GearScore: %s",
		PROFILE_ILVL = "iLvl: %s",
		PROFILE_GUILD = "Гильдия: %s",
		PROFILE_MET = "Встреча: %s",
		PROFILE_WHEN = "Когда: %s",
		PROFILE_REALM = "Реалм: %s",
		PROFILE_GUID = "GUID: %s",

		SETTINGS_LANGUAGE = "Язык",
		SETTINGS_LANGUAGE_HINT = "Язык интерфейса. Сохраняется на этом аккаунте.",
		LOCALE_EN = "English",
		LOCALE_RU = "Русский",

		CHAT_LOADED = "загружен (v%s). Введите /raidwise для справки.",
		CHAT_HELP_HELP = "/raidwise help    - эта справка",
		CHAT_HELP_VERSION = "/raidwise version - версия аддона",
		CHAT_HELP_STATUS = "/raidwise status  - статус загрузки",
		CHAT_HELP_SHOW = "/raidwise show    - открыть окно",
		CHAT_HELP_HIDE = "/raidwise hide    - закрыть окно",
		CHAT_VERSION = "версия %s",
		CHAT_STATUS = "v%s | updated=%s | enabled=%s | player=%s",
		CHAT_UNKNOWN = "Неизвестная команда. Введите /raidwise help",

		MONTH_1 = "янв",
		MONTH_2 = "фев",
		MONTH_3 = "мар",
		MONTH_4 = "апр",
		MONTH_5 = "мая",
		MONTH_6 = "июн",
		MONTH_7 = "июл",
		MONTH_8 = "авг",
		MONTH_9 = "сен",
		MONTH_10 = "окт",
		MONTH_11 = "ноя",
		MONTH_12 = "дек",
	},
}

local ROLE_LABEL_KEYS = {
	tank = "ROLE_TANK",
	healer = "ROLE_HEALER",
	melee = "ROLE_MELEE",
	ranged = "ROLE_RANGED",
	unknown = "ROLE_UNKNOWN",
}

local activeLocale = "enUS"

local function NormalizeLocale(locale)
	if not locale then
		return "enUS"
	end
	local lower = string.lower(tostring(locale))
	if lower == "ruru" then
		return "ruRU"
	end
	if lower:find("en", 1, true) then
		return "enUS"
	end
	return "enUS"
end

function Addon:DetectClientLocale()
	return NormalizeLocale(GetLocale and GetLocale())
end

function Addon:GetLocaleId()
	if self.db and (self.db.locale == "enUS" or self.db.locale == "ruRU") then
		return self.db.locale
	end
	return activeLocale
end

function Addon:T(key, ...)
	local pack = Translations[activeLocale] or Translations.enUS
	local text = pack[key] or Translations.enUS[key] or key
	if select("#", ...) <= 0 then
		return text
	end
	local ok, formatted = pcall(string.format, text, ...)
	if ok then
		return formatted
	end
	return text
end

function Addon:SetLocale(locale, skipRefresh)
	locale = NormalizeLocale(locale)
	if locale ~= "enUS" and locale ~= "ruRU" then
		locale = "enUS"
	end
	activeLocale = locale
	if self.db then
		self.db.locale = locale
	end
	if not skipRefresh and self.RefreshLocalizedUI then
		self:RefreshLocalizedUI()
	end
end

function Addon:RoleLabelKey(role)
	return ROLE_LABEL_KEYS[role] or ROLE_LABEL_KEYS.unknown
end

function Addon:FormatShortDateTime(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then
		return "-"
	end
	local month = tonumber(date("%m", timestamp)) or 0
	local day = tonumber(date("%d", timestamp)) or 0
	local hour = date("%H", timestamp) or "00"
	local minute = date("%M", timestamp) or "00"
	return string.format("%d %s %s:%s", day, self:T("MONTH_" .. tostring(month)), hour, minute)
end

activeLocale = Addon:DetectClientLocale()
Addon:SetLocale(activeLocale, true)
