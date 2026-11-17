# Defer profile exchange until a new contract exists

The character redesign decisions of 2026-10-29/30 deferred profile exchange and external Karma.
The retired `RaidwiseProfiles` v1 format lacks explicit opinion authorship and event context, and its preview/apply paths make different choices; re-enabling it would not implement the agreed model.
Future exchange selects one incoming version rather than automatically merging opinions, and separates sender, version author and event author.
[Synchronization.md](../characters/Synchronization.md) retains the future constraints and unresolved questions; the retired format and Karma scale are not promises of compatibility for a future service.
