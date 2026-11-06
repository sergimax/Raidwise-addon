import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

async function run(body: string) {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    for (const module of ["PlayerRecords", "PlayerRecordSupport", "PlayerRecordBridge", "PlayerRecordLinks", "PlayerEncounters", "RatingPresentation"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync("Raidwise:InitializeHistoryStore()");
    lua.doStringSync(body);
  } finally { lua.global.close(); }
}

test("screen reads are detached, including linked identities and roster authors", async () => {
  await run(`
    local a=Raidwise;local s=a:GetPlayerRecordStore()
    a:EnsureHistoryEntryForGuid('X',{name='Other'});a:EnsureHistoryEntryForGuid('Y',{name='Second'})
    a:SavePersonalRatingForGuid('X',nil,'positive',{},{});a:LinkPlayerCharacters('X','Y')
    s.identities.X.extra={nested='original'}
    local entry=a:GetHistoryEntry('X');entry.name='changed';entry.extra.nested='changed'
    local all=a:HistoryStore();all.X.extra.nested='changed';all.Y=nil
    for _,row in ipairs(a:GetLinkedCharacters('X')) do row.entry.name='changed' end
    a:GetCharacterLinkCandidates('Y','Other') -- linked member excluded
    a:UnlinkPlayerCharacter('X','Y')
    a:GetCharacterLinkCandidates('Y','Other')[1].extra.nested='changed'
    local roster=a:BuildHistoryRoster(true);roster[1].profileAuthor.name='changed'
    a:FindOpinionCharacter('Other').name='changed'
    assert(s.identities.X.name=='Other' and s.identities.X.extra.nested=='original' and s.identities.Y)
    assert(s.profiles.X.author.name=='Me')
    a:UpsertHistoryMember({guid='X',name='Other',gearScore=5000})
    assert(a:GetHistoryEntry('X').gearScore==5000)
    a:RecordTargetScanHistory({character={guid='X',name='Other'},collection={collectedAt=123}})
    assert(a:GetHistoryEntry('X').lastScannedAt==123)
  `);
});

test("name index follows rename, GUID upgrade, recovery and profile deletion", async () => {
  await run(`
    local a=Raidwise;local s=a:GetPlayerRecordStore()
    local alias=a:AddCharacterRecord('Other').guid
    a:SavePersonalRatingForGuid(alias,nil,'negative',{}, {})
    assert(a:FindOpinionCharacter('other-R E A L M').guid==alias)
    assert(a:UpsertPlayerRecordIdentity({guid='X',name='Other'})=='X')
    assert(a:FindOpinionCharacter('Other').guid=='X')
    assert(not a:FindPlayerRecordIdentities('Other','Realm')[alias])
    a:UpsertPlayerRecordIdentity({guid='X',name='Renamed'})
    assert(not a:FindOpinionCharacter('Other') and a:FindOpinionCharacter('Renamed').guid=='X')
    assert(a:UpsertPlayerRecordIdentity({name='Renamed'})=='X')
    a:UpsertPlayerRecordIdentity({guid='Y',name='Renamed'})
    a:SavePersonalRatingForGuid('Y',nil,'positive',{}, {})
    assert(a:FindOpinionCharacter('Renamed').guid=='X') -- equal timestamp, stable key
    now=now+1;a:SavePersonalRatingForGuid('Y',nil,'neutral',{}, {})
    assert(a:FindOpinionCharacter('Renamed').guid=='Y')
    a:DeleteCharacterDatabaseRecords({'Y'})
    assert(a:FindOpinionCharacter('Renamed').guid=='X' and a:GetHistoryEntry('Y'))
    s.identities.X.name=123;a:InitializeHistoryStore()
    assert(not a:FindOpinionCharacter('Renamed'))
    local index
    for i,row in ipairs(s.quarantine.entries) do if row.section=='identities' and row.key=='X' then index=i end end
    assert(a:RestorePlayerRecordEntry(index,{guid='X',name='Restored',realm='Realm'}))
    assert(a:FindOpinionCharacter('Restored').guid=='X')
    a:DeleteCharacterDatabaseRecords({'X'});assert(not a:FindOpinionCharacter('Restored'))
  `);
});

test("warm lookup and sparse rosters do not scan unrelated identities or copy encounter histories", async () => {
  await run(`
    local a=Raidwise;local s=a:GetPlayerRecordStore()
    for i=1,10000 do s.identities['G'..i]={guid='G'..i,name='Player'..i,realm='Realm'} end
    a:SavePersonalRatingForGuid('G9999',nil,'positive',{}, {})
    s.encounters.SELF={G9999={{lastSeenAt=now,places={{zoneName='Zone',lastSeenAt=now}}}}}
    s.meetingStats.SELF={G9999={count=12,firstMetAt=10}}
    assert(a:FindOpinionCharacter('Player9999'))
    local originalPairs=pairs
    function pairs(value) assert(value~=s.identities,'full identity scan');return originalPairs(value) end
    function a:GetCharacterEncounters() error('copied encounter history') end
    for i=1,100 do assert(a:FindOpinionCharacter('Player9999').guid=='G9999') end
    local db=a:BuildHistoryRoster(true);local history=a:BuildHistoryRoster(false)
    assert(#db==1 and #history==1 and history[1].meetCount==12 and history[1].lastSeenZone=='Zone')
    local profile=a:HistoryProfileForMember({guid='G9999'})
    assert(profile.meetCount==12 and profile.rating.personal.opinion=='positive')
    pairs=originalPairs
  `);
});
