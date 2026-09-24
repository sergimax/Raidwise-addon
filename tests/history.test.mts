import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("encounters expire independently of saved cards, filters and name-only identity", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(`
      Raidwise={db={}}
      local now=2000000
      function time() return now end
      function advance(seconds) now=now+seconds end
      function GetRealmName() return "Realm" end
      function UnitGUID() return "SELF" end
      function Raidwise:T(key) return key end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local addon=Raidwise
      local old=time()-14*86400
      addon.db.history={
        expired={guid="expired",name="Old",lastSeenAt=old,events={{type="same_party"}},
          changes={{kind="event_add",detail="same_party"}}},
        saved={guid="saved",name="Saved",lastSeenAt=old,notes="Keep me"},
        facts={guid="facts",name="Facts",rating={personal={facts={"raid_leader"}}}},
        imported={guid="imported",name="Imported",recordSource="website",recordSourceDetail="raidwise"},
      }
      addon:InitializeHistoryStore()
      assert(not addon.db.history.expired and addon.db.history.saved and addon.db.history.facts)
      assert(addon:GetCharacterProfileState(nil)=="unset")
      assert(addon:GetCharacterProfileState(addon.db.history.saved)=="local")
      assert(addon:GetCharacterProfileState(addon.db.history.imported)=="imported")
      assert(addon:ShouldMarkCharacterInChat(addon.db.history.imported))
      assert(#addon:BuildHistoryRoster()==0 and #addon:BuildHistoryRoster(true)==3)
      local manual=addon:AddCharacterRecord("  Tester-Realm  ")
      assert(manual and manual.metAt==0 and addon:GetCharacterProfileState(manual)=="local")
      assert(addon:AddCharacterRecord("tester-realm")==manual)
      assert(not addon:AddCharacterRecord("bad name") and not addon:AddCharacterRecord("|Hplayer:bad"))
      addon:SavePersonalRatingForGuid(manual.guid,manual,"negative",{}, {})
      addon:SaveProfileNotesForGuid(manual.guid,manual,"Reported by a friend")
      local previousKey=manual.guid
      addon:RecordTargetScanHistory({character={guid="REAL",name="Tester",realm="Realm",
        classFile="MAGE",className="Mage",guildName="Example Guild"},collection={collectedAt=time()}})
      assert(addon.db.history.REAL==manual and not addon.db.history[previousKey])
      assert(addon:GetProfileNotes(manual)=="Reported by a friend" and addon:GetPersonalRating(manual).opinion=="negative")
      assert(#addon:BuildHistoryRoster(false,{name="test",class="mag",guildName="example"})==1)
      assert(#addon:BuildHistoryRoster(true,{opinion="negative"})==1)
      assert(#addon:BuildHistoryRoster(true,{opinion="positive"})==0)
      -- recordSource is scrubbed by migration and cannot filter the database.
      assert(#addon:BuildHistoryRoster(true,{recordSource="website",opinion="negative"})==1)
      local first=manual.metAt
      advance(13*86400)
      addon:RecordTargetScanHistory({character={guid="REAL",name="Tester"},collection={collectedAt=time()}})
      assert(manual.metAt==first and manual.lastSeenAt==time())
      advance(2*86400)
      assert(#addon:BuildHistoryRoster()==1)
      advance(12*86400)
      addon:PruneHistory()
      assert(#addon:BuildHistoryRoster()==0 and addon.db.history.REAL==manual)
      assert(not addon:SaveProfileNotesForGuid("imported",nil,"Local annotation"))
      assert(addon:GetCharacterProfileState(addon.db.history.imported)=="imported")
		assert(#addon:BuildHistoryRoster(true,{recordSource="website"})==4)
      addon:RecordTargetScanHistory({character={guid="TEMP",name="Temporary"}})
      assert(not addon:IsCharacterDatabaseEntry(addon.db.history.TEMP))
      assert(addon:GetCharacterProfileState(addon.db.history.TEMP)=="unset")
      assert(addon:ShouldMarkCharacterInChat(addon.db.history.TEMP))
      advance(14*86400)
      assert(not addon:ShouldMarkCharacterInChat(addon.db.history.TEMP))
      addon:PruneHistory()
      assert(not addon.db.history.TEMP)
      addon.db.characterGroups={linked={members={REAL=true,imported=true}}}
      addon.db.localCharacterMains={linked="REAL"}
      addon.syncSelectedGuid="REAL"
      assert(addon:DeleteCharacterDatabaseRecords({"REAL"})==1)
      assert(not addon.db.history.REAL and not addon.db.characterGroups.linked)
      assert(not addon.syncSelectedGuid)
      assert(addon:DeleteCharacterDatabaseRecords()==3)
      assert(next(addon.db.history)==nil)
    `);
  } finally {
    lua.global.close();
  }
});

