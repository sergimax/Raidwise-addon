# RaidWise Addon — Gear Check

## 1. Goal

Add a **Gear Check** feature to the RaidWise WoW 3.3.5a addon.

The feature provides a rule-based, surface-level evaluation of a targeted player's equipped gear.

The purpose is to identify obvious gear problems for the player's class and specialization without attempting to determine BiS gear, optimize a specific build, or calculate detailed stat weights.

The Gear Check is intentionally designed for **WoW WotLK 3.3.5a** only.

---

# 2. User Flow

Initial use case: **one-player scan**.

1. User targets another player.
2. User opens the RaidWise addon.
3. User opens the **Gear Check** view.
4. The addon obtains the target's equipped gear.
5. The addon obtains:
   - item information;
   - gems in sockets;
   - enchants;
   - class;
   - specialization, where available.
6. The addon evaluates the gear against the applicable class/spec ruleset.
7. The addon displays the analysis.
8. The user can print:
   - the overall summary;
   - item warnings;
   - enchant warnings;
   - gem warnings.

Slash command:

```text
/rw gearcheck
```

The command should open or navigate to the Gear Check view for the current target.

---

# 3. Scope

## 3.1 In Scope

The first implementation must evaluate:

### Item compatibility

- class/spec compatibility;
- armor type;
- weapon type;
- weapon hand usage where applicable;
- main stats;
- secondary stats;
- obviously inappropriate stats;
- PvP-oriented stats such as Resilience;
- inappropriate itemization for the specialization.

### Enchants

- missing enchant;
- invalid/incompatible enchant;
- inappropriate stat enchant;
- lower-level enchant;
- maximum-level enchant.

### Gems

- missing gem;
- incompatible gem;
- inappropriate stat gem;
- lower-level gem;
- maximum-level gem.

### Meta gems

- whether the meta gem is compatible with the class/spec;
- whether the meta gem is active;
- whether its activation requirements are satisfied by the complete equipped gear set.

### Set information

Display set-piece counts such as:

```text
T10: 4/5 equipped
T9: 2/5 equipped
```

This information is purely informational.

It must not affect the item verdict.

---

# 4. Explicitly Out of Scope

The first version must NOT attempt to perform:

- BiS evaluation;
- BiS list comparison;
- build-specific evaluation;
- detailed stat-weight calculations;
- gear optimization;
- automatic replacement recommendations;
- socket-bonus optimization;
- encounter-specific optimization;
- item-level-based quality scoring;
- complete gear simulation;
- automatic gear history;
- automatic report persistence.

The Gear Check is a **surface-level rule-based evaluation**.

Display this limitation in the Gear Check UI:

> **Gear Check is a surface-level evaluation. It does not consider BiS lists, specific gear builds, encounter requirements, or detailed stat weights.**

---

# 5. Item Verdicts

Each checked item can receive one of four verdicts:

```text
BAD
REPLACE
OK
GOOD
```

## BAD

The item has a significant compatibility problem or violates a hard rule.

Examples:

- clearly inappropriate armor type;
- forbidden stat combination;
- incompatible weapon type;
- obviously unsuitable itemization.

## REPLACE

The item is usable but has an obvious problem or is clearly not the preferred choice.

Examples:

- acceptable but unwanted armor type;
- valid item with a significant itemization issue;
- lower-quality enchant;
- other correctable soft issue.

## OK

The item is appropriate for the specialization and has no significant obvious problem.

## GOOD

Definition:

> **Item is highly appropriate for the specialization and requires no obvious correction.**

`GOOD` does NOT mean:

- BiS;
- mathematically optimal;
- best item for every build;
- best item for every encounter.

---

# 6. Finding-Based Evaluation

Do not implement the item verdict as a collection of hardcoded `BAD / REPLACE / OK / GOOD` conditions.

Instead, each check should produce structured findings.

Conceptually:

```ts
type Finding = {
    code: string;
    severity: FindingSeverity;
    category: FindingCategory;
    slot: EquipmentSlot;
    message: string;
};
```

