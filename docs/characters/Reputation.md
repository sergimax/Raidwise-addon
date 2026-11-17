# Character-system task map

Start here for character/profile work. Search the named entry point before reading
its helpers. Paths below are relative to `Raidwise/`; tests are in `tests/`.
The active load order is [Raidwise.toc](../../Raidwise/Raidwise.toc).

| Change | Owner / entry point | Behavior checks |
|---|---|---|
| Save, autosave, retry, close or reload edits | `ProfileEditor.lua`: `SaveProfileEditor`, `TickProfileEditor`, `CloseProfileEditor`; `PlayerRecords.lua`: `CommitPlayerRecordDraft` | [profile-window](../../tests/profile-window.test.mts), [player-records](../../tests/player-records.test.mts) |
| Profile fields, event catalog, authorship or validation | `PlayerRecords.lua`: `CreatePlayerRecordDraft`, `AddPlayerRecordDraftEvent`, `CommitPlayerRecordDraft`; `PlayerRecordSupport.lua` | [player-records](../../tests/player-records.test.mts) |
| Identity lookup, rename or name-to-GUID upgrade | `PlayerRecords.lua`: `UpsertPlayerRecordIdentity`, `FindPlayerRecordIdentities`; `PlayerRecordBridge.lua`: `GetHistoryEntry` | [player-records](../../tests/player-records.test.mts), [opinion-display](../../tests/opinion-display.test.mts) |
| Link characters or delete profile data | `PlayerRecordLinks.lua`: `LinkPlayerCharacters`, `DeleteCharacterDatabaseRecords`; `ProfileCharacters.lua` | [player-links](../../tests/player-links.test.mts), [profile-window](../../tests/profile-window.test.mts), [database-page](../../tests/database-page.test.mts) |
| Record meetings, count sessions or prune details | `PlayerEncounters.lua`: `RecordCurrentGroupHistory`, `GetCharacterMeetingStats`, `PruneCharacterEncounters`; `RosterRefresh.lua` supplies roster observations | [encounters](../../tests/encounters.test.mts), [roster-refresh](../../tests/roster-refresh.test.mts) |
| Database / recent-history membership, filters or sorting | `PlayerEncounters.lua`: `BuildHistoryRoster`; `PageHistory.lua` | [database-page](../../tests/database-page.test.mts), [encounters](../../tests/encounters.test.mts) |
| Profile window or journal pagination | `ProfileWindow.lua`; `PlayerRecords.lua`: `GetPlayerRecordChangePage` | [profile-window](../../tests/profile-window.test.mts), [player-records](../../tests/player-records.test.mts) |
| Opinion marks, chat or tooltips | `RatingPresentation.lua`, `UnitTooltips.lua`, `ClassicOpinionMarkers.lua` | [opinion-display](../../tests/opinion-display.test.mts), [classic-opinion](../../tests/classic-opinion.test.mts) |
| Load, quarantine or repair saved records | `PlayerRecords.lua`: `InitializePlayerRecords`, `GetPlayerRecordHealth`, `RestorePlayerRecordEntry`; `PlayerRecordBridge.lua`: `InitializeHistoryStore` | [player-records](../../tests/player-records.test.mts), [architecture](../../tests/architecture.test.mts) |

Read [storage constraints and repair](Character-System-Contract.md) when changing
persistence or repairing SavedVariables. Reasons for the realm scope are in
[ADR 0001](../adr/0001-character-realm-scope.md).
For geometry use [UI views](../ui/UI-Views.md) and [sizes](../ui/UI-Sizes.md);
for commands and selecting checks use [tests/README.md](../../tests/README.md).
[Manual checks and dated evidence](Character-System-Verification.md) cover what
the offline harness cannot establish.

## Compatibility boundaries

The active core deliberately does not import retired profile/exchange data; [storage constraints](Character-System-Contract.md) describe that boundary.
[architecture tests](../../tests/architecture.test.mts) exercise current read, activation, target-addition and identity-upgrade APIs.
Linking/deletion and observer-specific meetings use [player-links](../../tests/player-links.test.mts) and [encounters](../../tests/encounters.test.mts).
For a future exchange/Karma design start with [Synchronization.md](Synchronization.md).
