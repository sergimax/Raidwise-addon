import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

async function run(modules: string[], setup: string, scenario: string): Promise<void> {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/wow-stubs.lua", import.meta.url), "utf8"));
    lua.doStringSync(setup);
    for (const name of modules) {
      lua.doStringSync((await readFile(new URL(`../Raidwise/${name}.lua`, import.meta.url), "utf8")).replace(/^\uFEFF/, ""));
    }
    lua.doStringSync(scenario);
  } finally { lua.global.close(); }
}

test("canonical reports preserve legacy inputs and separate grades from completeness", async () => {
  await run(["GearCheckReport"], "", `
    local legacy = {name="Tester",slots={{policy="CHECKED",item={sockets={}}}},
      inspect={needed=true,complete=true},stats={filledCheckedSlots=1,gearScore=6000}}
    local report = Raidwise:NormalizeGearCheckReport(legacy)
    assert(report.character.name=="Tester" and report.character.gearScore==6000)
    assert(report.equipment==report.slots and report.inspect==report.collection.inspect)
    assert(Raidwise:GetGearCheckScanState(report)=="complete")
    report.overall={status="S"}
    report.equipment[1].item.sockets.gemDataUncertain=true
    local state,reason=Raidwise:GetGearCheckScanState(report)
    assert(state=="incomplete" and reason=="gems_pending" and report.overall.status=="S")
    report.collection.counts.filledCheckedSlots=0
    assert(Raidwise:GetGearCheckScanState(report)=="unavailable")
    report.inspect={complete=true} -- stale legacy alias cannot override canonical data
    report.collection.inspect={needed=true,complete=false,canInspect=false}
    Raidwise:NormalizeGearCheckReport(report)
    assert(report.inspect==report.collection.inspect and report.stats.filledCheckedSlots==0)
    report.collection.counts.filledCheckedSlots=1
    state,reason=Raidwise:GetGearCheckScanState(report)
    assert(state=="unavailable" and reason=="cannot_inspect")
  `);
});

test("rating getters do not migrate or initialize SavedVariables", async () => {
  await run(["PlayerHistory", "PlayerHistoryStore"], "Raidwise.db={}; function time() return 100 end", `
    assert(Raidwise:GetHistoryEntry("absent")==nil and Raidwise.db.history==nil)
    assert(#Raidwise:BuildHistoryRoster()==0 and Raidwise.db.history==nil)
    local entry={guid="A",rating={personal={opinion="positive",tags={"late"},updatedAt=10}}}
    Raidwise.db.history={A=entry}
    Raidwise:GetPersonalRating(entry)
    Raidwise:GetCommunityRating(entry)
    Raidwise:GetHistoryEvents(entry)
    Raidwise:BuildHistoryRoster()
    assert(entry.events==nil and entry.notes==nil and not entry.rating.personal.reputationV2)
    assert(entry.rating.personal.tags[1]=="late")
    Raidwise:InitializeHistoryStore()
    assert(entry.rating.personal.reputationV2 and entry.events[1].type=="late_arrival")
    Raidwise:InitializeHistoryStore()
    assert(#entry.events==1)
    local personal=Raidwise:GetPersonalRating(entry)
    personal.tags[1]="changed"
    assert(entry.rating.personal.tags[1]==nil)
  `);
});

test("shell dispatches page lifecycle without knowing page controls", async () => {
  await run(["ExporterWindow"], "Raidwise.Widgets={}; Raidwise.UITheme={}; Raidwise.Pages={}", `
    local calls={}
    local function page() return {Show=function() end,Hide=function() end} end
    local frame={pages={settings=page(),history=page()},menuButtons={}}
    Raidwise.mainFrame=frame
    Raidwise.Pages.Settings={Refresh=function(host,entering)
      assert(host==frame.pages.settings); calls.entering=entering; calls.refresh=(calls.refresh or 0)+1
    end,ApplyLocale=function(host) assert(host==frame.pages.settings);calls.locale=true end}
    Raidwise:SelectTab("settings")
    assert(calls.entering and calls.refresh==1)
    Raidwise:RefreshLocalizedUI()
    assert(calls.locale and calls.refresh==2 and not calls.entering)
  `);
});

