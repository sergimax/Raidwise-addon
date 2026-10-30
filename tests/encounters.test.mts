import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

async function run(body: string) {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync(`
      Raidwise={db={}};now=1000;observer='SELF';zone='First';raid=false;group={'X'};timers={}
      function time() return now end
      function GetRealmName() return 'Realm' end
      function UnitGUID(unit)
        if unit=='player' then return observer end
        return group[tonumber(unit:match('%d+'))]
      end
      function UnitName(unit) return UnitGUID(unit),'Realm' end
      function UnitClass() return 'Mage','MAGE' end
      function GetNumPartyMembers() return not raid and #group or 0 end
      function GetNumRaidMembers() return raid and #group or 0 end
      function CreateFrame() return {SetScript=function(_,_,fn) timers[#timers+1]=fn end} end
      function Raidwise:CaptureEventContext() return {zoneName=zone} end
      function GetRealZoneText() return zone end
      function Raidwise:T(key) return key end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "PlayerRecords", "CharacterLinks", "PlayerRecordBridge", "PlayerEncounters"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync("Raidwise:InitializeHistoryStore()");
    const parts = body.split("-- RELOAD");
    for (let index = 0; index < parts.length; index++) {
      if (index > 0) {
        lua.doStringSync(await readFile(new URL("../Raidwise/PlayerEncounters.lua", import.meta.url), "utf8"));
      }
      lua.doStringSync(parts[index]);
    }
  } finally { lua.global.close(); }
}

test("presence sessions deduplicate members, survive quiet groups, zone and raid transitions", async () => {
  await run(`
    local a=Raidwise
    group={'X','X','SELF'};a:RecordCurrentGroupHistory(false)
    assert(a:GetCharacterMeetingStats('X').count==1)
    assert(a:GetCharacterMeetingStats('SELF').count==0)
    for i=1,30 do now=now+30;timers[1](nil,30) end
    assert(a:GetCharacterMeetingStats('X').count==1)
    raid=true;zone='Second';a:RecordCurrentGroupHistory(false)
    local meetings=a:GetCharacterEncounters('X');assert(#meetings==1 and #meetings[1].places==2)
    zone='First';now=now+1;a:RecordCurrentGroupHistory(false)
    assert(a:BuildHistoryRoster(false)[1].lastSeenZone=='First')
    group={};a:RecordCurrentGroupHistory(false)
    now=now+300;group={'X'};a:RecordCurrentGroupHistory(false)
    assert(a:GetCharacterMeetingStats('X').count==1)
    group={};a:RecordCurrentGroupHistory(false)
    now=now+301;group={'X'};a:RecordCurrentGroupHistory(false)
    assert(a:GetCharacterMeetingStats('X').count==2 and #a:GetCharacterEncounters('X')==2)
    local roster=a:BuildHistoryRoster(false);assert(#roster==1 and roster[1].meetCount==2)
    assert(a:GetHistoryEntry('X').meetCount==nil)
    meetings[1].places[1].zoneName='mutated'
    assert(a:GetCharacterEncounters('X')[1].places[1].zoneName=='First')
  `);
});

test("observer counts and history stay independent, scans never create encounters", async () => {
  await run(`
    local a=Raidwise
    a:RecordTargetScanHistory({character={guid='SCAN',name='Scanned',realm='Realm',gearScore=5000},collection={collectedAt=now}})
    assert(a:GetHistoryEntry('SCAN').gearScore==5000)
    assert(a:GetCharacterMeetingStats('SCAN').count==0 and #a:BuildHistoryRoster(false)==0)
    a:RecordCurrentGroupHistory(false);assert(a:GetCharacterMeetingStats('X').count==1)
    observer='ALT';assert(a:GetCharacterMeetingStats('X').count==0 and #a:BuildHistoryRoster(false)==0)
    now=now+1;a:RecordCurrentGroupHistory(false)
    assert(a:GetCharacterMeetingStats('X').count==1 and a:GetCharacterMeetingStats('X','SELF').count==1)
    local d=a:CreatePlayerRecordDraft('X');d.note='shared';assert(a:CommitPlayerRecordDraft(d))
    assert(#a:BuildHistoryRoster(true)==1)
    observer='SELF';assert(a:GetProfileNotes({guid='X'})=='shared')
    assert(a:HistoryProfileForMember({guid='X',name='X'}).meetCount==1)
  `);
});

test("age pruning preserves counters, identities, opinions, notes, events and journals", async () => {
  await run(`
    local a=Raidwise;a:RecordCurrentGroupHistory(false)
    local d=a:CreatePlayerRecordDraft('X');d.opinion='negative';d.note='keep'
    assert(a:AddPlayerRecordDraftEvent(d,'afk'));assert(a:CommitPlayerRecordDraft(d))
    local journal=#a:GetProfileChanges({guid='X'})
    group={};a:RecordCurrentGroupHistory(false)
    now=1000+14*86400;a:PruneHistory();assert(#a:GetCharacterEncounters('X')==1)
    now=now+1;a:PruneHistory();assert(#a:GetCharacterEncounters('X')==0)
    assert(a:GetCharacterMeetingStats('X').count==1 and a:GetHistoryEntry('X'))
    assert(a:GetPersonalRating({guid='X'}).opinion=='negative' and a:GetProfileNotes({guid='X'})=='keep')
    assert(#a:GetHistoryEvents({guid='X'})==1 and #a:GetProfileChanges({guid='X'})==journal)
    assert(#a:BuildHistoryRoster(false)==0 and #a:BuildHistoryRoster(true)==1)
    group={'X'};a:RecordCurrentGroupHistory(false);assert(a:GetCharacterMeetingStats('X').count==2)
  `);
});

test("persisted sessions continue after short unobserved gaps, split after long gaps", async () => {
  await run(`
    local a=Raidwise;a:RecordCurrentGroupHistory(false)
    -- RELOAD
    local a=Raidwise
    now=now+300;a:RecordCurrentGroupHistory(false)
    assert(a:GetCharacterMeetingStats('X').count==1)
    -- RELOAD
    local a=Raidwise
    now=now+301;a:RecordCurrentGroupHistory(false)
    assert(a:GetCharacterMeetingStats('X').count==2)
    a:InitializeHistoryStore();assert(a:GetCharacterMeetingStats('X').count==2)
  `);
});
