# Raidwise architecture and task map

Lua 5.1 / WoW 3.3.5a (`Interface: 30300`). Shipped code lives in `Raidwise/` on the single `Raidwise` namespace. GearScore is optional. Rules: [AGENTS.md](../AGENTS.md). Checks: [tests/README.md](../tests/README.md).

## Find the owner first

Paths below are relative to `Raidwise/`. Search the entry point before reading its helpers or callers.

| Task | Owner files | Entry points / boundaries |
|---|---|---|
| Bootstrap, DB, slash, report transport | `Raidwise.lua` | Lifecycle, slash handlers, `SendReportChat` |
| Copyable troubleshooting reports | `Diagnostics.lua`, `../scripts/diagnose.cjs` | `/rw diagnose` runtime smoke checks; `npm run diagnose` offline suite and report file; see tests/README.md |
| Language | `Locale.lua` | `Addon:T`; search exact keys in both languages |
| Chat preparation and gear reports | `ChatReports.lua`, `GearCheckReports.lua` | `PrepareReportMessage`, `BuildGearCheckChatMessages` |
| Gear/bags/currency export, lockouts | `CharacterExport.lua`, `CharacterLockouts.lua` | `FormatEquippedGearExport`, `CollectCharacterCurrency`, `BuildCooldownTable` |
| Inspect timing, identity, retries | `InspectCoordinator.lua`, `GearCheck.lua`, `PartyRoster.lua` | `StartInspectRequest`, `RetryInspectRequest`, `StartGearCheckUnitScan`, `CancelGearCheckScan` |
| Item links, sockets and gems | `GearCheckCollector.lua` | `CollectGearCheckObservation`; private `ParseItemLinkParts`, `NormalizeItem` |
| Report compatibility and completeness | `GearCheckReport.lua` | `NormalizeGearCheckReport`, `GetGearCheckScanState`; canonical nested fields win over legacy aliases |
| Findings, grades, explanations | `GearCheckRules.lua`, `GearCheckGrades.lua`, `GearCheckExplanations.lua` | `EvaluateGearCheck`, `AggregateGearCheckOverall`; internal `GearCheckPolicy` |
| Saved reports and dumps | `GearCheckSavedReports.lua`, `GearCheckDump.lua` | `SaveGearCheckReport`, `FormatGearCheckDump`; dump module owns asynchronous raid export jobs |
| Rosters and shared refresh | `PartyRoster.lua`, `RosterRefresh.lua` | `BuildRaidGroups`, `BuildRosterSnapshot`, `ScheduleRosterRefresh` |
| Roles, consumables, composition | `RaidRoles.lua`, `RaidComposition.lua` | `UnitConsumableStatus`, `AnalyzeRaidComposition` |
| Profile catalogs and identity support | `PlayerRecordSupport.lua`, `PlayerRecords.lua` | Three opinions, four facts, 22 event types; context capture, self-rating checks and identity presentation |
| Profile persistence and screen API | `PlayerRecords.lua`, `PlayerRecordBridge.lua` | `InitializeHistoryStore` activates `playerRecords` once without migrating old reviews; core drafts and screen-facing reads/writes |
| Group encounter sessions and retention | `PlayerEncounters.lua` | `RecordCurrentGroupHistory`, `GetCharacterEncounters`, `GetCharacterMeetingStats`, `PruneHistory`; 30-second lightweight presence observations, no inspect. Scan identity updates do not create meetings. |
| Database and recent-history lists | `PageHistory.lua`, `PlayerEncounters.lua` | `BuildHistoryRoster` selects filled profiles or recent encounters for the current observer; database sorts by profile/note update. Unset and explicit neutral opinions have distinct filters. |
| Linked player characters and deletion | `PlayerRecordLinks.lua`, `ProfileCharacters.lua` | Active groups in `playerRecords.groups`, no opinion synchronization; journal and generation-safe deletion. Display helpers live in `PlayerRecordSupport.lua`. |
| Retired profile exchange (not in TOC) | `SyncJSON.lua`, `SyncData.lua`, `SyncTransport.lua`, `PageSyncExport.lua`, `PageSync.lua`, `PageReputation.lua`, `KarmaData.lua` | Archived implementation for later redesign; no active transport registration, pages or Karma import. See [Synchronization.md](Synchronization.md). |
| Unsaved profile edits | `ProfileEditor.lua` | One-second autosave, explicit save, retained failed drafts, reload and invalidation on deletion |
| Profile window | `ProfileWindow.lua`, `ProfileEditor.lua`, `ProfileCharacters.lua` | Active v38 window, unified core drafts, one-second autosave, retained errors; old `CharacterProfile`/`ProfilePanels` are outside TOC. |
| Rating display and unit tooltips | `RatingPresentation.lua`, `UnitTooltips.lua` | `FindOpinionCharacter`, explicit-opinion tooltip lines (no tags/Karma); `RefreshUnitOpinionTooltip` rebuilds a shown unit fill after save/delete without touching item tooltips |
| Native friends, ignore, inbox and guild opinion marks | `ClassicOpinionMarkers.lua` | `InitializeClassicOpinionMarkers`, `RefreshClassicOpinionMarkers`; read-only name/realm lookup, secure post-update hooks |
| Theme / shared controls | `UITheme.lua`, `UIWidgets.lua`, `RosterWidgets.lua` | Stable theme tables; generic controls; roster/grade/rating controls |
| Raid and target gear views | `PageRaid.lua`, `PageGearCheckTarget.lua` | `RefreshRaidRosterView`, `RefreshGearCheckTargetView`, `ShowGearCheckReport` |
| Other pages | `PageCooldowns.lua`, `PageExport.lua`, `PageComposition.lua`, `PageHistory.lua` (History and Character database), `PageSettings.lua`, `PageInfo.lua` | `Addon.Pages.*` registrations |
| Shell and navigation | `ExporterWindow.lua`, `Minimap.lua` | `CreateMainFrame`, `SelectTab`, `RefreshLocalizedUI`; separate minimap entry point |

