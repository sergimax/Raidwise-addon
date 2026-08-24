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
| Verdicts | **OK / GOOD / REPLACE / BAD** (GOOD = highly appropriate, not BiS) |
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
| 3 | Rules engine | **done** | Hard/soft/info findings; catalogs + 30-spec profiles; `/rw gearcheck test` |
| 4 | Item verdicts | **done** | Per-slot OK / GOOD / REPLACE / BAD from findings (info ≠ BAD) |
| 5 | Gear-level evaluation | **done** | Overall worst-wins; resilience 1/2+; meta activation; T9/T10 counts |
| 6 | UI | **done** | Summary + Items/Enchants/Gems filters; dump behind Debug |
| 7 | Chat output | **done** | Self-chat summary/items/enchants/gems; UI + slash |
| 8 | Ruleset expansion | **done** | Enh intellect; gem not-checkable policy; leg/Engi/weapon catalogs |
| — | Raid-wide gear check | **backlog** | Menu stub only |
| — | Saved reports | **backlog** | Spec §25 |
| — | Trinket analysis | **backlog** | Slot policy PLANNED |
| — | Catalog / profile false positives | **backlog** | New reports after Phase 8 polish (Rhee items addressed) |

---

## Incomplete / remaining work

Features from the spec or locked decisions that are **not done** yet (or only partial). Use this as the leftover checklist.

### Product backlog

| Item | Spec / notes |
|------|----------------|
| Raid-wide gear check | Menu stub only (`PageGearCheckRaid.lua`) |
| Trinket analysis | Slots marked **PLANNED**; not evaluated |
| Saved reports | Spec §25 — manual save, ~14-day retention; no auto-persist |
| Ruleset versioning | Spec §26 — with saved reports |
| Data versioning | Spec §27 — with saved reports |
| Finding messages in RU | Chrome localized; finding `message` strings EN only |

### Spec in-scope, only partial

| Item | Spec | Current state |
|------|------|----------------|
| Weapon combinations | §12 | Weapon **type** ranks only; no MH/OH combo (1H+1H vs 2H), hand-usage, or “must have ranged” checks |
| Preferred / allowed enchants | §13, §19 | Catalog `maxLevel` + bad-stat checks; no per-spec preferred enchant lists |
| Preferred / allowed gems | §14, §19 | Same for gems (beyond `metaPreferred`) |
| Meta allowed / forbidden set | §16 | Soft `META_NOT_PREFERRED` vs profile list; not a full allowed/forbidden matrix |
| Set 2pc / 4pc milestones | §17 | Informational **T9/T10 X/5** counts only |
| Slot policy naming | §9 | Spec `UNSUPPORTED`; addon uses **PLANNED** for trinkets |
| Unknown / not-checkable UI | §8 | Info findings exist; All-filter hides pure info → easy to miss “cannot evaluate” |
| Catalog / profile completeness | Phase 8 | Seeded + “being maintained”; expand on false-positive reports |

### Explicitly out of scope (do not treat as incomplete)

BiS / stat weights / socket-bonus optimization / build-specific gearing / 2pc vs 4pc advice / ilvl scoring / auto history / web-style optimization (spec §§4, 15, 28).

---

## Known false positives / ruleset gaps

Observed on **Rhee (Enhancement Shaman)** during Phase 3; addressed in **Phase 8**. Keep this section for future reports.

| Area | Status | Notes |
|------|--------|-------|
| Gems epic → `GEM_LOWER_LEVEL` | **fixed** | Unknown gems are `GEM_NOT_CHECKABLE` (info); expanded ICC epic purple/orange/green seeds |
| Enhancement intellect discouraged | **fixed** | `S_ENHANCE` prefers intellect |
| LW / Tailoring leg kits | **fixed** | Frosthide/Icescale/Nerubian/Jormungar + spellthread ids |
| Engineering feet/hands | **fixed** | Nitro / Hyperspeed / Pyro Rocket / Flexweave / Frag Belt |
| Weapon enchants unknown | **fixed** | Mongoose, Executioner, Black Magic, Accuracy, Blade Ward, Blood Draining, … |

**Policy reminder:** unknown catalog ids stay **not-checkable** (info), never false **BAD**. Report new false REPLACE cases here for catalog/profile edits.

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
4. Catalogued enchants show `known=yes` (no `ENCHANT_UNMAPPED`); unknown ids stay not-checkable.
5. Trinkets remain `PLANNED`; shirt/tabard `IGNORED`; relics `IGNORED / relic`.

### Implemented files

- `Raidwise/GearCheck.lua` — normalize + Phase 2 dump
- `types/GearCheck.ts` — TypeScript shape for consumers / fixtures
- UI copy updated for Phase 2 dump wording

---

## Phase 3 — Rules engine

**Goal:** Findings only (`code`, severity, category, slot, message). Seed catalogs from AtlasLoot + enchantId map.

