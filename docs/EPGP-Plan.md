# EPGP guild roster plan

## Goal

Add a staged workflow for turning the in-game guild roster and officer notes into structured EPGP data:

1. Export guild members to JSON in WoW 3.3.5a.
2. Parse member notes and officer notes into normalized records.
3. Show character-to-main relationships as a visual alt map.
4. Calculate current priority (PR) from EP and GP.

The first implementation should fit the existing addon.
Keep parsing and calculations behind small module APIs so they can be moved into an optional companion module later without changing their data contracts.

## Data model

Treat the game roster as raw source data and retain the original notes alongside parsed fields.
A member record should include character name, guild rank, public note, officer note, and parse status.
Parsed public-note fields should include optional guild-join date, optional player name, and zero to two specs.
Each spec has free-form source text, normalized role/spec when confidently recognized, optional GearScore, optional Saurfang 25/25H DPS, and its order.
The first spec is the main spec.
Unknown values (`?`), absent values, and not-applicable values must remain distinct.

Officer notes have two supported forms: numeric `EP,GP` for a main character, or a character name indicating the main to which this character is linked.
Preserve the raw value and report invalid or ambiguous entries instead of guessing.
Numeric parsing should accept comma decimal/list conventions only according to an explicitly documented grammar; examples currently suggest integer EP and GP separated by a comma.

PR is `EP / max(GP, minimumGP)`. The configurable minimum GP defaults to **500**; GP=0 therefore uses effective GP=500.
Show both recorded GP and effective GP so the floor is visible.
Never silently divide by zero or invent a value.

Add a separate configurable minimum EP threshold for BIS rolls.
It defaults to **4000** for the current guild profile.
This eligibility threshold is independent of PR and should report eligible/ineligible/unknown without changing EP or PR.

## Stages

### 0. Confirm contracts and edge cases

- **Game/API scope:** target is WoW 3.3.5a (`Interface: 30300`). The client exposes guild roster enumeration through `GetNumGuildMembers()` and `GetGuildRosterInfo(index)`; roster refresh is requested through `GuildRoster()`. The exact return tuple and visibility/permission behavior must be verified against the target client before implementation. Export only values returned by that client. `CanEditOfficerNote()` can indicate officer-note editing rights, but reading visibility must be tested separately; if officer notes are unavailable, export them as unavailable rather than empty.
- **Snapshot and correction workflow:** export raw values first. Officers may edit note text in the exported snapshot and mark each record malformed or ambiguous. Preserve both original and corrected text, who/when metadata only if available from an explicit user action, and parse status. A correction must never overwrite the captured source silently. Re-import/re-parse should operate without a new guild scan.
- **Public-note grammar:** intentionally tolerant, not a fixed strict grammar. Split specs on `/` or `\\` when the segment structure is clear; recognize an optional player name/date, free-form spec label, optional GearScore and optional parenthesized Saurfang 25/25H DPS. Accept dot or comma decimal notation only when unambiguous in context. Preserve unknown `?` separately from missing data. One spec, two specs, two healing specs, absent DPS, no spec (low-level), and unrecognized labels are valid partial records. If a token can be interpreted in multiple ways, retain raw text and flag for officer review instead of guessing.
- **Officer-note grammar:** trim surrounding whitespace. A non-negative integer pair `EP,GP` is a balance record. Otherwise, a non-empty value is a main-character reference. Empty is missing. Other numeric forms, negative values, and malformed pairs are invalid and need review. This makes `0,0` a valid balance and avoids interpreting decimal commas as EP/GP.
- **Alt resolution:** normalize names by trimming whitespace and case-folding; compare within the current realm/guild snapshot (no cross-realm inference). A reference must resolve to exactly one member. Missing or duplicate matches remain unresolved. Resolve references to their terminal main while recording the direct link; detect self-links and cycles and exclude invalid chains from balance inheritance. Numeric balance notes identify mains. An alt's own numeric balance is a conflict requiring review, not an automatic override.
- **EPGP policy:** minimum GP defaults to 500 and is configurable. `effectiveGP = max(recordedGP, minimumGP)` and `PR = EP / effectiveGP`; preserve/display both GP values. Negative or malformed EP/GP are invalid. Minimum EP for BIS rolls defaults to 4000 and is independently configurable; eligibility is `EP >= threshold` for a character linked to a valid main balance. Missing/invalid balance yields unknown eligibility. Thresholds are stored with the snapshot/calculation so results are reproducible.
- **Data retention:** retain raw notes and roster fields in every snapshot. Parsing is additive; later grammar updates can reprocess existing snapshots, while manual corrections and review flags remain attached to the corresponding member record.

### 1. Guild roster JSON export

- Add an explicit guild-roster export action that collects name, rank, level/class when available, public note, officer note, and scan timestamp.
- Handle roster update timing and pagination/limits exposed by the target client; show progress and incomplete-scan status.
- Serialize with the addon's shared JSON escaping and a schema version. Keep this stage useful before parsing exists.
- Provide a copyable/exportable payload consistent with current addon export patterns.

**Deliverable:** reproducible raw JSON snapshot, with schema version and completeness metadata.

