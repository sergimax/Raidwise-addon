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

test("event journals migrate atomically, retain reversible history and reject unknown versions", async () => {
  await run(`
    local function copy(value)
      if type(value)~='table' then return value end
      local result={};for key,child in pairs(value) do result[key]=copy(child) end;return result
    end
    local function equal(left,right)
      if type(left)~=type(right) then return false end
      if type(left)~='table' then return left==right end
      for key,value in pairs(left) do if not equal(value,right[key]) then return false end end
      for key in pairs(right) do if left[key]==nil then return false end end
      return true
    end
    local a=Raidwise;local s=a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='X',name='Other'})
    local draft=a:CreatePlayerRecordDraft('X');draft.note='private';assert(a:CommitPlayerRecordDraft(draft))
    local first={id='one',type='afk',eventAt=10,updatedAt=10,context={zoneName='Old'},author={guid='OLD'}}
    local second=copy(first);second.id='two'
    local edited=copy(first);edited.type='helped_player';edited.author={guid='EDITOR'};edited.updatedAt=20
    local snapshots={
      {{first},{first,second}},
      {{first,second},{second,edited}},
      {{second,edited},{edited}},
      {{edited},{}},
      {{second},{second,first}}, -- A discontinuity retains its own baseline.
    }
    local legacy={}
    for index,pair in ipairs(snapshots) do
      legacy[#legacy+1]={id=tostring(index),at=index*10,actor={guid='AUTHOR'},kind='events',
        before=copy(pair[1]),after=copy(pair[2])}
    end
    legacy[#legacy+1]={id='opinion',at=80,actor={guid='AUTHOR'},kind='opinion',after='negative'}
    legacy[#legacy+1]={id='link',at=90,actor={guid='AUTHOR'},kind='character_link',detail='Alt'}
    s.profiles.X={opinion='negative',facts={},events=copy(snapshots[5][2]),revision=7,author={guid='AUTHOR'}}
    draft=a:CreatePlayerRecordDraft('X')
    s.changes.X=legacy;s.journalVersion=nil
    local original=copy(legacy);local nextId=s.nextId;local note=s.notes.X;local profile=s.profiles.X
    assert(a:InitializePlayerRecords()==s and s.journalVersion==2)
    assert(s.nextId==nextId and s.notes.X==note and s.profiles.X==profile and equal(legacy,original))
    local current={}
    for index,pair in ipairs(snapshots) do
      local change=s.changes.X[index]
      if change.baseline then current=copy(change.baseline) end
      assert(equal(current,pair[1]))
      assert(change.id==tostring(index) and change.at==index*10 and change.actor.guid=='AUTHOR')
      assert(change.before==nil and change.after==nil)
      local byId={}
      for position,event in ipairs(current) do byId[event.id]={position=position,event=event} end
      for _,delta in ipairs(change.events) do
        if not delta.afterIndex then byId[delta.id]=nil
        else byId[delta.id]={position=delta.afterIndex,event=copy(delta.after or byId[delta.id].event)} end
      end
      current={};for _,row in pairs(byId) do current[row.position]=row.event end
      assert(equal(current,pair[2]))
    end
    assert(equal(s.changes.X[6],original[6]) and equal(s.changes.X[7],original[7]))
    local migrated=s.changes;assert(a:InitializePlayerRecords()==s and s.changes==migrated)
    draft.note='after migration';assert(a:CommitPlayerRecordDraft(draft))
    draft.events[1].type='helped_player';assert(a:CommitPlayerRecordDraft(draft))
    assert(s.changes.X[8].events[1].before.id=='two' and s.changes.X[8].events[1].after.author.guid=='SELF')
    local invalid={X=legacy,Y={{kind='events',before={},after={{id='dup'},{id='dup'}}}}}
    s.changes=invalid;s.journalVersion=1
    local result,err=a:InitializePlayerRecords()
    assert(not result and err=='INVALID_JOURNAL' and s.changes==invalid and s.journalVersion==1)
    assert(equal(s.changes.X,original))
    s.journalVersion=99
    result,err=a:InitializePlayerRecords()
    assert(not result and err=='UNSUPPORTED_JOURNAL' and s.changes==invalid and s.journalVersion==99)
  `);
});

