# Gear Check catalog and profile maintenance

For owners and behavior checks use the [task map](Gear-Check-Progress.md).
The [scope decision](../adr/0003-gear-surface-assessment.md) explains how surface
appropriateness and published-list membership differ from optimization.

## Change the owning data

- Profiles/stat ranks/weapon setups: `Raidwise/GearCheckProfiles.lua`.
  Keys use WotLK talent tabs (`CLASSFILE-specTab`, e.g. `SHAMAN-2`).
  [stats-matrix.html](../../gear-check-debug/stats-matrix.html) is the maintenance
  editor/export tool; apply its Lua output to the owning profile definitions.
- Enchant IDs, gem stats/colors/meta conditions: `Raidwise/GearCheckCatalog.lua`.
  Preserve profession flags, legacy entries and explicit socket-enchant mappings.
- Trinket progression/preferred pools: `Raidwise/GearCheckTrinkets.lua`.
- Set IDs/counts: `Raidwise/GearCheckSets.lua`.
- BiS membership: generated `Raidwise/GearCheckBis.lua`; use the generator below.

For a false positive, retain the item link/ID, spec, enchant/gem IDs and observed
result in a focused behavioral fixture. Run the corresponding suite from the
map and `npm run check`; review the [revision policy](Gear-Check-Contract.md#revisions).
Collection changes also require a [client rescan](Gear-Check-Verification.md).

## Regenerate published-list membership

Run from the repository root:

```sh
node scripts/generate-gear-check-bis.js
```

The [generator](../../scripts/generate-gear-check-bis.js) reads the sibling web
repo's `../Raidwise/src/data/bis-presets/`, or `RAIDWISE_BIS_PRESETS` when set to
that folder. It unions preset item IDs by spec. Re-run when those presets change;
review the generated diff. Edit presets/input rather than the generated Lua.

## Provenance and import cautions

Historical surface research used `examples/bis-list-mix.md` (guild/RU composite)
and `examples/bis-list-sources.md` (Warmane, Circle, Icy Veins, Titans and others).
Those inputs are not present in this checkout; their old armor/weapon/trinket
matrices are not a current rules catalog. AtlasLoot extraction scripts in
`tools/` also require their optional research inputs; they are not runtime data.

Catalog seeds combined AtlasLoot research and hand-maintained enchant mappings.
The incremental 2026-09-10 comparison used the
[WoWSims gem database](https://github.com/wowsims/wotlk/blob/master/assets/database/db.json),
[stat/color schema](https://github.com/wowsims/wotlk/blob/master/proto/common.proto),
[meta conditions](https://github.com/wowsims/wotlk/blob/master/ui/core/proto_utils/gems.ts)
and [Outfitter socket-enchant mapping](https://github.com/cdmichaelb/Outfitter/blob/master/Outfitter.lua).
These are historical reference sources, not runtime dependencies or a guarantee
that current upstream data matches this client/server.

WoWSims separates spell/melee/ranged variants of hit, crit, haste and attack
power. Deduplicate equivalent variants into Raidwise's corresponding stat;
adding them together inflates values. Importing reference data must preserve
local meta requirements, profession flags, grading exceptions, legacy gems and
socket-enchant mappings. Gem recognition still needs a resolved gem item ID or
an explicit mapping; the reference database cannot make an inspect read complete.

## Unimplemented directions retained from the old plan

Finding-message RU localization, preferred per-spec enchant/gem lists, a full
allowed/forbidden meta matrix and a required-ranged-weapon rule were proposed
but are not delivered in that form. Future work needs its own scoped decision;
this list does not turn them into shipped promises. Set counts are informational;
build-aware 2pc/4pc advice belongs to the optimization boundary.