test("party and raid collection share identity fields and retain raid role", async () => {
  await run(["PartyRoster"], `
    function UnitName() return "Tester","Realm" end
    function UnitClass() return "Druid","DRUID" end
    function UnitGUID() return "A" end
    function UnitRace() return "Elf","NightElf" end
    function UnitFactionGroup() return "Alliance" end
    function UnitSex() return 3 end
    function UnitExists() return true end
    function UnitIsUnit() return true end
    function GetGuildInfo() return "Guild","Member" end
    function GetInventorySlotInfo() return nil end
    function GetRaidRosterInfo() return nil,nil,nil,nil,nil,nil,nil,nil,nil,"MAINTANK" end
    Raidwise.CollectPrimarySpec=function() return "Feral","icon",2 end
    Raidwise.RoleForRaidMember=function(_,class,tab,tank)
      assert(class=="DRUID" and tab==2); return tank and "tank" or "melee"
    end
    Raidwise.MergeRatingIntoMember=function(_,member) member.rating="merged" end
  `, `
    local party=Raidwise:CollectPartyMember("player",false)
    local raid=Raidwise:CollectRaidMember("player",false,1)
    for _,key in ipairs({"guid","name","realm","class","spec","specTab","race","faction","gender","rating"}) do
      assert(party[key]==raid[key],key)
    end
    assert(party.role==nil and raid.role=="tank")
    assert(Raidwise:CollectRaidMember("player",false).role=="melee")
  `);
});

test("profile panel construction and history rendering survive extraction", async () => {
  await run(["ProfilePanels"], `
    function widget()
      return setmetatable({}, {__index=function(_,key)
        if key=="GetFrameLevel" then return function() return 1 end end
        if key=="GetWidth" then return function() return 400 end end
        if key=="CreateTexture" then return widget end
        return function() end
      end})
    end
    CreateFrame=function() return widget() end
    Raidwise.Widgets={T=function(key) return key end,CreateFontString=widget,
      CreatePlainButton=widget,ApplyPlainPanel=function() end,SetFontColor=function() end}
  `, `
    local controls={UI={ACTION_BTN_GAP=8,ACTION_BTN_H=28},
      GetRatingTagGroups=function() return {} end,
      CreateOpinionRadio=function() return {host=widget()} end,
      CreateProfileNotesBox=function() return widget(),widget() end}
    for _,key in ipairs({"PROFILE_EVENT_GROUP_ICON","PROFILE_EVENT_PICKER_H","PROFILE_EVENT_TYPE_BTN_H",
      "PROFILE_EVENT_TYPE_ROW_H","PROFILE_LAYOUT_VERSION","PROFILE_OPINION_HEADER_H",
      "PROFILE_OPINION_ROW_H","PROFILE_TAG_COL_GAP","PROFILE_TAG_GROUP_GAP",
      "PROFILE_TAG_GROUP_HEADING_H","PROFILE_TAG_ROW_H"}) do controls[key]=20 end
    local frame={profilePanels={}}
    Raidwise:CreateProfilePanels(frame,widget(),440,controls)
    for _,key in ipairs({"opinion","facts","events","notes","history"}) do assert(frame.profilePanels[key],key) end
    Raidwise:RefreshProfileHistoryPanel(frame,{changes={}},14)
    assert(#frame.historyRows==1)
  `);
});

test("every shipped module compiles as Lua 5.1", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    const toc = await readFile(new URL("../Raidwise/Raidwise.toc", import.meta.url), "utf8");
    for (const name of toc.split(/\r?\n/).filter(line => line.endsWith(".lua"))) {
      const source = await readFile(new URL(`../Raidwise/${name}`, import.meta.url), "utf8");
      lua.global.set("source", source.replace(/^\uFEFF/, ""));
      lua.doStringSync("assert(loadstring(source))");
    }
  } finally { lua.global.close(); }
});

