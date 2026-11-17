# Guild external limits and data interpretation

Use the [task map](Guild-Management.md) for executable behavior and tests.
The note grammar and calculations live in `GuildRosterParser.lua`,
`GuildRosterLinks.lua` and `GuildEPGP.lua`; display geometry belongs to UI docs.

## Officer actions and shared client state

- Read permission for officer notes is independent of edit permission. Losing
  access hides notes, note-search matches, balances and journal details; it does
  not erase or encrypt officer information already stored in SavedVariables.
- Actions depend on current guild identity, permissions, rank hierarchy and
  original values. Resolve the recipient's current roster index by name at send
  time; a sorted UI row is not a stable API index.
- Public/officer-note writes are separate game commands, not an atomic
  transaction. Expected values in a fresh full roster confirm the operation;
  a partial result or timeout is uncertain. There is no automatic resend.
  Refresh/read the result before retrying, to avoid repeating a successful action.
- Editors match the stock 31-character UI limit. This is not a verified server
  byte limit. Server-specific rank/note enforcement needs client testing.
- Offline-member visibility is a shared game setting. Collection temporarily
  enables it and restores the previous value on close; other addons can change
  that same setting. A complete validated snapshot reduces partial-read errors,
  but cannot establish that the server's rows form a perfectly consistent view.

## Journal and persistence

Server events and snapshot observations are distinct sources. A server record
provides relative age captured at receipt; its displayed receipt time is not the
exact event timestamp. Note/rank observations record detection time, with unknown
author. Permission changes are not note edits, and missing rows alone are not
membership events. Intermediate edits between observations cannot be reconstructed.

The server supplies no stable event ID. Matching contents, occurrence counts and
approximate age avoids many repeats but cannot guarantee exact deduplication of
near-identical events or recovery after long gaps. This local convenience archive
is not a complete audit trail or synchronized officer history.

Archives use realm and guild name, without a server ID; identical realm/guild
names on independent servers are not distinguished. A renamed guild starts a
separate archive. Prior guild archives remain local. Reducing the shared journal
limit removes old entries from every retained archive; read the new limit before
applying it. The previous server-event window is stored separately for matching.
SavedVariables writes depend on normal client persistence; crashes can lose the
session's updates. Retired stores are not imported automatically.

## EPGP inputs

Guild information is read-only input. `@BASE_GP` is interpreted only within the
paired `-EPGP-` block; default/invalid/zero cases are defined by `ParseGuildInfo`
and covered in [guild-management tests](../../tests/guild-management.test.mts).
There is no manual base override or write-back of guild policy.
The local EP threshold changes displayed roll eligibility, independently of PR,
`@MIN_EP` and the game's `/roll`; it does not assign loot or change balances.

## Historical API research

The 2026-11-16 feasibility review consulted mirrors of the 3.3.5 stock UI:
[FriendsFrame.lua](https://github.com/wowgaming/3.3.5-interface-files/blob/main/FriendsFrame.lua),
[FriendsFrame.xml](https://github.com/wowgaming/3.3.5-interface-files/blob/main/FriendsFrame.xml)
and [StaticPopup.lua](https://github.com/wowgaming/3.3.5-interface-files/blob/main/StaticPopup.lua#L1997-L2060).
These explain the API/editor choices; they are not acceptance evidence for a
particular private server. Use the [manual matrix](Guild-Management-Verification.md).
