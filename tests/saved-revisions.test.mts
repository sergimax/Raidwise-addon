import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("saved snapshots detach observations, expire at the boundary and delete independently", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync("Raidwise={db={}}; local now=100; function time() return now end; function SetTime(value) now=value end");
    for (const module of ["GearCheckReport", "GearCheckSavedReports"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local report={character={guid="A",name="Original",unit="target"},equipment={
        {item={gems={{itemId=40113,stats={spellPower=23}}}}}}}
      local first=assert(Raidwise:SaveGearCheckReport(report))
      local saved=assert(Raidwise:GetGearCheckSavedReport(first))
      report.character.name="Changed"
      report.equipment[1].item.gems[1].stats.spellPower=99
      assert(saved.report.character.name=="Original")
      assert(saved.report.character.unit==nil and report.character.unit=="target")
      assert(saved.report.equipment[1].item.gems[1].stats.spellPower==23)
      assert(saved.report.equipment==saved.report.slots,"Snapshot compatibility aliases disagree")

      SetTime(101)
      local second=assert(Raidwise:SaveGearCheckReport(report))
      assert(first~=second and #Raidwise:ListGearCheckSavedReports("A")==2)
      SetTime(saved.expiresAt-1)
      assert(Raidwise:PruneExpiredGearCheckReports()==0)
      SetTime(saved.expiresAt)
      assert(Raidwise:PruneExpiredGearCheckReports()==1)
      assert(Raidwise:GetGearCheckSavedReport(first)==nil)
      assert(Raidwise:GetGearCheckSavedReport(second)~=nil,"Unexpired snapshot was removed")
      assert(Raidwise:DeleteGearCheckSavedReport(second))
      assert(not Raidwise:DeleteGearCheckSavedReport(second))
      assert(#Raidwise:ListGearCheckSavedReports("A")==0)
    `);
  } finally { lua.global.close(); }
});

test("saved report revisions are independent of release version and preserve legacy entries", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync("Raidwise={db={},version='1.21.0'}; function time() return 100 end");
    for (const module of ["GearCheckCatalog", "GearCheckReport", "GearCheckRules", "GearCheckSavedReports"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local report={schemaVersion=3,character={guid="A",name="Tester",unit="target"},equipment={}}
      local first=Raidwise:SaveGearCheckReport(report)
      local entry=Raidwise:GetGearCheckSavedReport(first)
      local rules,data=entry.rulesetVersion,entry.dataVersion
      assert(rules==Raidwise.GEAR_CHECK_RULESET_VERSION and data==Raidwise.GEAR_CHECK_DATA_VERSION)
      Raidwise.version="9.0.0"
      local second=Raidwise:GetGearCheckSavedReport(Raidwise:SaveGearCheckReport(report))
      assert(second.rulesetVersion==rules and second.dataVersion==data)
      assert(entry.report.schemaVersion==3 and entry.report.character.unit==nil)
      assert(report.character.unit=="target", "Saving mutated the source")
      entry.rulesetVersion="wotlk-3.3.5a-1.20.0"
      entry.dataVersion="legacy-catalog"
      assert(Raidwise:GetGearCheckSavedReport(first)==entry)
      assert(#Raidwise:ListGearCheckSavedReports("A")==2)
      assert(entry.rulesetVersion=="wotlk-3.3.5a-1.20.0" and entry.dataVersion=="legacy-catalog")
      Raidwise.GEAR_CHECK_RULESET_VERSION="test-next-revision"
      assert(Raidwise:GetGearCheckRulesetVersion()~=rules and Raidwise:GetGearCheckDataVersion()==data)
      Raidwise.GEAR_CHECK_DATA_VERSION="catalog-next"
      assert(Raidwise:GetGearCheckRulesetVersion()=="test-next-revision")
      Raidwise.GEAR_CHECK_RULESET_VERSION=nil; Raidwise.GEAR_CHECK_DATA_VERSION=nil
      assert(Raidwise:GetGearCheckRulesetVersion()=="unknown" and Raidwise:GetGearCheckDataVersion()=="unknown")
      assert(entry.rulesetVersion=="wotlk-3.3.5a-1.20.0")
    `);
  } finally { lua.global.close(); }
});
