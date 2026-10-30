import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

async function run(body: string) {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync(`
      Raidwise={db={history={legacy=true},characters={keep=true}}}
      actorGuid='SELF'; actorName='Me'; now=1000; zone='First'
      function time() return now end
      function GetRealmName() return 'Realm' end
      function UnitGUID() return actorGuid end
      function UnitName() return actorName end
      function Raidwise:CaptureEventContext() return {zoneName=zone} end
    `);
    lua.doStringSync(await readFile(new URL("../Raidwise/PlayerRecords.lua", import.meta.url), "utf8"));
    lua.doStringSync(body);
  } finally { lua.global.close(); }
}

test("new core is opt-in, reads are detached, unknown schemas are preserved", async () => {
  await run(`
    local a=Raidwise
    assert(a.db.playerRecords==nil and a:GetPlayerRecord('X')==nil)
    assert(not a:IsPlayerRecordFilled('X') and a.db.playerRecords==nil)
    local store=assert(a:InitializePlayerRecords())
    assert(a:InitializePlayerRecords()==store and a.db.history.legacy and a.db.characters.keep)
    assert(a:UpsertPlayerRecordIdentity({guid='X',name='Other'})=='X')
    local row=a:GetPlayerRecord('X'); row.identity.name='Mutated'
    assert(a:GetPlayerRecord('X').identity.name=='Other')
    a.db.playerRecords={schemaVersion=99,keep=true}
    local result,err=a:InitializePlayerRecords()
    assert(not result and err=='UNSUPPORTED_SCHEMA' and a.db.playerRecords.keep)
  `);
});

test("shared opinions, private notes, explicit neutral and per-event authorship", async () => {
  await run(`
    local a=Raidwise; a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='X',name='Other'})
    local d=a:CreatePlayerRecordDraft('X')
    d.note='private'; assert(a:CommitPlayerRecordDraft(d))
    assert(a:IsPlayerRecordFilled('X') and not a:GetPlayerRecord('X').profile)
    assert(#a:GetPlayerRecord('X').changes==0)
    d.opinion='neutral'; d.facts={'guild_officer','raid_leader'}
    local eventId=assert(a:AddPlayerRecordDraftEvent(d,'helped_player'))
    now=1005;zone='Second';assert(a:CommitPlayerRecordDraft(d))
    local p=a:GetPlayerRecord('X').profile
    assert(p.opinion=='neutral' and p.author.guid=='SELF' and p.facts[1]=='raid_leader')
    assert(p.events[1].id==eventId and p.events[1].eventAt==1000 and p.events[1].context.zoneName=='First')
    local changeCount=#a:GetPlayerRecord('X').changes
    local ok,changed=a:CommitPlayerRecordDraft(d);assert(ok and not changed)
    assert(#a:GetPlayerRecord('X').changes==changeCount)
    actorGuid='ALT';actorName='Alt'
    d=a:CreatePlayerRecordDraft('X');d.note='other private';assert(a:CommitPlayerRecordDraft(d))
    assert(a:GetPlayerRecord('X').profile.author.guid=='SELF')
    d.opinion='negative';assert(a:CommitPlayerRecordDraft(d))
    assert(a:GetPlayerRecord('X').profile.author.guid=='ALT')
    assert(a:GetPlayerRecord('X').profile.events[1].author.guid=='SELF')
    d.events[1].type='afk';assert(a:CommitPlayerRecordDraft(d))
    p=a:GetPlayerRecord('X').profile
    assert(p.events[1].author.guid=='ALT' and p.events[1].eventAt==1000)
    assert(p.events[1].context.zoneName=='First')
    d.events={};d.facts={};d.opinion=nil;d.note='';assert(a:CommitPlayerRecordDraft(d))
    assert(not a:IsPlayerRecordFilled('X'))
    for _,change in ipairs(a:GetPlayerRecord('X').changes) do assert(change.note==nil) end
  `);
});

test("invalid and stale commits are atomic; self notes work without self ratings", async () => {
  await run(`
    local a=Raidwise;local s=a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='SELF',name='Me'})
    local d=a:CreatePlayerRecordDraft('SELF');d.note='self note'
    assert(a:CommitPlayerRecordDraft(d))
    d.opinion='positive';d.note='must not save'
    local ok,err=a:CommitPlayerRecordDraft(d)
    assert(not ok and err=='SELF_RATING' and a:GetPlayerRecord('SELF').note.text=='self note')
    a:UpsertPlayerRecordIdentity({guid='X',name='Other'})
    d=a:CreatePlayerRecordDraft('X'); local stale=a:CreatePlayerRecordDraft('X')
    d.opinion='positive';assert(a:CommitPlayerRecordDraft(d))
    stale.note='stale';ok,err=a:CommitPlayerRecordDraft(stale)
    assert(not ok and err=='STALE_DRAFT' and not s.notes.X)
    assert(a:AddPlayerRecordDraftEvent(d,'afk'))
    d.events[1].eventAt=1;d.note='invalid'
    ok,err=a:CommitPlayerRecordDraft(d)
    assert(not ok and err=='IMMUTABLE_EVENT_FIELDS' and not s.notes.X and #s.profiles.X.events==0)
    d=a:CreatePlayerRecordDraft('X');d.facts={'raid_leader','raid_leader'}
    assert(not a:CommitPlayerRecordDraft(d))
    d.facts={[1]='raid_leader',[3]='guild_officer'}
    assert(not a:CommitPlayerRecordDraft(d))
    d=a:CreatePlayerRecordDraft('X');d.events={[2]={id='unknown',type='afk'}}
    assert(not a:CommitPlayerRecordDraft(d))
    d=a:CreatePlayerRecordDraft('X');s.generations.X=1
    local valid,reason=a:CommitPlayerRecordDraft(d)
    assert(not valid and reason=='STALE_DRAFT')
    d=a:CreatePlayerRecordDraft('X');d.opinion='negative';actorGuid=nil
    ok,err=a:CommitPlayerRecordDraft(d)
    assert(not ok and err=='AUTHOR_UNAVAILABLE' and s.profiles.X.opinion=='positive')
  `);
});

