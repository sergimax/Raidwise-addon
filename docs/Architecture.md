# Raidwise architecture and task map

Lua 5.1 / WoW 3.3.5a (`Interface: 30300`). Shipped code lives in `Raidwise/` on the single `Raidwise` namespace. GearScore is optional. Rules: [AGENTS.md](../AGENTS.md). Checks: [tests/README.md](../tests/README.md).

Repository audit (2026-11-06): [findings and remediation plan](audits/Audit-2026-11-06.md), [verification and reproduction](audits/Audit-2026-11-06-Evidence.md). This is a dated assessment, not a replacement for the contracts below.

Guild roster, officer tools and balances: [guild module contract](raid/Guild-Management.md). The old [EPGP implementation plan](raid/EPGP-Plan.md) is historical.

## Find the owner first

Paths below are relative to `Raidwise/`. Search the entry point before reading its helpers or callers.

| Task | Owner files | Entry points / boundaries |
|---|---|---|
| Bootstrap, DB, slash, report transport | `Raidwise.lua` | Lifecycle, slash handlers, `SendReportChat` |
| Copyable troubleshooting reports | `Diagnostics.lua`, `../scripts/diagnose.cjs` | `/rw diagnose` runtime smoke checks; `npm run diagnose` offline suite and report file; see tests/README.md |
| Language | `Locale.lua` | `Addon:T`; search exact keys in both languages |
| Chat preparation and gear reports | `ChatReports.lua`, `GearCheckReports.lua` | `PrepareReportMessage`, `BuildGearCheckChatMessages` |
| Gear/bags/currency export, lockouts | `CharacterExport.lua`, `CharacterLockouts.lua` | `FormatEquippedGearExport`, `CollectCharacterCurrency`, `BuildCooldownTable` |
| Guild module | `../Raidwise_Guild/` | GuildManagement owns live roster, permission-aware note/rank operations and local journal; GuildRosterParser/Links and GuildEPGP resolve balances and guild-info base GP; PageGuild owns the single roster/journal view. See [guild management](raid/Guild-Management.md) |
| Inspect timing, identity, retries | `InspectCoordinator.lua`, `GearCheck.lua`, `PartyRoster.lua` | `StartInspectRequest`, `RetryInspectRequest`, `StartGearCheckUnitScan`, `CancelGearCheckScan` |
| Item links, sockets and gems | `GearCheckCollector.lua` | `CollectGearCheckObservation`; private `ParseItemLinkParts`, `NormalizeItem` |
| Report compatibility and completeness | `GearCheckReport.lua` | `NormalizeGearCheckReport`, `GetGearCheckScanState`; canonical nested fields win over legacy aliases |
| Findings, grades, explanations | `GearCheckRules.lua`, `GearCheckGrades.lua`, `GearCheckExplanations.lua` | `EvaluateGearCheck`, `AggregateGearCheckOverall`; internal `GearCheckPolicy` |
| Saved reports and dumps | `GearCheckSavedReports.lua`, `GearCheckDump.lua` | `SaveGearCheckReport`, `FormatGearCheckDump`; dump module owns asynchronous raid export jobs |
| Rosters and shared refresh | `PartyRoster.lua`, `RosterRefresh.lua` | `BuildRaidGroups`, `BuildRosterSnapshot`, `ScheduleRosterRefresh` |
| Roles, consumables, composition | `RaidRoles.lua`, `RaidComposition.lua` | `UnitConsumableStatus`, `AnalyzeRaidComposition` |
| Profile catalogs and identity support | `PlayerRecordSupport.lua`, `PlayerRecords.lua` | `GetProfileEventCatalog`, `UpsertPlayerRecordIdentity`, `FindPlayerRecordIdentities` |
| Profile persistence and screen API | `PlayerRecords.lua`, `PlayerRecordBridge.lua` | `CommitPlayerRecordDraft`, `InitializeHistoryStore`, `RestorePlayerRecordEntry` |
| Group encounter sessions and retention | `PlayerEncounters.lua` | `RecordCurrentGroupHistory`, `GetCharacterMeetingStats`, `PruneCharacterEncounters` |
| Database and recent-history lists | `PageHistory.lua`, `PlayerEncounters.lua` | `BuildHistoryRoster` |
| Linked player characters and deletion | `PlayerRecordLinks.lua`, `ProfileCharacters.lua` | `LinkPlayerCharacters`, `DeleteCharacterDatabaseRecords` |
| Retired profile exchange (not in TOC) | Sync/Karma modules | Historical owners and checks: [Synchronization.md](characters/Synchronization.md) |
| Unsaved profile edits | `ProfileEditor.lua` | `SaveProfileEditor`, `TickProfileEditor`, `CloseProfileEditor` |
| Profile window | `ProfileWindow.lua`, `ProfileEditor.lua`, `ProfileCharacters.lua` | `ShowRaidCharacterWindow`; character tasks and checks: [task map](characters/Reputation.md) |
| Rating display and unit tooltips | `RatingPresentation.lua`, `UnitTooltips.lua` | `FindOpinionCharacter`, `RefreshUnitOpinionTooltip` |
| Native friends, ignore, inbox and guild opinion marks | `ClassicOpinionMarkers.lua` | `InitializeClassicOpinionMarkers`, `RefreshClassicOpinionMarkers` |
| Theme / shared controls | `UITheme.lua`, `UIWidgets.lua`, `RosterWidgets.lua` | Stable theme tables; generic controls; roster/grade/rating controls |
| Raid and target gear views | `PageRaid.lua`, `PageGearCheckTarget.lua` | `RefreshRaidRosterView`, `RefreshGearCheckTargetView`, `ShowGearCheckReport` |
| Other pages | `PageCooldowns.lua`, `PageExport.lua`, `PageComposition.lua`, `PageHistory.lua` (History and Character database), `PageSettings.lua`, `PageInfo.lua` | `Addon.Pages.*` registrations |
| Shell and navigation | `ExporterWindow.lua`, `Minimap.lua` | `CreateMainFrame`, `SelectTab`, `RefreshLocalizedUI`; separate minimap entry point |

