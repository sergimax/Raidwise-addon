# Guild and composition manual checks

Use the [guild map](Guild-Management.md) and [composition map](Raid-Composition.md)
for automated suites. The removed feasibility/implementation plans recorded
proposed checks, not successful in-client acceptance. No dated user acceptance
results were present in those documents.

## Guild server and permission matrix

Exercise an ordinary member, officer-note read-only access, an editing officer
and guild master on the target server. Record date, commit, client/server, role,
other guild/inspect addons and the exact scenarios/results.

- Include offline members; check complete snapshot publication, real progress,
  slow replies, changed counts and last-good-snapshot retention on failure.
- Edit public/officer notes, with an intervening edit by another officer; check
  retained drafts, conflict handling, partial confirmation and uncertain timeout.
  Observe the actual result before manually retrying.
- Check promote/demote rank restrictions and current recipient after roster
  reordering. Lose read/edit permissions while the editor/journal is visible.
- Close/reopen during a pending operation, change guild, and verify restoration
  of offline visibility alongside other addons using the same game setting.
- Import overlapping/ageing server event windows, compare server-vs-observation
  labels, reduce retention and check all archives after restart/reload.
- Validate BASE_GP and alt-note conventions against this guild's actual data;
  confirm local roll eligibility is only a display decision.
- Check both locales/themes, long notes/names, filters, scroll/header alignment,
  pagination, selected-row highlight and preserved drafts.

## Composition presentation

Check solo, party and active raid groups versus reserves, unknown/known specs as
inspect results arrive, role/class counts and changed roster membership. Inspect
long source tooltips and reports in both locales/themes. Exercise native spell
links and hover with the real chat skin; compare preview and sent messages.
Potential coverage is not proof of actual talents, pets, buffs or assignments.

Mock passes do not establish native UI rendering, server history depth, actual
command confirmation or crash-safe disk persistence. These evidence gaps are not
confirmed defects and do not block cleanup that preserves those scenarios.
