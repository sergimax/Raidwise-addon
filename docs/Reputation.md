# Reputation model

Local player reputation for other characters is stored under `RaidwiseDB.reputation.localProfilesByGuid[guid]` and edited in the Character profile. `RaidwiseDB.history` contains encounter/scan identity only. Catalogs and rating access live in [`PlayerHistory.lua`](../Raidwise/PlayerHistory.lua); persistence and migrations live in [`PlayerHistoryStore.lua`](../Raidwise/PlayerHistoryStore.lua). Draft edits belong to [`ProfileDraft.lua`](../Raidwise/ProfileDraft.lua), and labels/tooltips to [`RatingPresentation.lua`](../Raidwise/RatingPresentation.lua).

## Data-base separation (foundation)

`RaidwiseDB.reputation` is the dedicated root for the three rating bases. Its
version-2 shape contains `localProfilesByGuid`, `exchangeProfilesBySource`, and
an optional `globalKarma` dataset. `InitializeHistoryStore()` performs the
one-shot Phase 6 migration before UI construction, then removes copied legacy
profile fields from every history row.

The eventual ownership rules are fixed now: only local profiles may be edited
and included in a personal export; exchanged profiles are retained per sender;
and Global Karma is a read-only versioned dataset. GetReputationStore,
GetLocalProfile, GetExchangeProfileSources, and GetGlobalKarmaDataset are
read-only helpers and never initialize SavedVariables or silently project legacy
history rows into a new base.

Local Profiles exclusively own editable opinions, tags, facts, manual events,
notes, and profile changes. Exchange Profiles exclusively own received opinions,
events, and links under a sender-scoped key. Received profiles are read-only and
are never included in an outgoing export. Character Database and Character
Profile read profile data through the Local/Exchange APIs, not legacy history
fields or `recordSource`.

## Linked characters

The profile's **Characters** tab records local associations between characters of
one player. Choose a known character from History (search by name/realm), or use
**Link target**. These associations are manual, not verified account identities.

Each group has exactly one **local Main** and any number of Alts. Main is a
personal display preference: other players may choose a different Main without
conflict. Shared Alt links mean only that characters belong to the same person;
they carry no Main designation. `GetSharedCharacterLinks` provides membership
data without local roles, opinions, or history. The [Synchronization view](Synchronization.md)
exchanges selected profiles or the saved database with explicit review and consent.

The first character is
the initial Main; selecting another member's Main button changes it. Choose a
replacement Main before unlinking the current one. A character already linked
to another group must be unlinked there first; linking does not silently merge
whole groups. Changes save immediately, separately from profile drafts.

Only the positive/neutral/negative opinion is shared. Saving it on any member
updates that opinion for every linked member. Tags, facts, events, and private
notes stay character-specific. If opinions differ during linking, choose which
one to keep or cancel. Unlinking retains the last shared opinion on the detached
character; subsequent opinion changes no longer propagate to it.

Link/unlink records are appended to each affected character's profile History,
with the other character's name and realm. Main changes are recorded too. Unit
and roster tooltips list linked characters, class-colored, with Main/Alt labels.

Storage: `RaidwiseDB.characterGroups[id]` contains `members` only. Main preferences
live separately in `RaidwiseDB.localCharacterMains[id]`. Initialization migrates
legacy `mainGuid` values without overriding an existing local preference;
history entries refer to `playerGroupId`. `nextCharacterGroupId` allocates stable
group IDs. Main-change history is local and excluded from the membership payload.
Existing `history.links` data is not repurposed. Opinion synchronization
updates existing personal opinion fields; no facts/events/notes are merged.

## Chat highlighting

Chat markers show `<Rw51>` with the current Karma percentage (without `%`).
Marks appear only for saved profiles or players scanned through target/raid Gear
Check within the last 14 days. Ordinary party encounters and unknown senders have
no mark. Eligible players use the mock fallback of 51%; if the Karma getter
has no rating, their mark is `<Rw>`.
The `Rw` text uses green for positive personal opinions, white for neutral or
missing opinions, and red for negative. Brackets and the number are white.
Negative opinions also color the message body red.
Item and achievement links retain their original colors and remain clickable;
text after them resumes red. This applies to the registered player chat channels
(including whispers, party, raid, guild and emotes); channel headers and sender
formatting remain controlled by WoW. Linked characters inherit this behavior through their shared personal
opinion. Display changes are local and do not alter outgoing message content.

