[English](README.md) | [Русский](README.ru.md)

# Raidwise

Raid-prep addon for **Wrath of the Lich King 3.3.5a** (`Interface: 30300`): party and raid rosters, raid composition checklist, player ratings, meeting history, account-wide lockouts, and character JSON export.

![](https://img.shields.io/badge/current_version-1.8.0-purple)
![](https://img.shields.io/badge/last_updated-2026--08--20-blue)


## Install

1. Copy the `Raidwise` folder into your client’s AddOns directory:

   ```text
   <WoW>/Interface/AddOns/Raidwise/
   ```

2. Restart the client (or `/reload`).
3. Enable **Raidwise** on the character select AddOns screen if needed.
4. If you previously used **mrc-exporter**, remove that folder from AddOns so only Raidwise loads.


## Usage

In-game slash commands:

| Command | Description |
|---------|-------------|
| `/raidwise` or `/rw` (also `/rw help`) | Show help |
| `/raidwise version` | Show addon version |
| `/raidwise status` | Show load status |
| `/raidwise show` | Open the main window |
| `/raidwise hide` | Close the main window |

Plain panels, a **left menu**, and a content page.
The status bar shows the addon name and version.
Esc or the title **X** closes the window.

**Character cooldowns** tab:

- Table of raid and dungeon lockouts for every character saved on this account
- First column is the instance name and type (10 / 10 Heroic / 25 / 25 Heroic, plus older 20 and 40)
- Other columns are characters (class-colored name, spec icon, and last check time); log in on each alt to record them
- Saved cells show time remaining until reset

**Export gear and CDs** tab:

- Short description, then **Include item names**
- **Export character data** fills the JSON box (name, class, spec, gearScore, gear, bags, lockouts)
- **Select all** highlights the JSON for Ctrl+C
- `gearScore` comes from the **GearScore** addon when it is installed (optional dependency)

**Party roster** tab:

- Table of the current 5-player party (you alone when not grouped)
- Line above the table: average item level and average GearScore
- Columns: name, class icon, spec icon, raid-buff icons, GearScore, average item level, personal opinion, tags, guild with rank
- **Refresh** re-scans GearScore and re-inspects nearby members for spec updates

**Raid roster** tab:

- Two blocks: raid groups **1–5**, then **6–8**
- Line above the cells: overall average GearScore; second line is per-role count and average GS (`Tanks: 2 (6200 gs)`)
- Each group is a column of five player cards: class + name, role + spec + GS/iLvl, raid-buff icons, personal opinion, and tags
- Role icon matches RaidBuffStatus (tank / healer / melee / ranged)
- Buff icons are spec- and race-specific raid utilities (hover for the name)
- Click a filled card to open **Character profile** (`{name} - Character profile`)
- **Refresh** re-scans GearScore and re-inspects nearby members for spec icons

**Raid composition** tab:

- Checklist of the current party or raid (solo uses only you)
- Sections: roles, buffs, external buffs, damage reduction, debuffs, mana regeneration, health regeneration
- Gold rows are already covered; dim rows are missing. Hover for who in the group has it and which class/spec can bring it
- **Refresh** re-reads the group (same inspect path as Raid roster)
- Full tracking list: [`docs/Raid-Composition.md`](docs/Raid-Composition.md)

**History** tab:

- Table of players you have been in a party or raid with (saved in `RaidwiseDB.history`, survives logout)
- Columns: name, class icon, spec icon, personal opinion, tags, GearScore, iLvl, where you met, when, guild
- Click a row to open **Character profile** (includes GUID, meeting zone, time, and realm)
- **Refresh** records the current group again and redraws the list

**Player rating** in Character profile:

- Tabs: **History**, **Edit note**, **Edit memo**
- On **Edit note**, set **Positive** / **Neutral** / **Negative** and personal tags (up to 3 per category); **Update** saves the draft
- On **Edit memo**, write a free-form note with **Save** / **Reset**
- Party, Raid, and History show your saved opinion and tag summary; click a row or card to open the profile
- **Community note** is currently a mock preview for a future addon exchange / web app feature

**Settings** tab:

- Interface language: **English** or **Русский**
- The choice is saved on this account (`RaidwiseDB.locale`); a Russian client defaults to Russian

**Info** tab:

- What the addon does (rosters, composition, history, lockouts, export) and which slash commands exist
- Repository URL in a copy box with **Select all** (Ctrl+C)

View layouts: [`docs/UI-Views.md`](docs/UI-Views.md). Pixel sizes: [`docs/UI-Sizes.md`](docs/UI-Sizes.md). Composition tracking: [`docs/Raid-Composition.md`](docs/Raid-Composition.md).

Consumers can type the export JSON with `types/CharacterExport.ts` and `types/CooldownsExport.ts`.

## Screenshots:
Main addon view (`/raidwise show`):

![Main addon view](./screenshots/main-view.png)

In-chat menu (`/raidwise help`):

![In-chat menu](./screenshots/in-chat-menu.png)

# Development

## Layout

```text
Raidwise/
  Raidwise.toc        # addon metadata (Interface 30300)
  Raidwise.lua        # entry point, events, slash commands
  Locale.lua          # English / Russian UI strings and language switch
  CharacterExport.lua # character JSON export (gear, bags, lockouts)
  CharacterLockouts.lua # account-wide lockout snapshots for the cooldowns table
  PartyRoster.lua     # party / raid member stats for roster views
  RaidRoles.lua       # raid role and spec/race buff lookups
  RaidComposition.lua # party/raid buff, debuff, and utility coverage
  PlayerHistory.lua   # saved party/raid encounter list + personal ratings
  UIWidgets.lua       # shared panels, buttons, icons, layout version badges
  CharacterProfile.lua # Character profile window (opinion, tags, notes, history)
  PageCooldowns.lua   # Character cooldowns tab
  PageExport.lua      # Export gear and CDs tab
  PageParty.lua       # Party roster tab
  PageRaid.lua        # Raid roster tab
  PageComposition.lua # Raid composition tab
  PageHistory.lua     # History tab
  PageSettings.lua    # Settings tab
  PageInfo.lua        # Info tab
  ExporterWindow.lua  # main window shell (menu, title, status, tab wiring)
docs/
  Architecture.md     # TOC order, layers, SavedVariables, refresh API
  UI-Views.md         # ASCII layouts for each view + layout version table
  UI-Sizes.md         # window / control pixel sizes
  Raid-Composition.md # classes/specs tracked by the Raid composition tab
types/
  CharacterExport.ts  # TypeScript types for the character export JSON
  CooldownsExport.ts  # TypeScript types for the account cooldown export JSON
```

## Notes

- Target build: **3.3.5a** (private-server style clients use `## Interface: 30300`).
- Saved variables are stored in `RaidwiseDB` (`WTF/Account/.../SavedVariables/`). Settings from the old `MrcExporterDB` are migrated on first load. Per-character lockouts for the cooldowns table live in `RaidwiseDB.characters`. Party and raid encounters live in `RaidwiseDB.history` (keyed by GUID), including personal ratings (`.rating.personal`), notes (`.notes`), and change log (`.changes`). Interface language is `RaidwiseDB.locale` (`enUS` or `ruRU`).
- `## X-LastUpdated` in the `.toc` is set manually; keep the README badge in sync.
- Optional dependency: **GearScore** (`## OptionalDeps`) for the `gearScore` export field.
