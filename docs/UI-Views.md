# UI view schemes

ASCII layouts for each window and content page. Update this file when a view changes. Pixel sizes live in [`UI-Sizes.md`](UI-Sizes.md) and the `UI` table in `ExporterWindow.lua`.

## Shell

Details-style plain panels: left menu, content page, status bar under both.

```text
[ Menu 170 ] 2px [ Content 790 x 480 ]
                 [ title bar 20      ]
                 [ page body         ]
[ addon name ] [ current version ]
```

Status bar:

| Block | In-game text |
|-------|----------------|
| addon name | Raidwise |
| current version | `v` + `Addon.version` |

Menu tabs (top to bottom):

```text
[ Character cooldowns ]
[ Party roster ]
[ Raid roster ]
[ History ]
[ Export gear and CDs ]
[ Export cooldowns ]
[ Info ]
```

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
[ Icecrown Citadel                               | 2d 4h | -   ]
[ Raid / 25 Heroic                               |       |     ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Lockouts for every character saved on this account.” |
| Refresh | Requests fresh raid info, then redraws the table |
| first column | Instance name, then type (`Raid` / `Dungeon` / size / Heroic) |
| character columns | Name in class color with the primary spec icon; current character first |
| saved cell | Remaining time until reset (gold); tooltip has instance + type |
| empty cell | `-` (not saved) |
| empty table | “Log in on each character…” if none saved; “No current lockouts.” if columns exist but nothing is saved |

Rows come only from current lockouts (10 / 10 Heroic / 25 / 25 Heroic, plus older 20 and 40). Expired lockouts are dropped.

## Party roster

Current 5-player party (you plus up to four others). Solo shows only you. Raid members are listed on Raid roster. Spec for other members is filled via inspect when they are nearby.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Average iLvl: 264     Average GS: 6158 ]
        8 px gap
[ Name | (class) | (spec) | GS | iLvl | Karma | Tags | Guild (rank) ]
[ Rhee |  SH   |  Enh   | 6158 | 264 | 4.3 | #tag #tag | MyGuild (Member) ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Current party (5 players max). Refresh after gear or spec changes.” |
| Refresh | Re-reads GearScore, item levels, guild info; re-queues inspect for specs |
| averages | Mean iLvl and GearScore of members that have a value (`-` when none) |
| Name | Class-colored character name |
| Class | Class icon (`CLASS_ICON_TCOORDS`); hover shows localized class name |
| Spec | Primary talent tree icon only; hover shows spec name |
| GS | GearScore when the GearScore addon has scanned the player |
| iLvl | Average equipped item level (tooltip scan when item cache is cold) |
| Karma | Placeholder `4.3` until karma is implemented |
| Tags | `#tag #tag`; placeholder until tag functions exist |
| Guild | `GuildName (Rank)` from `GetGuildInfo`; `-` when not in a guild |

## Raid roster

Current raid layout by group. Parties 1–5 are the first block; parties 6–8 are the second. Each party has five player slots. Not in a raid: party members fill group 1.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Average iLvl: 264     Average GS: 6158 ]
        8 px gap