test("Settings and character linking panels avoid circular frame anchors", async () => {
  await run(["PlayerHistory", "PlayerHistoryStore", "CharacterLinks", "PageSettings", "ProfileCharacters"], `
    local serial=0
    local function depends(region,wanted,seen)
      if region==wanted then return true end
      seen=seen or {}; if seen[region] then return false end; seen[region]=true
      for _,relative in pairs(region.anchors) do if depends(relative,wanted,seen) then return true end end
      return false
    end
    function region(parent,name)
      serial=serial+1
      local result={anchors={},scripts={},parent=parent,name=name or tostring(serial)}
      function result:SetPoint(point,relative)
        if type(relative)~="table" then relative=self.parent end
        if relative then
          assert(not depends(relative,self),"Circular anchor: "..tostring(self.name).." -> "..tostring(relative.name))
          self.anchors[point]=relative
        end
      end
      function result:SetAllPoints(relative) self:SetPoint("TOPLEFT",relative) end
      function result:ClearAllPoints() self.anchors={} end
      function result:SetScript(event,callback) self.scripts[event]=callback end
      function result:SetText(text) self.text=text end
      function result:GetText() return self.text or "" end
      function result:Show() self.shown=true end
      function result:Hide() self.shown=false end
      function result:GetName() return self.name end
      function result:GetStringHeight() return 14 end
      function result:CreateTexture() return region(self) end
      return setmetatable(result,{__index=function(_,key)
        if key:match("^Set") or key=="Enable" or key=="Disable" or key=="EnableMouse" then return function() end end
      end})
    end
    CreateFrame=function(_,name,parent) return region(parent,name) end
    Raidwise.UITheme=setmetatable({CHECK_SIZE=24},{__index=function() return 8 end})
    Raidwise.Widgets=setmetatable({T=function(key) return key end,
      CreateFontString=function(parent) return region(parent) end,
      CreatePlainButton=function(parent) local button=region(parent);button.label=region(button);return button end,
      CreateLineCopyBox=function(parent) local host=region(parent);return region(host),host end,
      ContentInnerWidth=function() return 940 end,
    },{__index=function() return function() end end})
    Raidwise.GetLocaleId=function() return "enUS" end
    Raidwise.GetTheme=function() return "dark" end
    Raidwise.GetTooltipSettings=function() return {} end
    Raidwise.db={}
    Raidwise.RatingOpinionLabel=function(_,opinion) return opinion end
    function time() return 100 end
    function GetRealmName() return "Realm" end
    function UnitGUID() return "SELF" end
  `, `
    local page=Raidwise.Pages.Settings.Create(region())
    assert(page.changelogButton and page.layoutVersion==Raidwise.Pages.Settings.LAYOUT_VERSION)
    local profile={profilePanels={}}
    Raidwise:CreateProfileCharactersPanel(profile,region(),440,32)
    assert(profile.profilePanels.characters and #profile.characterConflictButtons==2)
    local a=Raidwise:EnsureHistoryEntryForGuid("A",{name="First",realm="Realm"})
    local b=Raidwise:EnsureHistoryEntryForGuid("B",{name="Second",realm="Realm"})
    Raidwise:SavePersonalRatingForGuid("A",nil,"positive",{}, {})
    Raidwise:SavePersonalRatingForGuid("B",nil,"negative",{}, {})
    profile.profileMember=a
    profile.profileDraft={draftOpinion="positive",draftTags={"unsaved"}}
    Raidwise:RefreshProfileCharacters(profile)
    profile.characterCandidateRows[1].buttons.CHAR_LINK_ADD.scripts.OnClick()
    assert(profile.pendingCharacterLink and not a.playerGroupId)
    profile.characterConflictButtons[2].scripts.OnClick()
    assert(a.playerGroupId==b.playerGroupId and a.rating.personal.opinion=="negative")
    assert(profile.profileDraft.draftOpinion=="negative" and profile.profileDraft.draftTags[1]=="unsaved")
    profile.characterRows[2].buttons.CHAR_LINK_REMOVE.scripts.OnClick()
    assert(not b.playerGroupId and #Raidwise:GetLinkedCharacters("A")==1)
  `);
});