## Entity reference

`InitializeHistoryStore()` normalizes and migrates saved entries at addon initialization, before the UI is created. Explicit write methods also normalize their entries. `GetPersonalRating`, `GetCommunityRating`, `GetHistoryEvents`, `GetHistoryEntry`, and `BuildHistoryRoster` do not migrate or initialize storage. Integrations replacing the history store should explicitly initialize it before displaying legacy data.

| Entity | Meaning | Stored as |
|--------|---------|-----------|
| **Opinion** | Overall personal note (positive / neutral / negative) | `rating.personal.opinion` |
| **Tags** | Subjective labels by category (organization, behavior, trust, loot, discipline, gameplay) | `rating.personal.tags[]` |
| **Facts** | Persistent roles / identity (Raid Leader, PUG Raid Leader, Guild Master, Guild Officer) | `rating.personal.facts[]` |
| **Events** | Witnessed occurrences grouped by category (attendance, loot, help, behavior) | `events[]`. Attendance includes auto-logged `same_party` when `meetCount` increments |
| **Memo** | Private free text | `notes` |

Caps: max **3** tags per category; max **4** facts. Events are an unbounded list (change log capped at 50 rows). Opinion, tags, facts, and events are edited as drafts in Character profile until **Save and Update**; memo saves separately and is never logged.

## Record metadata

The currently logged-in character's own opinion, tags, facts, and events cannot
be edited, to prevent self-rating. The disabled save control explains this on
the Edit note, Facts, and Events tabs. Private memo edits and character linking,
unlinking, and local Main selection are allowed for the current character.
The store enforces the same rule by GUID and matching local name/realm, including
name-only cards. Linked opinion synchronization skips the current character's
opinion while updating other linked characters. Other characters remain editable.

Profiles have three states, exposed by `GetCharacterProfileState` and shown in
the existing History/Character database source column:

| State | Meaning | Retention |
|-------|---------|-----------|
| `local` | Profile saved or customized locally, including notes and character links | Kept in Character database |
| `imported` | Profile supplied by one or more Exchange senders | Kept in Character database |
| `unset` | No saved profile; may have encounter or scan history | Removed from History after 14 days without an encounter/scan |

Scanning does not create a saved profile. `lastScannedAt` records explicit target
and raid Gear Check scans separately from ordinary encounters. Old scan-only
records without this field need a new scan to qualify for chat marking.
Opening a profile does not save it. Legacy `recordSource`, imported personal
ratings, notes, and manual events are copied once during migration, then removed
from history; they no longer drive UI, filters, exports, or chat markers.
The import transport/UI and versioned JSON contract are described in [Synchronization.md](Synchronization.md).

On personal rating save and on each new event:

- `creatorId` — local `UnitGUID("player")`
- Opinion block also has `createdAt` (first save) and `updatedAt`
- Each event has `eventAt` and `context` (`zoneName`, `zoneId`, `instanceName`, `difficulty`, reserved `itemId` / `bossId` / `instanceId`)

## Migration

One-shot per history entry (`personal.reputationV2`):

- Fact-meta tags (`raid_leader`, `pug_leader`, …) → `facts`
- Discipline/loot tags that became events (`late`, `afk`, `rage_quit`, `ninja_looter`, …) → `events` (empty context)
- Dropped tags (`raid_organizer`, `experienced`) removed

## Explicit profile exchange

| Entity | Web app | Other players |
|--------|---------|---------------|
| Opinion | yes | yes |
| Tags | yes | yes |
| Facts | yes | yes |
| Events | yes | yes |
| Memo | never | never |

Exchange is manual and reviewed; it does not calculate Karma consensus or
automatically synchronize guild members. See [Synchronization.md](Synchronization.md)
for field limits, local-profile protection and link import rules.

Roster views show personal opinion on the card; Raid roster uses one compact line (`P:` Qiraji crystal icon + `K: 75%`) with Karma percent from `GetCommunityRating` (`K: —` when missing). Crystals: green = positive, yellow = neutral, red = negative. Tags and full Karma detail stay on hover / Character profile; facts appear in the profile header; events are listed on the Events / History tabs. Character profile opens on the **History** tab by default; opinion/tags are edited on **Edit note**.

