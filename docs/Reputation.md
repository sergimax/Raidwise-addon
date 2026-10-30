# Local character profiles

Current implementation after the character-system redesign. Detailed fields and
rules: [contract](Character-System-Contract.md). Original behavior is retained in
[baseline](Character-System-Baseline.md); implementation/verification status is
tracked in the [plan](Character-System-Implementation-Plan.md).

## Storage and ownership

`RaidwiseDB.playerRecords` owns identities, profiles, notes, changes, groups,
encounters and meeting statistics. Profile/Note are shared across one's own
characters; meeting details and counters belong to the observer/subject pair.
The author is a concrete character. Editing a version changes its author;
editing only the private Note does not. Unchanged events retain their authors.
No legacy `history`/`reputation` data is imported, and the new store is not
reset on subsequent logins. Other addon settings, lockouts and gear reports remain.

## Profile

The independent v37 window contains three tabs: Events, History, Characters.
Opinion, four facts, authorship, meeting summary and the private Note stay visible.
There are three explicit opinions and a distinct Not set state. Events use the
22-type catalog and automatically captured time/place; backdating is unavailable.
Facts remain Raid Leader, PUG Raid Leader, Guild Master and Guild Officer.

Changes save after one second idle or by Save. Close/switch attempts a save;
on failure the draft remains in memory with a visible error and Reload option.
Saved means SavedVariables in memory, not an immediate guaranteed disk write.
Self-rating is disabled; a private Note about oneself is allowed. The Note is
never part of shared opinion data or the change log.

## Database, History and deletion

Database v12 lists meaningfully filled profiles; one Note or an explicit neutral
opinion suffices. Adding a name/target only opens an empty Profile. History v7
lists current observer's group/raid meetings from the last 14 days, including
players with or without saved profiles. A target scan never creates a meeting.

Repeated observations, zone changes and party-to-raid transitions do not inflate
counts. Returns within five minutes continue a session; longer unobserved gaps
start another. A lightweight 30-second observation supports quiet groups.
Age pruning deletes old meeting details only, preserving approximate lifetime
counts, events, changes, notes and filled profiles.

Manual links retain a local Main but never share opinions. Full deletion clears
the selected profile, Note, changes and links, invalidates pending drafts and
preserves encounters/counters plus other members' profiles. It requires confirmation.

## Presentation

Chat, roster, unit tooltips, friends, ignore, inbox and guild use the chosen explicit
opinion regardless of author. Not set, a Note alone, a scan or a meeting cannot
create a neutral marker. Negative chat keeps item/achievement links and their colors.
Open unit tooltips and native lists refresh after save/delete. Only one opinion
visibility setting remains; retired Karma/tag flags do not affect output.

There is no active Karma, profile import/export or Share menu. The future external
service and exchange contract are deferred. Offline tests do not establish real
server, skin, clipboard or screen-layout behavior; see the final verification report.