[ 1              ][ 2              ][ 3              ][ 4              ][ 5              ]
[ (class) Rhee   ][ empty slot     ] ...
[ (spec) 6158gs 264ilvl ]
[ 4.3 Karma      ]
[ #tag #tag      ]
        12 px gap
[ 6              ][ 7              ][ 8              ]
[ player cell    ] ...
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Raid groups 1–5 and 6–8. Refresh after gear or spec changes.” |
| Refresh | Re-reads GearScore, iLvl, and re-queues inspect for spec icons |
| averages | Mean iLvl and GearScore of filled raid members that have a value (`-` when none) |
| column header | Group number (`1`–`8`) |
| line 1 | Class icon + class-colored name |
| line 2 | Spec icon + `6158gs 264ilvl` (omit missing values) |
| line 3 | Temporary karma placeholder (`4.3 Karma`) |
| line 4 | Tags (`#tag #tag`); placeholder until tag functions exist |
| click | Left-click a filled cell opens **Character profile** |

## Character profile

Standalone window opened from Raid roster or History (left-click a filled player cell or row). Esc or **X** closes it; drag the title bar to move it.

```text
[ Rhee - Character profile                                      X ]
[ (class) Shaman ]
[ (spec) Enhancement ]
[ GearScore: 6158 ]
[ iLvl: 264 ]
[ Guild: MyGuild (Member) ]
[ 4.3 Karma ]
[ #tag #tag ]
[ Met: Icecrown Citadel ]
[ When: 2026-08-18 18:54 ]
[ Realm: Icecrown ]
[ GUID: 0x00000000002a3b4c ]
```

| Block | In-game text / control |
|-------|------------------------|
| title | `{characterName} - Character profile` |
| close | **X** (right of title bar); Esc also closes |
| class | Class icon + localized class name (class-colored) |
| spec | Talent tree icon + spec name (`-` until inspect) |
| GearScore | `GearScore: {score}` or `GearScore: -` |
| iLvl | `iLvl: {average}` or `iLvl: -` |
| Guild | `Guild: GuildName (Rank)` or `Guild: -` |
| Karma | Placeholder `{value} Karma` (`4.3 Karma`) |
| Tags | `#tag #tag`; placeholder until tag functions exist |
| Met | Raid or dungeon (or zone) where you first grouped with them; `-` if unknown |
| When | Local date and time of that first meeting (`YYYY-MM-DD HH:MM`) |
| Realm | Realm where the meeting happened; `-` if unknown |
| GUID | `UnitGUID` for this character; shown only here |

## History

Players you have been in a party or raid with (not yourself). Each GUID is stored in `RaidwiseDB.history` and survives logout. First meeting zone, time, and realm are kept; later grouping updates GearScore, iLvl, spec, and last seen.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Name | (class) | (spec) | GS | iLvl | Met in | When | Guild (rank) ]
[ Rhee |  SH   |  Enh   | 6158 | 264 | Icecrown Citadel | 2026-08-18 18:54 | MyGuild (Member) ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Players from your parties and raids. Saved on this account.” |
| Refresh | Records the current group again, then redraws the saved list |
| Name | Class-colored character name |
| Class | Class icon; hover shows localized class name |
| Spec | Primary talent tree icon; hover shows spec name |
| GS | Last stored GearScore |
| iLvl | Last stored average item level |
| Met in | Raid, dungeon, or zone at first meeting |
| When | First meeting date and time |
| Guild | Last stored `GuildName (Rank)` |
| click | Left-click a row opens **Character profile** |

Notes, tags, links, and a change log are stored empty on each record for later editing; they are not shown on this table yet.

## Export cooldowns

```text
[ short description ]
[ export cooldowns button ] [ select all button ]
[ short hint about copy ]
[ input for copy ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Export account-wide raid and dungeon lockouts as JSON.” |
| export cooldowns button | **Export cooldowns** — fills the copy box |
| select all button | **Select all** — highlights JSON for Ctrl+C (disabled until export) |
| short hint | Starts as “After export, press Ctrl+C to copy.” |
| input for copy | Same tooltip-bordered multiline EditBox as Export gear and CDs |

JSON includes `exportedAt` and a `characters[]` array (key, name, realm, class, spec, `updatedAt`, `lockouts[]`). Log in on each alt so their lockouts are stored.

## Info

```text
[ about heading ]
[ descriptions about addon functions ]
[ github heading ]
[ short hint about copy ]
[ input for repo URL ] [ select all button ]
```

| Block | In-game text / control |
|-------|------------------------|
| about heading | About |
| descriptions | Raid-prep overview (rosters, history, lockouts, export); what Character cooldowns, Party roster, Raid roster, History, Export gear and CDs, and Export cooldowns do; slash commands |
| github heading | GitHub |
| short hint | “Select the URL, then press Ctrl+C to copy.” |
| input for repo URL | Single-line copy box with `https://github.com/sergimax/Raidwise-addon` |
| select all button | **Select all** — highlights the URL for Ctrl+C |

## Adding a view

1. Add a tab in `PAGES` in `ExporterWindow.lua`.
2. Paste a new `## Title` scheme here (same `[ block ]` style).
3. Implement the page and record sizes in `UI-Sizes.md`.
