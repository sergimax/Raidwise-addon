import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

async function runScenario(scenario: string): Promise<void> {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    for (const path of ["lua/wow-stubs.lua", "lua/scan-runtime.lua", "../Raidwise/GearCheck.lua", "lua/scan-scenarios.lua"]) {
      lua.doStringSync((await readFile(new URL(path, import.meta.url), "utf8")).replace(/^\uFEFF/, ""));
    }
    lua.doStringSync(`RunScanScenario("${scenario}")`);
  } finally {
    lua.global.close();
  }
}

for (const scenario of ["repeated", "event-order", "missing", "deadline", "raid"]) {
  test(`scan lifecycle: ${scenario}`, () => runScenario(scenario));
}

// Executed desired-behavior assertions, not skipped tests. Remove TODO when fixed.
for (const scenario of ["identity", "spec-retry", "gem-retry"]) {
  test(`scan known defect: ${scenario}`, {
    todo: process.env.RAIDWISE_STRICT_SCAN_TESTS === "1" ? false : "Phase 4 inspect coordinator",
  }, () => runScenario(scenario));
}
