# Offline addon tests

Use Node.js 24.4 or later in the 24.x series and npm. From the repository root:

```sh
npm ci --ignore-scripts
npm run check
```

`npm run check` type-checks the TypeScript test runner and export contracts, then runs the tests. Use
`npm test` for tests alone or `npm run test:watch` while editing. Failures return
a nonzero exit status for CI.

## Guild checks

Use the [guild task map](../docs/raid/Guild-Management.md) for owners and scenarios
in `guild-management.test.mts`: roster/refresh, officer actions, local journal,
parsing/links/balances and page interactions. It also points to actual bootstrap/
TOC coverage. [External limits](../docs/raid/Guild-Management-Contract.md) and the
[manual matrix](../docs/raid/Guild-Management-Verification.md) distinguish mock
coverage from actual server confirmation and UI behavior.

## Type checking

`npm run typecheck` runs both `tests/tsconfig.json` and `types/tsconfig.json`.
The second project explicitly includes all three `types/*.ts` files and
`export-contracts.test.mts`. It permits the existing `InstanceDifficulty` enum
and extensionless type import; this preserves the public TypeScript contract.
The export test imports these types with `import type`, so Node never executes
the enum. Other tests retain the erasable-only compiler restriction. The export
test is excluded from the first project because it is checked by the second;
`npm test` still runs it through the normal `*.test.mts` glob.

`export-contracts.test.mts` parses real Lua character/cooldown JSON as `unknown`,
validates fields and reconstructs values with explicit contract return types.
Required type changes therefore affect compilation, and malformed runtime values
fail assertions. Fixtures cover all 32 control bytes, quotes/backslashes, Unicode,
names on/off, optional GearScore/currency, populated lockouts and empty lists.
Gear Check's model is explicitly type-checked; its real Lua behavior remains
covered by the existing gear/report tests, not a new complete runtime TS validator.

The Addon tests workflow runs only on pull requests (opened, synchronized with new
commits, or reopened), on both Windows and Ubuntu. Branch pushes without a pull
request and manual dispatch do not trigger it.
Tag publication has its own release workflow and checks.
Required checks/branch protection are configured separately in GitHub.

`architecture.test.mts` loads all active modules in TOC order and exercises
bootstrap and profile persistence, including missing core/bridge APIs.
Native UI construction and social-hook initialization are excluded from this bootstrap test; it is not a visual or in-client loading test.
Navigation assertions check registered group membership, unique page IDs and
retired-page rejection rather than a fixed menu order. The anchor regression's
frame fixture implements size getters/setters so page construction reaches the
actual circular-anchor checks.

`dump.test.mts` provides the colon-splitting WoW helper used by item links and
checks compact versus full raid exports (grades, enchants and sockets), matching
synchronous/asynchronous output, cancellation and export routing.


## Character-system checks

Select the suite by task using the [character task map](../docs/characters/Reputation.md).
It links the active owners to the behavioral tests for persistence, identity,
authorship, journals/recovery, deletion/links, encounters, lists and opinion marks.
Use the named suite for focused work, for example:

```sh
node --test tests/player-links.test.mts
```