## Display helpers (`PlayerHistory.lua`)

Used by roster pages, Character profile, and unit tooltips:

| Method | Role |
|--------|------|
| `MergeRatingIntoMember` | Attach saved opinion/tags/facts to a roster row |
| `RatingOpinionSymbol` / `RatingOpinionIcon` / `RatingOpinionLabel` / `RatingOpinionColor` | Opinion column (History crystals), raid rating line, and tooltips |
| `RatingTagColoredSummary` / `RatingTagSummary` | Tag column and tooltips |
| `FactColoredSummary` / `FactSummary` | Profile header facts line |
| `FormatHistoryTime` | History tab and change-log timestamps |
| `GetHistoryEvents` | Events tab and profile drafts |
| `EventTypeGroups` / `EventTypeLabel` / `EventTypeDisplayLabel` / `EventTypeGroupIcon` / `ProfileHistoryChangeIcon` | Categorized event picker, History change-log icons, and category icons |
| `BuildUnitTooltipRatingLinesForMember` | Unit tooltip lines (via `UnitTooltips.lua`) |

## Unit tooltips

`UnitTooltips.lua` hooks `GameTooltip` `OnTooltipSetUnit` (same pattern as GearScore). For player units:

1. **Personal** — if a saved personal note exists: opinion label (colored) and up to 3 tags (`Positive: Fair Loot, …`)
2. **Karma** — if the GUID is in History: mock percent + up to 3 tags until real exchange data lands (`51 % positive:` then tag line)

Visibility is controlled by `RaidwiseDB.tooltip` hide flags (Settings).


## Personal opinion in the native interface

The standard Wrath friends list, ignore list, and inbox sender rows display a
14 px reputation crystal and colored [+] / [=] / [-] prefix for saved positive,
neutral, or negative personal opinions. Encounter-only records have no marker.
Names match case-insensitively within the character realm; explicit Name-Realm
values are supported, and unqualified names use the current realm. If duplicate
records match, the most recently updated saved personal rating wins.

Both native guild modes (player status and guild status) show a colored
[+] / [=] / [-] tag at the right edge and tint the whole row light green / light gray / light red at
15% opacity, including offline characters with saved opinions. Native name colors
and selection highlights remain intact. Guild sorting and scrolling use
the roster index assigned by Blizzard to each row.

Guild marks use a mouse-disabled child frame one level above the row, following
the local reputation example. The independent tag avoids clipping inside ElvUI's
100 px name field. Roster events and guild scroll updates schedule a single
next-frame refresh after skin hooks; there is no continuous polling. The overlay
fills the existing row and anchors its tag 3 px from the right edge.

If marks are missing, keep the guild roster open and run `/rw diagnose`.
Diagnostics v2 explicitly fails when the marker module is missing or outdated;
install the complete addon folder (including the TOC) and fully restart the
client before repeating the check. A report without this section does not
verify native markers.
The native marker section reports its implementation revision, initialization,
hook state, refresh count, saved/current-realm opinion counts, and each guild
row pool's visible identities, matches, and shown overlays. It includes no
character names or saved notes. These counts describe runtime state, not a
guarantee that a skin renders the overlay visibly.

Markers refresh after native list updates, scrolling, mailbox pagination, and
profile rating refreshes. Recycled rows and empty inboxes clear old marks.
Battle.net account rows, ignore section headers, and dynamic scroll spacers are
excluded. Native row clicks, selection, sender identity and mailbox actions are
unchanged. Tooltip visibility settings
do not control these list markers.

Implementation: `ClassicOpinionMarkers.lua`, using the post-update approach from
the local reputation mailbox example. Native row identities and hook points were
checked against the [3.3.5 FriendsFrame source](https://github.com/wowgaming/3.3.5-interface-files/blob/main/FriendsFrame.lua)
and [dynamic scroll implementation](https://github.com/wowgaming/3.3.5-interface-files/blob/main/UIPanelTemplates.lua).
Offline coverage is in `tests/classic-opinion.test.mts`. In game, check a saved
positive/neutral/negative character in each list, scroll or change inbox pages,
and edit an opinion while a list is open. Install the new Lua file and updated
TOC together, then restart the client before this check.
