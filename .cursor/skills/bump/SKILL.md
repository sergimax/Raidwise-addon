---
name: bump
description: >-
  Bump the addon semver, update CHANGELOG.md, and sync docs for new
  user-facing behavior. Use only when the user invokes /bump or explicitly
  asks to bump/release the version.
disable-model-invocation: true
---

# /bump — Version bump & changelog

Follow `.cursor/rules/versioning-changelog.mdc` exactly. Do not invent a
different versioning or changelog style.

## When to stop without releasing

If there are **no notable user-facing changes** since the previous release
(only internal refactors, comment-only edits, etc.), do **not** bump.
Tell the user why and stop.

## Workflow

Copy and track:

```
Bump progress:
- [ ] 1. Diff since last release
- [ ] 2. Choose MAJOR / MINOR / PATCH
- [ ] 3. Bump version in toc + lua
- [ ] 4. Write CHANGELOG.md entry
- [ ] 5. Sync README / docs for new public surface
- [ ] 6. Summarize for the user (do not commit unless asked)
```

### 1. Diff since last release

- Read current version from `mrc-exporter/mrc-exporter.toc` (`## Version`)
  and `Addon.version` in `mrc-exporter/mrc-exporter.lua` — they must already
  match; if not, fix that first.
- Collect changes since the previous tagged/released version (or since the
  last `CHANGELOG.md` entry if no tag): commits + diff of addon sources and docs.
- Focus on **user-facing** changes: slash commands, SavedVariables, export
  behavior, UI, install steps, breaking renames.

### 2. Choose bump type

Per versioning-changelog.mdc:

| Bump | When |
|------|------|
| **PATCH** | Bug fixes, minor tweaks |
| **MINOR** | New features, non-breaking changes |
| **MAJOR** | Breaking changes |

If commits include `BREAKING CHANGE` / `!`, prefer **MAJOR**.

### 3. Bump version (both places)

Set the same `X.Y.Z` in:

1. `mrc-exporter/mrc-exporter.toc` → `## Version: X.Y.Z`
2. `mrc-exporter/mrc-exporter.lua` → `Addon.version = "X.Y.Z"`

Never bump only one file.

### 4. Update CHANGELOG.md

- File: `CHANGELOG.md` at repo root
- Keep a Changelog format
- New entry **at the top** (above older releases):

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Changed
- ...

### Fixed
- ...
```

Rules:

- Use today's date (`YYYY-MM-DD`) unless the user specifies otherwise.
- Include only sections that have real bullets: `### Added`, `### Changed`,
  `### Deprecated`, `### Removed`, `### Fixed`, `### Security`.
- Describe **actual** changes from the diff/commits — not “bump version”,
  “chore”, or empty filler.
- One clear bullet per user-visible change.

### 5. Docs check (required)

Compare public surface in code vs docs:

| Check | Where |
|-------|--------|
| Slash commands (`/mrc`, aliases, subcommands) | `README.md` Usage |
| Install / folder / TOC title | `README.md` Install |
| Layout / new Lua modules | `README.md` Layout |
| SavedVariables name | `README.md` Notes |
| New exported globals or user-facing APIs | README (or dedicated docs if present) |

If code added commands, modules, or behavior not mentioned in docs, **update
the docs in the same bump**. If docs mention removed behavior, fix or remove
those lines.

### 6. Finish

- Do **not** create a git commit or tag unless the user asks.
- Report: new version, changelog bullets written, and any doc updates made.

## Anti-patterns

- Bumping for “release hygiene” with nothing user-facing
- Changelog that only says “version bump”
- Updating toc version but leaving `Addon.version` stale (or the reverse)
- Skipping the README/docs pass after adding slash commands or modules
