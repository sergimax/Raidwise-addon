<!-- You can write in English or Russian. Remove sections and checklist items
that do not apply. Use a scoped Conventional Commit title, for example:
fix(export): include missing character data -->

# Checklist

- [ ] Run `npm run check` to test addon code under Lua 5.1; verify WoW 3.3.5a API compatibility (`Interface: 30300`) in game.
- [ ] Run `/rw diagnose` in game.
- [ ] Relevant documentation is updated for behavior or usage changes.
- [ ] UI structure or geometry changes increment the relevant layout version and update `docs/UI-Views.md` (and `docs/UI-Sizes.md` when pixels change).
- [ ] Addon semver is unchanged unless a version bump or release was explicitly requested; requested releases follow `.agents/skills/bump/SKILL.md`.

# Summary

<!--
Describe the problem and the resulting behavior.
Include a before/after example when helpful, and link any related issues (for example, Closes #123).
-->
