# Character storage constraints and repair

For owners, entry points and behavior tests use the [task map](Reputation.md).
The executable storage shape, validation and migrations belong to
[PlayerRecords.lua](../../Raidwise/PlayerRecords.lua); compatibility behavior is
checked by [player-records.test.mts](../../tests/player-records.test.mts).
This document retains external limits and the maintenance procedure, rather than
another field catalog or screen specification.

## Storage limits

- Supported scope is one realm per SavedVariables dataset, including GUID-keyed
  Gear Check reports. Different servers with the same realm name cannot be
  distinguished. Previously mixed data is not automatically separated.
  Multi-realm/server support needs a server identity and coordinated migration
  of all references, including reports and recovery archives. See
  [the scope decision](../adr/0001-character-realm-scope.md).
- Profile and private Note are shared across one's own characters; encounter
  statistics are observer/subject-specific. Linking characters does not establish
  a real-world identity or merge their opinions. Event time/place are recorded
  context, not independent proof of a claim.
- A successful save updates SavedVariables in memory. It does not guarantee an
  immediate disk write by the WoW client. The new local store does not import
  retired profile/exchange data. Profile exchange is [deferred](Synchronization.md).
- Meeting counters are approximate lifetime observations, not an exact attendance
  ledger. Expiry of detailed meetings does not reset them. Profile deletion is
  not a full privacy purge: identities, meeting counters/details and quarantine
  originals remain. The UI has no complete reset of these stores.
- Journal v2 stores event deltas to avoid duplicating full event arrays on each
  save. Downgrading to code that cannot read v2 is not a supported migration.
- Total SavedVariables size is not bounded: identities, lifetime counters,
  profiles and journals can grow. Quarantine has no automatic expiry and can
  contain information already deleted from an active profile.

## Repairing quarantined records

Use `GetPlayerRecordHealth()` and `/rw diagnose` for content-free status.
Unknown root/schema/journal formats remain unavailable and are not overwritten
with an empty database. Repairing individual records cannot bypass that block;
use a compatible addon version or a SavedVariables backup for root recovery.
Validation occurs on loading, not continuously after arbitrary direct writes.

1. Back up SavedVariables. Select the entry by metadata in
   `playerRecords.quarantine.entries`; preserve its original `value`.
2. Prepare a separate corrected component table using the validator for its
   `section` in `PlayerRecords.lua`. Call
   `Raidwise:RestorePlayerRecordEntry(index, replacement)` from maintenance Lua.
   `index` is the archive index, not a character GUID. A Note replacement, for
   example, is `{text="recovered text", revision=1, updatedAt=time()}`.
3. `INVALID_REPAIR` leaves archive/live data unchanged. `REPAIR_CONFLICT` means
   the live target is occupied; repair does not merge or overwrite it. Restore
   counters before dependent meetings and identities before dependent groups.
4. On success the method returns `true`, stores a detached replacement, marks
   the archive entry `restored=true` and retains its original `value`. A v1
   journal is converted before restoration. Old drafts are invalidated: reopen
   the profile, check `/rw diagnose`, then verify persistence after `/reload`.

The procedure is covered on synthetic Lua records by
[player-records.test.mts](../../tests/player-records.test.mts); it is not evidence
of recovery from a particular user's live corrupted SavedVariables file.
