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

test("negative personal opinions color the whole chat body red and preserve chat arguments and links", async () => {
  await run(["PlayerHistory", "PlayerHistoryStore", "CharacterLinks", "RatingPresentation"], `
    Raidwise.db={}
    function time() return 1000 end
    function GetRealmName() return "Realm" end
    function UnitGUID() return "SELF" end
    filters={}
    function ChatFrame_AddMessageEventFilter(event, callback) filters[event]=callback end
  `, `
    Raidwise:EnsureHistoryEntryForGuid("A",{name="Sender",realm="Realm"})
    Raidwise:SavePersonalRatingForGuid("A",nil,"negative",{},{})
    local item="|cffa335ee|Hitem:123:0:0|h[Item]|h|r"
    local achievement="|cffffff00|Hachievement:456:Player:1:0|h[Achievement]|h|r"
    local text="Hello |cff00ff00green|r "..item..achievement.." end ||cffffffff literal ||r"
    for event, filter in pairs(filters) do
      local hidden, message, sender, language, _, _, _, _, _, _, _, lineId, guid, tail =
        filter(nil,event,text,"Sender","Common",nil,nil,nil,nil,nil,nil,nil,123,"A","tail")
      assert(hidden==false and sender=="Sender" and language=="Common")
      assert(lineId==123 and guid=="A" and tail=="tail")
      assert(message=="|cffff0000<Rw> Hello green |r"..item.."|cffff0000|r"..achievement.."|cffff0000 end ||cffffffff literal ||r|r")
    end
    local filter=filters.CHAT_MSG_SAY
    assert(filter(nil,"CHAT_MSG_SAY","hello","Sender-OtherRealm")==nil)
    assert(filter(nil,"CHAT_MSG_SAY","hello","Unknown")==nil)
    for _, opinion in ipairs({"positive","neutral"}) do
      Raidwise:SavePersonalRatingForGuid("A",nil,opinion,{},{})
      local _, message=filter(nil,"CHAT_MSG_SAY",text,"Sender-Realm")
      assert(message:sub(-#text)==text and not message:find("|cffff0000",1,true))
      assert(message:find("|cff"..Raidwise:RatingColorHex(Raidwise:NativeOpinionColor(opinion)).."Rw",1,true))
    end
    Raidwise:EnsureHistoryEntryForGuid("B",{name="Alt",realm="Realm"})
    assert(Raidwise:LinkPlayerCharacters("A","B"))
    Raidwise:SavePersonalRatingForGuid("A",nil,"negative",{},{})
    local _, message=filter(nil,"CHAT_MSG_SAY","alt message","Alt")
    assert(message=="|cffff0000<Rw> alt message|r")
  `);
});

test("roster Gear targets the same character before navigation and native inspect avoids active scans", async () => {
  await run(["PageGearCheckTarget"], `
    Raidwise.UITheme={ACTION_BTN_H=28}
    Raidwise.Widgets={T=function(key) return key end}
  `, `
    local target,combat,busy,opened,inspected=nil,false,false,0,0
    function InCombatLockdown() return combat end
    function UnitGUID(unit) return unit=="raid1" and "A" or target end
    function UnitExists() return target~=nil end
    function UnitIsPlayer() return true end
    function CanInspect() return true end
    function TargetUnit() error("Targeting must use the secure button action") end
    function InspectUnit(unit) assert(unit=="target"); inspected=inspected+1 end
    Raidwise.IsGearCheckScanBusy=function() return busy end
    Raidwise.Print=function() end
    Raidwise.OpenGearCheckTarget=function(self,scan) assert(target=="A" and scan); opened=opened+1 end
    Raidwise.ShowGearCheckReport=function(self,report) assert(target==report.character.guid); opened=opened+1 end
    local member={unit="raid1",guid="A"}
    assert(not Raidwise:OpenRaidMemberGear(member) and opened==0)
    target="A" -- secure target action runs before the navigation callback
    assert(Raidwise:OpenRaidMemberGear(member) and opened==1)
    assert(Raidwise:OpenRaidMemberGear(member,{report={character={guid="A"}}}) and opened==2)
    assert(not Raidwise:OpenRaidMemberGear({unit="raid1",guid="B"}))
    assert(Raidwise:OpenTargetInspection() and inspected==1)
    busy=true
    assert(not Raidwise:OpenTargetInspection() and not Raidwise:OpenRaidMemberGear(member))
    busy=false; combat=true
    assert(not Raidwise:OpenTargetInspection() and not Raidwise:OpenRaidMemberGear(member))
    assert(opened==2 and inspected==1)
  `);
});

