# Gear Check — implementation progress

Tracks work against the Gear Check specification (`docs/RaidWise Addon — Gear Check Specification.md`).  
Statuses: **planned** · **in progress** · **done** · **blocked** · **backlog**

Update this file when a phase starts or finishes. Prefer small, testable slices.

---

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Menus | Keep **Gear check (target)** and **Gear check (raid)**; raid is empty backlog |
| Specs | Full 30 WotLK specs; UI notes that rules are **being maintained** |
| Unknown spec | Class-only rules **and** a “spec unknown” banner |
| Self-check | Yes — use player when there is no friendly player target |
| Chat reports | Self / default chat only (for now) |
| Verdicts (v1) | **OK / REPLACE / BAD** only (no GOOD yet) |
| Overall status | Worst wins; BAD/REPLACE summaries note that items have those statuses |
| Resilience (PvE) | 1 item with Resilience → overall **REPLACE**; 2+ → **BAD** |
| Catalogs | Seed from AtlasLoot lists + hand-built enchantId map; unknown IDs → **not-checkable** (no false BAD) |
| Trinkets / relics / shirt / tabard | Ignored for now; trinkets marked **planned** |
| Finding locale | English only for now (RU later) |
| Persistence / ruleset versioning | Backlog (spec §§25–27) |

---

## Phase board

| Phase | Name | Status | Notes |
|-------|------|--------|-------|
| 1 | Data collection | **done** | Target/self unit, slots, item/enchant/gem IDs, class/spec; Phase 1 dump UI |
| 2 | Normalized gear model | **done** | `schemaVersion = 2`; `types/GearCheck.ts`; dump shows stats/types/gaps |
| 3 | Rules engine | planned | Hard/soft findings; armor/stat/weapon/enchant/gem/meta |
| 4 | Item verdicts | planned | Aggregate findings → OK / REPLACE / BAD |
| 5 | Gear-level evaluation | planned | Overall status, meta activation, set counts, counters |
| 6 | UI | planned | Breakdown screens beyond Phase 1 dump |
| 7 | Chat output | planned | `/rw gearcheck` reports (summary / items / enchants / gems) |
| 8 | Ruleset expansion | planned | Verify all 30 specs; maintain continuously |
| — | Raid-wide gear check | **backlog** | Menu stub only |
| — | Saved reports | **backlog** | Spec §25 |
| — | Trinket analysis | **backlog** | Slot policy PLANNED |

---

## Phase 1 — Data collection

**Goal:** Obtain enough equipped-gear data for one player (target or self) to drive later phases. No suitability rules.

**Status: done** (2026-08-24)

### Checklist

- [x] Progress doc (this file)
- [x] Resolve scan unit (player target if player; else self)
- [x] Class + primary spec (inspect when needed; mark unknown)
- [x] Slot policy: CHECKED / IGNORED / PLANNED
- [x] Per checked slot: item id, link, name, ilvl (informational), enchant id, gem item ids, meta gem id if present
- [x] Relic in ranged slot detected and treated as ignored (not evaluated later)
- [x] Phase 1 dump visible on **Gear check (target)** for manual testing
- [x] `/rw gearcheck` opens that tab and runs a scan

### How to test

1. `/reload`, then `/rw gearcheck` (or open **Gear check (target)** and press **Scan**).
2. **Self:** clear target → scan → dump shows your name, class, spec, equipped slots with enchant/gem ids.
3. **Other player:** target a nearby inspectable player → scan → after inspect, dump fills (may take a moment).
4. Confirm trinkets / shirt / tabard appear as planned/ignored, not as checked gear lines.
5. Confirm empty slots are listed as empty (not invented items).

### Out of scope this phase

Rules, verdicts, chat report modes, set-bonus logic, socket-bonus matching, BiS.

### Implemented files

- `Raidwise/GearCheck.lua` — collector + inspect retries + Phase 1 dump formatter
- `Raidwise/PageGearCheckTarget.lua` — Scan / Select all / copy box (`LAYOUT_VERSION = 2`)
- Slash: `/rw gearcheck` or `/raidwise gearcheck`

---

## Phase 2 — Normalized gear model

**Goal:** Freeze the internal table shape used by the rules engine (no WoW API calls inside rules).

**Status: done** (2026-08-24)

### Checklist