**Status: done** (2026-08-24)

### Checklist

- [x] Enchant / gem seed catalogs (`GearCheckCatalog.lua`)
- [x] Class + 30-spec profiles (`GearCheckProfiles.lua`)
- [x] Rules engine emits findings only (`GearCheckRules.lua`) — no OK/REPLACE/BAD
- [x] Evaluate after collect; dump prints `Findings (N):`
- [x] Catalogued enchant ids mark `known = true` (clears `ENCHANT_UNMAPPED`)
- [x] Cloaks / jewelry skip armor-type rules
- [x] Offline fixtures: `/rw gearcheck test`
- [x] `types/GearCheck.ts` findings + profile types

### Finding shape

```text
{ code, severity: hard|soft|info, category, slot?, message }  -- message EN only
```

Common codes: `ARMOR_FORBIDDEN`, `STAT_FORBIDDEN`, `RESILIENCE_PVE`, `MISSING_ENCHANT`, `ENCHANT_NOT_CHECKABLE`, `GEM_LOWER_LEVEL`, `SPEC_UNKNOWN`, …

### How to test

1. `/reload`, then `/rw gearcheck test` → expect **4 / 4 passed**.
2. `/rw gearcheck` (self) → dump ends with `Findings (N):` and profile line.
3. Cloth on a plate tank (or fixture) → `ARMOR_FORBIDDEN`; resilience gear → `RESILIENCE_PVE`.

### Out of scope this phase

Item verdicts, overall status, chat report modes, meta activation across full set.

### Implemented files

- `Raidwise/GearCheckCatalog.lua` — enchantId / gem itemId seeds
- `Raidwise/GearCheckProfiles.lua` — class fallbacks + 30 specs
- `Raidwise/GearCheckRules.lua` — `EvaluateGearCheck` + `GearCheckRulesSelfTest`
- `Raidwise/GearCheck.lua` — attach findings; Phase 3 dump
- TOC loads Catalog → Profiles → Rules → GearCheck

---

## Phase 4 — Item verdicts

**Goal:** Per-slot OK / REPLACE / BAD from findings (no GOOD yet).

**Status: done** (2026-08-24)

### Checklist

- [x] Aggregate findings → slot `verdict` (`AggregateGearCheckVerdicts`)
- [x] hard → **BAD**; soft → **REPLACE**; clean preferred + max enchant/gems → **GOOD**; else **OK** (info ≠ BAD)
- [x] Dump shows `verdict=` per filled checked slot + `Item verdicts: GOOD=… OK=… REPLACE=… BAD=…`
- [x] Self-test covers verdicts (`/rw gearcheck test`)
- [x] Types: `GearCheckItemVerdict`, `verdicts` summary

### Aggregation

```text
any hard finding on slot  → BAD
else any soft finding     → REPLACE
else preferred type + max-level enchant (if required) + max-level gems → GOOD
else                      → OK   (info-only / not-checkable / acceptable type do not demote)
IGNORED / PLANNED / empty → no verdict (counted as skipped)
```

Overall gear status is **Phase 5** (worst-wins + resilience counts; all-GOOD → overall GOOD).

### How to test

1. `/rw gearcheck test` → all checks pass (findings + verdicts).
2. `/rw gearcheck` → each filled checked slot shows `verdict=OK|REPLACE|BAD`.
3. Same fixtures: cloth/prot → BAD; resilience → REPLACE; missing enchant → REPLACE; SP/fury → BAD.

### Out of scope this phase

Overall status, meta activation across full set, chat reports, catalog false-positive fixes (see backlog).

---

## Phase 5 — Gear-level evaluation

**Goal:** Overall status (worst wins), resilience 1→REPLACE / 2+→BAD, meta activation across full set, informational set counts (T9/T10…).

**Status: done** (2026-08-24)

### Checklist

- [x] Overall status from item verdicts + findings (worst wins)
- [x] Resilience: 1 unique item → overall at least REPLACE; 2+ → overall **BAD**
- [x] Meta activation vs full-set gem colors (`META_INACTIVE` / `META_NOT_CHECKABLE`)
- [x] Issue counters: items / enchants / gems / meta
- [x] T9/T10 set counts informational only (do not change verdicts)
- [x] Dump shows Overall / Issues / Meta / Sets
- [x] Self-test covers resilience pair, meta blues, T10 4/5

### Overall

```text
any BAD item (or hard finding)     → BAD
else any REPLACE item (or soft)    → REPLACE
else                               → OK
then: resilienceItems >= 2         → BAD
      resilienceItems == 1 and OK  → REPLACE
```

Set lines like `T10: 4/5` never change OK/REPLACE/BAD.

### How to test

1. `/rw gearcheck test` — includes two-ring resilience → overall BAD; Chaotic without blues → `META_INACTIVE`; two blues → active; T10 4/5.
2. `/rw gearcheck` — header shows `Overall: …` and optional `Sets (informational):`.

