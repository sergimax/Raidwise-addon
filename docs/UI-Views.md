# UI view schemes

ASCII layouts for each window and content page. Update this file when a view changes. Pixel sizes live in [`UI-Sizes.md`](UI-Sizes.md). Shared widgets: `UIWidgets.lua`. Page modules and shell: see [`Architecture.md`](Architecture.md).

Architecture overview (TOC order, SavedVariables, refresh API): [`Architecture.md`](Architecture.md).

## Shell

Classic-theme plain panels: left menu, content page, status bar under both.

```text
[ Menu 170 ] 2px [ Content 890 x 940 ]
                 [ title bar 20  {page} vN  X ]
                 [ page body         ]
[ addon name ] [ current version ]
```

Title bar (left to right): **active menu item name**, that page’s layout badge **`vN`**, close **X**. Shell `SHELL_LAYOUT_VERSION` is used for rebuild only (not shown). Addon semver stays in the status bar.

Status bar:

| Block | In-game text |
|-------|----------------|
| addon name | Raidwise |
| current version | `v` + `Addon.version` |

Menu tabs (top to bottom; each row has a 16×16 category icon + label):

```text
[ watch ] Character cooldowns
[ note  ] Export gear and CDs
[ PoF   ] Party roster
[ glory ] Raid roster
[ BoK   ] Raid composition
[ scope ] Gear check (target)
[ book  ] History
[ gear  ] Settings
[  ?    ] Info
```