- [x] Document field list (`types/GearCheck.ts` + this section)
- [x] Collector returns only that shape (`schemaVersion = 2`)
- [x] Unknown / missing data explicit (`gaps[]` + `known` flags); never fake BAD
- [x] Dump shows category / armorType / weaponType / stats / sockets / enchant / gems / gaps

### Model (rules-facing)

```text
GearCheckReport
  schemaVersion = 2
  character { unit, isSelf, name, classFile, specTab, specKnown, gaps[] }
  equipment[]  (stable slot order)
    slot { key, slotName, policy CHECKED|IGNORED|PLANNED, policyNote?, empty, item?, gaps[] }
      item {
        itemId, name?, equipLoc?, category, armorType?, weaponType?, isRelic,
        stats{}, sockets{}, enchant{ enchantId, present, known, gaps[] },
        gems[], metaGemId?, infoKnown, pendingLink, gaps[]
      }
  gaps[]
  collection { … inspect / counts — not for rules }
```

- Stat ids: `strength`, `agility`, `stamina`, `intellect`, `spirit`, ratings, `spellPower`, `resilience`, `armor`, …
- Armor types: `cloth` / `leather` / `mail` / `plate` / `shield` / `offhand` / …
- Weapon types: `axe1h`, `sword2h`, `staff`, …
- Enchant with id but no catalog yet → `known = false` + gap `ENCHANT_UNMAPPED`
- `itemLevel` is collected for display only

### How to test

1. `/reload`, `/rw gearcheck` (self and nearby target).
2. Dump header shows `schemaVersion=2`.
3. Filled slots show `category`, `armorType` or `weaponType`, `stats: …`, `sockets: …`, `enchant: id=… present=… known=…`.
4. Enchanted items show `enchantGaps: ENCHANT_UNMAPPED` until Phase 3 catalogs.
5. Trinkets remain `PLANNED`; shirt/tabard `IGNORED`; relics `IGNORED / relic`.

### Implemented files

- `Raidwise/GearCheck.lua` — normalize + Phase 2 dump
- `types/GearCheck.ts` — TypeScript shape for consumers / fixtures
- UI copy updated for Phase 2 dump wording

---

## Phase 3 — Rules engine

**Goal:** Findings only (`code`, severity, category, slot, message). Seed catalogs from AtlasLoot + enchantId map.

### How to test

Known bad fixtures (cloth on prot warrior, resilience ring, missing chest enchant) produce expected finding codes.

---

## Phase 4 — Item verdicts

**Goal:** Per-slot OK / REPLACE / BAD from findings (no GOOD yet).

### How to test

Same fixtures; each slot shows verdict + explainable findings.

---

## Phase 5 — Gear-level evaluation

**Goal:** Overall status (worst wins), resilience 1→REPLACE / 2+→BAD, meta activation across full set, informational set counts (T9/T10…).

### How to test

Multi-slot resilience cases; meta with missing blue gems; set line like `T10: 4/5` does not change verdicts.

---

## Phase 6 — UI

**Goal:** Proper Gear Check screen (summary + item/enchant/gem breakdown + surface-level disclaimer). Phase 1 dump can be removed or moved behind a debug toggle.

### How to test

Walk target/self flows in-game; language switch keeps chrome working (findings stay EN).

---

## Phase 7 — Chat output

**Goal:** Print summary / items / enchants / gems to self chat.

### How to test

Buttons or `/rw gearcheck …` variants; messages appear only for you.

---

## Phase 8 — Ruleset expansion

**Goal:** All 30 specs covered; keep “being maintained” copy accurate.

### How to test

Spot-check one tank / one melee / one caster / one healer after each ruleset edit.

---

## File map (expected)

| File | Role |
|------|------|
| `Raidwise/GearCheck.lua` | Collector, normalize (`schemaVersion` 2), scan orchestration, dump |
| `types/GearCheck.ts` | Frozen TypeScript shape for the normalized report |
| `Raidwise/PageGearCheckTarget.lua` | Target/self UI |
| `Raidwise/PageGearCheckRaid.lua` | Backlog stub |
| `Raidwise/GearCheckRules*.lua` | Later: profiles + catalogs (names TBD) |
| `docs/Gear-Check-Progress.md` | This tracker |
| `docs/RaidWise Addon — Gear Check Specification.md` | Product spec |

Do **not** auto-persist scans (spec §25).