test("composition excludes reserve groups in live and snapshot reads without shrinking gear scans", async () => {
  await run(["RaidComposition"], "", `
    function GetNumRaidMembers() return 8 end
    local groups={}
    for index=1,8 do groups[index]={{guid=tostring(index),class="DRUID"}} end
    Raidwise.BuildRaidGroups=function() return groups end
    local live=Raidwise:CompositionMembers(false)
    local cached=Raidwise:CompositionMembers(false,{groups=groups})
    assert(#live==5 and #cached==5 and live[5].guid=="5")
    assert(cached[1]==groups[1][1] and groups[8][1].guid=="8")
    assert(#Raidwise:CompositionMembers(false,nil,true)==8)
    -- A move out of reserves takes effect on the next refresh.
    groups[5],groups[6]=groups[6],groups[5]
    assert(Raidwise:CompositionMembers(false)[5].guid=="6")
    function GetNumRaidMembers() return 0 end
    Raidwise.BuildPartyRoster=function() return groups[1] end
    assert(#Raidwise:CompositionMembers(false)==1)
  `);
});

test("raid scan selects active groups and summaries exclude manually scanned reserves", async () => {
  await run(["GearCheck"], "", `
    local groups={[1]={{guid="A"}},[5]={{guid="B"}},[6]={{guid="C"}},[8]={{guid="D"}}}
    local results={{member={guid="A"}},{report={character={guid="B"}}},{member={guid="C"}},{member={guid="D"}}}
    Raidwise.BuildRaidGroups=function() return groups end
    local filtered=Raidwise:FilterActiveRaidGearResults(results)
    assert(#filtered==2 and filtered[1]==results[1] and filtered[2]==results[2])
    assert(#results==4,"Manual reserve reports must remain available")
    groups[1],groups[6]=groups[6],groups[1]
    filtered=Raidwise:FilterActiveRaidGearResults(results)
    assert(#filtered==2 and filtered[2]==results[3],"Use current groups, not scan-time membership")
    Raidwise.CompositionMembers=function(self,refresh,snapshot,includeReserves)
      assert(not includeReserves,"Automatic scan included reserves")
      return {}
    end
    assert(Raidwise:StartGearCheckRaidScan(nil,function(found,status) assert(#found==0 and status=="empty") end))
  `);
});

test("diagnostic slash commands report missing modules and popup failures in local chat", async () => {
  await run(["Raidwise"], "SlashCmdList = {}", `
    local messages = {}
    Raidwise.Print = function(self, text) messages[#messages+1] = text end
    SlashCmdList.RAIDWISE(" diagnose ")
    assert(messages[1] == "Diagnostics starting...")
    assert(messages[2]:find("Diagnostics.lua did not load",1,true))
    local called = 0
    Raidwise.ShowDiagnostics = function(self)
      called = called + 1
      self.lastDiagnosticReport = "PASS gear rules"
      error("popup failed")
    end
    SlashCmdList.RAIDWISE("DIAGNOSE")
    assert(called == 1)
    assert(Raidwise.lastDiagnosticReport:find("PASS gear rules",1,true))
    assert(Raidwise.lastDiagnosticReport:find("popup failed",1,true))
    assert(table.concat(messages,"\\n"):find("FAIL diagnostic command",1,true))
    SlashCmdList.RAIDWISE = function() error("another addon owns /rw") end
    SlashCmdList.RAIDWISEDIAGNOSTICS()
    assert(called == 2 and SLASH_RAIDWISEDIAGNOSTICS1 == "/raidwisediag")
  `);
});

