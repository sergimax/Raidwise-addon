# Reputation model

Local player reputation for other characters is stored under `RaidwiseDB.history[guid]` and edited in the Character profile. Catalogs and persistence live in [`PlayerHistory.lua`](../Raidwise/PlayerHistory.lua).

## Entities

| Entity | Meaning | Stored as |
|--------|---------|-----------|
| **Opinion** | Overall personal note (positive / neutral / negative) | `rating.personal.opinion` |
| **Tags** | Subjective labels by category (organization, behavior, trust, loot, discipline, gameplay) | `rating.personal.tags[]` |
| **Facts** | Persistent roles / identity (Raid Leader, PUG Raid Leader, Guild Master, Guild Officer) | `rating.personal.facts[]` |
| **Events** | Witnessed occurrences (left raid, late arrival, ninja loot, helped player, …) | `events[]` |
| **Memo** | Private free text | `notes` |

Caps: max **3** tags per category; max **4** facts. Events are an unbounded list (change log capped at 50 rows). Opinion, tags, facts, and events are edited as drafts in Character profile until **Save and Update**; memo saves separately and is never logged.

## Record metadata

On personal rating save and on each new event:

- `creatorId` — local `UnitGUID("player")`
- Opinion block also has `createdAt` (first save) and `updatedAt`
- Each event has `eventAt` and `context` (`zoneName`, `zoneId`, `instanceName`, `difficulty`, reserved `itemId` / `bossId` / `instanceId`)

## Migration

One-shot per history entry (`personal.reputationV2`):

- Fact-meta tags (`raid_leader`, `pug_leader`, …) → `facts`
- Discipline/loot tags that became events (`late`, `afk`, `rage_quit`, `ninja_looter`, …) → `events` (empty context)
- Dropped tags (`raid_organizer`, `experienced`) removed

## Future share matrix (not implemented in UI yet)

| Entity | Web app | Other players |
|--------|---------|---------------|
| Opinion | yes | no |
| Tags | yes | yes |
| Facts | yes | yes |
| Events | yes | yes |
| Memo | never | never |

Roster views continue to show opinion + tags only; facts appear in the profile header; events are listed on the Events / History tabs. Character profile opens on the **History** tab by default; opinion/tags are edited on **Edit note**.

## Display helpers (`PlayerHistory.lua`)

Used by roster pages, Character profile, and unit tooltips:

| Method | Role |
|--------|------|
| `MergeRatingIntoMember` | Attach saved opinion/tags/facts to a roster row |
| `RatingOpinionSymbol` / `RatingOpinionLabel` / `RatingOpinionColor` | Opinion column and tooltips |
| `RatingTagColoredSummary` / `RatingTagSummary` | Tag column and tooltips |
| `FactColoredSummary` / `FactSummary` | Profile header facts line |
| `FormatHistoryTime` | History tab and change-log timestamps |
| `GetHistoryEvents` | Events tab and profile drafts |
| `BuildUnitTooltipRatingLinesForMember` | Unit tooltip lines (via `UnitTooltips.lua`) |

## Unit tooltips

`UnitTooltips.lua` hooks `GameTooltip` `OnTooltipSetUnit` (same pattern as GearScore). For player units:

1. **Personal** — if a saved personal note exists: opinion label (colored) and up to 3 tags (`Positive: Fair Loot, …`)
2. **Community** — if the GUID is in History: mock percent + up to 3 tags until real exchange data lands (`91 % positive:` then tag line)

Visibility is controlled by `RaidwiseDB.tooltip` hide flags (Settings).
