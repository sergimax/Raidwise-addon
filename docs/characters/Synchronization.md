# Deferred profile exchange and Karma

No profile transport, import/export pages, Share menu or Karma loader is active.
Gear/currency/lockout exports are separate. The reason for deferral is recorded in
[ADR 0002](../adr/0002-deferred-profile-exchange.md).

## Before designing a replacement

These are retained future-design constraints, not shipped behavior:

- Select one incoming version. Accepting it retains its author; substantive
  editing transfers responsibility to the current character. Sender, opinion
  author and event author are distinct roles. Event context must be preserved.
- Private Notes remain local: exchange cannot transmit or overwrite them, and
  editing only a Note does not transfer opinion authorship.
- Preview and apply must use the same decision plan. Partial payloads, forwarding
  third-party versions, provenance/trust, repeat imports and conflicts still need
  explicit design.
- Karma is intended as an externally aggregated result of personal opinions.
  Formula, scale, format, identity, freshness and migration are undecided.
  `RaidwiseKarma` v1 and its 0–100 scale are historical; missing data must not be
  replaced with demonstration values.

## Active boundary checks

[player-records.test.mts](../../tests/player-records.test.mts) guards exclusion of retired modules from the TOC and the absence of active exchange entry points.
[architecture.test.mts](../../tests/architecture.test.mts) checks current bootstrap and explicit activation without importing retired reviews.
New exchange work needs the replacement design above; start active character changes at the [task map](Reputation.md).
