# Raid composition task map

Paths below are relative to `Raidwise/`. The executable effect catalog is
`EFFECTS` in [RaidComposition.lua](../../Raidwise/RaidComposition.lua): categories,
class/tree sources, spell IDs and hidden/priority flags belong there.

| Change | Owner / search entry point | Behavior checks |
|---|---|---|
| Active roster, party/solo or reserves | `RaidComposition.lua`: `CompositionMembers`; `PartyRoster.lua` supplies members | [architecture](../../tests/architecture.test.mts): live/snapshot active groups and explicit reserves |
| Effect/provider matching and class/spec totals | `RaidComposition.lua`: `EFFECTS`, private `SourceMatches`, `AnalyzeRaidComposition` | [architecture](../../tests/architecture.test.mts): unknown versus known primary trees and potential providers |
| Role classification | `RaidRoles.lua`: `RoleForRaidMember`; `RaidComposition.lua`: private `EnsureMemberRole` | [architecture](../../tests/architecture.test.mts): inferred role with known tree |
| Shared roster refresh or visible-page redraw | `RosterRefresh.lua`: `BuildRosterSnapshot`, `ScheduleRosterRefresh`; `PageComposition.lua`: `RefreshCompositionView` | [roster-refresh](../../tests/roster-refresh.test.mts) |
| Effect/missing-class report, preview or spell links | `PageComposition.lua`: private `BuildEffectRowMessage`, `BuildMissingClassesMessage`, `AddChatPreview`; `ChatReports.lua`: `PrepareReportMessage` | [gear-check](../../tests/gear-check.test.mts): composition report links, fallback, whole-source trimming and byte budget |
| Controls and geometry | `PageComposition.lua`; [UI views](../ui/UI-Views.md) / [sizes](../ui/UI-Sizes.md) | [manual checks](Guild-Management-Verification.md#composition-presentation) |

## Meaning and limits of coverage

Composition shows **potential providers** inferred from class and primary talent
tree. It does not inspect deep talent choices, pets, current auras/casts or
subgroup assignments of blessings/totems. A matching tree can light a category
without the corresponding talent actually being selected. Category presence is
not a comparison of active spell strength.

An unknown spec remains in its class total and can supply class-wide effects;
spec-specific effects require the matching known tree. Roles use class/tree
heuristics and supplied roles, including the roster's Main Tank override.
Default raid input is groups 1–5; reserves 6–8 stay in the full shared snapshot
and require explicit inclusion. Solo/party use the corresponding collected roster.

The shared header chooses the report channel. Link/hover presentation depends
on client and chat skin; see the [manual checks](Guild-Management-Verification.md#composition-presentation).
For guild balance work use the [guild map](Guild-Management.md).

## Historical catalog references

The checklist drew on [Wowhead composition](https://www.wowhead.com/wotlk/raid-composition),
[Icy Veins categories](https://www.icy-veins.com/wotlk-classic/raid-buffs-and-debuffs)
and the Blizzard WotLK exclusive-category list cited by the former document.
These are provenance, not a guarantee of current behavior on a private server.
Change the owning Lua data and exercise representative provider behavior rather
than maintaining a second Markdown matrix of every spell.
