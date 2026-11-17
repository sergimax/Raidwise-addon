# Documentation map

This directory is organized by topic. Start with [Architecture.md](Architecture.md) for code ownership, load order, and project contracts.

| Folder | Contents |
|---|---|
| [ui/](ui/UI-Views.md) | UI task map/layout inventory, geometry owners and indexed design references. |
| [raid/](raid/Guild-Management.md) | Guild task map, external limits/manual checks and [composition navigation](raid/Raid-Composition.md). |
| [gear-check/](gear-check/Gear-Check-Progress.md) | Gear Check task map, compatibility, catalog maintenance and manual verification. |
| [characters/](characters/Reputation.md) | Character task map, storage constraints/repair, manual evidence and deferred exchange. |
| [adr/](adr/) | Reasons for consequential choices; read the record linked by the relevant task map. |
| [audits/](audits/Audit-2026-11-06-Evidence.md) | Dated historical measurements; optional evidence, not active specifications or backlog. |

`Architecture.md` is intentionally kept at the root as the task-routing entry point referenced by `AGENTS.md`.

## Documentation ownership

- Task maps route a change to its owner, entry point and behavior checks.
- Source and tests own executable behavior; update the relevant map when ownership moves.
- Keep necessary external format/platform limits and maintenance procedures beside
  their task map. Preserve non-obvious reasons near the code, or in a short ADR
  for consequential decisions; distinguish known reasons from guesses.
- Keep dated evidence separate from current status. State revision, environment
  and limits; an offline pass does not establish real-client acceptance.
- Remove completed plans and duplicate implementation descriptions after extracting
  constraints, unfinished obligations and nonreproducible evidence. Git retains history.
- For discrepancies describe the observed implementation, and separate suspected
  behavior defects for their own investigation rather than changing behavior to match prose.
