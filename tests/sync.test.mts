import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("sync JSON, consent, provenance, privacy, transport and rejection contracts", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "CharacterLinks", "RatingPresentation", "SyncJSON", "SyncData", "SyncTransport"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(await readFile(new URL("lua/sync.lua", import.meta.url), "utf8"));
  } finally { lua.global.close(); }
});
