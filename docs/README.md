# Documentation map

This directory is organized by topic. Start with [Architecture.md](Architecture.md) for code ownership, load order, and project contracts.

| Folder | Contents |
|---|---|
| [ui/](ui/) | Window/page layout references, pixel sizes, and HTML visual previews including theme and raid-scan colors. |
| [raid/](raid/) | Raid composition and EPGP design notes. |
| [gear-check/](gear-check/) | Gear Check specification, progress tracker, and item-surface rules. |
| [characters/](characters/Reputation.md) | Character task map, storage constraints/repair, manual evidence and deferred exchange. |
| [adr/](adr/) | Reasons for consequential choices; read the record linked by the relevant task map. |
| [audits/](audits/) | Dated repository audits and evidence. |

`Architecture.md` is intentionally kept at the root as the task-routing entry point referenced by `AGENTS.md`.

For character work, keep entry points and checks in the task map; put executable
behavior in source/tests. Preserve non-obvious reasons beside the relevant code
or in a short decision record, and keep dated evidence separate from current status.