test("100 and 1000 event histories grow linearly and profile/page reads stay detached", async () => {
  await run(`
    local a=Raidwise;local s=a:InitializePlayerRecords()
    for _,count in ipairs({100,1000}) do
      local key='X'..count
      a:UpsertPlayerRecordIdentity({guid=key,name='Other'})
      local draft=a:CreatePlayerRecordDraft(key)
      for index=1,count do
        assert(a:AddPlayerRecordDraftEvent(draft,'afk'))
        assert(a:CommitPlayerRecordDraft(draft))
      end
      local copies=0
      for _,change in ipairs(s.changes[key]) do
        assert(change.before==nil and change.after==nil and change.baseline==nil)
        assert(#change.events==1)
        for _,delta in ipairs(change.events) do
          if delta.before then copies=copies+1 end
          if delta.after then copies=copies+1 end
        end
      end
      assert(copies==count and a:GetPlayerRecordChangeCount(key)==count)
      local page=a:GetPlayerRecordChangePage(key,2)
      assert(#page==25 and page[1].id==s.changes[key][count-25].id)
      page[1].events[1].after.type='mutated'
      assert(s.changes[key][count-25].events[1].after.type=='afk')
      assert(#a:GetPlayerRecordChangePage(key,count)==0)
      local profile=a:GetPlayerRecordProfile(key)
      assert(profile.changes==nil and #profile.profile.events==count)
      profile.profile.events[1].context.zoneName='mutated'
      assert(s.profiles[key].events[1].context.zoneName=='First')
      -- A cycle outside the requested page detects accidental full-journal copies.
      s.changes[key][1].unread=s.changes[key][1]
      assert(a:GetPlayerRecordProfile(key).changes==nil)
      assert(#a:GetPlayerRecordChangePage(key,1)==25)
      s.changes[key][1].unread=nil
    end
  `);
});

test("event deltas retain authorship, original dates and atomic stale-draft rejection", async () => {
  await run(`
    local a=Raidwise;local s=a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='X',name='Other'})
    local draft=a:CreatePlayerRecordDraft('X')
    local id=a:AddPlayerRecordDraftEvent(draft,'afk');assert(a:CommitPlayerRecordDraft(draft))
    local stale=a:CreatePlayerRecordDraft('X')
    now=2000;actorGuid='ALT';actorName='Alt'
    draft.events[1].type='helped_player';assert(a:CommitPlayerRecordDraft(draft))
    local delta=s.changes.X[2].events[1]
    assert(delta.id==id and delta.before.author.guid=='SELF' and delta.after.author.guid=='ALT')
    assert(delta.before.eventAt==1000 and delta.after.eventAt==1000 and delta.after.updatedAt==2000)
    local count=#s.changes.X
    stale.events={};local ok,err=a:CommitPlayerRecordDraft(stale)
    assert(not ok and err=='STALE_DRAFT' and #s.changes.X==count)
    draft.events={};assert(a:CommitPlayerRecordDraft(draft))
    delta=s.changes.X[3].events[1]
    assert(delta.before.id==id and delta.before.author.guid=='ALT' and delta.after==nil)
    assert(#a:GetPlayerRecord('X').changes==3)
  `);
});

test("active bridge retires legacy profiles once and routes reads and writes to the new core", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    for (const module of ["PlayerRecords", "PlayerRecordSupport", "PlayerRecordBridge", "PlayerRecordLinks", "PlayerEncounters", "Diagnostics"]) {
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
      assert(a.db.history==nil and a.db.reputation==nil)
      a.GetClassicOpinionDiagnostics=function() return 'initialized=true' end
      a.ShowMainFrame=function(self) self.mainFrame={IsShown=function() return true end} end
      a.ShowRaidCharacterWindow=function() end
      a.GearCheckRulesSelfTest=function() return {{ok=true}},1,1 end
      local report,ok=a:RunDiagnostics()
      assert(ok and report:find('PASS local character system',1,true))
      a.db.history={legacy=true}
      report,ok=a:RunDiagnostics()
      assert(not ok and report:find('FAIL local character system',1,true) and a.db.history.legacy)
    `);
    const toc = await readFile(new URL("../Raidwise/Raidwise.toc", import.meta.url), "utf8");
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "CharacterLinks", "ProfileDraft", "CharacterProfile", "ProfilePanels", "SyncTransport", "SyncData", "KarmaData", "PageSync", "PageSyncExport", "PageReputation"]) {
      assert(!toc.split(/\r?\n/).includes(module + ".lua"), module + " remains active");
    }
    lua.doStringSync("assert(Raidwise.OnSyncAddonMessage==nil and Raidwise.StageSyncImport==nil)");
  } finally { lua.global.close(); }
});