## Load order and contracts

[Raidwise.toc](../Raidwise/Raidwise.toc) is the authoritative executable load order. Read it when adding/moving modules; do not maintain a duplicate full list here.

- Bootstrap creates the namespace; later modules attach methods before normal event-driven use.
- `InspectCoordinator` precedes roster consumers and owns inspect API calls/events. Roster and gear retain their queues and result handling.
- Profile core/support, screen APIs, links and encounters precede presentation; ProfileEditor and ProfileCharacters precede ProfileWindow.
- Legacy PlayerHistory, PlayerHistoryStore, CharacterLinks, ProfileDraft, CharacterProfile/ProfilePanels and Sync/Karma modules are not loaded; historical fixtures may load them explicitly in tests.
- `UITheme` precedes `UIWidgets`, then `RosterWidgets`, then views. Theme/color tables retain identity across theme changes.
- Gear catalogs and report compatibility helpers precede rules, grades, explanations and self-tests. Saved reports and collector precede `GearCheck`; reports and dumps follow it. Pages load before the shell.

### Gear flow

Inspect readiness accepts absent payloads, matching unit tokens, and matching
character GUIDs; current unit identity is checked before dispatch. Unknown-spec
evaluation defers specialization-dependent penalties while retaining objective
checks such as missing enchants/gems and resilience. It remains provisional.

Dump diagnostics include a copied request trace (requests/events/accepted/last
payload) and `character.talentRead` (readiness, raw group/tab count, selected group,
and per-tree points). These distinguish event delivery from empty talent reads;
an incomplete final verdict alone does not prove the ready event was absent.

`CollectGearCheck` normalizes truthy numeric WoW API results to a boolean before
passing inspect readiness to the collector; its strict `true` check must not
receive a raw `UnitIsUnit` result of `1`.

`StartGearCheckUnitScan` requests inspect through the coordinator. `CollectGearCheck` supplies readiness to `CollectGearCheckObservation(unit, inspectReady)` and retains the observation. Collection does not evaluate. Finalization calls `EvaluateGearCheck`, which produces findings and invokes grade aggregation. Formatting belongs in reports, dumps and explanations.