The exact implementation is left to the existing addon architecture.

The important requirement is that:

**rules produce findings; findings are then aggregated into an item verdict.**

This makes the system extensible and allows the same findings to be used by:

- addon UI;
- chat output;
- summary;
- future web analysis.

---

# 7. Hard vs Soft Rules

Rules should distinguish between hard and soft violations.

## Hard violation

A hard violation indicates that the item is fundamentally inappropriate.

Examples:

- forbidden armor type;
- forbidden weapon type;
- clearly inappropriate stat;
- PvP-only stat where inappropriate;
- other explicitly forbidden itemization.

Hard violations should normally result in:

```text
BAD
```

## Soft violation

A soft violation indicates that the item is usable but should preferably be corrected.

Examples:

- unwanted armor type;
- lower-level enchant;
- lower-level gem;
- other non-critical optimization issue.

Soft violations should normally result in:

```text
REPLACE
```

If no significant findings exist, the item can be:

```text
OK
```

or:

```text
GOOD
```

---

# 8. Unknown / Not Checkable State

Do not classify an item as `BAD` when the addon lacks sufficient data to evaluate it.

The system must support an explicit unknown/not-checkable state.

Examples:

- unknown item ID;
- unknown enchant ID;
- unknown gem ID;
- missing ruleset information;
- unsupported item data.

Example UI:

```text
Chest
⚠ Cannot evaluate this item
Unknown item data
```

Unknown data must not produce a false negative.

---

# 9. Equipment Slots

The initial Gear Check should check all relevant equipment slots except:

- trinkets;
- relic-type slots:
  - idol;
  - libram;
  - totem;
  - sigil;
- tabard;
- shirt.

These slots should be represented as intentionally unsupported/ignored rather than accidentally omitted.

Use an explicit slot policy where appropriate:

```text
CHECKED
IGNORED
UNSUPPORTED
```

The exact implementation can follow the addon architecture.

---

# 10. Armor Rules

Armor rules must be specialization-specific.

Do not implement armor logic as a single global rule.

The ruleset should support categories such as:

```text
preferred
acceptable
unwanted
forbidden
```

Example:

```text
Fury Warrior

Plate      preferred
Leather    acceptable/unwanted
Mail       unwanted
Cloth      forbidden
```

The exact values must be determined during the ruleset-definition phase.

Armor rules must account for the fact that some physical DPS specializations can legitimately use leather or mail items in certain situations.

For tanks, inappropriate armor types should receive stronger penalties.

For example, protection specializations should generally require plate armor.

Do not use modern Retail armor-specialization mechanics. The addon targets **WoW 3.3.5a**.

---

# 11. Stat Rules

Stats must be evaluated relative to class and specialization.

Do not use only binary "stat exists / stat does not exist" logic.

The ruleset should support at least:

```text
preferred
acceptable
unwanted
forbidden
```

| Rank | Meaning | Verdict effect |
|------|---------|----------------|
| **preferred** | BiS-appropriate for the spec | No finding; required (with max enchant/gems) for **GOOD** |
| **acceptable** | Usable surface choice (offsets, hybrid leftovers) | No finding; **OK** by default; can still be **GOOD** on offset slots / special rules |
| **unwanted** | Wrong-for-spec soft waste | Soft finding → slot **REPLACE** |
| **forbidden** | Explicitly inappropriate | Hard finding → slot **BAD** |

The initial rules should identify obviously inappropriate stats.

Examples:

- Spell Power on pure physical DPS;
- Resilience on PvE gear;
- Spirit on specializations where it is clearly inappropriate;
- Intellect on specializations where it is clearly inappropriate.

Important:

A stat being non-preferred does not automatically mean that the item is `BAD`.

Distinguish between:

```text
FORBIDDEN
```

and:

```text
UNWANTED
```

**unwanted** is the canonical soft rank name (formerly “discouraged” in early drafts). It produces a soft finding that maps to **REPLACE**, not **BAD**.

The initial system must avoid attempting to determine exact stat weights.

