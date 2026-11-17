# Guild task map

The companion [Raidwise_Guild.toc](../../Raidwise_Guild/Raidwise_Guild.toc) owns
load order. Core loads it before building the shell; install it with Raidwise and
restart after TOC changes. It uses the shared Raidwise namespace, widgets and DB.
Paths below are relative to `Raidwise_Guild/`; `Guild` is `Raidwise.GuildManagement`.

| Change | Owner / search entry point | Behavior checks |
|---|---|---|
| Permissions, note/rank command, conflict or confirmation | `GuildManagement.lua`: `Guild.Permissions`, `Guild.Submit`, `Guild.CanRank`, `Guild.Accept` | [guild-management](../../tests/guild-management.test.mts): live index, all-field validation, partial results, hierarchy, uncertain timeout |
| Roster request, complete snapshot or progress | `GuildManagement.lua`: `Guild.Request`, `Guild.Collect`, private `ReadMembers`, `Guild.Progress`, `Guild.Close` | [guild-management](../../tests/guild-management.test.mts): coalescing, chunk progress, interrupted reads, guild/permission changes, offline flag restoration |
| Journal sources, repeated server windows or retention | `GuildManagement.lua`: `Guild.ImportEvents`, `Guild.Entries`, `Guild.SetLimit`; private `EventKey`, `Prune` | [guild-management](../../tests/guild-management.test.mts): baseline, observation changes, ageing/occurrence matching, all-archive pruning |
| Note grammar or main/alt chain | `GuildRosterParser.lua`: `Parser.ParseOfficerNote`, `Parser.ParseGuildRosterSnapshot`; `GuildRosterLinks.lua`: `Resolver.Resolve` | [guild-management](../../tests/guild-management.test.mts): Cyrillic chains, missing/cyclic links, raw notes and current read access |
| BASE_GP, PR or roll eligibility | `GuildEPGP.lua`: `EPGP.ParseGuildInfo`, `EPGP.Calculate`; `GuildManagement.lua`: `Guild.Balances`, `Guild.SetRollMinimumEP` | [guild-management](../../tests/guild-management.test.mts): defaults/invalid/zero base, independent threshold, unrounded PR |
| Search, raid/mains-only filter or numeric sort | `GuildManagement.lua`: `Guild.Members`, `Guild.RaidNames` | [guild-management](../../tests/guild-management.test.mts): unknowns, full-snapshot alt resolution, active raid groups and filter intersections |
| Drafts, pagination, headers or tooltips | `PageGuild.lua`: private `Refresh`, `SetEditor`, `Submit`, `LayoutTable` | [guild-management](../../tests/guild-management.test.mts): retained drafts, rights loss, aligned scrolling, pagination, highlights and readable tooltip colors |
| Bootstrap or packaging | `Raidwise.lua` in the core addon; guild TOC | [guild-management](../../tests/guild-management.test.mts): actual bootstrap/TOC loading; [release](../../tests/release.test.mts) |

Before changing commands, storage or data interpretation read
[external limits](Guild-Management-Contract.md). For actual server behavior and
visual acceptance use the [manual matrix](Guild-Management-Verification.md).
Geometry belongs to [UI views](../ui/UI-Views.md) and [sizes](../ui/UI-Sizes.md).
Commands/test conventions: [tests/README.md](../../tests/README.md).

## Retired and deferred work

The Raidwise_EPGP addon, its separate page and guild JSON export are removed.
`RaidwiseDB.guild` is the current store; retired `epgp` / `guildManagement` roots
are not an active contract. Do not restore old imports or GP overrides from the
removed plan as part of a maintenance change.

That plan also proposed reviewed snapshot import/corrections, a grouped alt map,
item competitors and generated raid proposals. These remain future directions,
not current features. A new task must define provenance, uncertainty and criteria;
unknown raid experience is not zero, competition estimates do not assign loot,
and proposal generation is separate from [live composition](Raid-Composition.md).
Item competition would use [Gear Check observations](../gear-check/Gear-Check-Progress.md);
raid proposals need explicit GS/DPS/experience criteria and a source for experience.
