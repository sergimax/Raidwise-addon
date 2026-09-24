import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("global Karma datasets validate, stage, replace atomically, and resolve by character id", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(`Raidwise={db={}}; function time() return 1000 end; function Raidwise:T(key) return key end`);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "SyncJSON", "KarmaData", "SyncData"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local addon=Raidwise
      addon:InitializeHistoryStore()
      local payload={format="RaidwiseKarma",reportVersion=1,datasetId="official",revision=2,publishedAt=900,
        characters=addon:SyncJSONArray({{character="Alice",characterId="A",race="Human",level=80,class="MAGE",rating=72}})}
      local text=assert(addon:EncodeSyncJSON(payload))
      assert(addon:StagePastedImport(text))
      assert(not addon:GetGlobalKarmaDataset())
      assert(addon:ApplyGlobalKarmaImport().revision==2)
      assert(addon:GetGlobalKarmaRecord({guid="A"}).rating==72)
      assert(addon:GetCommunityRating({guid="A",name="Alice"}).positivePercent==72)
      assert(not addon:StagePastedImport(text))
      payload.revision=3; payload.characters=addon:SyncJSONArray({{character="Alice",characterId="A",race="Human",level=80,class="MAGE",rating=85}})
      assert(addon:StageGlobalKarmaImport(assert(addon:EncodeSyncJSON(payload)),"web"))
      assert(addon:ApplyGlobalKarmaImport().recordsByCharacterId.A.rating==85)
      payload.characters=addon:SyncJSONArray({{character="Bad",characterId="A",race="Human",level=81,class="MAGE",rating=1}})
      assert(not addon:ValidateGlobalKarmaText(assert(addon:EncodeSyncJSON(payload))))
    `);
  } finally { lua.global.close(); }
});
