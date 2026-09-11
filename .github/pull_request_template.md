<!-- You can write in English or Russian. Remove sections and checklist items
that do not apply. Use a scoped Conventional Commit title, for example:
fix(export): include missing character data -->

## Summary

Describe the problem and the resulting behavior. Include a before/after example
when helpful, and link any related issues (for example, Closes #123).

## Validation

Describe the checks performed and their results. For code changes, run
`npm run check` where applicable. For in-game testing, include the Raidwise
version, WoW client build/language, and the steps or scenarios tested.
State any checks you could not perform.

## Screenshots

For visible UI changes, include before/after screenshots if available.

## Checklist

- [ ] Code remains compatible with Lua 5.1 and WoW 3.3.5a APIs (`Interface: 30300`).
- [ ] Relevant documentation is updated for behavior or usage changes.
- [ ] UI structure or geometry changes increment the relevant layout version and update `docs/UI-Views.md` (and `docs/UI-Sizes.md` when pixels change).
- [ ] Addon semver is unchanged unless a version bump or release was explicitly requested; requested releases follow `.agents/skills/bump/SKILL.md`.

## Risks or limitations

Note any known limitations, compatibility concerns, or follow-up work.
