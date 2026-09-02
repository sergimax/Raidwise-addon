# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.18.0] - 2026-09-02

### Added
- Character profile **Events** grouped by category (**Attendance**, **Loot**, **Help**, **Behavior**) with category icons in the picker and event list
- **In the same party** attendance event is logged automatically when the meet count increments (first grouping, or again after ≥30 minutes)
- Icons on Character profile **History** changelog rows (event category or change kind)
- Starter trinkets for Retribution Paladin in Gear check

### Changed
- Character profile window has a bronze outer border

## [1.17.0] - 2026-09-02

### Added
- **Raid roster** gear check: **Scan** with a progress bar, **Export** of scanned dumps (also `/rw gearcheck raid dump`), per-player **Rescan**, and **Profile** / **Gear** on each card
- Separate **Armor/weap** and **Ench/sock** grades on raid player cards
- Left menu groups **Personal**, **Raiding**, and **Other**
- Hover tips on Scan, Export, Refresh, and related buttons

### Changed
- When you are not in a raid, the current party fills Raid roster group 1
- Addon version is shown in the left-menu title bar; the footer status bar is gone, and the menu sits flush against the content panel
- **Info** uses larger text, one sentence per line, and lists; descriptions match the current pages
- Gear check catalogs cover more Northrend gems and enchants; incomplete inspects and situational trinkets are called out more clearly
- Saved startup pages `party` and `gearraid` move to **Raid roster**

### Removed
- **Party roster** tab (party view lives on Raid roster)
- **Gear check (raid)** tab (raid scan lives on Raid roster)

### Fixed
- Missing party-only raid buffs use a red tint so they are easier to spot

## [1.16.0] - 2026-08-25

### Added
- **Gear check (target)**: Scan target or self for surface-level PvE gear evaluation (armor/weapons/stats/enchants/gems/meta), Overall status, filtered findings, self-chat reports, and optional raw dump via **Show as a text**
- **Gear check (raid)**: Sequential party/raid scan with a Raid-roster-style group grid (parties 1–5 / 6–8); click a player to open the full target report
- Manual **Save report** / load / delete for gear-check snapshots (~14-day retention)
- Spec-specific rule profiles, enchant/gem catalogs, trinket pools, T9/T10 set counts (informational), and `/rw gearcheck test` offline self-test
- Class and spec icons in the Gear check (target) summary band

### Changed
- Gear check (target) uses a two-column layout (summary + findings left; Scan / text view / saved reports right)
- Stat preference labels use **unwanted** instead of discouraged; tighter per-class/spec stat templates (Priest, Druid, Warlock, and others)

### Fixed
- Inspect re-scans no longer invent empty sockets / missing gems when gem IDs are stripped from item links
- Raid gear-check no longer applies the previous player’s talent tree (e.g. Protection name on a Priest) when inspecting the next member

## [1.15.0] - 2026-08-24

### Added
- **Settings → Startup page**: choose which left-menu tab opens on `/raidwise` (`RaidwiseDB.startupTab`; default Character cooldowns)

### Changed
- Startup page options use a radio group; **Info** cannot be selected as the startup page

## [1.14.0] - 2026-08-24

### Changed
- Main window and Character profile use the Classic theme (navy panels, gold accents, bronze borders)
- Character profile opens on the **History** tab by default
- Character profile tab renamed **Note** → **Edit note** (RU: **Изменить заметку**)

### Fixed
- Party roster and History: class, spec, and buff icons no longer overlap the top row border

## [1.13.0] - 2026-08-24

### Added
- Player unit tooltips show personal opinion + top tags, and community rating + tags for players in History (`UnitTooltips.lua`)
- **Settings → Unit tooltips**: hide personal / personal tags / community / community tags (`RaidwiseDB.tooltip`), with compact and stacked layout previews

### Fixed
- Tooltip lines no longer disappear when holding Shift (rebuild with GearScore)
- Raid/party frame hover no longer stacks duplicate Raidwise lines when moving between players

## [1.12.0] - 2026-08-23

### Added
- **Character cooldowns**: **Remove** on non-current character columns drops that alt from `RaidwiseDB.characters` (log in again to restore)

