# Gear Check manual verification

Offline suite selection is in the [task map](Gear-Check-Progress.md).
The removed implementation phases/specification recorded intended checks,
not user acceptance results. No real-client timing baseline was recorded there.
Passing mocks establish neither live server latency nor tooltip/skin behavior.

## Before and after inspect/collector changes

1. Record addon commit, client/server, group size, online/in-range counts and
   other inspect addons. Keep conditions comparable for the next run.
2. Scan the same target five times; record elapsed time, completeness and
   gem/meta/weapon consistency. Separate the first cold scan from repeats.
3. Run three raid scans; record duration, completed/skipped/timeouts and any
   inconsistent results. Compare median and range, not offline test duration.
4. Switch target or let it disappear during collection, then rescan. During a
   raid scan, have a member leave/go offline. Check cancellation/restart and
   subsequent roster-inspect handoff, including other inspect addons enabled.
5. Repeat the protocol after the change and compare correctness and duration.

Unconfirmed empty sockets and absent talent data require special attention.
Exercise delayed item/gem cache reads and localized socket-tooltip labels in
both supported locales. Use request traces/talent diagnostics from dumps rather
than attributing an incomplete verdict to a missing event by itself.

## Reports, persistence and views

For affected changes check:

- Both locales/themes, target and raid pages, long content, saved selection,
  preview/send equality and actual clipboard copying from text exports.
- Save/list/delete, retention and persistence after `/reload`; saving in memory
  is not itself evidence of a disk write. Capture the original saved metadata
  before checking behavior under a different installed rules/catalog revision.
- Target/raid dump progress, cancel/restart and navigation while an asynchronous
  dump job is active. Preserve completed scan results on cancellation.
- Short/full network reports with Cyrillic, item/spell links and long names.
  Observe realm flood behavior; message length correctness does not establish
  safe multi-message bursts.

Record date, revision and exact scenarios/results for new client evidence.
These evidence gaps are not confirmed defects and do not block documentation
cleanup that leaves the corresponding behavior unchanged.
