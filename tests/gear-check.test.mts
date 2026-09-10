import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

const modules = [
  "GearCheckCatalog", "GearCheckSets", "GearCheckTrinkets",
  "GearCheckProfiles", "GearCheckBis", "GearCheckRules", "GearCheck",
];

async function withAddon(run: (lua: Lua) => Promise<void>): Promise<void> {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync('return _VERSION'), "Lua 5.1");
    lua.doStringSync(await readFile(new URL("lua/wow-stubs.lua", import.meta.url), "utf8"));
    for (const name of modules) {
      const source = await readFile(new URL(`../Raidwise/${name}.lua`, import.meta.url), "utf8");
      lua.doStringSync(source.replace(/^\uFEFF/, ""));
    }
    await run(lua);
  } finally {
    lua.global.close();
  }
}

test("gear-check rule self-tests", async (context) => {
  await withAddon(async (lua) => {
    const count = lua.doStringSync(`
      local results, passed, total = Raidwise:GearCheckRulesSelfTest()
      local failures = {}
      for _, result in ipairs(results) do
        if not result.ok then failures[#failures + 1] = result.name end
      end
      assert(total > 0, "No rule checks were run")
      assert(passed == total, table.concat(failures, "\\n"))
      return total
    `);
    context.diagnostic(`${count} Lua rule checks passed`);
  });
});

test("gem collection, cache invalidation, and meta regressions", async () => {
  await withAddon(async (lua) => {
    lua.doStringSync(await readFile(new URL("lua/gear-check-gems.lua", import.meta.url), "utf8"));
  });
});

test("roster issue reports group codes, separate categories, and retain unknown checks", async () => {
  await withAddon(async (lua) => {
    lua.doStringSync(`
      local report = { character = { name = "Tester" }, findings = {
        { code = "GEM_NOT_CHECKABLE", category = "gem", severity = "info", slot = "neck" },
        { code = "GEM_NOT_CHECKABLE", category = "gem", severity = "info", slot = "wrist" },
        { code = "GEM_NOT_CHECKABLE", category = "gem", severity = "info", slot = "neck" },
        { code = "MISSING_ENCHANT", category = "enchant", severity = "soft", slot = "head" },
        { code = "WRONG_WEAPON", category = "weapon", severity = "hard", slot = "mainHand" },
      } }
      Raidwise.GetReportForm = function() return "full" end
      local lines = Raidwise:FormatGearCheckMemberIssues(report, "enchant")
      assert(#lines == 1)
      assert(lines[1] == "[Raidwise]-raid Tester Enchants/Gems: GEM_NOT_CHECKABLE - neck,wrist; MISSING_ENCHANT - head", lines[1])
      assert(Raidwise:FormatGearCheckMemberIssues(report, "gear")[1] == "[Raidwise]-raid Tester Gear: WRONG_WEAPON - MH")
      assert(#Raidwise:FormatGearCheckMemberIssues(nil, "gear") == 0)
      assert(Raidwise:FormatGearCheckMemberIssues({}, "gear")[1] == "[Raidwise]-raid ? Gear: No issues in this category.")
      for index = 1, 40 do
        report.findings[#report.findings + 1] = { code = "ISSUE_" .. index, category = "gem", severity = "soft", slot = "head" }
      end
      lines = Raidwise:FormatGearCheckMemberIssues(report, "enchant")
      assert(#lines > 1)
      for _, line in ipairs(lines) do
        assert(#line <= 220, line)
        assert(string.find(line, "[Raidwise]-raid Tester Enchants/Gems: ", 1, true) == 1, line)
      end
      assert(string.find(lines[#lines], "ISSUE_40", 1, true))
    `);
  });
});
