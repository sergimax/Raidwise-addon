[English](README.md) | [Русский](README.ru.md)

# Raidwise

Raid-prep addon for **Wrath of the Lich King 3.3.5a** (`Interface: 30300`): party and raid rosters, raid composition checklist, player ratings, meeting history, account-wide lockouts, and character JSON export.

![](https://img.shields.io/badge/current_version-1.26.0-purple)
![](https://img.shields.io/badge/last_updated-2026--09--22-blue)


## Install

1. Copy the `Raidwise` folder into your client’s AddOns directory:

   ```text
   <WoW>/Interface/AddOns/Raidwise/
   ```

2. Fully restart the client after installing new files or an updated TOC. Use `/reload` for edits to already loaded files.
3. Enable **Raidwise** on the character select AddOns screen if needed.
4. If you previously used **mrc-exporter**, remove that folder from AddOns so only Raidwise loads.


## Usage

In-game slash commands:

| Command | Description |
|---------|-------------|
| `/raidwise` or `/rw` | Open the main window |
| `/raidwise close` or `/rw close` | Close the main window |
| `/raidwise gearcheck` or `/rw gearcheck` | Open Gear check (target) and scan |
| `/rw gearcheck summary` (also `items`, `enchants`, `gems`, `ok`) | Print that report to the report chat channel (scans first if needed) |
| `/rw gearcheck raid dump` | Open Raid roster and show the last raid gear-check dump for copy |
| `/rw gearcheck test` | Offline rules self-test |
| `/rw diagnose`, `/raidwise diagnose`, or `/raidwisediag` | Test window opening and gear rules; show a copyable diagnostic report |

Run diagnostics immediately after `/reload`, outside combat, to test fresh window construction. Copy the report with Ctrl+A / Ctrl+C. After installing new Lua files, restart the client with the entire updated `Raidwise` folder. For CLI checks, `npm run diagnose` writes `diagnostics/latest.txt`; see [tests/README.md](tests/README.md).

Plain panels, a **left menu** grouped as Personal / Raiding / Other, and a content page.
The menu title bar shows **Raidwise** and the addon version.
Esc or the title **X** closes the window.

The draggable minimap button opens **Raid roster** on left-click and **Character cooldowns** on right-click. Hover for raid readiness, consumables, and account-wide character lockouts.

**Character cooldowns** tab:

- Table of raid and dungeon lockouts for every character saved on this account
- First column is the instance name and kind (`(Raid)` / `(Dungeon)`); size and mode live in character cells
- Other columns are characters (class-colored name, spec icon, and last check time); log in on each alt to record them
- **Remove** on non-current character columns drops that alt from the table (login again restores it)
- Saved cells show size/mode tags (`10`, `10h`, `25`, `25h`; heroic in red); hover for time until reset
- **Currency** row at the bottom: labels with account totals in the first column; each character column shows icon + quantity for gold, emblems, honor/arena, and other tokens (from the in-game Currency tab)

**Export gear and CDs** tab:

- Short description, then **Include item names**
- **Export character data** fills the JSON box (name, class, spec, gearScore, gear, bags, lockouts)
- **Select all** highlights the JSON for Ctrl+C
- `gearScore` comes from the **GearScore** addon when it is installed (optional dependency)

**Raid roster** tab:

- Two blocks: raid groups **1–5**, then **6–8**; when not in a raid, your party fills group 1
- Lines above the grid: compact header (S·A·B·C·D chips, GS and role counts, flask/food/gems/armor/weapons/enchants with report icons, Scan/Export/Refresh/Back icons); then scan status and progress
- Each player card: class + name, flask/food status icons, role + spec + GS/iLvl, compact `P:`/`K:` ratings, separate gem/armor/weapon/enchant grades, **Gear** / **Rescan**, and sword/gem report icons
- Sword/gem icons post that player's gear/weapon or gem/enchant findings to the configured report channel, always in short form (`CODE - slot,slot; CODE - slot`); hover previews the message
- A successful full scan shows its completion date and time with the success message; individual rescans do not change that timestamp
- Hover a card for opinion, tags, Karma data, **guild (rank)**, raid buffs, and gear-check details
- **Scan** / **Export all** for raid-wide gear check; **Export all** opens copy text; **Back to roster** closes it; click the dump + Ctrl+C to copy
- **Refresh** re-scans GearScore and re-inspects nearby members for spec icons
- Card click opens **Character profile**

**Raid composition** tab:

- Checklist of the current party or raid (solo uses only you)
- Detected specialization icons and counts appear beneath each class; hover lists the players
- Top band: **Roles** and all 10 **Classes** with counts; then sections: Aggro, buffs, external buffs, damage reduction, debuffs, mana regeneration, health regeneration
- Gold rows are covered; dim rows are missing. Section titles show present/total (red when nothing in the section is present)
- Hover a row for who has it and which class/spec brings which spell; **Shift-click** posts that effect to the report chat channel (header)
- **Report missing** posts absent classes to the report chat channel (header); **Refresh** re-reads the group (same inspect path as Raid roster)
- Full tracking list: [`docs/Raid-Composition.md`](docs/Raid-Composition.md)
- Reports preview their output; effect reports include clickable spell links and fit one 255-byte chat message.

**Gear check (target)** tab:

- **Scan** evaluates target or self (Overall S / A / B / C / D, class/spec icons, GS/iLvl, findings by filter: All / Items / Enchants / Gems / B)
- Spec ranks: **preferred** / **acceptable** / **unwanted** / **forbidden** (map to A / B / C / D). **S** = equipped item ID is on published BiS lists for that spec (not a unique pick)
- **Report …** buttons and `/rw gearcheck summary|items|enchants|gems|ok` print to the **report chat channel** (header; default Auto = raid/party)
- Report buttons show icons and previews; summaries list all grade counts, and gem reports group warnings by theme without gem IDs.
- **Show as a text** toggles the raw dump; **Save report** keeps a snapshot (~14 days)
- **Character profile** opens the scanned player's profile; target scans also record that player in History
- Surface-level disclaimer; rules and known false positives: [`docs/Gear-Check-Progress.md`](docs/Gear-Check-Progress.md)
- `/rw gearcheck` opens this tab and scans; `/rw gearcheck test` runs the offline self-test

**History** tab:

- Recent party, raid and target-scan encounters, filterable by name, class and guild; unused encounter-only records expire after 14 days.
- Meeting location appears in the row tooltip.
- Click a row to open **Character profile** (includes GUID, meeting zone, time, and realm)
- **Refresh** records the current group again and redraws the list

**Character database** keeps manually edited and imported cards, with source icons and filters for name, class, guild, personal opinion and record source. Add a character by name without scanning them. Delete one row or clear the database with confirmation. Saved cards survive encounter cleanup; see [Reputation.md](docs/Reputation.md).

**Synchronization** supports explicit Player-to-Player and Player-to-External exchange:

- Search by character name in the Sync view, then share one character or the full saved database to a target, guild, or raid.
- Use **Share** from an open Character profile, or the database share action, to open the same recipient menu.
- Export selected data or the database as copyable JSON. Paste JSON from a player or web app, review the short list of incoming changes, then **Apply** or **Cancel**.
- Incoming requests require consent and can be declined, ignored by character name across realms, or disabled. The ignored-character list is searchable, paginated, and supports **Unignore**.
- Sync JSON carries `reportVersion: 1`; private memos remain local and are never included in exchange data.

Native friends, ignore and inbox rows show opinion marks. Both guild roster modes also show light green/gray/red backgrounds, including with ElvUI. Chat markers use green/white/red; negative message bodies remain red. `/rw diagnose` reports missing marker code and guild matching status.

**Player rating** in Character profile:

- Tabs: **History**, **Edit note**, **Facts**, **Events**, **Memo**, **Characters** — **History** opens by default
- **Characters** links one player's characters, with one local Main and multiple Alts. Opinion is shared across linked characters; tags, facts, events and notes remain separate. Link/unlink and Main changes appear in History, and tooltips list linked characters. Main is a local preference excluded from shareable membership data; player-to-player exchange is not implemented yet. See [Reputation.md](docs/Reputation.md).
- On **Edit note**, set **Positive** / **Neutral** / **Negative** and personal tags (up to 3 per category); **Save and Update** commits opinion, tags, facts, and events
- On **Facts**, set role / identity facts (up to 4)
- Profile **History** shows **Met**, **Was in the same party**, and a changelog with icons
- On **Events**, pick a type by category (**Attendance**, **Loot**, **Help**, **Behavior** — each with an icon) and **Add event** / **Remove** (draft until **Save and Update**; context captured when adding). Joining a party or raid also logs **In the same party** when the meet count goes up (first meet, or ≥30 minutes since last seen)
- On **Memo**, write a private free-form note with **Save** / **Reset** (not shared, not logged in History)
- Raid and History show your saved opinion and tag summary; click a row or card to open the profile
- Negative personal opinions make the chat message text and `<Rw>` marker red; item and achievement links keep their original colors. Positive/neutral markers retain white brackets with mint/lavender text and normal channel-colored messages.
- **Karma** is currently a mock preview for future addon exchange / web app data

Report controls in the shared header:

- **Report chat channel**: where Raid roster, Composition, and Gear check reports are posted (`RaidwiseDB.reportChannel`; default Auto = raid in a raid, party in a party)
- **Gear check report form**: Short (default, fewer chat lines) or Full detailed wording (`RaidwiseDB.reportForm`)
- Channel radios appear only on Raid roster, Raid composition, and Gear check (target); Short / Full appears only on Gear check (target). Channel labels use chat colors.

**Settings** tab:

- Copyable repository changelog link with **Select all**

- Interface language: **English** or **Русский**
- The choice is saved on this account (`RaidwiseDB.locale`); a Russian client defaults to Russian
- **Theme** category: switch between light and dark; saved per account in `RaidwiseDB.theme`
- **Startup page**: which left-menu tab opens on `/raidwise` (`RaidwiseDB.startupTab`; default Character cooldowns; **Info** cannot be selected)
- Unit tooltip toggles: hide personal opinion / personal tags / Karma / Karma tags (`RaidwiseDB.tooltip`)
- Preview of compact (live) and stacked tooltip layouts

The minimap button position is saved in `RaidwiseDB.minimapAngle`.

**Info** tab:

- About overview (one sentence per line, with lists) plus per-menu feature sections (same icons as the left menu, each with that view’s layout `vN`)
- Repository URL in a copy box with **Select all** (Ctrl+C)

View layouts: [`docs/UI-Views.md`](docs/UI-Views.md). Pixel sizes: [`docs/UI-Sizes.md`](docs/UI-Sizes.md). Reputation model: [`docs/Reputation.md`](docs/Reputation.md). Composition tracking: [`docs/Raid-Composition.md`](docs/Raid-Composition.md).

Consumers can type the Export-tab JSON with `types/CharacterExport.ts`. `types/CooldownsExport.ts` describes the account-wide cooldown JSON shape (from `FormatCooldownsExport`; not wired to a UI button yet). `types/GearCheck.ts` describes the Gear Check normalized report (`schemaVersion` 3).

## Screenshots

Main addon view (`/raidwise`):

![Main addon view](./screenshots/main-view.png)

# Development

## Layout

```text
Raidwise/
  Raidwise.toc        # addon metadata (Interface 30300)
  Raidwise.lua        # entry point, events, slash commands
  Locale.lua          # English / Russian UI strings and language switch
  ChatReports.lua     # shared final chat message preparation
  CharacterExport.lua # character JSON export (gear, bags, lockouts)
  CharacterLockouts.lua # account-wide lockout snapshots for the cooldowns table
  InspectCoordinator.lua # shared inspect ownership, identity, and deadlines
  PartyRoster.lua     # party / raid member stats for roster views
  RosterRefresh.lua   # coalesced refreshes and shared per-pass roster snapshots
  RaidRoles.lua       # raid role and spec/race buff lookups
  RaidComposition.lua # party/raid buff, debuff, and utility coverage
  PlayerHistory.lua   # rating catalogs, normalization, and access
  PlayerHistoryStore.lua # history persistence and legacy migration
  RatingPresentation.lua # rating labels, tooltips, and chat marks
  ProfileDraft.lua    # plain profile draft editing model
  ProfilePanels.lua  # profile tab builders and history rendering
  CharacterLinks.lua # linked membership and local Main preferences
  ProfileCharacters.lua # profile Characters tab
  Diagnostics.lua    # runtime checks and independent copy window
  Minimap.lua         # draggable launcher and raid/lockout summary tooltip
  UnitTooltips.lua    # personal/community lines on player unit tooltips
  ClassicOpinionMarkers.lua # native social, inbox and guild opinion marks
  UITheme.lua         # theme palettes and bound colors/text
  UIWidgets.lua       # shared panels, buttons, icons, layout version badges
  RosterWidgets.lua   # roster, rating, and gear presentation helpers
  CharacterProfile.lua # Character profile window (opinion, tags, notes, history)
  SyncData.lua         # versioned profile export/import and review staging
  SyncTransport.lua    # addon sync offers, consent, ignore list, and routing
  GearCheckCatalog.lua # enchant / gem seed catalogs
  GearCheckSets.lua   # T9/T10 set-piece ids (informational)
  GearCheckTrinkets.lua # preferred/allowed trinket pools by role
  GearCheckProfiles.lua # class + 30-spec Gear Check profiles
  GearCheckBis.lua    # generated spec BiS item-ID sets (S grade)
  GearCheckRules.lua  # findings, meta activation, and rule revision
  GearCheckReport.lua # report compatibility and scan completeness
  GearCheckGrades.lua # slot, category, and overall grades
  GearCheckExplanations.lua # category tooltips and grade explanations
  GearCheckSelfTest.lua # offline and in-game rule fixtures
  GearCheckCollector.lua # item/gem reads and normalized snapshots
  GearCheckSavedReports.lua # manual save / load / prune (~14 days)
  GearCheck.lua       # scan orchestration and last-report state
  GearCheckReports.lua # gear report formatting and final messages
  GearCheckDump.lua    # text dumps and asynchronous raid export jobs
  PageCooldowns.lua   # Character cooldowns tab
  PageExport.lua      # Export gear and CDs tab
  PageRaid.lua        # Raid roster tab
  PageComposition.lua # Raid composition tab
  PageGearCheckTarget.lua # Gear check (target) tab
  PageHistory.lua     # History and Character database tabs
  PageSync.lua        # Synchronization tab
  PageSettings.lua    # Settings tab
  PageInfo.lua        # Info tab
  ExporterWindow.lua  # main window shell (menu, title, status, tab wiring)
scripts/
  generate-gear-check-bis.js # union web-app BiS preset IDs → GearCheckBis.lua
docs/
  Architecture.md     # TOC order, layers, SavedVariables, refresh API
  UI-Views.md         # ASCII layouts for each view + layout version table
  UI-Sizes.md         # window / control pixel sizes
  Gear-Check-Progress.md # Gear Check phase board (planned / done / test steps)
  Reputation.md       # personal rating / events / memo model
  Raid-Composition.md # classes/specs tracked by the Raid composition tab
types/
  CharacterExport.ts  # TypeScript types for the Export tab JSON
  CooldownsExport.ts  # TypeScript types for account-wide cooldown JSON shape
  GearCheck.ts        # TypeScript types for Gear Check report + findings
```

## Notes

- Linked membership lives in `RaidwiseDB.characterGroups`; local Main preferences live separately in `RaidwiseDB.localCharacterMains`. Existing Main selections migrate automatically. Public membership projection `GetSharedCharacterLinks` is documented in [Reputation.md](docs/Reputation.md).
- Incomplete/unavailable scans remain visibly marked and do not count as ready in raid/minimap summaries; unconfirmed empty sockets require another inspect response before being reported as missing gems.

Offline development checks use TypeScript, Node.js 24, and a Lua 5.1 WebAssembly
runtime: `npm ci --ignore-scripts`, then `npm run check`. See
[tests/README.md](tests/README.md) for test organization, watch mode, and manual CI.

- Target build: **3.3.5a** (private-server style clients use `## Interface: 30300`).
- Saved variables are stored in `RaidwiseDB` (`WTF/Account/.../SavedVariables/`). Settings from the old `MrcExporterDB` are migrated on first load. Per-character lockouts and currency snapshots for the cooldowns table live in `RaidwiseDB.characters` (`.lockouts`, `.currency`). Party and raid encounters live in `RaidwiseDB.history` (keyed by GUID), including personal ratings (`.rating.personal` with opinion/tags/facts), events (`.events`), notes (`.notes`), change log (`.changes`), and party/raid meet count (`.meetCount`). Interface language is `RaidwiseDB.locale` (`enUS` or `ruRU`). Startup left-menu page is `RaidwiseDB.startupTab`. Unit tooltip visibility flags live in `RaidwiseDB.tooltip`.
- `## X-LastUpdated` in the `.toc` is set manually; keep the README badge in sync.
- Character, cooldown, Gear Check, and Sync JSON/text exports include a format version. Sync imports reject unknown `reportVersion` values; private profile memos are never exported.
- Optional dependency: **GearScore** (`## OptionalDeps`) for the `gearScore` export field.
- Regenerating S-grade BiS IDs: `node scripts/generate-gear-check-bis.js` (reads sibling `Raidwise` web-app presets; see `docs/Gear-Check-Surface-From-BiS.md`).