test("character groups share only opinions, log changes and retain one main", async () => {
  await run(["PlayerHistory", "PlayerHistoryStore", "CharacterLinks", "RatingPresentation"], `
    Raidwise.db={}
    function time() return 100 end
    function GetRealmName() return "Realm" end
    function UnitGUID() return "SELF" end
    function ChatFrame_AddMessageEventFilter() end
  `, `
    local a=Raidwise:EnsureHistoryEntryForGuid("A",{name="Main",realm="Realm"})
    local b=Raidwise:EnsureHistoryEntryForGuid("B",{name="Alt",realm="Realm"})
    local c=Raidwise:EnsureHistoryEntryForGuid("C",{name="Alt",realm="Other"})
    Raidwise:SavePersonalRatingForGuid("A",nil,"positive",{}, {"raid_leader"})
    Raidwise:SavePersonalRatingForGuid("B",nil,"negative",{}, {})
    b.notes="private"; b.events={{id="own",type="same_party",eventAt=1,context={}}}
    local ok,reason=Raidwise:LinkPlayerCharacters("A","B")
    assert(not ok and reason=="CHAR_LINK_CONFLICT" and not a.playerGroupId and not b.playerGroupId)
    assert(Raidwise:LinkPlayerCharacters("A","B",nil,"positive"))
    local groupId=a.playerGroupId
    assert(b.playerGroupId==groupId and Raidwise.db.characterGroups[groupId].mainGuid=="A")
    assert(Raidwise:GetPersonalRating(b).opinion=="positive" and #b.rating.personal.facts==0)
    assert(b.notes=="private" and #b.events==1)
    local count=#a.changes
    assert(not Raidwise:LinkPlayerCharacters("A","B") and #a.changes==count)
    assert(Raidwise:LinkPlayerCharacters("B","C",nil,"positive"))
    assert(#Raidwise:GetLinkedCharacters("C")==3)
    Raidwise:SavePersonalRatingForGuid("B",nil,"negative",{}, {})
    assert(a.rating.personal.opinion=="negative" and c.rating.personal.opinion=="negative")
    assert(a.rating.personal.facts[1]=="raid_leader" and b.notes=="private" and #b.events==1)
    assert(not Raidwise:UnlinkPlayerCharacter("B","A"),"Allowed removal of the main")
    assert(Raidwise:SetLinkedCharacterRole("B","B","main"))
    assert(Raidwise:GetLinkedCharacters("C")[1].guid=="B")
    assert(Raidwise:UnlinkPlayerCharacter("B","A"))
    assert(not a.playerGroupId and a.rating.personal.opinion=="negative")
    assert(a.changes[#a.changes].kind=="character_unlink")
    Raidwise:SavePersonalRatingForGuid("B",nil,"positive",{}, {})
    assert(a.rating.personal.opinion=="negative" and c.rating.personal.opinion=="positive")
    local d=Raidwise:EnsureHistoryEntryForGuid("D",{name="Another"})
    assert(Raidwise:LinkPlayerCharacters("A","D",nil,"negative"))
    assert(a.playerGroupId~=groupId and Raidwise.db.characterGroups[groupId].members.B)
    ok,reason=Raidwise:LinkPlayerCharacters("A","C",nil,"positive")
    assert(not ok and reason=="CHAR_LINK_OTHER_GROUP")
    assert(#Raidwise:BuildLinkedCharacterTooltipLines(b)==3)
    local saved=Raidwise.db; Raidwise.db=nil; Raidwise.db=saved
    assert(Raidwise:GetLinkedCharacters("C")[1].guid=="B")
    assert(not Raidwise:SetLinkedCharacterRole("B","C","twink"))
  `);
});
