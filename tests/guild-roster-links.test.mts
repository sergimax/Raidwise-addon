import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("guild main and alt resolution reports groups and unsafe links", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync("Raidwise = {}\n");
    for (const name of ["GuildRosterParser", "GuildRosterLinks"]) {
      lua.doStringSync((await readFile(new URL(`../Raidwise/${name}.lua`, import.meta.url), "utf8")).replace(/^\uFEFF/, ""));
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
