# Profile exchange — deferred

Profile exchange is disabled in the current addon: no transport registration,
receive/send requests, profile export, Share menus, Import or Reputation pages.
Gear/currency/lockout export is a separate feature and remains available.
Global Karma and its loader are also disabled; there is no mock fallback.

The old modules remain outside the TOC for historical tests. They are not an
active supported exchange contract. Their original behavior and audit are in
[baseline](Character-System-Baseline.md) and [redesign decisions](Character-System-Redesign.md).

Future work requires explicit author/subject identity, immutable event context,
selection of one incoming version, and a shared review/apply plan. Private Notes
must remain local. External Karma calculation and import are separate future work.
See [implementation plan](Character-System-Implementation-Plan.md).