### Changed
- Lockouts for one instance are a single row; character cells show compact size/mode tags (`10`, `10h`, `25`, `25h`); heroic tags are red; hover shows reset time per variant
- First column shows instance name with `(Raid)` / `(Dungeon)` instead of separate size/heroic subtype lines

### Fixed
- Opening `/rw` no longer errors when building united lockout rows (`FormatRemaining` order)

## [1.11.0] - 2026-08-23

### Added
- **Character cooldowns** **Currency** row: gold, raid emblems (Frost/Triumph), honor/arena, and quest tokens (Heroism, Valor, Conquest, Champion’s Seal) snapped from the in-game Currency tab
- First column shows each currency label with an **account-wide total**; character columns show icon + quantity chips aligned to those labels
- Currency snapshots stored in `RaidwiseDB.characters[key].currency` (and included in cooldowns export JSON)

### Fixed
- Opening `/rw` no longer errors when building the currency row
- Currency icons no longer show as red squares on alts with older SavedVariables (icons resolve from the catalog at display time)

## [1.10.0] - 2026-08-22

### Added
- **Raid composition** top summary: Roles and all 10 class icons with counts (present gold, missing dim)
- **Aggro** section (Misdirection, Tricks of the Trade)
- **Report missing** posts absent class names to raid or party chat
- **Shift-click** an effect row to post that effect with provider class/spec and spell names (`need` / `have`)
- Effect tooltips list each source on its own line with class/spec and spell name from `GetSpellInfo`
- Section headings show **present/total** coverage; heading turns red only when present is `0`
- Judgement of Wisdom under Mana regeneration; JoW / JoL stay hidden in Debuffs

### Changed
- Composition layout: classes/roles on a horizontal band above the three-column checklist
- Damage reduction includes Hand of Sacrifice, Divine Sacrifice, Hand of Protection, and Pain Suppression
- Innervate is listed under Mana (hidden as External); Divine Shield and Tranquility are hidden
- Corrected composition spell labels and IDs (Gift of the Wild, Sanctuary / Renewed Hope, Swift Retribution)

### Fixed
- Section count columns no longer wrap double-digit `present/total` values

## [1.9.0] - 2026-08-22

### Added
- Character profile **Facts** and **Events** tabs (role/identity facts up to 4; typed events with zone/instance context); **Save and Update** commits opinion, tags, facts, and events together
- Profile History shows **Was in the same party** count (increments after ≥30 minutes since last seen in a group)
- Left menu category icons for each tab
- **Info** page feature sections with the same menu icons and each view’s layout `vN`
- Reputation model docs ([`docs/Reputation.md`](docs/Reputation.md))

### Changed
- Slash commands: `/raidwise` / `/rw` open the window; `/raidwise close` / `/rw close` close it (removed `help`, `version`, `status`, `show`, `hide`)
- Main window title shows the active menu name and that page’s layout `vN` (shell layout version is rebuild-only, not shown)
- Profile tabs renamed to **History** / **Note** / **Facts** / **Events** / **Memo**; memo stays private and is not logged in History
- Personal rating catalog split into tags, facts, and event types (with one-shot SavedVariables migration)

## [1.8.0] - 2026-08-20

### Added
- Layout version badges (`vN`) on the main window title bar and every content page (Character profile already showed one); mismatched versions rebuild the window without relying on `/reload` alone

### Changed
- Main UI split into shared widgets (`UIWidgets.lua`), one module per tab (`Page*.lua`), and a thinner shell (`ExporterWindow.lua`)

## [1.7.0] - 2026-08-20

### Added
- **Personal player ratings**: Positive / Neutral / Negative opinion and personal tags (up to 3 per category), saved in `RaidwiseDB.history[guid].rating.personal`
- **Character profile** tabs: **History**, **Edit note**, and **Edit memo** — draft opinion/tags with bottom **Update**; memo **Save** / **Reset**
- Race icon on the Character profile header (with race/faction tooltip)
- Profile change log for opinion, tag, and note edits
- Community note mock preview in Character profile (future exchange / web feature)
- Left-click a **Party roster** row to open Character profile (same as Raid roster and History)