For example, it should be able to state:

> Spell Power is inappropriate for this specialization.

It should not attempt to state:

> 20 Strength is exactly 3.17% better than 20 Armor Penetration.

That level of analysis belongs to future build-aware web functionality.

---

# 12. Weapon Rules

Weapons require a separate rules category.

The ruleset must be capable of evaluating:

- weapon type;
- one-handed vs two-handed;
- main-hand/off-hand compatibility;
- weapon combinations;
- ranged weapon requirements where applicable;
- specialization-specific weapon restrictions;
- relevant weapon characteristics.

Do not treat weapons as ordinary armor items.

Use a dedicated weapon ruleset.

The rules must support cases where a specialization legitimately has multiple weapon configurations.

Examples:

```text
1H + 1H
2H
MH + OH
specific weapon types
```

The exact specialization rules should be defined separately from the evaluation engine.

---

# 13. Enchant Rules

Enchant evaluation must be independent from item evaluation.

Each enchant should be evaluated for:

1. existence;
2. validity;
3. class/spec compatibility;
4. stat suitability;
5. enchant quality/level.

Conceptually:

```text
missing
invalid
wrong/inappropriate
valid but lower-level
correct
maximum
```

A high-level enchant with inappropriate stats is still inappropriate.

Therefore:

```text
isMaxLevel
```

must not imply:

```text
isRecommended
```

The ruleset must contain the applicable maximum/high-level enchants for WoW 3.3.5a.

---

# 14. Gem Rules

Gem evaluation must be independent from item evaluation.

Each gem should be evaluated for:

1. existence;
2. gem level;
3. stat compatibility;
4. specialization compatibility.

The system should distinguish:

```text
maximum-level gem
pre-maximum-level gem
wrong/inappropriate gem
missing gem
```

A maximum-level gem with inappropriate stats must not automatically receive a positive verdict.

---

# 15. Socket Bonuses

Do NOT require socket colors to be matched in the first version.

Do NOT automatically penalize a player for ignoring a socket bonus.

Reason:

Some specializations/builds may deliberately use gems that do not match the socket color because the direct value of the gem's stats can exceed the socket bonus.

Examples include:

- Strength-focused Unholy DK gearing;
- Haste-focused Holy Paladin;
- Intellect-focused Holy Paladin;
- other specialization-specific gearing strategies.

Therefore the first Gear Check only evaluates gem suitability itself.

Socket-bonus optimization is explicitly outside the scope of the addon Gear Check.

---

# 16. Meta Gems

Meta gems are evaluated at the gear-set level.

The system must check:

### Compatibility

Is the meta gem appropriate for the class/spec?

### Activation

Is the meta gem currently active?

### Requirements

Are the required gems across the entire equipped gear set present?

For example:

```text
Meta requirement:
2 blue gems
```

must be evaluated against the complete equipped gear, not only the item containing the meta gem.

Meta gem checks therefore belong partly to **gear-level evaluation**, not only item-level evaluation.

---

# 17. Set Bonuses

Set bonuses are informational only.

The system should detect and display set-piece counts.

Examples:

```text
T10: 4/5
T9: 2/5
```

It may display 2-piece and 4-piece milestones where relevant.

The system must NOT evaluate whether:

- 2-piece is better than 4-piece;
- a set bonus should be maintained;
- one set should be replaced by another.

That requires build-aware analysis and is outside the first version.

---

# 18. Item Level

Item level must not be used to determine:

```text
BAD
REPLACE
OK
GOOD
```

The same addon can be used in raids with very different average gear levels.

A lower-item-level item is not automatically bad.

Item level may be displayed as informational data if already available, but it must not affect the Gear Check verdict.

---

# 19. Class/Spec Rules Architecture

Do not hardcode large amounts of class/spec logic directly into the evaluation engine.

The evaluation engine should consume a declarative ruleset.

Conceptually:

```text
Rule Engine
    +
WoW 3.3.5a Rules
    +
Class/Spec Profile
```

A specialization profile should be capable of defining:

```text
Armor
    preferred
    acceptable
    unwanted
    forbidden

Stats
    preferred
    acceptable
    unwanted
    forbidden

Weapons
    preferred
    acceptable
    unwanted
    forbidden

Enchants
    allowed
    preferred
    maximum/recommended

Gems
    allowed
    preferred
    maximum/recommended

Meta Gems
    allowed
    preferred
```

The exact data structure may differ from this conceptual model.

---

# 20. Build-Independent vs Build-Dependent Rules

The ruleset must clearly distinguish between rules that can be evaluated without knowing the player's specific build and rules that require optimization.

### Build-independent

Examples:

```text
Spell Power on pure physical DPS
Resilience on PvE gear
Cloth armor on a tank
Incompatible weapon type
Wrong stat enchant
Inappropriate gem
Missing enchant
```

These belong in the addon.

### Build-dependent

Examples:

```text
Strength vs Armor Penetration
Strength vs Haste
Socket bonus vs non-matching gem
2T10 vs 4T10
specific BiS item
exact stat weights
```

These do not belong in the first addon implementation.

This distinction must be maintained throughout the implementation.

---

# 21. Overall Gear Result

After evaluating all applicable items, enchants, gems, meta requirements and other findings, calculate an overall gear status.

The overall status should be derived from the collection of findings rather than independently hardcoded.

The result should provide at least:

```text
Overall status

Item issues
Enchant issues
Gem issues
Meta issues
```

Example:

```text
Gear Check
────────────────────

Overall: REPLACE

Items:    1 issue
Enchants: 2 issues
Gems:     3 issues
Meta:     OK
```

---

# 22. Report Output

The addon must support several report modes.

## Summary

Example:

```text
[GearCheck] PlayerName — REPLACE
1 bad item, 2 enchant issues, 3 gem issues.
```

## Items

Example:

```text
[GearCheck] PlayerName — Items:
Chest: leather armor — plate is recommended
Ring: resilience — inappropriate PvP stat
```

## Enchants

Example:

```text
[GearCheck] PlayerName — Enchants:
Chest: missing enchant
Gloves: lower-level enchant
```

## Gems

Example:

```text
[GearCheck] PlayerName — Gems:
Chest: lower-level gem
Legs: inappropriate stat gem
```

The exact formatting can be adapted to WoW chat limitations and addon UI conventions.

---

# 23. Explainable Findings

Every important finding should have a machine-readable reason code.

Conceptually:

```ts
{
    code: "ARMOR_TYPE_NOT_RECOMMENDED",
    severity: "warning",
    slot: "chest",
    message: "Plate armor is recommended for this specialization."
}
```

The system should not only say:

```text
Chest — REPLACE
```

It should be able to explain:

```text
Chest — REPLACE
Leather armor
Plate armor is recommended for this specialization.
```

This is important for:

- addon UI;
- chat reports;
- debugging;
- future localization;
- future web reuse.

---

# 24. Gear Check Data Model

The implementation should conceptually separate:

```text
Target Gear
      ↓
Gear Collector
      ↓
Normalized Gear
      ↓
Rules Engine
      ↓
Findings
      ↓
Item Verdicts
      ↓
Gear Summary
```

Do not mix WoW API data collection with evaluation rules.

The collector should obtain and normalize the current character data.

The rule engine should operate on normalized data.

This makes the rules independently testable.

---

# 25. Saved Reports

Manual save only — scans are **not** auto-persisted.

Implemented in `GearCheckSavedReports.lua` + **Gear check (target)** UI:

- user presses **Save report** after a scan;
- report is keyed to the scanned character (GUID, or name-realm);
- snapshot includes full evaluated report + `savedAt` / `expiresAt` (~14 days);
- expired entries are pruned on load and save;
- saved list supports load (frozen snapshot) and delete.

---

# 26. Ruleset Versioning

Every saved report stores `rulesetVersion`, e.g. `wotlk-3.3.5a-1.16.0` (WotLK + addon version).

This allows historical reports to be interpreted after rules change.

---

# 27. Data Versioning

