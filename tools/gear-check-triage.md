# Gear Check triage (from raid dumps in `2.md`)

Decisions applied 2026-08-31.

## Report audit — 2026-09-08

Reviewed `____GEAR_REPORTS_TO_CHECK/1.md` through `4.md` against the current collector, catalogs, and rules. This section records analysis and proposed fixes; it does not mark them implemented. The text snapshots lack original item hyperlinks and per-socket collection provenance, so corrected final grades require a fresh scan.

### Follow-up decisions — 2026-09-08

- Implemented: Whispering Fanged Skull normal/heroic (50342/50343) belongs to the allowed physical-DPS and hunter pools, inherited by Retribution and Enhancement. It no longer triggers `TRINKET_NOT_PREFERRED`; this does not automatically make it BiS.
- Confirmed policy: Mighty Health is acceptable for healers, with +10 stats generally preferred. Major Spirit is acceptable for Holy Priest and Restoration Druid. Existing info-only lower-level notices and B qualification preserve this distinction; these enchants do not warrant C/D or bad-stat findings on those healers. No enchant ranking change was needed.
- Added regression checks for both trinket variants across physical-DPS profiles and for the healer enchant choices above. All 152 gear-check rule self-tests pass under Lua 5.1.
- Gem collector hardening remains proposed: distinguish empty, occupied-unresolved, and resolved sockets; keep raw enchant IDs separate; validate gem item identity; merge/retry each socket; never derive definite meta failure from unknown colors; invalidate cache on socket-content changes. Preserve raw links and provenance in diagnostics. Do not repair these reports by adding the bogus item IDs to the gem catalog.

| Report | Assessment |
|--------|------------|
| 1 — Мелоун, Retribution | Gem identification is unreliable. Inactive meta is not established by counting unknown colors as zero. The helmet's missing gem needs verification. Wrist missing-enchant finding is consistent with the snapshot. Hidden belt `id=15`, iLvl 0, no equipment location or stats incorrectly qualifies for A. Whispering Fanged Skull is absent from the trinket pools, producing C. |
| 2 — Тазиколивье, Fury | The only D comes from `META_NOT_META` while both helmet gems are unknown. That conclusion is unsupported. Gem names such as a staff and bracers expose identifier confusion. Four missing enchants are consistent with the snapshot; C would remain if those reads are accurate, even after removing the false D. The waist missing-gem claim needs verification. |
| 3 — Бинтоман, Holy | B is consistent with the existing policy. Chest enchant 3233 and wrist enchant 2326 are cataloged below maximum, which blocks promotion to A/S without adding soft issues. Thus `issues=0`, twelve S items, and overall B can coexist. The dump needs clearer reasons for B. This is not evidence of the gem-reading bug. |
| 4 — Санпо, Marksmanship | Unknown neck/shoulder gem IDs share the collector problem. Chest and feet C grades depend entirely on missing-gem findings derived from partial reads; neither is proven by this snapshot. The active meta is supported by the known Nightmare Tear. Ranged enchant 3608 is unmapped, but the ranged-slot rule bypasses enchant checking and still permits S. |

### 1. Gem identity fallback confuses identifier domains — high priority

`Raidwise/GearCheck.lua`, `ParseItemLinkParts` and `CollectGemsFromItemLink`: raw socket fields from the equipment hyperlink are copied directly into `gem.itemId` when no `GetItemGem` links resolve. The fallback assumes they are item IDs. The reports contain values 3518, 3519, 3525, 3446, 3549, 3550, and 3625; some resolve through `GetItemInfo` to unrelated equipment. This is consistent with socket enchant IDs being interpreted as gem item IDs. `NormalizeGem` also accepts any successful item-name lookup as known without verifying that the item is a gem.

Fix: keep socket enchant IDs separate from gem item IDs. Resolve through `GetItemGem` or a verified 3.3.5a mapping; otherwise retain an occupied but unresolved socket. Never query arbitrary item IDs or assign gem stats from unrelated equipment.

### 2. Partial gem resolution becomes a confirmed missing socket — high priority

`CollectGemsFromItemLink` only runs its fallback when **zero** gems resolve. When one of two sockets resolves, the other socket is dropped even if its raw link field is nonzero. `NormalizeItem` then sets `emptyConfirmed=true` from `layoutTotal - #gems`. `CollectGemItemIds` caches that partial result, while `EquipmentHasUncertainGems` sees no uncertainty and can end the retry cycle.

Affected claims: report 1 head; report 2 waist; report 4 chest and feet. They may be genuinely empty, but these reports cannot distinguish emptiness from a failed lookup.

Fix: collect occupancy and resolution per socket, merge results per socket, and set uncertainty whenever an occupied gem cannot resolve. Only penalize confirmed emptiness. Preserve added sockets from buckles/blacksmithing.

### 3. Unknown gems produce definite meta failures — high priority

`Raidwise/GearCheckRules.lua`, `EvaluateGems`: if no recognized meta is found and the number of gems is at least the number of meta sockets, it emits hard `META_NOT_META`. It does not establish which socket contains which gem, or whether an unknown gem is actually a meta. This explains report 2's only D.

