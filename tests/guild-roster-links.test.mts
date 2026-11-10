import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("guild main and alt resolution reports groups and unsafe links", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync("Raidwise = {}\n");
    for (const name of ["GuildRosterParser", "GuildRosterLinks"]) {
      lua.doStringSync((await readFile(new URL(`../Raidwise_EPGP/${name}.lua`, import.meta.url), "utf8")).replace(/^\uFEFF/, ""));
    }
    lua.doStringSync(`
      local snapshot={members={
        {name="Main",officerNote="22400,500"},
        {name="Alt",officerNote=" main "},
        {name="AltTwo",officerNote="Alt"},
        {name="Missing",officerNote="Nobody"},
        {name="Self",officerNote="Self"},
        {name="CycleA",officerNote="CycleB"},
        {name="CycleB",officerNote="CycleA"},
        {name="Conflict",officerNote="Main"},
        {name="Dup",officerNote="1,1"},
        {name="Dup",officerNote="2,2"},
        {name="PointsToDup",officerNote="Dup"},
      }}
      local parsed=Raidwise.GuildRosterParser.ParseGuildRosterSnapshot(snapshot)
      local result=Raidwise.GuildRosterLinks.Resolve(parsed)
      assert(result.members[2].mainIndex==1 and result.members[2].linkStatus=="linked", "direct alt: "..tostring(result.members[2].mainIndex).."/"..tostring(result.members[2].linkStatus).."/"..tostring(result.members[2].officerNoteParsed.status))
      assert(result.members[3].mainIndex==1 and result.members[3].linkStatus=="chain", "alt chain")
      assert(result.members[4].linkStatus=="unresolved", "missing main")
      assert(result.members[5].linkStatus=="invalid", "self link")
      assert(result.members[6].linkStatus=="cycle" and result.members[7].linkStatus=="cycle", "cycle")
      assert(result.members[8].linkStatus=="linked", "alt to main balance")
      assert(result.members[11].linkStatus=="ambiguous", "duplicate main")
      assert(#result.characterGroups==3 and #result.characterGroups[1].memberIndexes==4, "group members")
    `);
  } finally { lua.global.close(); }
});

test("guild EPGP calculations apply GP base and BIS EP threshold", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync("Raidwise = {}\n");
    for (const name of ["GuildEPGP"]) {
      lua.doStringSync((await readFile(new URL(`../Raidwise_EPGP/${name}.lua`, import.meta.url), "utf8")).replace(/^\uFEFF/, ""));
    }
    lua.doStringSync(`
      local snapshot={members={
        {name="Main",mainBalance={ep=4000,gp=0},mainIndex=1,linkStatus="main"},
        {name="Alt",mainIndex=1,linkStatus="linked"},
        {name="Below",mainBalance={ep=3999,gp=100},mainIndex=3,linkStatus="main"},
        {name="Unknown",linkStatus="unresolved"},
        {name="Bad",mainBalance={ep=-1,gp=500},mainIndex=5,linkStatus="main"},
        {name="MissingGP",mainBalance={ep=1000},mainIndex=6,linkStatus="main"},
      }}
      local result=Raidwise.GuildEPGP.Calculate(snapshot)
      assert(result.epgpSettings.minimumGP==500 and result.epgpSettings.bisMinimumEP==4000)
      assert(result.members[1].effectiveGP==500 and result.members[1].pr==8 and result.members[1].bisEligible)
      assert(result.members[2].balanceOwnerIndex==1 and result.members[2].bisEligible)
      assert(result.members[3].effectiveGP==600 and result.members[3].pr==3999/600 and result.members[3].bisEligible==false)
      assert(result.members[4].prStatus=="unknown" and result.members[4].bisEligibilityStatus=="unknown")
      assert(result.members[5].prStatus=="invalid")
      assert(result.members[6].effectiveGP==500 and result.members[6].pr==2)
      local described=Raidwise.GuildEPGP.Calculate({members={{name="Example",mainBalance={ep=106370,gp=1599},mainIndex=1}}})
      assert(described.members[1].effectiveGP==2099 and described.members[1].pr==106370/2099)
      local custom=Raidwise.GuildEPGP.Calculate(snapshot,{bisMinimumEP=4500})
      assert(custom.members[1].pr==8 and custom.members[1].bisEligible==false)
    `);
  } finally { lua.global.close(); }
});

test("raid planner GearScore threshold accepts compact note values", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync("Raidwise = {}\n");
    const page = (await readFile(new URL("../Raidwise_EPGP/PageRaidPlanner.lua", import.meta.url), "utf8")).replace(/^\uFEFF/, "");
    lua.doStringSync(page);
    lua.doStringSync(`
      assert(Raidwise.RaidPlannerGearScoreThreshold("5800") == 5800)
      assert(Raidwise.RaidPlannerGearScoreThreshold("5.8") == 5800)
      assert(Raidwise.RaidPlannerGearScoreThreshold("6") == 6000)
      assert(Raidwise.RaidPlannerGearScoreThreshold("6,2") == 6200)
    `);
  } finally { lua.global.close(); }
});
