# Raidwise project instructions

This file is the shared source of project rules for Codex and Cursor.

## Code style

- Target Lua 5.1 and WoW 3.3.5a APIs only (`Interface: 30300`); do not use retail or Classic APIs.
- Keep addon state on the single `Raidwise` namespace table; use `local` for internals.
- Prefer small, focused functions and early returns over deep nesting.
- Do not introduce Ace3 or other libraries unless explicitly requested.
- Match existing formatting and indentation in touched files.

## Editing

- Prefer editing existing files over creating new ones; keep changes within the requested scope.
- If a linter or checker is configured, run the relevant checks after changes and fix new issues.
- This repository is a WoW addon; do not import React, TypeScript, or Vite conventions from other projects.

## Naming

- The addon lives in `Raidwise/`, including `Raidwise.toc` and `Raidwise.lua`; install that folder into `Interface/AddOns/Raidwise/`.
- Prefer PascalCase for major module filenames and public addon methods, such as `ExporterWindow.lua` and `Addon:OnInitialize`.
- Prefer camelCase or descriptive locals for private helpers; names such as `EnsureDB` and `DeepCopy` are fine when matching existing style.
- Use descriptive local and parameter names such as `event`, `unit`, `itemLink`, and `character` instead of `v`, `d`, `c`, or `e`.
- Keep shipped SavedVariables and slash-command keys stable, including `RaidwiseDB` and `SLASH_RAIDWISE1`.

## Commit messages

When creating commits, use Conventional Commits: `<type>[optional scope]: <description>`.
Use `feat` for features, `fix` for fixes, `docs` for documentation, `style` for formatting,
`refactor` for refactoring, `perf` for performance, `test` for tests, and `chore` for tooling.
Mark breaking changes with `!` after the type/scope or a `BREAKING CHANGE` footer.
Example: `feat(export): add glyph socket export`.

## Versioning and changelog

- Use semantic versions (`MAJOR.MINOR.PATCH`): PATCH for fixes and minor tweaks, MINOR for non-breaking features, MAJOR for breaking changes.
- Keep `## Version` in `Raidwise/Raidwise.toc` synchronized with `Addon.version` in `Raidwise/Raidwise.lua`.
- Ordinary edits do not trigger a semver release. Bump the addon version only when the user requests a bump or release.
- For a requested release, follow the shared workflow in [.agents/skills/bump/SKILL.md](.agents/skills/bump/SKILL.md). In Codex CLI/IDE, it can be invoked with `$bump`.
- Update root `CHANGELOG.md` using Keep a Changelog: `## [X.Y.Z] - YYYY-MM-DD`, newest release first. Use only applicable `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` sections.
- Entries must describe actual user-facing changes from commits and diffs since the previous release. Do not add filler such as "version bump for release".
- If there are no notable user-facing changes, do not cut a release unless the user explicitly requests an exception and its reason is documented.
- Do not create a commit or tag unless requested.

## Layout versions

Apply these rules when changing UI structure or geometry in `Raidwise/**/*.lua`,
or updating `docs/UI-Views.md` and `docs/UI-Sizes.md`. Layout versions (`vN`) are
independent of addon semver (`Addon.version`).

Bump the relevant layout constant for new or removed panels, tabs, or columns;
changed anchors, sizes, or scroll areas; named frames that must be recreated;
or shared `Addon.UITheme` sizes affecting existing views.

Do not bump layout versions for locale/string-only edits, data-only logic
(rosters, export JSON, lockout math), or colors without geometry changes.
User-visible color tweaks can qualify for PATCH in a requested semver release.

| View | Constant | Module |
|------|----------|--------|
| Main shell | `SHELL_LAYOUT_VERSION` | `Raidwise/ExporterWindow.lua` |
| Profile popup | `PROFILE_LAYOUT_VERSION` | `Raidwise/CharacterProfile.lua` |
| Content pages | `LAYOUT_VERSION` on `Addon.Pages.*` | `Raidwise/Page*.lua` |

- Read the current constant from code; start new views at `1` and increment by one per structural change. Profile versions may jump for large refactors; keep one constant per profile window generation.
- Stamp `frame.layoutVersion` or `page.layoutVersion` in `Create`, and ensure rebuild logic compares it with the registered constant.
- Content page badges belong in the shell title bar via `UpdateShellHeader` in `ExporterWindow.lua`, showing page name plus `vN`; do not add per-page toolbar badges.
- Profile badges use `Addon.Widgets.AttachLayoutVersionLabel` on the profile title bar.
- `SHELL_LAYOUT_VERSION` is for rebuilding only and is not shown in the title bar.
- Update the layout table in `docs/UI-Views.md`; update affected sizes in `docs/UI-Sizes.md` when pixels change.
