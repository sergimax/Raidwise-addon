---
name: bump
description: Bump Raidwise addon semver, write a user-facing changelog, and synchronize release documentation when explicitly invoked or asked to bump or release the version.
---

# Version bump and changelog

Read the repository's [AGENTS.md](../../../AGENTS.md), especially "Versioning and
changelog", before making release edits. Paths below are relative to the repository root.
This is the shared workflow for Codex `$bump` and the Cursor `/bump` adapter.

## 1. Establish the release changes

- Read `## Version` in `Raidwise/Raidwise.toc` and `Addon.version` in `Raidwise/Raidwise.lua`.
- If they differ, determine the intended current version from release history and existing edits before synchronizing them; do not guess which value is authoritative.
- Review commits and the working diff of addon sources and docs since the previous tagged/released version. If there is no tag, use the commit corresponding to the last `CHANGELOG.md` release entry; if that baseline cannot be established, explain the uncertainty rather than inventing release changes.
- Identify user-facing changes to commands, SavedVariables, exports, UI, installation, or breaking names.
- If there are no notable user-facing changes, explain why and stop without bumping, unless the user explicitly requested a documented exception under the project release policy.

## 2. Choose and synchronize the version

Use the requested version when supplied; otherwise select MAJOR, MINOR, or PATCH
under `AGENTS.md`. Treat `BREAKING CHANGE` or `!` commits as evidence for MAJOR.
Set the same `X.Y.Z` in both version locations. Never bump just one file.

## 3. Write the changelog

Add the release above older entries in root `CHANGELOG.md`, following the format
and sections in `AGENTS.md`. Use today's date unless specified otherwise.
Include only sections with real bullets, with one clear bullet per user-visible
change supported by the reviewed commits/diff. Do not write filler about bumping
the version or release hygiene.

## 4. Synchronize documentation

Compare the released public surface against README and relevant docs:

| Check | Documentation |
|-------|---------------|
| Slash commands, aliases, subcommands | README Usage |
| Installation, folder, TOC title | README Install |
| Layout and new Lua modules | README Layout and UI docs |
| SavedVariables names | README Notes |
| New exported globals or user-facing APIs | README or dedicated docs |

Document new behavior and remove or correct descriptions of removed behavior
in the same bump. Check corresponding translated README sections when present.

## 5. Verify and report

Verify the two version values and changelog heading agree, and review the diff
for release accuracy and documentation coverage. Report the new version,
changelog bullets, and documentation updates. Do not create a commit or tag
unless the user requested it.