`CountMatchingGems` / `EvaluateMetaActivation`: unknown colors contribute zero, then unmet requirements produce `META_INACTIVE`. This explains report 1's unsupported `red 0/1, yellow 0/1, blue 0/1` conclusion.

Fix: report unresolved meta identity/activation as not-checkable. Known gems may prove activation even when other colors are unknown, as in report 4; otherwise unknown data must not become a definite failure.

### 4. Hidden or non-equipment placeholder can receive A

Report 1 waist has `id=15`, name `Скрыто`, iLvl 0, category `other`, empty equipment location, and no stats. `TypeQualifiesForGood` defaults to true for this category; the remaining promotion checks do not reject it. `AverageItemLevelFromEquipment` also includes numeric zero in its average. The report's average of 247 is consistent with including this placeholder; excluding it from the shown 15 filled items yields about 265. The underlying real belt and any effect on GearScore cannot be reconstructed here.

Fix: validate that an item is checkable equipment for the slot. Keep hidden/unresolved items out of positive grading and item-level averages, and expose the incomplete measurement. Do not infer the real item from appearance.

### 5. Whispering Fanged Skull is missing from the trinket pools

`Raidwise/GearCheckTrinkets.lua` contains neither 50342 nor 50343. Consequently report 1's 50343 falls outside Retribution's allowed set and gets `TRINKET_NOT_PREFERRED`, C. This is a whitelist omission, not an analysis of its proc. A contemporary Ret player's [trinket discussion](https://retributionpaladins.com/top-7-ret-paladin-trinkets/) includes Whispering Fanged Skull among relevant choices.

Proposed correction: verify and add normal/heroic variants to appropriate physical-DPS **allowed** pools. This need not make them preferred or BiS. Do not turn an incomplete whitelist into a claim that every absent item is unsuitable.

### 6. Report 3 exposes grade-explanation and catalog limitations

`GearCheckCatalog.lua` marks Mighty Health (3233) and Major Spirit (2326) as `maxLevel=false`. `EvaluateEnchant` emits info-only findings, while `EnchantIsMaxLevel` and `CollectNotGoodEnchantSocketReasons` still block A/S. The existing triage policy deliberately softened these findings to info, not to full qualification for A.

The health enchant's `stats={}` also means the evaluator cannot judge its stat suitability. A decision about health enchants on healers is separate from whether the enchant is below maximum. Do not automatically change the Holy report to A/S merely because it has zero soft/hard issues.

### 7. Ranged enchant coverage is deliberately bypassed

`EnchantableSlot` excludes bows, guns, crossbows, and wands before reading enchant information. This follows the older triage decision below, but report 4 demonstrates the limitation: an unmapped applied ranged enhancement does not produce `ENCHANT_NOT_CHECKABLE` and does not block S. Revisit ranged scopes separately from ordinary weapon enchants, with class-aware requirements; a warrior's ranged stat stick and a hunter's ranged weapon should not automatically share the same policy.

### 8. Cache and report diagnostics need stronger provenance

`GemCacheKey` uses GUID, slot, item ID, and ordinary enchant ID; it excludes socket contents and has no expiry. Re-gemming the same item can leave stale cached data available when live gem collection fails. This is a code-level risk, not a proven event in these four reports.

For regression coverage, exercise all-gems-unresolved, partially resolved, confirmed empty, unknown meta, known active meta plus unknown colors, regemming the same item, hidden equipment, allowed progression trinkets, and report 3's intentional B. Future dumps should include original equipment links, raw socket enchant IDs, resolution source, cache use, and uncertainty/empty-confirmation flags.

## A — tooling / inspect

| Item | Decision | Status |
|------|----------|--------|ц
| SPEC_UNKNOWN clarity | Improve message; grades may be less accurate | Done |
| GEM_NOT_CHECKABLE when inspect incomplete | Keep info-only; do not grade gems | Already + incomplete cap |
| Incomplete inspect grades | Cap overall / category grades: never GOOD | Done |

## B — rule fixes

| Item | Decision | Status |
|------|----------|--------|
| Crossbow/bow/gun on melee ranged | Acceptable (thrown preferred) | Done |
| Enchant on bow/gun/crossbow/wand | Not enchantable — skip MISSING_ENCHANT | Done |
| Holy Pala shield blockValue/armor | Acceptable (not forbidden) | Done |
| Prot Pala DPS trinkets | Allowed as situational (info), include Tiny Abom | Done |

## C — keep / skip / soften

| Item | Decision | Status |
|------|----------|--------|
| Resilience PvE | Skip (leave as-is) | Skipped |
| Cloth on Holy Pala / Boom+Resto Druid / all Shaman | Acceptable | Done |
| Missing enchants (Dimazmey) | Skip re-check | Skipped |
| ENCHANT_LOWER_LEVEL | Soften to **info** (usable, not REPLACE) | Done |
| Transmog / scan vs target mismatch | Skip for now | Skipped |
| Cloth on resto/balance druids | Same as C-2 | Done |
| Spirit unwanted on resto shaman MH | Keep | Kept |
| Hit enchant on resto feet | Keep | Kept |

## Export

Raid **Export** button: fixed overwrite when opening Gear check (target) tab; EditBox `SetMaxLetters(0)` for large dumps.