Every saved report stores `dataVersion` (catalog revision, e.g. `catalog-2026-08-24` from `GEAR_CHECK_DATA_VERSION`).

This distinguishes snapshots taken under different enchant/gem catalog seeds.

---

# 28. Future Web Application Boundary

The addon Gear Check should remain intentionally lightweight.

The future web application may provide:

- build-specific gear analysis;
- multiple gearing strategies;
- BiS lists;
- stat weights;
- socket optimization;
- gear alternatives;
- upgrade paths;
- set bonus optimization;
- detailed gear scoring;
- simulations.

The addon should not attempt to duplicate this functionality.

The addon answers:

> **"Are there obvious gear problems?"**

The web application can eventually answer:

> **"How should this character optimize their gear for a specific build or goal?"**

---

# 29. Initial Implementation Order

Implement the feature in stages.

### Phase 1 — Data collection

Implement:

- target detection;
- class/spec detection;
- equipment slot scanning;
- item IDs;
- enchant IDs;
- gem IDs;
- meta gem data;
- relevant item information.

Do not implement complex rules yet.

### Phase 2 — Normalized gear model

Create a stable internal representation of:

```text
Character
    ↓
Equipment
    ↓
Item
    ├── armor/weapon information
    ├── stats
    ├── enchant
    └── gems
```

### Phase 3 — Rules engine

Implement:

- hard/soft findings;
- armor rules;
- stat rules;
- weapon rules;
- enchant rules;
- gem rules;
- meta gem rules.

### Phase 4 — Item verdicts

Implement:

```text
BAD
REPLACE
OK
GOOD
```

based on findings.

### Phase 5 — Gear-level evaluation

Implement:

- overall status;
- meta activation;
- meta requirements;
- set-piece information;
- issue counters.

### Phase 6 — UI

Implement:

- Gear Check screen;
- item breakdown;
- enchant breakdown;
- gem breakdown;
- summary;
- explanatory findings.

### Phase 7 — Chat output

Implement:

```text
/rw gearcheck
```

and report modes for:

- summary;
- items;
- enchants;
- gems.

### Phase 8 — Ruleset expansion

Add and verify class/spec-specific rules for all relevant WotLK 3.3.5a specializations.

---

# 30. Acceptance Criteria

The implementation is considered complete for the initial version when:

- the user can target a player and open Gear Check;
- `/rw gearcheck` opens the Gear Check functionality;
- equipped gear can be collected;
- gems and enchants can be detected;
- the target's class/spec rules are selected;
- every supported item is evaluated against those rules;
- hard and soft violations are distinguished;
- every evaluated item receives `BAD`, `REPLACE`, `OK`, or `GOOD`;
- unknown data does not produce false `BAD` results;
- enchant problems are reported separately;
- gem problems are reported separately;
- meta gem compatibility and activation are checked;
- meta activation requirements are evaluated across the entire gear set;
- set-piece counts are displayed separately from the verdict;
- item level does not affect the verdict;
- socket bonuses do not affect the verdict;
- BiS/build/stat-weight optimization is not performed;
- the UI clearly states that this is a surface-level evaluation;
- the user can print a summary;
- the user can print item warnings;
- the user can print enchant warnings;
- the user can print gem warnings;
- no automatic Gear Check history is persisted.

---

# 31. Design Principle

The central design principle is:

> **The Gear Check identifies obvious problems; it does not attempt to solve gear optimization.**

The system should answer:

- Is this item appropriate for the class/spec?
- Does it contain obviously inappropriate stats?
- Is the armor/weapon type appropriate?
- Is the enchant appropriate and sufficiently high-level?
- Are the gems appropriate and sufficiently high-level?
- Is the meta gem compatible and active?
- Are there obvious corrections the player should make?

It should deliberately avoid answering:

- Is this BiS?
- Which item is mathematically better?
- Which build is better?
- Should the player sacrifice a socket bonus?
- Which stat should the player maximize?
- Which item should replace the current item?

Those questions belong to future, build-aware analysis.