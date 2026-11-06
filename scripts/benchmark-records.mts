import { readFileSync } from "node:fs";
import { performance } from "node:perf_hooks";
import { Lua } from "wasmoon-lua5.1";
import { execFileSync } from "node:child_process";

// Synthetic read workload, not a client FPS benchmark. No user SavedVariables.
const baseline = process.argv.includes("--baseline");
const dense = process.argv.includes("--dense");
for (const size of [1000, 10000]) {
  const lua = await Lua.create();
  try {
    lua.doStringSync(`
      Raidwise={db={}};function time() return 1000 end
      function GetRealmName() return 'Realm' end
      function UnitGUID() return 'SELF' end
      function UnitName() return 'Me','Realm' end
      function ChatFrame_AddMessageEventFilter() end
      function CreateFrame() return {SetScript=function() end} end
    `);
    for (const module of ["PlayerRecords", "PlayerRecordSupport", "PlayerRecordBridge", "PlayerEncounters", "RatingPresentation"]) {
      lua.doStringSync(baseline
        ? execFileSync("git", ["show", `HEAD:Raidwise/${module}.lua`], {encoding:"utf8"})
        : readFileSync(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      Raidwise:InitializeHistoryStore();local s=Raidwise:GetPlayerRecordStore()
      s.encounters.SELF={};s.meetingStats.SELF={}
      for i=1,${size} do
        local key='G'..i
        s.identities[key]={guid=key,name='Player'..i,realm='Realm',class='MAGE'}
        if ${dense} or i<=10 or i==${size} then
          s.profiles[key]={opinion='positive',facts={},events={},updatedAt=1}
          s.encounters.SELF[key]={{lastSeenAt=1000,places={}}}
          s.meetingStats.SELF[key]={count=1}
        end
      end
    `);
    const measure = (body: string) => {
      const start = performance.now(); lua.doStringSync(body); return +(performance.now() - start).toFixed(2);
    };
    const coldLookupMs = measure(`assert(Raidwise:FindOpinionCharacter('Player${size}'))`);
    const lookup100Ms = measure(`for i=1,100 do assert(Raidwise:FindOpinionCharacter('Player${size}')) end`);
    const database10Ms = measure(`for i=1,10 do assert(#Raidwise:BuildHistoryRoster(true)==${dense ? size : 11}) end`);
    const history10Ms = measure(`for i=1,10 do assert(#Raidwise:BuildHistoryRoster(false)==${dense ? size : 11}) end`);
    console.log(JSON.stringify({source:baseline ? "HEAD" : "worktree", dense, identities:size, coldLookupMs, lookup100Ms, database10Ms, history10Ms}));
  } finally { lua.global.close(); }
}