## Load order and contracts

[Raidwise.toc](../Raidwise/Raidwise.toc) is the authoritative executable load order. Read it when adding/moving modules; do not maintain a duplicate full list here.

- Bootstrap creates the namespace; later modules attach methods before normal event-driven use.
- After core DB/locale initialization, bootstrap loads `Raidwise_Guild` before constructing the shell. The guild addon depends on Raidwise, uses its widgets/locale/DB, registers one Guild page, and owns its roster/raid event listener. Its TOC is the authoritative guild module load order. The retired Raidwise_EPGP addon and guild-export commands are removed.
- `CharacterExport` provides `Addon.EscapeJsonString` before `CharacterLockouts`; both export formats share complete JSON string escaping (including U+0000–U+001F).
- Initialization checks the active profile core/bridge APIs before opening UI. Missing APIs report an incomplete installation; retired `RatingTagGroups` is not a startup requirement.
- `InspectCoordinator` precedes roster consumers and owns inspect API calls/events. Roster and gear retain their queues and result handling.
- Profile core/support, screen APIs, links and encounters precede presentation; ProfileEditor and ProfileCharacters precede ProfileWindow.
- `HistoryProfileForMember` belongs to support and explicitly calls the encounter projection. `PruneHistory` belongs to bridge and delegates to encounter retention. Later modules do not replace either method or capture its previous implementation.
- Legacy PlayerHistory, PlayerHistoryStore, CharacterLinks, ProfileDraft, CharacterProfile/ProfilePanels and Sync/Karma modules are not loaded; historical fixtures may load them explicitly in tests.
- `UITheme` precedes `UIWidgets`, then `RosterWidgets`, then views. Theme/color tables retain identity across theme changes.
- Gear catalogs and report compatibility helpers precede rules, grades, explanations and self-tests. Saved reports and collector precede `GearCheck`; reports and dumps follow it. Pages load before the shell.

### Gear flow

Use the [Gear Check task map](gear-check/Gear-Check-Progress.md) for inspect, collection, grades, saved reports, dumps and their tests.
Before changing formats or revisions read [compatibility and limits](gear-check/Gear-Check-Contract.md); for IDs/profiles/BiS inputs use [maintenance](gear-check/Gear-Check-Surface-From-BiS.md).
Real-client timing and inspect interference require the separate [verification protocol](gear-check/Gear-Check-Verification.md).

### Refresh and reputation flow

For profile reads/writes, identity lookup, journals and encounter projection, use the [character task map](characters/Reputation.md) to find the owner and behavior tests.
Storage constraints and maintenance are linked from that map.

Composition uses groups 1–5 from live collection or the shared snapshot, excluding reserve groups 6–8.
Its counts, providers and chat reports use that same subset.
Raid gear scanning also uses groups 1–5.
Roster grade summaries filter saved and manual results against current group membership.
Reserves retain manual Rescan and individual reports; shared snapshots remain complete.

`ScheduleRosterRefresh` merges same-frame requests. Each pass builds one snapshot shared by history and the visible raid/composition page. Hidden views are not redrawn; history still records. Snapshots are not cached across passes. Inspect queue advancement is immediate; consumable icons have their own targeted refresh path.

Pages register `Create`, `Refresh(page, entering)`, and `ApplyLocale(page)`. The shell dispatches these methods; page modules own control labels and entry-specific collection. `entering=true` requests the original tab-entry work (lockout requests, roster refresh or history recording); locale refresh omits it. Public refresh wrappers remain compatible. Profile extraction preserves anchors, dimensions and named-frame versions.

### SavedVariables and versions