test("history migration is idempotent and ratings, events, and notes persist", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync(`
      Raidwise = {db={}}
      function Raidwise:T(key) return key end
      function time() return 1000 end
      function date() return "test date" end
      function UnitGUID() return "SELF" end
      function GetRealmName() return "Realm" end
      function ChatFrame_AddMessageEventFilter() end
      function PlaySound() end
      Raidwise.UITheme = {}
      Raidwise.Widgets = { T=function(key) return key end }
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "RatingPresentation", "ProfileDraft", "ProfilePanels", "CharacterProfile"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local legacy = {guid="A",name="Tester",metAt=100,
        rating={personal={opinion="positive",tags={"raid_leader","late","experienced"},updatedAt=500}}}
      Raidwise.db.history={A=legacy}
      Raidwise:InitializeHistoryStore()
      local entry=Raidwise:EnsureHistoryEntryForGuid("A")
      local personal=Raidwise:GetPersonalRating(entry)
      assert(personal.facts[1]=="raid_leader")
      assert(#Raidwise:GetHistoryEvents(entry)==1 and Raidwise:GetHistoryEvents(entry)[1].type=="late_arrival")
      assert(entry.rating==nil and entry.events==nil and entry.lastSeenAt==100 and entry.meetCount==1)
      local tag=Raidwise:RatingTagGroups()[1].tags[1].id
      Raidwise:SavePersonalRatingForGuid("A",nil,"negative",{tag},{"raid_leader"})
      assert(Raidwise:GetPersonalRating(entry).opinion=="negative" and Raidwise:GetPersonalRating(entry).tags[1]==tag)
      local event={id="draft-1",type="same_party",eventAt=1000,context={zoneName="Test zone"}}
      Raidwise:SaveHistoryEventsForGuid("A",nil,{event})
      event.context.zoneName="Changed draft"
      assert(#Raidwise:GetHistoryEvents(entry)==1 and Raidwise:GetHistoryEvents(entry)[1].context.zoneName=="Test zone")
      Raidwise:SaveProfileNotesForGuid("A",nil,"Private note")
      assert(Raidwise:GetProfileNotes(entry)=="Private note")
      Raidwise:SaveProfileNotesForGuid("A",nil,"")
      assert(Raidwise:GetProfileNotes(entry)=="")
      Raidwise:SaveHistoryEventsForGuid("A",nil,{})
      assert(#Raidwise:GetHistoryEvents(entry)==0)
      local persisted=Raidwise.db
      Raidwise.db=nil; Raidwise.db=persisted
      assert(Raidwise:GetPersonalRating(Raidwise:GetHistoryEntry("A")).opinion=="negative")
      assert(Raidwise:SavePersonalRatingForGuid("",nil,"positive",{})==nil)
      -- Draft changes and cancellation must not mutate persisted ratings/events.
      local draft = Raidwise:CreateProfileDraft(entry)
      draft.draftOpinion="positive"
      Raidwise:AddProfileDraftEvent(draft,"same_party")
      assert(Raidwise:GetPersonalRating(entry).opinion=="negative" and #Raidwise:GetHistoryEvents(entry)==0)
      draft=Raidwise:CreateProfileDraft(entry) -- discard/reopen
      assert(draft.draftOpinion=="negative" and #draft.draftEvents==0)
      local tags=Raidwise:RatingTagGroups()[1].tags
      draft.draftTags={}
      for index=1,3 do assert(Raidwise:ToggleProfileDraftTag(draft,tags[index].id)) end
      local ok,key=Raidwise:ToggleProfileDraftTag(draft,tags[4].id)
      assert(not ok and key=="RATING_GROUP_LIMIT" and #draft.draftTags==3)
      assert(Raidwise:ToggleProfileDraftTag(draft,tags[1].id) and #draft.draftTags==2)
      Raidwise:AddProfileDraftEvent(draft,"same_party")
      local id=draft.draftEvents[1].id
      Raidwise:RemoveProfileDraftEvent(draft,id)
      assert(#draft.draftEvents==0)
      -- Exercise the real UI command wrappers with a minimal frame.
      Raidwise.raidDetailFrame={profileMember=entry,profileDraft=draft}
      Raidwise:SetProfileOpinion("positive")
      Raidwise:AddProfileEvent("same_party")
      assert(Raidwise:GetPersonalRating(entry).opinion=="negative" and #Raidwise:GetHistoryEvents(entry)==0)
      Raidwise:CommitProfileRating()
      assert(Raidwise:GetPersonalRating(entry).opinion=="positive" and #Raidwise:GetHistoryEvents(entry)==1)
      local reopened=Raidwise:CreateProfileDraft(entry)
      reopened.draftEvents[1].context.zoneName="Draft only"
      assert(Raidwise:GetHistoryEvents(entry)[1].context.zoneName~="Draft only")
      Raidwise:SaveProfileNotes("Saved through UI")
      assert(Raidwise:GetProfileNotes(entry)=="Saved through UI")
      Raidwise:ResetProfileNotes()
      assert(Raidwise:GetProfileNotes(entry)=="")
    `);
  } finally { lua.global.close(); }
});

test("phase 6 migration is idempotent and removes legacy history profile fields", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(`
      Raidwise={db={history={legacy={guid="legacy",name="Legacy",rating={personal={opinion="positive"}}}}}}
      function time() return 1000 end
      function UnitGUID() return "SELF" end
      function GetRealmName() return "Realm" end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local addon=Raidwise
      assert(addon:GetReputationStore()==nil)
      addon:InitializeHistoryStore()
      local store=addon:GetReputationStore()
      assert(store and store.storeVersion==2)
      assert(type(store.localProfilesByGuid)=="table" and store.localProfilesByGuid.legacy)
      assert(type(store.exchangeProfilesBySource)=="table" and next(store.exchangeProfilesBySource)==nil)
      assert(addon:GetGlobalKarmaDataset()==nil)
      assert(addon:GetLocalProfile("legacy").personal.opinion=="positive" and #addon:GetExchangeProfileSources("legacy")==0)
      assert(addon.db.history.legacy.rating==nil and addon.db.history.legacy.notes==nil and addon.db.history.legacy.events==nil)
      local original=store
      addon:InitializeHistoryStore()
      assert(addon:GetReputationStore()==original and addon.db.history.legacy)
    `);
  } finally { lua.global.close(); }
});
