# UI view schemes

ASCII layouts for each window and content page. Update this file when a view changes. Pixel sizes live in [`UI-Sizes.md`](UI-Sizes.md) and the `UI` table in `ExporterWindow.lua`.

## Shell

Details-style plain panels: left menu, content page, status bar under both.

```text
[ Menu 170 ] 2px [ Content 520 x 480 ]
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
[ Party ]
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

## Party

Current party roster (solo shows only you). Spec for party members is filled via inspect when they are nearby.

```text
[ short description ]                              [ Refresh ]
        8 px gap
[ Name | (class) | (spec) | GS | iLvl | Guild | Rank ]
[ Rhee |  SH   |  Enh   | 6158 | 264 | MyGuild | Member ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Current party or raid members. Refresh after gear or spec changes.” |
| Refresh | Re-reads GearScore, item levels, guild info; re-queues inspect for specs |
| Name | Class-colored character name |
| Class | Class icon (`CLASS_ICON_TCOORDS`); hover shows localized class name |
| Spec | Primary talent tree icon only; hover shows spec name (`-` until inspect completes for others) |
| GS | GearScore when the GearScore addon has scanned the player |
| iLvl | Average equipped item level (tooltip scan when item cache is cold) |
| Guild / Rank | From `GetGuildInfo` when available (`-` otherwise) |

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
| descriptions | What Export, Character cooldowns, Party, and Export cooldowns do; optional item names, GearScore, slash commands |
| github heading | GitHub |
| short hint | “Select the URL, then press Ctrl+C to copy.” |
| input for repo URL | Single-line copy box with `https://github.com/sergimax/Raidwise-addon` |
| select all button | **Select all** — highlights the URL for Ctrl+C |

## Adding a view

1. Add a tab in `PAGES` in `ExporterWindow.lua`.
2. Paste a new `## Title` scheme here (same `[ block ]` style).
3. Implement the page and record sizes in `UI-Sizes.md`.