### Changed
- Party roster, Raid roster, and History show your saved personal opinion and tag summary instead of placeholder karma
- Character profile is a full rating and notes editor (not only meeting details)
- Addon list notes and Info about text mention player ratings

### Fixed
- Closing Character profile refreshes the open Party / Raid / History tab so opinion and tags stay in sync

## [1.6.0] - 2026-08-19

### Added
- **Raid composition** tab: Wowhead-style checklist of roles, raid buffs, external CDs, damage reduction, debuffs, and mana/health regen for the current party or raid (self-targeted defensives are omitted)
- **Settings** tab: English / Russian interface language, saved in `RaidwiseDB.locale`
- Russian localization for in-game UI, slash help, and addon list notes (`## Notes-ruRU`)
- Russian README ([`README.ru.md`](README.ru.md))
- **Character cooldowns** column headers show when that character was last checked (`18 Aug 23:58`; full date on hover)

### Changed
- Left menu order: Character cooldowns, Export gear and CDs, Party roster, Raid roster, Raid composition, History, Settings, Info
- Addon list notes and Info about text mention raid composition

### Removed
- **Export cooldowns** tab (account lockouts for the current character are already in **Export gear and CDs**)

## [1.5.0] - 2026-08-18

### Added
- **History** tab: party and raid players saved in `RaidwiseDB.history` (keyed by GUID), with where/when you met and guild
- **Character profile** from History or Raid roster adds meeting zone, time, realm, and GUID
- Raid roster **role icons** (tank / healer / melee / ranged, RaidBuffStatus-style) and **spec/race raid-buff** icons on player cards
- **Buffs** column on **Party roster** (same raid-utility icons as Raid roster)
- Raid roster summary: overall average GearScore plus per-role count and average GS (`Tanks: 2 (6200 gs)`)

### Changed
- Main window content area is **890 × 690** so raid groups 1–5 fit without vertical scrolling
- Larger roster icons (party/history **18** px, raid **20** px, buffs **18** px, profile **24** px)
- Raid roster summary hides average iLvl (transmog skews it); per-player cells still show iLvl
- Left menu adds **History** between Raid roster and Export gear and CDs
- Addon list notes and Info about text mention meeting history

### Fixed
- Raid roster player-card **#tag** line no longer clipped at the bottom of the cell

## [1.4.0] - 2026-08-18

### Added
- **Raid roster** tab: raid groups **1–5** and **6–8** as player cards (class icon, name, spec, GearScore, iLvl, karma, tags)
- **Character profile** window from left-clicking a filled Raid roster card (`{name} - Character profile`)
- Karma and Tags columns on **Party roster** (placeholder `4.3` and `#tag #tag` until those features exist)
- Average iLvl and average GearScore line above the Party roster table and Raid roster cells

### Changed
- Main window content area is **790 × 480** so the Raid roster grid fits
- Left menu order: Character cooldowns, Party roster, Raid roster, Export gear and CDs, Export cooldowns, Info
- Party roster lists the current 5-player party only (raid members stay on Raid roster)
- Addon list notes and Info about text describe rosters, lockouts, and export (not only character export)

### Fixed
- Other members’ item levels no longer vanish after inspect; iLvl is cached until the next successful scan
- Party and Raid roster refresh when the group or raid composition changes

## [1.3.0] - 2026-08-18

### Added
- **Party roster** tab: scrollable table of current party or raid members with class icon, spec icon (inspect for others), GearScore, average item level, and guild shown as `GuildName (Rank)`
- **Refresh** on Party roster re-scans GearScore, item levels, and guild info, and re-queues talent inspect for nearby members

### Changed
- Left menu order: Character cooldowns, Party roster, Export gear and CDs, Export cooldowns, Info

### Fixed
- Party roster rows failed to render when class-icon tooltips used mouse handlers on textures (3.3.5 requires a Frame host)
- Other members’ specs were not filled in because talent data was read on `INSPECT_READY` instead of `INSPECT_TALENT_READY`
- Player GearScore, item level, and guild on Party roster now use the same collection paths as export (including tooltip scan when the item cache is cold)

