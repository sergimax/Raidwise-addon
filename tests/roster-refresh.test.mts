import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("roster bursts share collection with history and render only the visible view", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    for (const path of ["lua/wow-stubs.lua", "lua/scan-runtime.lua", "../Raidwise/PartyRoster.lua",
      "../Raidwise/RosterRefresh.lua", "../Raidwise/RaidComposition.lua", "../Raidwise/PlayerHistoryStore.lua"]) {
      lua.doStringSync(await readFile(new URL(path, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      Raidwise.db={}
      function GetNumRaidMembers() return 2 end
      function GetRaidRosterInfo(index) return "Name",nil,index end
      local collections,raidRenders,compositionRenders,historyWrites,inspects=0,0,0,0,0
      local version=1
      local forceScores
      Raidwise.CollectRaidMember=function(_,unit,refresh)
        collections=collections+1; forceScores=refresh
        return {unit=unit,guid=UnitGUID(unit),class="WARRIOR",name=unit,version=version}
      end
      Raidwise.CollectPartyMember=function() error("History recollected the shared roster") end
      local recorded={}
      Raidwise.UpsertHistoryMember=function(_,member)
        historyWrites=historyWrites+1; recorded[member.unit]=member
      end
      Raidwise.QueuePartyInspects=function() inspects=inspects+1 end
      Raidwise.mainFrame={selectedTab="raid",shown=true,IsShown=function(self) return self.shown end}
      Raidwise.RefreshRaidRosterView=function(_,refresh,snapshot)
        raidRenders=raidRenders+1
        assert(snapshot.groups[1][1]==recorded.raid1)
        assert(snapshot.byUnit.raid2==recorded.raid2)
        assert(snapshot.members[1].version==version)
      end
      Raidwise.RefreshCompositionView=function(self,refresh,snapshot)
        compositionRenders=compositionRenders+1
        local members=self:CompositionMembers(refresh,snapshot)
        assert(#members==2 and members[1]==recorded.raid1 and members[1].version==version)
      end
      Raidwise:RefreshPartyData(true)
      assert(inspects==1 and collections==0, "Inspect start was delayed or collection was immediate")
      for index=1,10 do Raidwise:ScheduleRosterRefresh(false) end
      ScanRuntime:Tick(0.01)
      assert(collections==2 and historyWrites==2 and raidRenders==1 and compositionRenders==0)
      assert(forceScores==true, "Strong refresh request was lost")
      ScanRuntime:Tick(0.01); assert(collections==2)
      version=2; ScanRuntime.identities.raid1="CHANGED"
      Raidwise.mainFrame.selectedTab="composition"
      Raidwise:ScheduleRosterRefresh(false); ScanRuntime:Tick(0.01)
      assert(collections==4 and recorded.raid1.guid=="CHANGED" and forceScores==false)
      assert(raidRenders==1 and compositionRenders==1)
      Raidwise.mainFrame.shown=false
      Raidwise:ScheduleRosterRefresh(false); ScanRuntime:Tick(0.01)
      assert(collections==6 and historyWrites==6 and raidRenders==1 and compositionRenders==1)
      -- A request raised during rendering must survive for the next frame.
      Raidwise.mainFrame.shown=true
      local render=Raidwise.RefreshCompositionView
      Raidwise.RefreshCompositionView=function(self,...)
        render(self,...); self:ScheduleRosterRefresh(false); self.RefreshCompositionView=render
      end
      Raidwise:ScheduleRosterRefresh(false); ScanRuntime:Tick(0.01); ScanRuntime:Tick(0.01)
      assert(collections==10 and compositionRenders==3)
    `);
  } finally { lua.global.close(); }
});
