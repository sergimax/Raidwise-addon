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