## [1.2.0] - 2026-08-18

### Added
- **Character cooldowns** tab: account-wide lockout table with instance + difficulty rows and one column per character (class-colored name and spec icon)
- **Export cooldowns** tab: JSON export of every stored character and their current lockouts (`types/CooldownsExport.ts`)
- Account-wide lockout snapshots in `RaidwiseDB.characters` (updated on login, `/reload`, and export)

### Changed
- Left menu order: Character cooldowns, Export gear and CDs, Export cooldowns, Info; window opens on Character cooldowns
- Export gear and CDs button renamed to **Export character data**
- Addon list title uses a colored **Raid**wise label

### Fixed
- Character cooldowns stayed empty after login when `UPDATE_INSTANCE_INFO` did not fire; lockouts now save from live client data on login and when opening the tab
- Refresh button on Character cooldowns overlapped the table top border

## [1.1.0] - 2026-08-17

### Added
- Details-style window with a left menu, content panel, and status bar (addon name and version)
- **Info** tab with a short addon description and a GitHub URL copy box (**Select all**, then Ctrl+C)

### Changed
- Export tab is now **Export gear and CDs**: description, include-names checkbox, **Export data** / **Select all**, then a WowSims-style copy box
- Window uses plain panels; drag the title bars only (not the whole frame)

### Fixed
- Long JSON exports could not scroll to the bottom of the copy box (`ChatFontNormal` line height)

### Removed
- Right-click to close the window (use **X** or Esc)

## [1.0.0] - 2026-08-16

### Changed
- Renamed the addon from **mrc-exporter** to **Raidwise** (folder, TOC title, UI, chat prefix)
- Slash commands are now `/raidwise` and `/rw` (replacing `/mrc` and `/mrcexporter`)
- SavedVariables renamed to `RaidwiseDB` (migrates settings from `MrcExporterDB` on first load)

### Removed
- Install path `Interface/AddOns/mrc-exporter/` — use `Interface/AddOns/Raidwise/` instead

## [0.5.0] - 2026-08-15

### Added
- Optional `gearScore` field in the character JSON export, read from the **GearScore** addon (same value as the character window)
- `## OptionalDeps: GearScore` so GearScore loads before mrc-exporter when both are installed
- `gearScore?: number` on the TypeScript `CharacterExport` type

## [0.4.0] - 2026-08-15

### Added
- Raid and dungeon instance lockouts in the character JSON export (`lockouts`: name, id, reset timers, difficulty, locked/extended flags)
- Fresh lockout data via `RequestRaidInfo` on login and when exporting
- TypeScript types for the export payload (`types/CharacterExport.ts`), including `InstanceDifficulty` and optional item `names`

## [0.3.0] - 2026-08-15

### Added
- Character JSON export with name, class, spec, equipped gear, and bag items (`CharacterExport.lua`)
- **Include item names** checkbox to optionally omit `names` arrays from the export (SavedVariables `includeGearNames`)
- Addon version shown under the window title
- Slash command `/mrc version` to print the addon version
- `## X-LastUpdated` TOC field (mirrored by README badge); `/mrc status` includes the last-updated date

### Changed
- Export output is a JSON-like object instead of two comma-separated lines

### Removed
- **Version** and **Character Info** buttons from the main window (use `/mrc version` and the title label instead)

## [0.2.0] - 2026-08-15

### Added
- Main in-game window (`ExporterWindow.lua`) with addon title header
- **Version** button that prints the current addon version to chat
- **Character Info** button that prints local date/time and character name to chat
- Slash commands `/mrc show` (also `ui`) and `/mrc hide` to open/close the window

## [0.1.0] - 2026-08-15

### Added
- Initial **mrc-exporter** addon for Wrath of the Lich King 3.3.5a (`Interface: 30300`)
- Slash commands `/mrc` and `/mrcexporter` with `help` and `status` subcommands
- SavedVariables store `MrcExporterDB` (default `enabled` flag)
- Load message in chat when the addon initializes
