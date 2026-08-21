# Raidwise architecture

Lua 5.1 / Interface **30300** (Wrath 3.3.5a). One global namespace (`Raidwise`); no Ace or embedded libs. Soft dependency: GearScore (`GearScore_GetScore` / `GS_Data`).

## TOC load order

From [`Raidwise/Raidwise.toc`](../Raidwise/Raidwise.toc):

```text
Raidwise.lua          bootstrap, DB, events, slash
Locale.lua            enUS / ruRU + Addon:T
CharacterExport.lua   gear / bags / lockout collectors + JSON export
CharacterLockouts.lua account-wide lockout SV + cooldown table model
PartyRoster.lua       party/raid snapshots, inspect queue, GS/iLvl
RaidRoles.lua         role classification, raid buff icons, role GS averages
RaidComposition.lua   composition effect catalog + AnalyzeRaidComposition
PlayerHistory.lua     history store + personal rating domain API
UIWidgets.lua         shared UI helpers (panels, buttons, icons, layout badge)
CharacterProfile.lua  character profile popup
PageCooldowns.lua     … PageInfo.lua   content pages (Addon.Pages.*)
ExporterWindow.lua    main shell (menu, title, status, tab wiring)
```

Order is the dependency graph: bootstrap → locale → domain → shared widgets → profile → pages → shell.

## Layers

| Layer | Files | Role |
|-------|-------|------|
| Bootstrap | `Raidwise.lua` | `Addon.db`, lifecycle, slash `/raidwise` / `/rw` (open), `close` (hide) |
| i18n | `Locale.lua` | Strings; `SetLocale` → `RefreshLocalizedUI` |
| Domain | Export, Lockouts, PartyRoster, RaidRoles, Composition, History | Data and analysis; no frame creation |
| Shared UI | `UIWidgets.lua` | Plain panels, buttons, icons, drag, copy box, layout version label |
| UI | Profile + pages + shell | Frames, refresh, localization refresh |

## SavedVariables

TOC: `RaidwiseDB`, `MrcExporterDB` (legacy migrate-only).

| Key | Owner | Purpose |
|-----|-------|---------|
| `enabled` | `Raidwise.lua` | Addon on/off (status) |
| `includeGearNames` | Export page / `CharacterExport` | JSON export option |
| `locale` | `Locale.lua` | `enUS` / `ruRU` |
| `characters` | `CharacterLockouts.lua` | Per-character lockout columns |
| `history` | `PlayerHistory.lua` | GUID-keyed meetings, opinion/tags/facts, events, notes |

Bound as `Addon.db` after `EnsureDB`.

History personal reputation shape (see [Reputation.md](Reputation.md)):

- `history[guid].rating.personal` — `opinion`, `tags`, `facts`, `createdAt`, `updatedAt`, `creatorId`
- `history[guid].events[]` — typed occurrences with `eventAt` + context
- `history[guid].notes` — private memo (never shared)
- `history[guid].changes[]` — local change log (`opinion`, `tags`, `facts`, `event_add`, `event_remove`)
- `history[guid].meetCount` — party/raid encounters with this character (first meet = 1; +1 after ≥30 min since `lastSeenAt`)

## Two version concepts

| Kind | Where | Shown | Purpose |
|------|-------|-------|---------|
| **Addon semver** | `Addon.version` + TOC `## Version` | Status bar (`v1.7.0`) | Release / changelog |
| **Layout version** | `*_LAYOUT_VERSION` per view | Shell title bar next to page name (`vN`); profile title bar; shell constant is rebuild-only | Force UI rebuild when structure changes |

Bump layout versions when sizes, named frames, or control layout change. Do **not** bump for pure locale string edits. Keep docs in sync (`UI-Views.md`, `UI-Sizes.md`).

## Public UI refresh API

Optional duck-typed methods on `Raidwise` (callers check `if self.Foo then`):

| Method | Defined in | Used by |
|--------|------------|---------|
| `CreateMainFrame` / `ShowMainFrame` / `HideMainFrame` | Shell | Bootstrap, slash |
| `RefreshLocalizedUI` | Shell | `SetLocale` |
| `RefreshCooldownTable` | Cooldowns page | Lockout events |
| `FlushExportToWindow` | Export page | Lockout export path |
| `RefreshPartyView` | Party page | Roster, profile, guild |
| `RefreshRaidRosterView` | Raid page | Roster, guild |
| `RefreshCompositionView` | Composition page | Roster, guild |
| `RefreshHistoryView` | History page | History record, profile |
| `ShowRaidCharacterWindow` | Profile | Party / raid / history clicks |
| `RefreshPartyData` | `PartyRoster.lua` | Fan-out refresh (below) |

## Refresh fan-out

`Addon:RefreshPartyData(refreshGearScore)` (PartyRoster):

1. Rebuilds party/raid roster data (and inspect queue as needed).
2. Calls `RefreshPartyView`, `RefreshRaidRosterView`, and `RefreshCompositionView` when those methods exist.

Group roster events (`PARTY_MEMBERS_CHANGED` / `RAID_ROSTER_UPDATE`) call `RefreshPartyData` when the main window is open on party/raid/composition; otherwise they only record history.

Profile save/close refreshes the visible party, raid, or history tab.

## Known limitations

- Domain → UI coupling is intentional but soft (optional method checks). Prefer keeping refresh orchestration on the shell/pages, not deeper into collectors.
- Named frames use versioned suffixes (`…V` .. layout version) so layout rebuilds do not collide with stale global frames.