Schema 3 retains compatibility aliases (`equipment`/`slots`, nested/top-level inspect and counts). `NormalizeGearCheckReport` is the adapter at collection, evaluation and snapshot creation boundaries; canonical fields are `character`, `equipment`, and `collection`. Equipment/inspect accessors centralize reads of legacy reports. Rule and catalog revisions are independent of addon semver; saved reports retain original metadata. See [Gear-Check-Progress.md](Gear-Check-Progress.md) for compatibility and grading details.

`GetGearCheckScanState` derives `complete`, `incomplete`, or `unavailable` independently of S/A/B/C/D grades. Overall results carry optional `scanState`, `scanReason`, and `provisional` metadata. Views and chat show incomplete/unavailable labels; raid/minimap readiness counts exclude those reports. Diagnostic grades remain available for partial observations.

Raid roster presentation derives independent category grades from the same report:
gems, armor, weapons (main-hand, off-hand, two-hand and relic slots), and
enchants. The legacy combined `gearGrade` and `enchantSocketGrade` fields remain
available for older consumers and saved reports.

### Refresh and reputation flow

Composition uses groups 1–5 from live collection or the shared snapshot, excluding
reserve groups 6–8. Its counts, providers and chat reports use that same subset.
Raid gear scanning also uses groups 1–5. Roster grade summaries filter saved and
manual results against current group membership. Reserves retain manual Rescan
and individual reports; shared snapshots remain complete.

`ScheduleRosterRefresh` merges same-frame requests. Each pass builds one snapshot shared by history and the visible raid/composition page. Hidden views are not redrawn; history still records. Snapshots are not cached across passes. Inspect queue advancement is immediate; consumable icons have their own targeted refresh path.

Profile commands commit one core draft, then refresh rating views. The local note shares
save controls but does not change opinion authorship. Initialization activates the new
store once; no old review migration runs. Read APIs do not initialize SavedVariables.
Group observations track independent observer/subject sessions and preserve counters
when details expire. There is no active Karma fallback or profile exchange.

Pages register `Create`, `Refresh(page, entering)`, and `ApplyLocale(page)`. The shell dispatches these methods; page modules own control labels and entry-specific collection. `entering=true` requests the original tab-entry work (lockout requests, roster refresh or history recording); locale refresh omits it. Public refresh wrappers remain compatible. Profile extraction preserves anchors, dimensions and named-frame versions.

### SavedVariables and versions

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

See [Reputation.md](Reputation.md) for reputation data. Addon semver, rule/catalog revisions, and layout versions serve different purposes. Geometry rules live in `AGENTS.md`; current layouts and dimensions live in [UI-Views.md](UI-Views.md) and [UI-Sizes.md](UI-Sizes.md).

The [character-system baseline](Character-System-Baseline.md) records the pre-simplification behavior and known documentation/code discrepancies as of 2026-10-29; it is a historical analysis, not the future design contract.

Agreed changes for the new system are tracked separately in [character-system redesign decisions](Character-System-Redesign.md).

The [character-system implementation plan](Character-System-Implementation-Plan.md) orders the work and defines validation for each stage; it does not indicate that the redesign has shipped.

The [new character-system contract](Character-System-Contract.md) defines the local data model, reduced event catalog and planned screen structure. The transition bridge is active; complete screen redesign and encounter sessions are subsequent stages.

## Focused searches

Start with named files from the task table, or `Raidwise/` and `tests/`. Examples from the repository root (PowerShell-compatible):

```powershell
rg -n 'StartGearCheckUnitScan|TryCollectPending' Raidwise/GearCheck.lua
rg -n -C 6 'gemFieldsComplete' Raidwise/GearCheckCollector.lua
rg -n 'SETTINGS_CHANGELOG' Raidwise/Locale.lua Raidwise/PageSettings.lua
rg -n '^function Addon:|^local function' Raidwise/CharacterProfile.lua
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
