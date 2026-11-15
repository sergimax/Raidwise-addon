# Guild management

The `Raidwise_Guild` addon provides **Guild → Guild roster**, with Roster and Journal modes using WoW 3.3.5a APIs. It depends on Raidwise and shares its namespace, DB, locale and widgets. Core loads it before constructing the shell. The old Raidwise_EPGP page, grouping/filter UI and guild JSON export commands are removed. Install Raidwise and Raidwise_Guild, remove the old Raidwise_EPGP folder and restart the client. English and Russian labels follow the addon locale.

## Roster and officer actions

All members, including offline characters, initially appear alphabetically with a class icon, class-colored name, rank, online status, EP, GP, PR, public note and officer note. The table scrolls horizontally, with headers moving together with rows. EP/GP/PR headers toggle numeric sorting; unknown values stay last and equal values sort by name. PR sorts without rounding and displays two decimal places. Online status is green; the selected character's row stays highlighted while editing, including on hover and refresh. Search matches a literal substring in the name or either accessible note; the class filter applies at the same time. Cyrillic case folding includes Ё/ё. The current-raid filter includes only guild members in groups 1–5 and does not add their mains as extra rows. Outside a raid that filter returns an empty list. Raid roster events refresh visible membership. Class and journal-type buttons cycle through choices and return to All after the last choice. Lists show 10 rows per page; hover a roster row for class name, full notes, balance owner and calculation/reason details.

Select a character to edit notes. Save and Reload / cancel are explicit; refreshes preserve drafts. The editors follow the stock 31-character UI limit. Raw officer notes are not reformatted as EPGP. Confirmed changes update balances from the new game roster.

## Balances and guild settings

Officer notes encode `EP,GP`, or the name of a main character. Main/alt chains are resolved from the full guild snapshot before any display filters. Cyrillic name comparisons are case-insensitive. Missing mains, cycles, ambiguous/invalid links or inaccessible notes produce unknown balances, with reasons in the tooltip. Access loss also hides previously calculated balances.

`PR = EP / (note GP + BASE_GP)`. The base is read only from `@BASE_GP` inside a paired `-EPGP-` block in guild information. Missing block/parameter uses 500 with an explicit default label. Malformed, unclosed or contradictory settings make PR unknown; equal repeated base values are accepted. Other EPGP parameters (`@DECAY_P`, `@MIN_EP`, `@EXTRAS_P`) do not affect this page's calculations or local roll threshold. There is no manual base override and the module never changes guild information. A base of zero is valid, but a zero denominator produces unknown PR while EP, GP and roll eligibility remain available.

GP displays the note value and base, e.g. `1000 (+500)`. The local minimum EP for roll defaults to 4000, accepts non-negative integers via Apply and is stored per realm/guild. `V` means EP meets the threshold, `X` means below it and `?` means unknown. Alts use their main's EP. This threshold changes only the displayed eligibility, not PR or the game's `/roll` command. It is independent of `@MIN_EP` and the retired EPGP settings.

Before sending, the model checks the current guild, current permissions, original values and current roster index by character name. A conflict retains the draft; use Reload / cancel to read the new game value before editing again. Both changed notes are validated before either command, but the game's two commands are not an atomic transaction. A partial result remains unconfirmed.

Promote and Demote change one rank immediately without an extra confirmation. The game's hierarchy constraints apply. All mutation buttons are blocked during an outstanding operation. Confirmation requires the expected values in a fresh full roster; after 12 seconds without confirmation, the result is reported as uncertain. Commands are never automatically resent. Refresh and inspect the result before retrying.

Officer-note reading uses `CanViewOfficerNote`, independently of editing. Losing read permission hides notes, search matches and officer-note journal details, including previously stored entries. Retained local SavedVariables are not encrypted or erased by that visibility rule. Other actions require their corresponding permissions; disabled buttons explain the restriction.

## Refresh

Opening the page requests the full roster and server event log. The Refresh button uses the same path. While visible, the page processes roster events and requests another refresh every 30 seconds. Requests coalesce, with a minimum two-second interval and a 12-second timeout. A pending mutation can finish or time out after closing the page; otherwise no background collection occurs.

The collector temporarily includes offline members and restores the previous offline flag when closed. This is a shared game setting; simultaneous external addons can also change it.

Incomplete or unavailable roster replies do not replace the last good snapshot. The collector requires every reported row, unique names, ranks, unchanged count and guild identity, and offline visibility. These checks cannot detect every server-side inconsistency. The first complete snapshot is a baseline, without synthetic member-add events.

## Local journal

The journal combines two labelled sources:

- Server events: invitations, joins, quits, removals, promotions and demotions. The details include the actor when provided and the relative age reported by the server, captured at receipt. The displayed receipt time is not the event's exact timestamp.
- Observations: before/after public notes, accessible officer notes and ranks compared between full snapshots. Author and exact change time are unknown. The timestamp is detection time. Rank observations and server promotion/demotion records remain distinct sources.

Changing read access is not a note edit. Multiple intervening edits cannot be reconstructed. Joining/leaving information comes from the available server log, rather than treating a missing row as a membership event.

Repeated server windows are matched by event contents, occurrence count and approximate age, accounting for relative-age drift. There is no stable server event ID; identical events near each other or long gaps can remain ambiguous. This is an officer convenience archive, not a complete audit trail.

Archives and last snapshots are separated by realm and guild name. They remain local to the installation/SavedVariables and are not synchronized between officers. A new guild page shows only that guild's data; previous archives remain retained. Guild renames create a separate archive.

The new module uses `RaidwiseDB.guild`. Old `guildManagement` and `epgp` data are not migrated or consulted; the new archive/threshold starts fresh. Existing unrelated character profiles, encounters and addon settings are unaffected.

The shared limit defaults to 1000 and accepts 100–10000 entries per guild archive. Applying a smaller limit immediately removes the oldest entries from every retained archive. The previous server window is retained separately for import matching. SavedVariables persist at normal logout/reload; a crash can lose the current session's writes.

## Validation

`tests/guild-management.test.mts` exercises real Lua 5.1 modules with mocked game APIs: permissions, Cyrillic search/alt chains, detached reads, snapshot gaps, realm/guild separation, live-index writes, all-field conflict validation, partial confirmations, rank constraints, uncertain timeouts, ageing/repeated event windows, retention, request coalescing, draft preservation, aligned/scrolled headers, raid groups 1–5, numeric sorting, base parsing, roll thresholds and real bootstrap/TOC loading of the new addon.

Run `npm run check` before delivery. Native in-client visual verification and server behavior still require testing with an ordinary member, read-only officer-note access, officer and guild master, concurrent officer edits, offline members and slow replies. No claim of in-game acceptance follows from offline mocks.