Roster export commands: `/rw guildexport` uses the current roster visibility; `/rw guildexport all` includes offline members; `/rw guildexport 80` includes all level-80 members, including offline members.
Filtered exports retain the total roster count and record `levelFilter` and `memberCountMatchingFilter` in the JSON metadata.

### 2. Note parsing and normalized roster

- Implement a pure parser that accepts a raw member record and returns parsed fields plus warnings/confidence.
- Parse each spec segment independently; do not assume every segment has a GearScore or DPS, and do not assign DPS to healing specs unless explicitly applicable.
- Preserve original capitalization/text and token spans where practical; normalized spec aliases should be additive, not destructive.
- Build summary counts for parsed, partial, ambiguous, and unparsed notes. Include fixtures derived from the supplied examples and adversarial cases.

**Deliverable:** normalized roster JSON and an inspectable parse report. Parser must be independently testable without WoW APIs.

### 3. Alt map

- Resolve numeric EP/GP notes as main-character EPGP entries; resolve name-valued officer notes as alt links.
- Build a graph keyed by normalized character identity, detect unresolved references, self-links, cycles, duplicate identities, and conflicting numeric/link notes.
- Present each main with linked alts, each character's parsed specs and note status, and unresolved entries in a separate review list.
- Allow navigation from an alt to its main and from a main to all known alts. Avoid destructive auto-correction.

**Deliverable:** visual roster map that makes uncertain links visible and keeps the raw officer note accessible.

### 4. EP/GP and PR view

- Calculate PR for entries with numeric EP/GP only, using the agreed minimum-GP/zero policy.
- Display EP, GP, effective GP if a floor is used, PR, and the source note. Sort/filter without changing source values.
- Show missing, invalid, and linked-alt values distinctly; linked alts inherit their main association but should not be counted as separate EPGP balances unless guild policy explicitly says otherwise.
- Keep calculation helpers pure and include boundary cases: GP=0, below floor, negative/invalid values, large totals, and rounding/display precision.

**Deliverable:** current PR view with transparent inputs and explicit handling for non-computable rows.

### 5. Current-raid item competitors

- Join the current raid roster to the imported guild snapshot and main/alt map, with explicit handling when a raid character is not in the snapshot.
- Reuse the existing mass GearCheck collection and report APIs; do not create a second equipment-inspection pipeline.
- For a selected item or slot, identify raid members whose current equipment indicates a plausible upgrade/competition candidate, using item/spec compatibility and the collected gear report.
- Show the evidence and confidence for each candidate, alongside main/alt identity and PR/BIS-roll eligibility where available. GearCheck estimates competition; it does not assign loot or replace EPGP ordering.

**Deliverable:** an in-raid competitor view grounded in current scan results and guild roster data.

### 6. Raid composition proposal

- Accept configurable minimum GearScore, minimum DPS, and raid-experience requirements as inputs. Keep thresholds and experience criteria editable per proposal.
- Use parsed roster specs and available GS/DPS values to filter and rank candidates; use experience only when recorded in a defined source/field, otherwise mark it unknown rather than treating it as zero.
- Propose a composition that also respects role/spec coverage and the target raid size. Explain included/excluded candidates and missing data; allow officer review and manual adjustment.
- Reuse existing role and composition concepts where applicable, while keeping proposal generation separate from live raid composition analysis.

**Deliverable:** a reviewable roster proposal with criteria, rationale, and uncertainty visible.

## Architecture and rollout

- Design for eventual extraction as an optional companion addon from the first implementation. Use a namespaced `RaidwiseEPGP` module API and versioned JSON snapshot as the boundary; do not make future code depend on private Raidwise UI state or SavedVariables internals.
- Keep the current integration as a thin adapter: WoW roster API collection, event/command wiring, and display. Snapshot normalization, parsing, correction handling, alt resolution, policy, and PR calculations belong in pure modules with no frame globals or WoW API calls.
- Keep exported data and editable/corrected data distinct. The data contract should be portable outside the addon; only the adapter translates to/from WoW APIs and the host addon's shared JSON escaping.
- Avoid cross-module mutation and implicit load-order dependencies. Expose explicit functions that accept records/config and return results; any host integration should be optional and capability-checked.
- Stage 1 currently collects a Lua snapshot and formats JSON separately (`CollectGuildRosterSnapshot`, `FormatGuildRosterSnapshot`). Continue this separation in later stages and add parser/calculator tests against supplied data fixtures.
- When extracting, move the pure modules and their tests first, then add a companion-addon adapter for roster access/UI. Keep the JSON schema and pure APIs stable so migration does not require rewriting data logic.
- No semver or layout version bump is needed for planning. When UI structure is implemented, update the relevant layout version and UI docs per `AGENTS.md`.
- For implementation, follow `tests/README.md`; add behavior-based parser, resolver, and PR coverage and run `npm run check` before completion.

## Open decisions before implementation

1. Exact separator and number grammar for officer notes and public-note fields.
2. Whether the addon should export only, or also retain/import snapshots between sessions.
3. The guild's minimum GP and rounding/display rules for PR.
4. Whether alt characters can have their own EP/GP and how conflicts are handled.
5. Preferred UI: a new page in the current window, a separate window, or export-first with external visualization.

6. Where raid experience will be recorded and how it will be measured (for example, encounter kills or officer-entered experience).
7. How item-level competitor matching should map specs to eligible loot and define an upgrade.