Icons (`Interface\Icons\`): `INV_Misc_PocketWatch_01`, `INV_Misc_Note_01`, `Spell_Holy_PrayerOfFortitude`, `Achievement_Dungeon_GloryoftheRaider`, `Spell_Magic_GreaterBlessingofKings`, `INV_Misc_Spyglass_03`, `INV_Misc_Book_11`, `INV_Misc_Gear_01`, `INV_Misc_QuestionMark`.
## Layout versions

Independent from addon semver (`Addon.version` in the status bar). Bump a view’s `LAYOUT_VERSION` when structure, sizes, or named frames change; open windows rebuild on next show.

| View | Constant | File | Badge location |
|------|----------|------|----------------|
| Main shell | `SHELL_LAYOUT_VERSION = 7` | `ExporterWindow.lua` | Rebuild only (not shown in UI) |
| Character profile | `PROFILE_LAYOUT_VERSION = 27` | `CharacterProfile.lua` | Title bar (left of close) |
| Cooldowns | `LAYOUT_VERSION = 8` | `PageCooldowns.lua` | Shell title bar (next to page name) |
| Export | `LAYOUT_VERSION = 1` | `PageExport.lua` | Shell title bar (next to page name) |
| Party | `LAYOUT_VERSION = 1` | `PageParty.lua` | Shell title bar (next to page name) |
| Raid | `LAYOUT_VERSION = 5` | `PageRaid.lua` | Shell title bar (next to page name) |
| Composition | `LAYOUT_VERSION = 8` | `PageComposition.lua` | Shell title bar (next to page name) |
| Gear check (target) | `LAYOUT_VERSION = 10` | `PageGearCheckTarget.lua` | Shell title bar (next to page name) |
| History | `LAYOUT_VERSION = 1` | `PageHistory.lua` | Shell title bar (next to page name) |
| Settings | `LAYOUT_VERSION = 6` | `PageSettings.lua` | Shell title bar (next to page name) |
| Info | `LAYOUT_VERSION = 3` | `PageInfo.lua` | Shell title bar (next to page name) |

Rules: see `.cursor/rules/layout-versions.mdc`. Do **not** bump layout versions for locale-only string edits.

## Export gear and CDs

```text
[ short description ]
[ checkbox for including item names ]
[ export data button ] [ select all data button ]
[ short hint about copy ]
[ input for copy ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Export this character's gear, bags, and raid lockouts as JSON.” |
| checkbox | Include item names |
| export data button | **Export character data** — fills the copy box |
| select all data button | **Select all** — highlights JSON for Ctrl+C (disabled until export) |
| short hint | Starts as “After export, press Ctrl+C to copy.” |
| input for copy | Tooltip-bordered multiline EditBox (WowSimsExporter / AceGUI style). Click selects all; Ctrl+C copies. |

## Character cooldowns

Account-wide lockout table. Columns persist in `RaidwiseDB.characters` after you log in on each character.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Raid / Dungeon | Char (class color + spec icon) | Char | ... ]
                 | last check                     | last check |
                 |                                | [ Remove ] |
[ Icecrown Citadel                               | 10 10h 25 25h | -   ]
[ (Raid)                                         |               |     ]
[ Currency          | (title line — empty in char cols)        ]
[ Gold  12.3kg      | [icon] 645g  | ...                      ]
[ Frost  47         | [icon] 2     | ...                      ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Lockouts and currency for every character saved on this account.” |
| Refresh | Requests fresh raid info, then redraws the table (hover tip) |
| first column | Instance name, then kind in parentheses (`(Raid)` / `(Dungeon)`); **Currency** row at bottom |
| character columns | Name in class color with the primary spec icon; last check time (`18 Aug 23:58`) under the name; current character first; **Remove** on other columns deletes that character from `RaidwiseDB.characters` (login again restores) |
| saved cell | Compact size/mode tags (`10`, `10h`, `25`, `25h`, …); tooltip lists each variant with time until reset |
| currency cell | Title line + label column with account totals (`Gold  12kg`); character columns skip one line, then icon+count chips aligned to labels |
| empty cell | `-` (not saved) |
| empty table | “Log in on each character…” if none saved; “No current lockouts.” if columns exist but no lockouts (**Currency** row still shows) |

Rows come only from current lockouts; each instance is one row with all size/mode variants combined in character cells (10 / 10 Heroic / 25 / 25 Heroic, plus older 20 and 40). Expired lockouts are dropped.

## Party roster

Current 5-player party (you plus up to four others). Solo shows only you. Raid members are listed on Raid roster. Spec for other members is filled via inspect when they are nearby.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Average iLvl: 264     Average GS: 6158 ]
        8 px gap
[ Name | (class) | (spec) | (buffs) | GS | iLvl | Opinion | Tags | Guild (rank) ]
[ Rhee |  SH   |  Enh   |  icons  | 6158 | 264 |   +   | Friendly, Good Tank | MyGuild (Member) ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Current party (5 players max). Refresh after gear or spec changes.” |
| Refresh | Re-reads GearScore, item levels, guild info; re-queues inspect for specs (hover tip) |
| averages | Mean iLvl and GearScore of members that have a value (`-` when none) |
| Name | Class-colored character name |
| Class | Class icon (`CLASS_ICON_TCOORDS`); hover shows localized class name |
| Spec | Primary talent tree icon only; hover shows spec name |
| Buffs | Spec- and race-specific raid buff icons (hover for name); up to 8 |
| GS | GearScore when the GearScore addon has scanned the player |
| iLvl | Average equipped item level (tooltip scan when item cache is cold) |
| Opinion | Saved personal opinion symbol: `+` (Positive), `=` (Neutral), `-` (Negative); color-coded |
| Tags | Colored tag summary (up to 3 labels, then `+N`); `-` when none |
| Guild | `GuildName (Rank)` from `GetGuildInfo`; `-` when not in a guild |
| hover | Tooltip shows full opinion label and tag summary |
| click | Left-click a row opens **Character profile** |

Personal opinion and tags come from `RaidwiseDB.history` (keyed by GUID). Default opinion is Neutral with no tags.

## Raid roster

Current raid layout by group, with integrated gear-check scan. Parties 1–5 are the first block; parties 6–8 are the second. Each party has five player slots. Not in a raid: party members fill group 1.

```text
[                                    Scan ] [ Refresh ]
[ short description — full width ]
[ gear check hint / scan progress ]
        8 px gap
[ Average GS: 6158 ]
[ Tanks: 2 (6200 gs)     Healers: 6 (5800 gs)     Melee: 10 (6400 gs)     Range: 7 (6100 gs) ]
[ BAD · REPLACE · OK · GOOD · Failed ]
        8 px gap
[ 1              ][ 2              ][ 3              ][ 4              ][ 5              ]
[ (class) Rhee   ][ empty slot     ] ...
[ (role)(spec) 6158gs 264ilvl ]
[ (buff)(buff)(buff) ]
[ Personal opinion: Positive ]
[ Friendly, Good Tank ]
[ Armor/weap: GOOD ]
[ Ench/sock: REPLACE ]
[ Profile ][ Gear check ]
        12 px gap
[ 6              ][ 7              ][ 8              ]
[ player cell    ] ...
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Raid groups 1–5 and 6–8… Scan shows armor/weap and ench/sock grades per player.” |
| Scan | **Scan** — queues gear check over `CompositionMembers()` one inspect at a time (hover tip) |
| Refresh | Re-reads GearScore, iLvl, and re-queues inspect for spec icons (hover tip) |
| gear check hint / status | Rating legend (GOOD / OK / REPLACE / BAD + preferred / acceptable / unwanted / forbidden); progress `Scanning N/M: Name…` while scanning |
| averages | Mean GearScore of members that have a value (`-` when none). Average iLvl is omitted (transmog skews it). |
| role averages | Count and mean GS per role (`Tanks: 2 (6200 gs)`); `-` when none |
| gear summary | Counts by overall status + failed/skipped inspects; dim until first scan |
| column header | Group number (`1`–`8`) |
| line 1 | Class icon + class-colored name |
| line 2 | Role icon (same as RaidBuffStatus) + spec icon + `6158gs 264ilvl` |
| line 3 | Spec- and race-specific raid buff icons (hover for name); up to 8 |
| line 4 | `Personal opinion: {Positive|Neutral|Negative}`; color-coded |
| line 5 | Colored tag summary (up to 3 labels, then `+N`); dim when none |
| line 6 | `Armor/weap: {GOOD|OK|REPLACE|BAD}` (colored grade) or fail / not scanned (`—`) |
| line 7 | `Ench/sock: {GOOD|OK|REPLACE|BAD}` (colored grade); blank when not scanned |
| line 8 | **Profile** (Character profile) and **Gear check** (opens report on Gear check (target); disabled until scanned); both have hover tips |
| hover | Tooltip shows opinion/tags |
| click | Left-click card → **Character profile**; **Profile** / **Gear check** buttons do the same actions |

API: `StartGearCheckRaidScan`, `GetLastGearCheckRaidResults`, `ShowGearCheckReport`, `IsGearCheckScanBusy`.

## Raid composition

Wowhead-style checklist of the current party or raid: who is needed, and which exclusive buffs, externals, DR, debuffs, and regen are already covered. Tracking list: [`Raid-Composition.md`](Raid-Composition.md).

```text
[ short description ]                   [ Report missing ] [ Refresh ]
        8 px gap
[ Roles ]                    [ Classes ]
[ (tank)2 (heal)6 (m)12 (r)5 ] [ W2 Pa1 Hu0 Ro1 … Dr0 ]
        gap
[ Aggro              ] [ Buffs              ] [ External buffs    ]
[ (icon) Misdirect 1 ] [ (icon) 10% stats 1 ] [ (icon) Focus Magic 0 ]
[ Damage reduction   ] [ Debuffs            ] [ Mana / Health regen ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Who is needed, and which raid buffs, debuffs, and utility are already covered.” |
| Report missing | Posts absent classes to raid chat (or party); all present → short “all classes present” line (hover tip) |
| Refresh | Re-reads the current group (same inspect/GearScore path as Raid roster) (hover tip) |
| Roles | Left of top band: role icon + count; tooltip = role name + who / Missing |
| Classes | Right of top band: all 10 WotLK class icons + count; present gold, absent dim; tooltip = class + who / Missing |
| columns | Three equal columns below; sections pack into the shortest column |
| section heading | Name left; `present/total` right-aligned above row counts; gold, or **red** when present is `0` |
| row | Spell icon, name, count of players who can provide it; **Shift-click** posts effect + class/spec — spell lines to raid/party chat |
| present | Gold name and count (`> 0`) |
| missing | Dim name and `0` |
| tooltip | Who in the raid has it; then **Brought by:** on its own line, then one source class/spec — spell per line; hint for Shift-click |

Spec is the primary talent tree (same as Raid roster). Solo shows only your own coverage.

## Gear check (target)

Two-column layout: **left** — summary, chat reports, filters, findings; **right** — status, Scan, Show as a text, Select all (top band), then Save report, Delete selected report, scrollable saved list. Spec / progress: Gear Check specification + `docs/Gear-Check-Progress.md`. Types: `types/GearCheck.ts`. Stat profile editor: `gear-check-debug/stats-matrix.html`.

```text
[ short description — full width ]
[ surface-level limitation — full width ]

LEFT (~670px)                          RIGHT (~220px)
[ summary: Overall / class+spec icons / who / GS+iLvl … ]  [ status line 1 ]
                                        [ status line 2 … ]
                                        [ Scan ]
                                        [ Show as a text ]
                                        [ Select all ]

[ Report summary | … | Report OK ]
[ All | Items | Enchants | Gems | OK ]

[ scrollable findings by slot ]         [ Save report ]
                                        [ Delete selected report ]
                                        [ Saved reports (~14 days) — scroll ]

(Show as a text → raw dump copy box below top band; text view + Select all stay in top band)
```

| Block | In-game text / control |
|-------|------------------------|
| short description | Overall: GOOD (preferred) / OK (usable·acceptable) / REPLACE (unwanted·soft) / BAD (forbidden·wrong for spec); surface-level PvE; not BiS |
| limitation | No BiS lists, builds, encounter requirements, or detailed stat weights |
| summary (left) | Overall status (colored), class + spec icons + character line, GearScore / avg iLvl, issue counts, meta, sets |
| status (right) | Multi-line hint or scan result (`\n` breaks + word wrap); sits above Scan |
| Scan | Resolves target or self, inspects if needed, evaluate + refresh UI (hover tip) |
| Show as a text | Toggles raw dump (replaces main columns; stays in top band) (hover tip) |
| Select all | Enabled in text view when dump has text (hover tip) |
| report buttons | Print to **self chat only** (`[GearCheck]` lines); hover tip per mode |
| filters | All / Items / Enchants / Gems / **OK**; hover tip per filter |
| breakdown (left) | Active filter name as gold header (except **All**); then `[VERDICT] Slot — Item` plus finding bullets |
| Save report | Stores current evaluated snapshot (~14 days); scans are **not** auto-saved (hover tip) |
| Delete selected report | Removes the currently viewed saved entry (hover tip) |
| saved panel (right) | Scrollable list of all saved entries; click loads frozen snapshot |

`LAYOUT_VERSION = 10`. Slash: `/rw gearcheck`; `/rw gearcheck summary|items|enchants|gems|ok`; `/rw gearcheck test`.

Saved snapshot fields: `rulesetVersion` (`wotlk-3.3.5a-{addonVersion}`), `dataVersion` (`GEAR_CHECK_DATA_VERSION` in catalog). Expired entries prune on load/save.

Raid-wide gear check lives on **Raid roster** (Scan button + report rows per player cell). See that section for layout and interaction.

## Character profile

Standalone window (**460 × 560**) opened from Party roster, Raid roster, or History (left-click a row or filled player cell). Esc or **X** closes it; drag the title bar to move it.

```text
[ Rhee - Character profile                              v27   X ]
| (race)(class) Shaman    | (spec) Enhancement                  |
| GearScore: 6158         | iLvl: 264                           |
| Personal note: Positive | Community note                      |
| Friendly, Good Tank     | mock preview text                   |
| Facts: Raid Leader      | (percentages, sample reports)       |
| Guild: MyGuild (Member) |                                     |
| GUID: 0x...              |                                    |
| Realm: Icecrown         |                                     |
[ History ] [ Edit note ] [ Facts ] [ Events ] [ Memo ]
        --- tab content (History selected by default) ---
(tab: Edit note)
[ Summary: Positive | Tags: Friendly, Good Tank, Prepared ]
( ) Positive   (*) Neutral   ( ) Negative
[ Personal tags — category checkboxes (max 3 per category) ]
(tab: Facts)
[ Facts — role checkboxes (max 4) ]
(tab: Events)
[ Pick type — scrollable type buttons ]
[ Add event ]
[ event rows with Remove, newest first ]
(tab: Memo)
[ Memo ]
[ Personal memo only. Not shared and not recorded in History. ]
[ Memo — multiline edit box ]
[ Save ] [ Reset ]
(tab: History)
[ Met: Icecrown Citadel          Was in the same party: 3 ]
[ When: 2026-08-18 18:54 ]
[ change log entries, newest first ]
[ Save and Update ]```

| Block | In-game text / control |
|-------|------------------------|
| title | `{characterName} - Character profile` |
| layout version | Title-bar badge `v` + `PROFILE_LAYOUT_VERSION` (UI structure; not addon semver) |
| close | **X** (right of title bar); Esc also closes |
| class / spec | Side-by-side row: race + class icons + name (class-colored), spec icon + name (`-` until inspect) |
| GearScore / iLvl | Side-by-side row: `GearScore: {score}` and `iLvl: {average}`; `-` when unknown |
| Race icon | Character-creation race portrait on the class row (same size as class/spec icons); tooltip shows race name and faction |
| Summary (left column) | Read-only: personal note, tag summary, facts, guild, GUID, realm — reflects **saved** values only until **Save and Update** |
| Community note (right column) | Mock preview for a future addon exchange / web app feature (read-only) |
| Tabs | **History**, **Edit note**, **Facts**, **Events**, **Memo** — **History** opens by default |
| Edit note (editor tab) | Summary line (draft preview); three exclusive radio options; tag checkboxes by category (draft until **Save and Update**) |
| Facts (editor tab) | Role / identity checkboxes (draft until **Save and Update**); max **4** |
| Events tab | Pick an event type, **Add event** / **Remove** edit a draft list; **Save and Update** persists events with auto zone/instance context on add |
| Memo (editor tab) | Personal-use hint; multiline EditBox; **Save** / **Reset**. Memo is not written to History |
| History tab | **Met** (left) and **Was in the same party** count (right) on the first row, then **When**, then logged opinion/tag/facts/event changes (and any older memo rows if present) |
| Save and Update | Bottom of window on **Edit note** / **Facts** / **Events** only; saves opinion, tags, facts, and events. Hidden on **History** and **Memo** (memo uses its own **Save** / **Reset**) |
| editable | Opinion, tags, facts, events, and notes require a valid GUID; controls are disabled otherwise |
| persistence | Opinion/tags/facts in `RaidwiseDB.history[guid].rating.personal`; events in `.events`; notes in `.notes`; change log in `.changes`; `meetCount` for party/raid encounters |

Changing opinion, tags, facts, or events (via **Save and Update**) refreshes Party roster, Raid roster, and History when the profile closes or Save and Update is pressed. Closing without Save discards Edit note / Facts / Events drafts.

See also [Reputation.md](Reputation.md) for entity definitions and future share matrix.

## History

Players you have been in a party or raid with (not yourself). Each GUID is stored in `RaidwiseDB.history` and survives logout. First meeting zone, time, and realm are kept; later grouping updates GearScore, iLvl, spec, and last seen.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Name | (class) | (spec) | Opinion | Tags | GS | iLvl | Met in | When | Guild (rank) ]
[ Rhee |  SH   |  Enh   |    +    | Friendly, Good Tank | 6158 | 264 | Icecrown Citadel | 2026-08-18 18:54 | MyGuild (Member) ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Players from your parties and raids. Saved on this account.” |
| Refresh | Records the current group again, then redraws the saved list |
| Name | Class-colored character name |
| Class | Class icon; hover shows localized class name |
| Spec | Primary talent tree icon; hover shows spec name |
| Opinion | Saved personal opinion symbol: `+`, `=`, or `-`; color-coded |
| Tags | Colored tag summary (up to 3 labels, then `+N`); `-` when none |
| GS | Last stored GearScore |
| iLvl | Last stored average item level |
| Met in | Raid, dungeon, or zone at first meeting |
| When | First meeting date and time |
| Guild | Last stored `GuildName (Rank)` |
| hover | Tooltip shows full opinion label and tag summary |
| click | Left-click a row opens **Character profile** |

Notes are stored on each history record (`notes`) and edited in Character profile; they are not shown in this table.

## Settings

```text
[ language heading ]
[ short hint ]
[ English button ] [ Русский button ]

[ Startup page heading ]
[ short hint ]
( ) Cooldowns   ( ) Export      ( ) Party       ( ) Raid
( ) Composition ( ) Gear target ( ) Gear raid   ( ) History
( ) Settings

[ Unit tooltips heading ]
[ short hint ]
[ ] Hide personal opinion
[ ] Hide personal tags
[ ] Hide community rating
[ ] Hide community tags

[ Preview ]
Compact (live tooltip)
Positive: Good Raid Leader, Fair Loot, Good player
91 % positive:
Fair Loot, Good Raid Leader, Good player
Stacked (variant)
…
```

| Block | In-game text / control |
|-------|------------------------|
| language heading | Language |
| short hint | “Interface language. Saved on this account.” |
| English / Русский | Menu-style buttons; the active locale is selected. Choice is stored in `RaidwiseDB.locale` (`enUS` / `ruRU`). Default is the client locale. |
| Startup page | Exclusive radio group for left-menu pages (**Info** excluded); selected page opens on `/raidwise`. Stored in `RaidwiseDB.startupTab` (default `cooldowns`). |
| Unit tooltips | Checkboxes stored in `RaidwiseDB.tooltip` (`hidePersonal`, `hidePersonalTags`, `hideCommunity`, `hideCommunityTags`); default all shown |
| Preview | Sample compact (live) and stacked layout lines; updates when checkboxes change |

Switching language updates the left menu, page labels, and visible tables without `/reload`. Player unit tooltips (mouseover/target) append personal opinion + top 3 tags and, for players in History, community mock percent + top 3 tags (`UnitTooltips.lua`).

## Info

```text
[ about heading ]
[ short intro + slash commands ]
[ menu icon ] Menu name  vN
[ section description ]
… (one block per menu page except Info)
[ github heading ]
[ short hint about copy ]
[ input for repo URL ] [ select all button ]
```

| Block | In-game text / control |
|-------|------------------------|
| about heading | About |
| intro | Raid-prep overview and slash commands (`/raidwise`, `/rw`, `close`) |
| feature sections | Same icons as the left menu; title = menu label; **`vN`** = that page’s `LAYOUT_VERSION`; body describes the view |
| github heading | GitHub |
| short hint | “Select the URL, then press Ctrl+C to copy.” |
| input for repo URL | Single-line copy box with `https://github.com/sergimax/Raidwise-addon` |
| select all button | **Select all** — highlights the URL for Ctrl+C |
| scroll | Vertical scroll when sections exceed the content area |

## Adding a view

1. Add a tab in `PAGES` in `ExporterWindow.lua` (shell) and a `Page*.lua` module under `Addon.Pages`.
2. Give the view a `LAYOUT_VERSION` constant, stamp it on the frame, and show it in the shell title bar next to the menu name (pages) or with `AttachLayoutVersionLabel` (profile popup).
3. Paste a new `## Title` scheme here (same `[ block ]` style) including the layout `vN`.
4. Implement the page and record sizes in `UI-Sizes.md`.
5. See [`Architecture.md`](Architecture.md) for load order and the two version concepts (addon semver vs layout).

> **Note:** Shell and per-page layout versions force recreate when constants bump (see Architecture). Named scroll/edit frames use a `V` + layout version suffix.
