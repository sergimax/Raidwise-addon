# Offline addon tests

Use Node.js 24.4 or later in the 24.x series and npm. From the repository root:

```sh
npm ci --ignore-scripts
npm run check
```

`npm run check` type-checks the TypeScript test runner and runs the tests. Use
`npm test` for tests alone or `npm run test:watch` while editing. Failures return
a nonzero exit status for CI.

The runner is TypeScript (`gear-check.test.mts`) using Node's built-in `node:test`
and `node:assert/strict`. Node runs the erasable TypeScript directly; `tsc` handles
type checking separately. The existing CommonJS scripts in `scripts/` keep their
module format.

The pinned [wasmoon-lua5.1](https://github.com/JX3BOX/wasmoon-lua5.1) dependency
executes the real addon Lua through WebAssembly. Each test creates an isolated VM,
asserts `_VERSION == "Lua 5.1"`, loads the modules in addon dependency order, and
closes the VM in `finally`. Python, Lupa, and a separate system Lua installation
are not required.

## Test files

- `gear-check.test.mts`: TypeScript orchestration, runtime guard, and test cases.
- `lua/wow-stubs.lua`: minimal offline WoW API substitutes.
- `lua/gear-check-gems.lua`: gem ID, partial-read, cache, and meta regressions
  migrated from the Python harness without removing assertions.
- `../Raidwise/GearCheckRules.lua`: the existing rule self-tests, also available
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

## Dump extraction (phase 3)

`GearCheckDump.lua` owns target/raid dump formatting, name resolution for dump
details, and asynchronous raid export jobs. Public methods and output are
unchanged. `dump.test.mts` covers synchronous/asynchronous output equality,
one-entry-per-frame progress, overlapping job rejection, completion cleanup,
cancellation exactly once, restart, empty results, and routing to the raid export
view or target text view. These checks passed before and after extraction.
Frame rendering and clipboard interaction still require an in-game check.

## Report preparation (phase 2)

`ChatReports.lua` owns final network-message preparation (255 UTF-8 bytes,
complete hyperlinks, and color resets). Self/unavailable-channel output remains
untruncated. `GearCheckReports.lua` owns gear report formatting; the existing
formatting APIs remain available, and `BuildGearCheckChatMessages` supplies the
final messages used by target previews and sending. Roster and composition
previews use the same finalizer as `SendReportChat`.

The final-message regression loads the real transport and verifies Cyrillic,
whole spell links, all gear report modes in Short/Full form, and local/network
preview equality. Existing grouping and composition tests remain in place.
Messages still send immediately; this phase adds no queue or pacing. Gear reports
now share the transport's existing unavailable-channel warning throttle.

## Scan refactoring baseline (phase 1)

`scan.test.mts` loads the real `GearCheck.lua` scheduler into an isolated Lua 5.1
VM for each scenario. `lua/scan-runtime.lua` supplies deterministic frames,
inspect events, unit identities, and elapsed time. `lua/scan-scenarios.lua` mocks
collection and evaluation so scheduler failures are isolated from gem rules.
Existing gem tests continue to exercise collection and normalization separately.

Passing scenarios cover consecutive target requests, rejection of overlapping
requests, idle/unrelated/duplicate inspect events, disappearance and recovery,
the four-second initial deadline, sequential raid requests, and resuming roster
inspects after completion. The roster resume callback is mocked; these tests do
not yet exercise PartyRoster.lua's queue or interference from other addons.

Three desired-behavior tests execute as TODOs and currently reproduce defects:

- `identity`: changing the target GUID before completion accepts the replacement
  character as a successful result for the original request.
- `spec-retry`: the additional inspect is sent, but the request immediately times
  out instead of using its extra two-second budget.
- `gem-retry`: the same early finalization occurs for uncertain gem data.

TODO failures are printed but do not fail the default check command. To run them
as blocking assertions in PowerShell:

```powershell
$env:RAIDWISE_STRICT_SCAN_TESTS = '1'
npm run check
Remove-Item Env:RAIDWISE_STRICT_SCAN_TESTS
```

Remove the TODO markers when the defects are fixed. No production behavior was
changed in phase 1. There is currently no target/raid scan cancellation API;
disappearance cleanup is covered, but explicit cancellation tests must accompany
the coordinator API in phase 4. Dump cancellation is a separate phase 3 concern.

### Timing baseline and in-game verification

Simulated baseline: a request with no inspect event releases the scanner at four
seconds; a two-member raid with events supplied 0.25 seconds apart completes at
0.5 simulated seconds with no extra successful-path wait. These are scheduling
observations, not real server latency or CPU performance measurements.

**Actual in-game baseline: pending.** Before changing inspect coordination:

1. Record addon commit, client/server, group size, online/in-range count, and
   whether other inspect addons are enabled. Use the same conditions afterward.
2. Scan the same target five times: record elapsed time, result status, and
   gem/meta/weapon consistency. Keep the first cold scan separate from repeats.
3. Run three full raid scans: record each elapsed time, completed/skipped/timeout
   counts, and any inconsistent reports. Record median and range.
4. During a target scan, switch target or let it disappear. Check recovery with
   another scan. During raid scanning, test a member leaving or going offline.
5. After phase 4, repeat this protocol and compare both correctness and duration.

Do not treat offline test runtime as the in-game baseline. Phase 1's automated
coverage is ready; its manual timing gate remains open until these observations
are recorded.

## Manual CI and future automation

`.github/workflows/tests.yml` runs the same install/check commands on Windows and
Linux. It has only `workflow_dispatch`, so it does not run on pushes or PRs. Once
the workflow is on GitHub's default branch, use **Actions → Addon tests → Run
workflow**. The workflow has been prepared locally; it has not been run on GitHub.

To automate later, add `pull_request:` and the desired `push:` branch filter
under `on:`. The test files and commands do not need to change.