Run `npm run check` before completing code/test changes. These suites execute
real Lua through mocks; they do not establish client rendering, live server timing
or disk persistence. [Manual checks and dated user evidence](../docs/characters/Character-System-Verification.md)
retain those limits. For SavedVariables maintenance use the
[repair procedure](../docs/characters/Character-System-Contract.md#repairing-quarantined-records).

Current screen reads and target-addition/identity-upgrade behavior are checked through the active core/bridge in `architecture.test.mts`. `roster-refresh.test.mts` uses active encounter persistence while checking shared snapshots and hidden views.
Self notes, independent linked opinions and deletion guarantees are covered by `player-records.test.mts` / `player-links.test.mts`; retired migration/exchange semantics are not supported contracts.

## Gear Check checks

Use the [Gear Check task map](../docs/gear-check/Gear-Check-Progress.md) to select
owners and suites for inspect lifecycle, collection, compatibility, findings,
grades, saved revisions, dumps and chat. It also links the shipped rule fixtures
(`GearCheckSelfTest.lua`, `/rw gearcheck test`) and Lua gem/scan scenarios.
New rules should be exercised through `EvaluateGearCheck`, with real Lua and
observations supplied as data. The boundary regression forbids live item/talent/
identity API reads during evaluation; do not replace it with a JS implementation.

[Revision/compatibility policy](../docs/gear-check/Gear-Check-Contract.md) describes
when the independent revisions change. For server timing, locale/tooltip reads,
inspect-addon interference, clipboard and persistence use the
[manual protocol](../docs/gear-check/Gear-Check-Verification.md). No live timing
baseline has been established by the simulated scheduling tests.

## Lua test runner

The runner is TypeScript (`gear-check.test.mts`) using Node's built-in `node:test`
and `node:assert/strict`. Node runs the erasable TypeScript directly; `tsc` handles
type checking separately. The existing CommonJS scripts in `scripts/` keep their
module format.

The pinned [wasmoon-lua5.1](https://github.com/JX3BOX/wasmoon-lua5.1) dependency
executes the real addon Lua through WebAssembly. Each test creates an isolated VM,
asserts `_VERSION == "Lua 5.1"`, loads the modules in addon dependency order, and
closes the VM in `finally`. Python, Lupa, and a separate system Lua installation
are not required.

## Export and lockout client checks

Owners: `CharacterExport.FormatEquippedGearExport`;
`CharacterLockouts.SaveCurrentCharacterLockouts`, `BuildCooldownTable`,
`RemoveCharacterLockouts`, `FormatCooldownsExport`.
[export-contracts.test.mts](export-contracts.test.mts) parses real Lua JSON against
[character](../types/CharacterExport.ts) and [cooldown](../types/CooldownsExport.ts)
contracts; [dump.test.mts](dump.test.mts) checks format versions. Their mocked
save/collection paths do not prove real server lockout/reset behavior.

For affected changes, record client/server/revision and check delayed raid-info
replies, different difficulties, reset boundaries, currency reads and each own
character's snapshots after login/reload. Parse the actual copied JSON with the
consumer. A mock pass or in-memory save does not demonstrate current disk
persistence or the target server's responses. No successful in-client execution
of this matrix was recorded in the removed November audit plan.

## Copyable diagnostics

Run `npm run diagnose` from the repository root after changes or when reporting a
problem. It runs `npm run check` (including the Settings/profile circular-anchor
regression), prints the results, and writes `diagnostics/latest.txt`. Copy that
file for analysis. Each run replaces it; failures return exit code 1. The report
includes Node/platform, Git revision and whether the checkout has modifications.
Dependencies must already be installed as described above.

In game, run `/reload`, then `/rw diagnose` (or `/raidwise diagnose`). It attempts
to open the main window and runs the gear rule self-tests, collecting failures
and stack traces without stopping at the first failed check. The independent
report window supports Ctrl+A / Ctrl+C and Escape to close. The latest text also
remains in `Raidwise.lastDiagnosticReport` for the current session. Diagnostic
text uses English PASS/FAIL/SKIP markers in both interface languages.

If `/rw diagnose` does not respond, try `/raidwisediag`, the dedicated alias.
The command prints `Diagnostics starting...` before running checks, reports a
missing diagnostic module, and falls back to local chat if the report window
fails. Install the entire `Raidwise` folder including new files and its TOC;
restart the client after installing newly added files. No starting message from
either command indicates command registration or installed-file problems.

Opening uses the normal startup page and may trigger its usual collection or
history refresh. It leaves the main window open when successful. In combat, the
opening check is explicitly skipped; rerun outside combat. A cached shell is
reported, so run immediately after `/reload` to exercise fresh construction.
This is an opening smoke test, not a check of every profile/tab interaction or
live inspect timing. If bootstrap fails before slash commands register, this
command cannot run; copy the game's Lua error instead. Reports omit saved player
records, but error text can contain runtime values: review before sharing.

## Test selection

`record-reads.test.mts` checks detached screen reads (including nested identity
data and roster authors), name-index rename/upgrade/recovery, profile deletion,
and sparse selection among 10,000 identities. Warm lookup and roster tests reject
a full identity scan; encounter summaries must not copy whole histories.
The chat-color regression uses the active core and verifies independent opinions
for linked characters.
No retired profile implementation is loaded by these checks.

For timings, run `node scripts/benchmark-records.mts`. It seeds synthetic 1k/10k
identities with 11 filled profiles/recent encounters, reports the cold name-index
lookup, 100 warm lookups and ten builds of each list. `--dense` fills every record;
`--baseline` loads Lua from Git HEAD instead of the working tree, without checkout.
These are single-process WASM measurements, not pass/fail latency thresholds or
WoW FPS/RAM estimates. Cold lookup includes index construction; sorting and
retention costs remain for dense lists. After committing, HEAD becomes the new
baseline; [the dated audit evidence](../docs/audits/Audit-2026-11-06-Evidence.md)
records the old comparison revision and its measurement limits.

`release.test.mts` validates the runtime allowlist and builds an actual ZIP from
HEAD in a temporary directory, then reads its central directory. The package must
contain exactly TOC modules, the TOC and tracked media. No release is published.
`node scripts/package-addon.mts <output.zip>` is also the release workflow command;
it always packages tracked HEAD content, not uncommitted working files. Missing
TOC modules, traversal paths and unsupported XML entries fail before archiving.

For focused iteration, run `node --test tests/scan.test.mts` (substitute the
relevant file below). Before finishing code/test changes, run `npm run check`
after the final edit. Reuse installed dependencies unless missing or the lockfile
changes; repeat successful checks only after new edits or unresolved concerns.

| Changed behavior | Start with |
|---|---|
| Release tag/version validation, changelog extraction and ZIP contents | `release.test.mts` |
| Report compatibility/state, read-only getters, page dispatch, shared member collection, profile builders | `architecture.test.mts` |
| Scan lifecycle, retries, cancellation | `scan.test.mts` |
| Inspect ownership and roster handoff | `inspect.test.mts` |
| Collection, grades, gems, meta, report chat/header | `gear-check.test.mts` |
| Saved revision compatibility | `saved-revisions.test.mts` |
| Roster snapshot sharing | `roster-refresh.test.mts` |
| Active profile drafts, journal migration, quarantine/recovery | `player-records.test.mts`, `profile-window.test.mts` |
| Identity read models/index, associations and deletion | `record-reads.test.mts`, `player-links.test.mts` |
| Meetings/retention and Database/History lists | `encounters.test.mts`, `database-page.test.mts` |
| Character/cooldown JSON and TypeScript contracts | `export-contracts.test.mts` |
| Native friends, ignore, inbox and guild opinion marks | `classic-opinion.test.mts` |
| Bare-client profile notes and diagnostics scroll template names | `architecture.test.mts` |
| Theme bindings | `theme.test.mts` |
| Dump jobs, cancellation, output routing | `dump.test.mts` |

Assert behavior rather than incidental version numbers: header radio tests check
exclusivity and page visibility, not the current Settings layout version. Keep
exact values for real contracts, such as Lua 5.1, schema compatibility and
protocol limits. Rebuild tests should compare frame stamps with registered
layout versions; revision tests should compare metadata across changes.

- `gear-check.test.mts`: TypeScript orchestration, runtime guard, and test cases.
- `lua/wow-stubs.lua`: minimal offline WoW API substitutes.
- `lua/gear-check-gems.lua`: gem ID, partial-read, cache, and meta regressions
  migrated from the Python harness without removing assertions.
- `../Raidwise/GearCheckSelfTest.lua`: the existing rule self-tests, also available
  in game through `/rw gearcheck test`.

Add a named `test(...)` in the TypeScript runner for a new scenario. Use Node
assertions for values returned from Lua, or a Lua fixture for cases involving
Lua tables, closures, and mocked WoW APIs. Keep the addon implementation in Lua;
tests must exercise it rather than a JavaScript reimplementation. Avoid exposing
test-only helpers on the shipped `Raidwise` namespace. The current regression
fixture finds private closures through Lua's debug API inside the test VM.

Check in the test files, `package.json`, and `package-lock.json`; ignore
`node_modules/`. These are development tools and are not shipped in the addon
folder. Offline tests cannot validate WoW's inspect event timing or real tooltip
behavior: follow collector changes with an in-game rescan.

## Roster and composition checks

The [composition task map](../docs/raid/Raid-Composition.md) routes effect data,
role inference and reports to their owners. `architecture.test.mts` checks active
versus reserve groups and known/unknown-tree provider inference;
`roster-refresh.test.mts` checks shared snapshots, coalesced requests, forced
refresh precedence, hidden-view behavior and refreshes requested during rendering.
The report-link/byte-budget scenarios are in `gear-check.test.mts`.
These are behavior/call-count checks, not measured client speed improvements.
Use the [client timing protocol](../docs/gear-check/Gear-Check-Verification.md)
when changing inspect/collection and the [composition manual checks](../docs/raid/Guild-Management-Verification.md#composition-presentation)
for actual display and chat-skin behavior.

## UI checks

Use the [UI task map](../docs/ui/UI-Views.md) for shell/page dispatch, theme
bindings, control builders, layout generations and their test suites.
`theme.test.mts` checks stable palette references and bound colors;
`architecture.test.mts` exercises page lifecycle and selected anchor regressions;
header-capability cases are in `gear-check.test.mts`.
`profile-window.test.mts` exercises the active window and rejects anonymous
`UIPanelScrollFrameTemplate` creation.
The separate diagnostics fixture also checks named template creation and reuse of its independent window.

The [native-client checklist](../docs/ui/UI-Views.md#native-client-constraints-and-verification)
retains locale/theme/scale, fresh construction, scrolling, tooltip and clipboard
checks that mocks cannot establish. The HTML previews are design references,
not native rendering tests.

## Pull request CI

`.github/workflows/tests.yml` runs the same install/check commands on Windows and
Linux for `pull_request` events: opening or reopening a PR and pushing new commits
to its branch. It has no `push` or `workflow_dispatch` trigger. Release tag pushes
are handled separately by `.github/workflows/release.yml`.

## Packaging and releases

[package-addon.mts](../scripts/package-addon.mts) and
[release.test.mts](release.test.mts) own the installable ZIP allowlist. The script
packages tracked HEAD content; it does not bundle uncommitted working files.
For a requested version change use the [bump procedure](../.agents/skills/bump/SKILL.md),
[AGENTS release rules](../AGENTS.md#versioning-and-changelog) and root changelog.

The [release workflow](../.github/workflows/release.yml) publishes stable version
tags; branch updates/PR merges alone do not publish. It checks the tagged tree,
runs the checks and packages `Raidwise/` plus `Raidwise_Guild/`. Installation uses
`Raidwise-vX.Y.Z.zip`; GitHub's automatic Source archives contain the repository.
The built-in token has `contents: write`; a personal access token is not required.

To repair an existing release asset, choose **Actions → Release addon → Run
workflow** on the default branch and supply its existing tag. The workflow checks
out that tag, checks/packages its files and replaces only its installable ZIP;
existing release notes and other assets remain. This does not move the tag.
After the prepared changes are committed and pushed, explicitly requested
publication uses an annotated stable tag (replace `X.Y.Z` with that version):

```sh
git tag -a vX.Y.Z -m "Raidwise X.Y.Z"
git push origin vX.Y.Z
```

Only publish/tag when explicitly requested. Release date metadata and README
badges should follow the released TOC, not an ordinary documentation edit.
