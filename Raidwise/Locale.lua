-- English / Russian strings. Active locale is RaidwiseDB.locale, else the client locale.

local Addon = Raidwise

local Translations = {
	enUS = {
		TAB_COOLDOWNS = "Character cooldowns",
		TAB_EXPORT = "Export gear and CDs",
		TAB_PARTY = "Party roster",
		TAB_RAID = "Raid roster",
		TAB_HISTORY = "History",
		TAB_COMPOSITION = "Raid composition",
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
			.. "Raid composition checks the current party or raid for roles and Wowhead-style exclusive buffs, external CDs, damage reduction, debuffs, and mana/health regen. "
			.. "Gold rows are covered; dim rows are missing. Hover a row to see who brings it.\n\n"
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
		COMP_HINT = "Who is needed, and which raid buffs, debuffs, and utility are already covered.",
		COMP_FAIL = "Composition module failed to load. Reload UI (/reload).",
		COMP_EMPTY = "Join a party or raid, or play solo to see your own coverage.",
		COMP_SECTION_ROLES = "Roles",
		COMP_SECTION_BUFFS = "Buffs",
		COMP_SECTION_EXTERNAL = "External buffs",
		COMP_SECTION_DR = "Damage reduction",
		COMP_SECTION_DEBUFFS = "Debuffs",
		COMP_SECTION_MANA = "Mana regeneration",
		COMP_SECTION_HP = "Health regeneration",
		COMP_MISSING = "Missing",
		COMP_PROVIDERS = "In raid: %s",
		COMP_CAN_BRING = "Brought by: %s",
		COMP_NONE = "-",
		COMP_STATS_PCT = "10% stats",
		COMP_MOTW = "Mark of the Wild",
		COMP_STAMINA = "Stamina",
		COMP_INTELLECT = "Intellect",
		COMP_SPIRIT = "Spirit",
		COMP_ATTACK_POWER = "Attack power",
		COMP_STR_AGI = "Strength / Agility",
		COMP_HEALTH = "Health",
		COMP_MP5 = "Mana per 5",
		COMP_SPELL_POWER = "Spell power",
		COMP_MELEE_CRIT = "5% melee crit",
		COMP_SPELL_CRIT = "5% spell crit",
		COMP_MELEE_HASTE = "Melee haste",
		COMP_SPELL_HASTE = "Spell haste",
		COMP_HASTE_ALL = "3% haste",
		COMP_DAMAGE_PCT = "3% damage",
		COMP_AP_PCT = "10% attack power",
		COMP_BLOODLUST = "Bloodlust / Heroism",
		COMP_HEALING_RECV = "Healing received",
		COMP_FOCUS_MAGIC = "Focus Magic",
		COMP_TRICKS = "Tricks of the Trade",
		COMP_UNHOLY_FRENZY = "Unholy Frenzy",
		COMP_POWER_INFUSION = "Power Infusion",
		COMP_INNERVATE = "Innervate",
		COMP_HAND_SALVATION = "Hand of Salvation",
		COMP_HAND_SACRIFICE = "Hand of Sacrifice",
		COMP_HAND_FREEDOM = "Hand of Freedom",
		COMP_HAND_PROTECTION = "Hand of Protection",
		COMP_PAIN_SUPPRESSION = "Pain Suppression",
		COMP_GUARDIAN_SPIRIT = "Guardian Spirit",
		COMP_MISDIRECTION = "Misdirection",
		COMP_EARTH_SHIELD = "Earth Shield",
		COMP_BEACON = "Beacon of Light",
		COMP_SACRED_SHIELD = "Sacred Shield",
		COMP_DIVINE_SACRIFICE = "Divine Sacrifice",
		COMP_INTERVENE = "Intervene",
		COMP_AMZ = "Anti-Magic Zone",
		COMP_DIVINE_GUARDIAN = "Divine Guardian",
		COMP_AURA_MASTERY = "Aura Mastery",
		COMP_SHIELD_WALL = "Shield Wall",
		COMP_LAST_STAND = "Last Stand",
		COMP_ICEBOUND = "Icebound Fortitude",
		COMP_VAMPIRIC_BLOOD = "Vampiric Blood",
		COMP_SURVIVAL_INSTINCTS = "Survival Instincts",
		COMP_FRENZIED_REGEN = "Frenzied Regeneration",
		COMP_DISPERSION = "Dispersion",
		COMP_DIVINE_PROTECTION = "Divine Protection",
		COMP_DIVINE_SHIELD = "Divine Shield",
		COMP_BARKSKIN = "Barkskin",
		COMP_ICE_BLOCK = "Ice Block",
		COMP_CLOAK = "Cloak of Shadows",
		COMP_AMS = "Anti-Magic Shell",
		COMP_LAY_ON_HANDS = "Lay on Hands",
		COMP_DIVINE_HYMN = "Divine Hymn",
		COMP_TRANQUILITY = "Tranquility",
		COMP_SANCTUARY_GRACE = "Sanctuary / Grace",
		COMP_INSPIRATION = "Inspiration / Ancestral Healing",
		COMP_ARMOR_MAJOR = "Armor (major)",
		COMP_ARMOR_MINOR = "Armor (minor)",
		COMP_BLEED = "Bleed damage",
		COMP_PHYS_TAKEN = "Physical damage taken",
		COMP_SPELL_TAKEN = "Spell damage taken",
		COMP_SPELL_HIT = "Spell hit (Misery)",
		COMP_CRIT_TAKEN = "Crit chance taken",
		COMP_SPELL_CRIT_TAKEN = "Spell crit taken",
		COMP_ATTACK_SLOW = "Attack speed slow",
		COMP_AP_DOWN = "Attack power down",
		COMP_HEALING_REDUCE = "Healing reduction",
		COMP_CAST_SLOW = "Cast speed slow",
		COMP_MELEE_HIT_DOWN = "Melee hit reduction",
		COMP_JOL = "Judgement of Light",
		COMP_JOW = "Judgement of Wisdom",
		COMP_REPLENISHMENT = "Replenishment",
		COMP_MANA_TIDE = "Mana Tide Totem",
		COMP_HYMN_OF_HOPE = "Hymn of Hope",
		COMP_SHADOWFIEND = "Shadowfiend",
		COMP_REVITALIZE = "Revitalize",
		COMP_IMP_LOTP = "Improved Leader of the Pack",
		COMP_VAMPIRIC_EMBRACE = "Vampiric Embrace",
		COMP_GIFT_NAARU = "Gift of the Naaru",
		COMP_SPEC_ANY = "any",
		COMP_SPEC_ARMS = "Arms",
		COMP_SPEC_FURY = "Fury",
		COMP_SPEC_PROTECTION = "Protection",
		COMP_SPEC_HOLY = "Holy",
		COMP_SPEC_RETRIBUTION = "Retribution",
		COMP_SPEC_BM = "Beast Mastery",
		COMP_SPEC_MM = "Marksmanship",
		COMP_SPEC_SURVIVAL = "Survival",
		COMP_SPEC_ASSASSINATION = "Assassination",
		COMP_SPEC_COMBAT = "Combat",
		COMP_SPEC_SUBTLETY = "Subtlety",
		COMP_SPEC_DISCIPLINE = "Discipline",
		COMP_SPEC_SHADOW = "Shadow",
		COMP_SPEC_BLOOD = "Blood",
		COMP_SPEC_FROST = "Frost",
		COMP_SPEC_UNHOLY = "Unholy",
		COMP_SPEC_ELEMENTAL = "Elemental",
		COMP_SPEC_ENHANCEMENT = "Enhancement",
		COMP_SPEC_RESTORATION = "Restoration",
		COMP_SPEC_ARCANE = "Arcane",
		COMP_SPEC_FIRE = "Fire",
		COMP_SPEC_AFFLICTION = "Affliction",
		COMP_SPEC_DEMONOLOGY = "Demonology",
		COMP_SPEC_DESTRUCTION = "Destruction",
		COMP_SPEC_BALANCE = "Balance",
		COMP_SPEC_FERAL = "Feral",
		COMP_CLASS_WARRIOR = "Warrior",
		COMP_CLASS_PALADIN = "Paladin",
		COMP_CLASS_HUNTER = "Hunter",
		COMP_CLASS_ROGUE = "Rogue",
		COMP_CLASS_PRIEST = "Priest",
		COMP_CLASS_DEATHKNIGHT = "Death Knight",
		COMP_CLASS_SHAMAN = "Shaman",
		COMP_CLASS_MAGE = "Mage",
		COMP_CLASS_WARLOCK = "Warlock",
		COMP_CLASS_DRUID = "Druid",
		COMP_SRC_ANY = "%s (any)",
		COMP_SRC_SPEC = "%s (%s)",
		COMP_SRC_DRAENEI = "Draenei",

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
		TAB_COMPOSITION = "Анализ состава",
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
			.. "Анализ состава проверяет текущую группу или рейд: роли и баффы, внешние КД, снижение урона, дебаффы, восполнение маны и здоровья (как на Wowhead). "
			.. "Золотые строки уже есть, серые — не хватает. Наведите курсор, чтобы увидеть, кто это даёт.\n\n"
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
		COMP_HINT = "Кого не хватает и какие баффы, дебаффы и утилиты уже есть в рейде.",
		COMP_FAIL = "Модуль анализа состава не загрузился. Перезагрузите интерфейс (/reload).",
		COMP_EMPTY = "Войдите в группу или рейд — или смотрите покрытие только своего персонажа.",
		COMP_SECTION_ROLES = "Роли",
		COMP_SECTION_BUFFS = "Баффы",
		COMP_SECTION_EXTERNAL = "Внешние баффы",
		COMP_SECTION_DR = "Снижение урона",
		COMP_SECTION_DEBUFFS = "Дебаффы",
		COMP_SECTION_MANA = "Восполнение маны",
		COMP_SECTION_HP = "Восполнение здоровья",
		COMP_MISSING = "Нет",
		COMP_PROVIDERS = "В рейде: %s",
		COMP_CAN_BRING = "Дают: %s",
		COMP_NONE = "-",
		COMP_STATS_PCT = "10% характеристик",
		COMP_MOTW = "Дар дикой природы",
		COMP_STAMINA = "Выносливость",
		COMP_INTELLECT = "Интеллект",
		COMP_SPIRIT = "Дух",
		COMP_ATTACK_POWER = "Сила атаки",
		COMP_STR_AGI = "Сила / Ловкость",
		COMP_HEALTH = "Здоровье",
		COMP_MP5 = "Мана раз в 5",
		COMP_SPELL_POWER = "Сила заклинаний",
		COMP_MELEE_CRIT = "5% крит ближнего боя",
		COMP_SPELL_CRIT = "5% крит заклинаний",
		COMP_MELEE_HASTE = "Скорость ближнего боя",
		COMP_SPELL_HASTE = "Скорость заклинаний",
		COMP_HASTE_ALL = "3% скорости",
		COMP_DAMAGE_PCT = "3% урона",
		COMP_AP_PCT = "10% силы атаки",
		COMP_BLOODLUST = "Жажда крови / Героизм",
		COMP_HEALING_RECV = "Получаемое исцеление",
		COMP_FOCUS_MAGIC = "Магическая концентрация",
		COMP_TRICKS = "Маленькие хитрости",
		COMP_UNHOLY_FRENZY = "Нечестивое бешенство",
		COMP_POWER_INFUSION = "Придание сил",
		COMP_INNERVATE = "Озарение",
		COMP_HAND_SALVATION = "Длань спасения",
		COMP_HAND_SACRIFICE = "Длань жертвенности",
		COMP_HAND_FREEDOM = "Длань свободы",
		COMP_HAND_PROTECTION = "Длань защиты",
		COMP_PAIN_SUPPRESSION = "Подавление боли",
		COMP_GUARDIAN_SPIRIT = "Оберегающий дух",
		COMP_MISDIRECTION = "Перенаправление",
		COMP_EARTH_SHIELD = "Щит земли",
		COMP_BEACON = "Частица Света",
		COMP_SACRED_SHIELD = "Священный щит",
		COMP_DIVINE_SACRIFICE = "Божественная жертва",
		COMP_INTERVENE = "Вмешательство",
		COMP_AMZ = "Антимагическая зона",
		COMP_DIVINE_GUARDIAN = "Божественный страж",
		COMP_AURA_MASTERY = "Мастерство аур",
		COMP_SHIELD_WALL = "Глухая оборона",
		COMP_LAST_STAND = "Ни шагу назад",
		COMP_ICEBOUND = "Незыблемость льда",
		COMP_VAMPIRIC_BLOOD = "Кровь вампира",
		COMP_SURVIVAL_INSTINCTS = "Инстинкты выживания",
		COMP_FRENZIED_REGEN = "Неистовое восстановление",
		COMP_DISPERSION = "Слияние с Тьмой",
		COMP_DIVINE_PROTECTION = "Божественная защита",
		COMP_DIVINE_SHIELD = "Божественный щит",
		COMP_BARKSKIN = "Дубовая кожа",
		COMP_ICE_BLOCK = "Ледяная глыба",
		COMP_CLOAK = "Плащ Теней",
		COMP_AMS = "Антимагический панцирь",
		COMP_LAY_ON_HANDS = "Возложение рук",
		COMP_DIVINE_HYMN = "Божественный гимн",
		COMP_TRANQUILITY = "Спокойствие",
		COMP_SANCTUARY_GRACE = "Святилище / Благодать",
		COMP_INSPIRATION = "Вдохновение / Исцеление предков",
		COMP_ARMOR_MAJOR = "Броня (крупная)",
		COMP_ARMOR_MINOR = "Броня (малая)",
		COMP_BLEED = "Урон от кровотечения",
		COMP_PHYS_TAKEN = "Получаемый физический урон",
		COMP_SPELL_TAKEN = "Получаемый урон от заклинаний",
		COMP_SPELL_HIT = "Меткость заклинаний (Страдание)",
		COMP_CRIT_TAKEN = "Шанс получить крит",
		COMP_SPELL_CRIT_TAKEN = "Шанс получить крит заклинания",
		COMP_ATTACK_SLOW = "Замедление атаки",
		COMP_AP_DOWN = "Снижение силы атаки",
		COMP_HEALING_REDUCE = "Снижение исцеления",
		COMP_CAST_SLOW = "Замедление заклинаний",
		COMP_MELEE_HIT_DOWN = "Снижение меткости ближнего боя",
		COMP_JOL = "Правосудие света",
		COMP_JOW = "Правосудие мудрости",
		COMP_REPLENISHMENT = "Восполнение",
		COMP_MANA_TIDE = "Тотем прилива маны",
		COMP_HYMN_OF_HOPE = "Гимн надежды",
		COMP_SHADOWFIEND = "Исчадие Тьмы",
		COMP_REVITALIZE = "Оживление",
		COMP_IMP_LOTP = "Улучшенный вожак стаи",
		COMP_VAMPIRIC_EMBRACE = "Объятия вампира",
		COMP_GIFT_NAARU = "Дар наару",
		COMP_SPEC_ANY = "любой",
		COMP_SPEC_ARMS = "Оружие",
		COMP_SPEC_FURY = "Неистовство",
		COMP_SPEC_PROTECTION = "Защита",
		COMP_SPEC_HOLY = "Свет",
		COMP_SPEC_RETRIBUTION = "Воздаяние",
		COMP_SPEC_BM = "Повелитель зверей",
		COMP_SPEC_MM = "Стрельба",
		COMP_SPEC_SURVIVAL = "Выживание",
		COMP_SPEC_ASSASSINATION = "Ликвидация",
		COMP_SPEC_COMBAT = "Бой",
		COMP_SPEC_SUBTLETY = "Скрытность",
		COMP_SPEC_DISCIPLINE = "Послушание",
		COMP_SPEC_SHADOW = "Тьма",
		COMP_SPEC_BLOOD = "Кровь",
		COMP_SPEC_FROST = "Лед",
		COMP_SPEC_UNHOLY = "Нечестивость",
		COMP_SPEC_ELEMENTAL = "Стихии",
		COMP_SPEC_ENHANCEMENT = "Совершенствование",
		COMP_SPEC_RESTORATION = "Исцеление",
		COMP_SPEC_ARCANE = "Тайная магия",
		COMP_SPEC_FIRE = "Огонь",
		COMP_SPEC_AFFLICTION = "Колдовство",
		COMP_SPEC_DEMONOLOGY = "Демонология",
		COMP_SPEC_DESTRUCTION = "Разрушение",
		COMP_SPEC_BALANCE = "Баланс",
		COMP_SPEC_FERAL = "Сила зверя",
		COMP_CLASS_WARRIOR = "Воин",
		COMP_CLASS_PALADIN = "Паладин",
		COMP_CLASS_HUNTER = "Охотник",
		COMP_CLASS_ROGUE = "Разбойник",
		COMP_CLASS_PRIEST = "Жрец",
		COMP_CLASS_DEATHKNIGHT = "Рыцарь смерти",
		COMP_CLASS_SHAMAN = "Шаман",
		COMP_CLASS_MAGE = "Маг",
		COMP_CLASS_WARLOCK = "Чернокнижник",
		COMP_CLASS_DRUID = "Друид",
		COMP_SRC_ANY = "%s (любой)",
		COMP_SRC_SPEC = "%s (%s)",
		COMP_SRC_DRAENEI = "Дреней",

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
