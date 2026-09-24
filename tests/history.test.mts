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
      assert(manual and manual.metAt==0 and manual.recordSource=="manual")
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
      assert(#addon:BuildHistoryRoster(true,{recordSource="manual",opinion="negative",name="test"})==1)
      assert(#addon:BuildHistoryRoster(true,{recordSource="website",opinion="negative"})==0)
      assert(addon:BuildHistoryRoster(true,{recordSource="website"})[1].guid=="imported")
      assert(#addon:BuildHistoryRoster(true,{recordSource="user"})==0)
      addon.db.history.imported.recordSource="user"
      assert(#addon:BuildHistoryRoster(true,{recordSource="user"})==1)
      addon.db.history.imported.recordSource="website"
      local first=manual.metAt
      advance(13*86400)
      addon:RecordTargetScanHistory({character={guid="REAL",name="Tester"},collection={collectedAt=time()}})
      assert(manual.metAt==first and manual.lastSeenAt==time())
      advance(2*86400)
      assert(#addon:BuildHistoryRoster()==1)
      advance(12*86400)
      addon:PruneHistory()
      assert(#addon:BuildHistoryRoster()==0 and addon.db.history.REAL==manual)
      addon:SaveProfileNotesForGuid("imported",nil,"Local annotation")
      assert(addon.db.history.imported.recordSource=="website")
      assert(addon:GetCharacterProfileState(addon.db.history.imported)=="local")
      assert(addon:GetCharacterRecordSource(addon.db.history.imported)=="manual")
      assert(#addon:BuildHistoryRoster(true,{recordSource="website"})==0)
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
      local entry=Raidwise:EnsureHistoryEntryForGuid("A")
      local personal=Raidwise:GetPersonalRating(entry)
      assert(entry.rating.personal.reputationV2 and personal.facts[1]=="raid_leader")
      assert(#entry.events==1 and entry.events[1].type=="late_arrival")
      Raidwise:EnsurePersonalRating(entry); Raidwise:EnsureHistoryEntryForGuid("A")
      assert(#entry.events==1 and entry.lastSeenAt==100 and entry.meetCount==1)
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
      assert(Raidwise:GetHistoryEntry("A").rating.personal.opinion=="negative")
      assert(Raidwise:SavePersonalRatingForGuid("",nil,"positive",{})==nil)
      -- Draft changes and cancellation must not mutate persisted ratings/events.
      local draft = Raidwise:CreateProfileDraft(entry)
      draft.draftOpinion="positive"
      Raidwise:AddProfileDraftEvent(draft,"same_party")
      assert(entry.rating.personal.opinion=="negative" and #entry.events==0)
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
      assert(entry.rating.personal.opinion=="negative" and #entry.events==0)
      Raidwise:CommitProfileRating()
      assert(entry.rating.personal.opinion=="positive" and #entry.events==1)
      local reopened=Raidwise:CreateProfileDraft(entry)
      reopened.draftEvents[1].context.zoneName="Draft only"
      assert(entry.events[1].context.zoneName~="Draft only")
      Raidwise:SaveProfileNotes("Saved through UI")
      assert(entry.notes=="Saved through UI")
      Raidwise:ResetProfileNotes()
      assert(entry.notes=="")
    `);
  } finally { lua.global.close(); }
});

test("reputation store foundation is separate, idempotent, and does not migrate history", async () => {
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
      assert(store and store.storeVersion==1)
      assert(type(store.localProfilesByGuid)=="table" and store.localProfilesByGuid.legacy)
      assert(type(store.exchangeProfilesBySource)=="table" and next(store.exchangeProfilesBySource)==nil)
      assert(addon:GetGlobalKarmaDataset()==nil)
      assert(addon:GetLocalProfile("legacy").personal.opinion=="positive" and #addon:GetExchangeProfileSources("legacy")==0)
      assert(addon.db.history.legacy.rating.personal.opinion=="positive")
      local original=store
      addon:InitializeHistoryStore()
      assert(addon:GetReputationStore()==original and addon.db.history.legacy)
    `);
  } finally { lua.global.close(); }
});