### Out of scope this phase

Chat reports, real UI breakdown, catalog false-positive fixes (see backlog). Socket-bonus matching. 2pc vs 4pc advice.

---

## Phase 6 — UI

**Goal:** Proper Gear Check screen (summary + item/enchant/gem breakdown + surface-level disclaimer). Phase 1 dump can be removed or moved behind a debug toggle.

**Status: done** (2026-08-24)

### Checklist

- [x] Surface-level disclaimer stays visible
- [x] Summary band: Overall, who/class/spec, issue counts, meta, sets
- [x] Filters: All / Items / Enchants / Gems with explainable findings per slot
- [x] Verdict coloring: BAD red, REPLACE gold, OK idle
- [x] Raw dump moved behind **Debug** (Select all works in Debug)
- [x] `LAYOUT_VERSION = 3`
- [x] Locale chrome (findings messages stay EN)

### How to test

1. `/reload`, `/rw gearcheck` — summary + breakdown (not the dump).
2. Switch All / Items / Enchants / Gems; empty category shows “No issues…”.
3. **Debug** → raw Phase 5 dump + Select all; toggle off returns to UI.
4. Switch language in Settings — chrome translates; finding text stays English.

### Out of scope this phase

Chat print buttons / `/rw gearcheck summary|items|…` (Phase 7). Catalog false-positive fixes.

---

## Phase 7 — Chat output

**Goal:** Print summary / items / enchants / gems to self chat.

**Status: done** (2026-08-24)

### Checklist

- [x] Self-only chat (`DEFAULT_CHAT_FRAME`, `[GearCheck]` prefix — never raid/party)
- [x] Modes: summary / items / enchants / gems
- [x] UI buttons: Report summary / items / enchants / gems
- [x] Slash: `/rw gearcheck summary|items|enchants|gems` (alias `report` → summary)
- [x] Scans first when no cached report
- [x] Detail lines capped (15) with “… and N more”
- [x] `LAYOUT_VERSION = 4`

### How to test

1. Scan someone, then press **Report summary** — only you see `[GearCheck] Name — STATUS`.
2. **Report items / enchants / gems** — category lines only; empty category says so.
3. `/rw gearcheck summary` (and items/enchants/gems) without prior scan — scans then prints.
4. Confirm nothing is sent to raid/party chat.

### Out of scope this phase

Catalog false-positive fixes; Phase 8 ruleset polish.

---

## Phase 8 — Ruleset expansion

**Goal:** All 30 specs covered; keep “being maintained” copy accurate; fix known false positives.

**Status: done** (2026-08-24)

### Checklist

- [x] Confirm 30 spec + 10 class profiles (`GetGearCheckProfileCount` = 40)
- [x] Enhancement: `S_ENHANCE` prefers intellect (Rhee false positive)
- [x] Gems: unknown → `GEM_NOT_CHECKABLE` only; expand ICC epic purple/orange/green seeds
- [x] Legs: Frosthide / Icescale / Nerubian / Jormungar / spellthread ids
- [x] Engineering: Nitro, Hyperspeed, Pyro Rocket, Flexweave, Frag Belt
- [x] Weapons: Mongoose, Executioner, Black Magic, Accuracy, Blade Ward, Blood Draining, …
- [x] Optional enchants (rings / waist): evaluate when present, never MISSING
- [x] Self-test covers Enh intellect, unknown gem, Nitro, Icescale, profile count

### How to test

1. `/rw gearcheck test` — all checks pass (incl. Phase 8 fixtures).
2. Scan **Rhee** (Enhancement): intellect should not be discouraged; epic gems / Icescale / Nitro should not soft-REPLACE for level.
3. Spot-check one tank / caster / healer if editing profiles later.

UI copy still says rules are **being maintained** — catalogs remain expandable when new ids appear.

---

## File map (expected)

| File | Role |
|------|------|
| `Raidwise/GearCheck.lua` | Collector, normalize (`schemaVersion` 2), evaluate hook, dump |
| `Raidwise/GearCheckCatalog.lua` | Enchant / gem seed catalogs |
| `Raidwise/GearCheckSets.lua` | T9/T10 item-id → set key (informational) |
| `Raidwise/GearCheckProfiles.lua` | Class + 30-spec rule profiles |
| `Raidwise/GearCheckRules.lua` | Findings engine + offline self-test |
| `types/GearCheck.ts` | Frozen TypeScript shape (report + findings) |
| `Raidwise/PageGearCheckTarget.lua` | Target/self UI |
| `Raidwise/PageGearCheckRaid.lua` | Backlog stub |
| `docs/Gear-Check-Progress.md` | This tracker |
| `docs/RaidWise Addon — Gear Check Specification.md` | Product spec |

Do **not** auto-persist scans (spec §25).
