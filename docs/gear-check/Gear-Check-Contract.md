# Gear Check compatibility and limits

Use the [task map](Gear-Check-Progress.md) for owners and behavior tests.
Field definitions belong to [types/GearCheck.ts](../../types/GearCheck.ts),
[collection](../../Raidwise/GearCheckCollector.lua) and the
[report adapter](../../Raidwise/GearCheckReport.lua), rather than a second schema here.

## Revisions

| Revision | Authoritative source | Change when |
|---|---|---|
| Normalized report schema | `GEAR_CHECK_SCHEMA_VERSION` in `GearCheckCollector.lua`; `types/GearCheck.ts` | Field meanings/normalized compatibility change; review adapter and types together |
| Evaluation rules | `GEAR_CHECK_RULESET_VERSION` in `GearCheckRules.lua` | Findings, eligibility, aggregation or unknown/incomplete policy changes; increment the rules revision |
| Catalog data | `GEAR_CHECK_DATA_VERSION` in `GearCheckCatalog.lua` | Gems/enchants, profiles, BiS/trinket pools or sets change; assign a new catalog revision |
| Text dump format | `REPORT_VERSION` in `GearCheckDump.lua` | The exported text contract changes |
| Addon semver / layout | TOC, `Addon.version` / view constants | Follow [AGENTS.md](../../AGENTS.md) release and geometry rules |

These revisions are independent. Mechanical refactors and UI/string-only edits
do not change evaluation revisions. Correcting observation collection alone does
not change grading policy; changed field meanings may require schema work.
Changes to both evaluation and reference data need both revisions reviewed.

## Saved reports and older consumers

Keep `RaidwiseDB.gearCheckSaved`, IDs, public methods and slash commands stable.
Canonical nested fields win over conflicting legacy aliases at
`NormalizeGearCheckReport`; consumers use the equipment/inspect accessors.
Completeness is separate from diagnostic grades; use `GetGearCheckScanState`.

Snapshots record schema/rule/catalog metadata, but the rules/catalog values are
stamped at **save time**. They do not prove that an imported/older observation was
freshly collected or evaluated. Legacy revision strings remain opaque historical
values; listing/loading does not relabel them as installed revisions. Missing
installed constants produce `unknown`, not a version guessed from addon semver.

`EnsureGearCheckGrades` has an existing lazy grade-refresh path: saved reports
are not promised immutable evaluation results. A fresh scan is the reliable way
to obtain current observations under current rules/data. Before consuming a
future incompatible schema, provide a tested migration or explicit unsupported/
rescan path; relabeling a snapshot is insufficient. Tests:
[saved-revisions](../../tests/saved-revisions.test.mts) and
[architecture](../../tests/architecture.test.mts).

Identity scope remains [one realm per dataset](../adr/0001-character-realm-scope.md),
including saved reports. A save updates SavedVariables in memory; the client owns
disk persistence. Client persistence checks are [separate](Gear-Check-Verification.md).

## Client and transport limits

An inspect event with no identity cannot conclusively be attributed to this
addon's request. GUID validation protects against a reassigned unit token;
interference with other inspect addons still needs [client checks](Gear-Check-Verification.md).
Request traces and `character.talentRead` in dumps help distinguish absent events
from empty talent reads; an incomplete verdict alone proves neither cause.

The complete outgoing network chat message must fit 255 UTF-8 bytes, including
prefix/name/separators, without splitting characters or hyperlinks. Use
`PrepareReportMessage`; local output has a separate path. Split reports are sent
immediately: there is no pacing or universal safe burst count across realms.
Historical references: [3.3.x ChatThrottleLib](https://repos.curseforge.com/wow/guilder/file/c25618699222/Libs/ChatThrottleLib/ChatThrottleLib.lua)
and [AzerothCore flood configuration](https://github.com/azerothcore/azerothcore-wotlk/blob/master/src/server/apps/worldserver/worldserver.conf.dist).
