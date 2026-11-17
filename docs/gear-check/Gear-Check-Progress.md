# Gear Check task map

Start here for gear scanning, evaluation and report work. Paths below are relative
to `Raidwise/`; search the named entry point before its helpers/callers.
[The TOC](../../Raidwise/Raidwise.toc) owns load order;
[types/GearCheck.ts](../../types/GearCheck.ts) describes the normalized model.

| Change | Owner / entry point | Behavior checks |
|---|---|---|
| Inspect identity, events, deadline or retries | `InspectCoordinator.lua`: `StartInspectRequest`, `RetryInspectRequest`, `CancelInspectRequest`; `GearCheck.lua`: `StartGearCheckUnitScan`, private `TryCollectPending` | [inspect](../../tests/inspect.test.mts), [scan](../../tests/scan.test.mts), [scan scenarios](../../tests/lua/scan-scenarios.lua) |
| Read items, links, enchants, gems or talents | `GearCheckCollector.lua`: `CollectGearCheckObservation`; `GearCheck.lua`: `CollectGearCheck` supplies readiness | [gear-check](../../tests/gear-check.test.mts), [gem fixtures](../../tests/lua/gear-check-gems.lua) |
| Compatibility aliases or incomplete/unavailable results | `GearCheckReport.lua`: `NormalizeGearCheckReport`, `GetGearCheckScanState` | [architecture](../../tests/architecture.test.mts), [gear-check](../../tests/gear-check.test.mts), [scan](../../tests/scan.test.mts) |
| Findings, meta activation or set counts | `GearCheckRules.lua`: `EvaluateGearCheck` | [gear-check](../../tests/gear-check.test.mts), shipped [rule fixtures](../../Raidwise/GearCheckSelfTest.lua) |
| Slot/category/overall grade or explanation | `GearCheckGrades.lua`: `AggregateGearCheckVerdicts`, `AggregateGearCheckOverall`; `GearCheckExplanations.lua`: `ExplainGearCheckNotGood`, `BuildGearCheckCategoryTooltipLines`; shared internal `GearCheckPolicy` | [gear-check](../../tests/gear-check.test.mts), [rule fixtures](../../Raidwise/GearCheckSelfTest.lua) |
| Wrong spec/stat/armor/weapon/trinket choice or catalog ID | `GearCheckProfiles.lua`, `GearCheckCatalog.lua`, `GearCheckTrinkets.lua`, `GearCheckSets.lua`; generated `GearCheckBis.lua` | [maintenance and sources](Gear-Check-Surface-From-BiS.md), [gear-check](../../tests/gear-check.test.mts), [gem fixtures](../../tests/lua/gear-check-gems.lua) |
| Save, list, delete or expire a snapshot; revision metadata | `GearCheckSavedReports.lua`: `SaveGearCheckReport`, `ListGearCheckSavedReports`, `DeleteGearCheckSavedReport`, `PruneExpiredGearCheckReports`; `GearCheck.lua`: `EnsureGearCheckGrades` | [saved-revisions](../../tests/saved-revisions.test.mts); client saved-report self-tests via `/rw gearcheck test` |
| Target/raid text dump, asynchronous export, cancel/restart | `GearCheckDump.lua`: `FormatGearCheckDump`, `BuildGearCheckRaidDumpAsync`, `CancelGearCheckRaidDump`; `PageRaid.lua`: `RunGearCheckRaidExport` | [dump](../../tests/dump.test.mts), [scan](../../tests/scan.test.mts) for scan cancellation |
| Raid work list or readiness summary | `GearCheck.lua`: `StartGearCheckRaidScan`, `FilterActiveRaidGearResults`; `PartyRoster.lua`, `RosterRefresh.lua` | [architecture](../../tests/architecture.test.mts), [scan](../../tests/scan.test.mts), [roster-refresh](../../tests/roster-refresh.test.mts) |
| Chat text, short/full forms, preview/send consistency | `GearCheckReports.lua`: `BuildGearCheckChatMessages`, `FormatGearCheckMemberIssues`; `ChatReports.lua`: `PrepareReportMessage` | [gear-check](../../tests/gear-check.test.mts) |
| Target/raid UI and saved selection | `PageGearCheckTarget.lua`, `PageRaid.lua`; use [UI views](../ui/UI-Views.md) / [sizes](../ui/UI-Sizes.md) for geometry | [dump](../../tests/dump.test.mts), [architecture](../../tests/architecture.test.mts); [client checks](Gear-Check-Verification.md) |

Before changing formats or revisions read [compatibility and limits](Gear-Check-Contract.md).
For catalog/profile/BiS changes read [maintenance](Gear-Check-Surface-From-BiS.md).
For why the check avoids optimization read [ADR 0003](../adr/0003-gear-surface-assessment.md).
[Manual checks](Gear-Check-Verification.md) distinguish unverified client behavior
from the offline suite. Commands and test conventions: [tests/README.md](../../tests/README.md).
