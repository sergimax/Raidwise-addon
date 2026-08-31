# Gear Check triage (from raid dumps in `2.md`)

Decisions applied 2026-08-31.

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