Before changing character identity scope or saved reports, read the
[realm-scope decision](adr/0001-character-realm-scope.md) and
[storage constraints](characters/Character-System-Contract.md).

Copyable character/gear and cooldown JSON exports carry numeric `reportVersion: 1`.
Profile JSON exchange is disabled. Target Gear
Check text dumps and both synchronous/asynchronous raid dump headers carry
`reportVersion=1`, including raid exports with only failed/skipped scans.
Gear dumps also include the embedded report's `schemaVersion`.
These are format-specific revisions, independent of addon semver and the scan
data's existing `schemaVersion`. Older exports without `reportVersion` are legacy
unversioned formats. Diagnostics retain their existing `Raidwise diagnostics v2`
header. Chat summaries are human-readable messages, not versioned data exports.

`RaidwiseDB` is bound as `Addon.db`; `MrcExporterDB` is legacy migration input.

| Key | Owner / purpose |
|---|---|
| `characters` | `CharacterLockouts`: account-wide lockouts/currency |
| `playerRecords` | Versioned identities, shared profiles/notes, changes, groups, personal encounters/counters; core/support, bridge, links and encounter modules |
| `history`, `reputation` | Retired roots, not active storage or aliases; legacy profile data is not imported |
| `gearCheckSaved` | `GearCheckSavedReports`: snapshots and retention (~14 days) |
| `tooltip` | `RatingPresentation` / Settings: rating tooltip visibility |
| `locale`, `theme`, `startupTab`, `reportChannel`, `reportForm` | Preferences consumed by locale, theme, shell and reporting |
| `guild` | Raidwise_Guild: shared retention limit (100–10000, default 1000), realm/guild archives with local roll EP threshold (4000), last complete snapshot and guild-info text, journal and previous server event window. Old `guildManagement`/`epgp` roots are not migrated or read. |

Character tasks and checks: [task map](characters/Reputation.md).
Addon semver, rule/catalog revisions, and layout versions serve different purposes.
Geometry rules live in `AGENTS.md`; current layouts and dimensions live in
[UI-Views.md](ui/UI-Views.md) and [UI-Sizes.md](ui/UI-Sizes.md).

## Runtime package and deferred UI extraction

The release workflow uses `scripts/package-addon.mts`: TOC + its Lua entries +
tracked media from HEAD. Retired Lua stays in the repository for historical tests
but is excluded from the installable ZIP. XML includes are not currently used;
the packager rejects them until recursive dependency handling is implemented.

Audit D08 remains deliberate follow-up debt, not a file-length target. When raid
export behavior changes, extract the `PageRaid` export state/actions together
(`UpdateRaidExportView`, `ShowRaidExportText`, `ExitRaidExportView`,
`RunGearCheckRaidExport`) while preserving dump-job ownership in `GearCheckDump`.
When target saved-report behavior changes, extract its list/selection/save/delete
controller from `PageGearCheckTarget` while preserving persistence ownership in
`GearCheckSavedReports`. Keep control creation and geometry in each page; verify
cancel/restart, selection and navigation before changing those boundaries. Queue 6
does not alter these features or layout versions, so no mechanical split is made.

## Focused searches

Start with named files from the task table, or `Raidwise/` and `tests/`. Examples from the repository root (PowerShell-compatible):

```powershell
rg -n 'StartGearCheckUnitScan|TryCollectPending' Raidwise/GearCheck.lua
rg -n -C 6 'gemFieldsComplete' Raidwise/GearCheckCollector.lua
rg -n 'SETTINGS_CHANGELOG' Raidwise/Locale.lua Raidwise/PageSettings.lua
rg -n '^function Addon:|^local function' Raidwise/ProfileWindow.lua
git diff --stat
git diff -- Raidwise/GearCheck.lua tests/scan.test.mts
```

Include these paths deliberately when relevant; no global search exclusion hides them:

| Path | Use |
|---|---|
| `Raidwise/GearCheckBis.lua` | Generated IDs: use `scripts/generate-gear-check-bis.js`, which reads sibling web-app presets or `RAIDWISE_BIS_PRESETS`. |
| `Raidwise/GearCheckCatalog.lua`, `GearCheckSets.lua`, `GearCheckTrinkets.lua`, `GearCheckProfiles.lua` | Runtime reference/rule data. Search the ID/spec; these are not all generated. |
| `tools/` | Catalog research scripts, scrape output and seeds; not shipped. |
| `gear-check-debug/`, `screenshots/` | Debug visualizations and UI references. |
| `____GEAR_REPORTS_TO_CHECK/`, `____EXAMPLES/` | Ignored local reports/examples; use explicit paths and `rg --no-ignore` when investigating them. |
| `node_modules/`, `package-lock.json` | Dependency/runtime investigations only. |
| `types/` | Export/report contracts; review when changing data shapes. |

Keep this map current when ownership changes. Put detailed behavior in its domain document rather than duplicating specifications here.
