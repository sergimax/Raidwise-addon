# Guild management

The core addon provides **Guild → Guild roster**, independently of the optional EPGP addon. The page has Roster and Journal modes and uses WoW 3.3.5a APIs. English and Russian labels follow the addon locale.

## Roster and officer actions

All members, including offline characters, appear in alphabetical order with a class icon, class-colored name, rank, online status, public note and officer note. Online status is green; the selected character's row stays highlighted while editing, including on hover and refresh. Search matches a literal substring in the name or either accessible note; the class filter applies at the same time. Cyrillic case folding includes Ё/ё. Class and journal-type buttons cycle through choices and return to All after the last choice. Lists show 12 rows per page; hover a roster row for class name and full notes.

Select a character to edit notes. Save and Reload / cancel are explicit; refreshes preserve drafts. The editors follow the stock 31-character UI limit. Raw officer notes are not reformatted as EPGP. After a confirmed action the loaded EPGP view is recalculated from the game roster.

Before sending, the model checks the current guild, current permissions, original values and current roster index by character name. A conflict retains the draft; use Reload / cancel to read the new game value before editing again. Both changed notes are validated before either command, but the game's two commands are not an atomic transaction. A partial result remains unconfirmed.

Promote and Demote change one rank immediately without an extra confirmation. The game's hierarchy constraints apply. All mutation buttons are blocked during an outstanding operation. Confirmation requires the expected values in a fresh full roster; after 12 seconds without confirmation, the result is reported as uncertain. Commands are never automatically resent. Refresh and inspect the result before retrying.

Officer-note reading uses `CanViewOfficerNote`, independently of editing. Losing read permission hides notes, search matches and officer-note journal details, including previously stored entries. Retained local SavedVariables are not encrypted or erased by that visibility rule. Other actions require their corresponding permissions; disabled buttons explain the restriction.

## Refresh

Opening the page requests the full roster and server event log. The Refresh button uses the same path. While visible, the page processes roster events and requests another refresh every 30 seconds. Requests coalesce, with a minimum two-second interval and a 12-second timeout. A pending mutation can finish or time out after closing the page; otherwise no background collection occurs.

The collector temporarily includes offline members. It restores the previous offline flag when closed, unless another Raidwise EPGP/export operation is still using it. This is a shared game setting; simultaneous external addons can also change it.

Incomplete or unavailable roster replies do not replace the last good snapshot. The collector requires every reported row, unique names, ranks, unchanged count and guild identity, and offline visibility. These checks cannot detect every server-side inconsistency. The first complete snapshot is a baseline, without synthetic member-add events.

## Local journal

The journal combines two labelled sources:

- Server events: invitations, joins, quits, removals, promotions and demotions. The details include the actor when provided and the relative age reported by the server, captured at receipt. The displayed receipt time is not the event's exact timestamp.
- Observations: before/after public notes, accessible officer notes and ranks compared between full snapshots. Author and exact change time are unknown. The timestamp is detection time. Rank observations and server promotion/demotion records remain distinct sources.

Changing read access is not a note edit. Multiple intervening edits cannot be reconstructed. Joining/leaving information comes from the available server log, rather than treating a missing row as a membership event.

Repeated server windows are matched by event contents, occurrence count and approximate age, accounting for relative-age drift. There is no stable server event ID; identical events near each other or long gaps can remain ambiguous. This is an officer convenience archive, not a complete audit trail.

Archives and last snapshots are separated by realm and guild name. They remain local to the installation/SavedVariables and are not synchronized between officers. A new guild page shows only that guild's data; previous archives remain retained. Guild renames create a separate archive.

The shared limit defaults to 1000 and accepts 100–10000 entries per guild archive. Applying a smaller limit immediately removes the oldest entries from every retained archive. The previous server window is retained separately for import matching. SavedVariables persist at normal logout/reload; a crash can lose the current session's writes.

## Validation

`tests/guild-management.test.mts` exercises real Lua 5.1 modules with mocked game APIs: permissions, Cyrillic search, detached reads, snapshot gaps, realm/guild separation, live-index writes, all-field conflict validation, partial confirmations, rank constraints, uncertain timeouts, ageing/repeated event windows, retention, request coalescing and draft preservation in the page.

Run `npm run check` before delivery. Native in-client visual verification and server behavior still require testing with an ordinary member, read-only officer-note access, officer and guild master, concurrent officer edits, offline members and slow replies. No claim of in-game acceptance follows from offline mocks.