test("diagnostics capture UI errors, continue rule checks, and report skipped or missing checks", async () => {
  await run(["Diagnostics"], "", `
    local calls = 0
    Raidwise.version = "test"
    Raidwise.GetClassicOpinionDiagnostics = function() return "native marker status" end
    debugstack = function() return "stack: Settings Create" end
    Raidwise.ShowMainFrame = function() error("Circular anchor") end
    Raidwise.GearCheckRulesSelfTest = function()
      calls = calls + 1
      return {{ok=true,name="rule"}}, 1, 1
    end
    local report, ok = Raidwise:RunDiagnostics()
    assert(not ok and report:find("FAIL main window opening",1,true))
    assert(report:find("Circular anchor",1,true) and report:find("stack: Settings Create",1,true))
    assert(report:find("PASS gear rule self-tests",1,true) and calls == 1)
    Raidwise.ShowMainFrame = function(self)
      self.mainFrame = {IsShown=function() return true end}
    end
    report, ok = Raidwise:RunDiagnostics()
    assert(ok and report:find("3 passed, 0 failed, 0 skipped",1,true))
    assert(report:find("native marker status",1,true))
    Raidwise.GetClassicOpinionDiagnostics = nil
    report, ok = Raidwise:RunDiagnostics()
    assert(not ok and report:find("FAIL native opinion markers module",1,true))
    assert(report:find("ClassicOpinionMarkers.lua is missing or outdated",1,true))
    Raidwise.GetClassicOpinionDiagnostics = function() return "native marker status" end
    InCombatLockdown = function() return true end
    Raidwise.ShowMainFrame = function() error("must not run in combat") end
    report, ok = Raidwise:RunDiagnostics()
    assert(not ok and report:find("2 passed, 0 failed, 1 skipped",1,true))
    InCombatLockdown = nil
    Raidwise.ShowMainFrame = nil
    Raidwise.GearCheckRulesSelfTest = nil
    report, ok = Raidwise:RunDiagnostics()
    assert(not ok and report:find("2 failed",1,true))
    Raidwise.GearCheckRulesSelfTest = function() return {{ok=false,name="broken rule"}}, 0, 1 end
    report, ok = Raidwise:RunDiagnostics()
    assert(not ok and report:find("FAIL rule: broken rule",1,true))
  `);
});

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
  await run(["PlayerHistory", "PlayerHistoryStore", "CharacterLinks", "PageSettings", "ProfileCharacters", "PageHistory"], `
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
        if key:match("^Set") or key=="Enable" or key=="Disable" or key=="EnableMouse" or key=="EnableMouseWheel" then return function() end end
      end})
    end
    CreateFrame=function(_,name,parent) return region(parent,name) end
    Raidwise.UITheme=setmetatable({CHECK_SIZE=24},{__index=function() return 8 end})
    Raidwise.Widgets=setmetatable({T=function(key) return key end,
      CreateFontString=function(parent) return region(parent) end,
      CreatePlainButton=function(parent) local button=region(parent);button.label=region(button);return button end,
      CreateCooldownScrollBar=function(parent) return region(parent) end,
      CooldownTableTopOffset=function() return 36 end,
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
    local history=Raidwise.Pages.History.Create(region())
    local database=Raidwise.Pages.Database.Create(region())
    assert(history.layoutVersion==Raidwise.Pages.History.LAYOUT_VERSION and not history.database)
    assert(database.layoutVersion==Raidwise.Pages.Database.LAYOUT_VERSION and database.addButton)
    local refreshes=0
    Raidwise.RefreshHistoryView=function() refreshes=refreshes+1 end
    database.opinionButton.scripts.OnClick()
    assert(database.filters.opinion=="positive" and refreshes==1)
    for _, source in ipairs({"manual", "website", "user", ""}) do
      database.sourceButton.scripts.OnClick()
      assert(database.filters.recordSource==source and database.filters.opinion=="positive")
    end
    assert(refreshes==5)

    local page=Raidwise.Pages.Settings.Create(region())
    assert(page.changelogButton and page.layoutVersion==Raidwise.Pages.Settings.LAYOUT_VERSION)
    local scrollValue, scrollMaximum, contentHeight = 500, 0, 0
    page.scroll.GetWidth=function() return 800 end
    page.scroll.GetHeight=function() return 400 end
    page.scroll.GetVerticalScroll=function() return scrollValue end
    page.scroll.SetVerticalScroll=function(_,value) scrollValue=value end
    page.content.GetWidth=function() return 800 end
    page.content.GetTop=function() return 500 end
    page.content.SetHeight=function(_,value) contentHeight=value end
    page.changelogButton.GetBottom=function() return -250 end
    page.scrollBar.SetMinMaxValues=function(_,minimum,maximum) scrollMaximum=maximum end
    page.QueueLayout(page)
    page.scripts.OnUpdate(page)
    assert(contentHeight==760 and scrollMaximum==360 and scrollValue==360)
    assert(page.scrollBar.shown and not page.scripts.OnUpdate)
    page.changelogButton.GetBottom=function() return 200 end
    page.QueueLayout(page)
    page.scripts.OnUpdate(page)
    assert(scrollMaximum==0 and scrollValue==0 and not page.scrollBar.shown)

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
    assert(b.playerGroupId==groupId and Raidwise.db.localCharacterMains[groupId]=="A")
    assert(Raidwise.db.characterGroups[groupId].mainGuid==nil)
    local shared = Raidwise:GetSharedCharacterLinks("A")
    assert(#shared==2 and shared[1].guid=="A" and shared[2].guid=="B")
    for _, member in ipairs(shared) do
      assert(member.role==nil and member.mainGuid==nil and member.entry==nil)
    end
    -- Migrate the original saved format once, retaining a local choice thereafter.
    Raidwise.db.localCharacterMains=nil
    Raidwise.db.characterGroups[groupId].mainGuid="A"
    Raidwise:InitializeHistoryStore()
    assert(Raidwise.db.localCharacterMains[groupId]=="A")
    assert(Raidwise.db.characterGroups[groupId].mainGuid==nil)
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
    local sharedAfter=Raidwise:GetSharedCharacterLinks("A")
    for index, member in ipairs(shared) do
      assert(sharedAfter[index].guid==member.guid and sharedAfter[index].name==member.name)
    end
    -- Foreign/legacy Main metadata cannot replace an existing local preference.
    Raidwise.db.characterGroups[groupId].mainGuid="A"
    Raidwise:InitializeCharacterLinks()
    assert(Raidwise.db.localCharacterMains[groupId]=="B")
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


test("compact shell fits active raid groups with reserves below the viewport", async () => {
  await run(["UITheme", "UIWidgets", "PageRaid"], `Raidwise.Widgets={}`, `
    local visited={}
    local function findUpvalue(callback,wanted)
      if visited[callback] then return end
      visited[callback]=true
      for index=1,100 do
        local name,value=debug.getupvalue(callback,index)
        if not name then break end
        if name==wanted then return value end
        if type(value)=="function" then
          local found=findUpvalue(value,wanted)
          if found then return found end
        end
      end
    end
    local blockHeight=findUpvalue(Raidwise.Pages.Raid.Create,"RaidBlockHeight")
    visited={}
    local contentSize=findUpvalue(Raidwise.Pages.Raid.Create,"RaidContentSize")
    assert(blockHeight and contentSize)
    local UI,W=Raidwise.UITheme,Raidwise.Widgets
    local viewport=UI.CONTENT_HEIGHT-UI.TITLE_H-UI.PAD*2-W.RaidRosterTableTopOffset()
      -1-(UI.CD_HSCROLL_H+2)
    assert(viewport==blockHeight(),"Shell must fit exactly the five active raid groups")
    local _,totalHeight=contentSize()
    assert(totalHeight>viewport*2,"Reserve groups must remain reachable by scrolling")
  `);
});


test("profile notes and diagnostics scroll templates receive unique names on bare Wrath", async () => {
  const source = await readFile(new URL("../Raidwise/CharacterProfile.lua", import.meta.url), "utf8");
  const start = source.indexOf("local function CreateProfileNotesBox(");
  const end = source.indexOf("local function ProfileFieldValue", start);
  assert.ok(start >= 0 && end > start);
  await run(["Diagnostics"], `
    widgets={}
    function widget(parent,name)
      local object={parent=parent,name=name,scripts={}}
      return setmetatable(object,{__index=function(_,key)
        if key=="ScrollBar" then return nil end
        if key=="GetParent" then return function(self) return self.parent end end
        if key=="CreateFontString" then return function(self) return widget(self) end end
        if key=="SetScript" then return function(self,event,callback) self.scripts[event]=callback end end
        if key=="SetPoint" then return function(self,point,relative) self.relative=relative end end
        return function() end
      end})
    end
    function CreateFrame(kind,name,parent,template)
      if template=="UIPanelScrollFrameTemplate" then
        assert(type(name)=="string" and name~="", "ScrollFrame_OnLoad concatenates GetName()")
        assert(not widgets[name], "Scroll template name reused")
      end
      local object=widget(parent,name)
      if name then widgets[name]=object end
      if template=="UIPanelScrollFrameTemplate" then
        _G[name.."ScrollBar"]=widget(object,name.."ScrollBar")
      end
      return object
    end
    Raidwise.Print=function() end
  `, `
    local W=setmetatable({},{__index=function() return function() end end})
    local Theme={}
    local PROFILE_LAYOUT_VERSION=1
    local notesScrollSerial=0
    ${source.slice(start, end)}
    local first=CreateProfileNotesBox(widget(),400,96)
    local second=CreateProfileNotesBox(widget(),400,96)
    assert(first.scroll.name~=second.scroll.name)
    assert(_G[first.scroll.name.."ScrollBar"].relative==first)
    assert(_G[second.scroll.name.."ScrollBar"].relative==second)
    Raidwise.RunDiagnostics=function() return "test report",true end
    Raidwise:ShowDiagnostics()
    local frame=Raidwise.diagnosticsFrame
    Raidwise:ShowDiagnostics()
    assert(frame==Raidwise.diagnosticsFrame)
  `);
});