test("name identity upgrade moves observer and subject references and drafts without merging conflicts", async () => {
  await run(`
    local a=Raidwise; local s=a:InitializePlayerRecords()
    local key=assert(a:UpsertPlayerRecordIdentity({name='Other',realm='R ealm'}))
    assert(key=='name:realm:other')
    local d=a:CreatePlayerRecordDraft(key);d.opinion='negative';assert(a:CommitPlayerRecordDraft(d))
    s.meetingStats.SELF={[key]={count=7}}
    s.meetingStats[key]={Z={count=2}}
    s.encounters.SELF={[key]={{id='meeting'}}}
    s.groups.g={members={[key]=true,Z=true},mainKey=key}
    assert(a:UpsertPlayerRecordIdentity({guid='REAL',name='Other',realm='Realm'})=='REAL')
    assert(a:UpsertPlayerRecordIdentity({name='Other',realm='Realm'})=='REAL')
    assert(not s.identities[key] and not s.profiles[key] and d.key=='REAL')
    assert(s.meetingStats.SELF.REAL.count==7 and s.meetingStats.REAL.Z.count==2)
    assert(s.encounters.SELF.REAL[1].id=='meeting' and s.groups.g.mainKey=='REAL')
    d.note='after move';assert(a:CommitPlayerRecordDraft(d))
    assert(s.profiles.REAL.author.guid=='SELF')
    local other=a:UpsertPlayerRecordIdentity({name='Other',realm='OtherRealm'})
    assert(other~='REAL')
    a:UpsertPlayerRecordIdentity({guid='CONFLICT',name='Different'})
    local left=a:CreatePlayerRecordDraft(other);left.note='left';a:CommitPlayerRecordDraft(left)
    local right=a:CreatePlayerRecordDraft('CONFLICT');right.note='right';a:CommitPlayerRecordDraft(right)
    local result,err=a:UpsertPlayerRecordIdentity({guid='CONFLICT',name='Other',realm='OtherRealm'})
    assert(not result and err=='IDENTITY_CONFLICT')
    assert(s.notes[other].text=='left' and s.notes.CONFLICT.text=='right')
    local typed=a:UpsertPlayerRecordIdentity({name='Cross'})
    local cross=a:CreatePlayerRecordDraft(typed);cross.note='only note';a:CommitPlayerRecordDraft(cross)
    a:UpsertPlayerRecordIdentity({guid='CROSS',name='DifferentCross'})
    cross=a:CreatePlayerRecordDraft('CROSS');cross.opinion='positive';a:CommitPlayerRecordDraft(cross)
    result,err=a:UpsertPlayerRecordIdentity({guid='CROSS',name='Cross'})
    assert(not result and err=='IDENTITY_CONFLICT' and s.notes[typed].text=='only note')
  `);
});

test("active bridge retires legacy profiles once and routes reads and writes to the new core", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "PlayerRecords", "CharacterLinks", "PlayerRecordBridge"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local a=Raidwise
      a.db.history={old={guid='old',name='Old',rating={personal={opinion='negative'}}}}
      a.db.reputation={globalKarma={rating=99}}
      a.db.characters={keep=true};a.db.gearCheckSaved={keep=true};a.db.theme='dark'
      a:InitializeHistoryStore()
      assert(not a:GetHistoryEntry('old') and a.db.reputation==nil)
      assert(a.db.characters.keep and a.db.gearCheckSaved.keep and a.db.theme=='dark')
      local entry=assert(a:EnsureHistoryEntryForGuid('X',{name='Other',realm='Realm'}))
      assert(not a:IsCharacterDatabaseEntry(entry))
      assert(a:SaveProfileNotesForGuid('X',entry,'private'))
      assert(not a:HasPersonalRatingData(a:GetPersonalRating(entry)))
      assert(a:SavePersonalRatingForGuid('X',entry,'negative',{}, {'raid_leader'}))
      assert(a.db.playerRecords.profiles.X.opinion=='negative')
      assert(a:GetLocalProfile('X').personal.opinion=='negative')
      assert(a:SaveHistoryEventsForGuid('X',entry,{{type='afk'}}))
      assert(#a:GetHistoryEvents(entry)==1)
      assert(a:GetCommunityRating(entry)==nil and #a:GetExchangeProfileSources('X')==0)
      a:InitializeHistoryStore()
      assert(a:GetProfileNotes(entry)=='private' and a:GetPersonalRating(entry).opinion=='negative')
      assert(a:GetHistoryEntry('X')==entry and a.db.reputation==nil)
      assert(a:DeleteCharacterDatabaseRecords({'X'})==1)
      assert(not a:IsCharacterDatabaseEntry(entry) and a:GetHistoryEntry('X')==entry)
    `);
    const toc = await readFile(new URL("../Raidwise/Raidwise.toc", import.meta.url), "utf8");
    for (const module of ["SyncTransport", "SyncData", "KarmaData", "PageSync", "PageSyncExport", "PageReputation"]) {
      assert(!toc.split(/\r?\n/).includes(module + ".lua"), module + " remains active");
    }
    lua.doStringSync("assert(Raidwise.OnSyncAddonMessage==nil and Raidwise.StageSyncImport==nil)");
  } finally { lua.global.close(); }
});
