import { readFile } from "node:fs/promises";
import assert from "node:assert/strict";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

const setup = `
Raidwise={db={}}
local clock=100
function GetTime() return clock end
function time() return clock end
function advance(seconds) clock=clock+seconds; if eventFrame then eventFrame.scripts.OnUpdate(eventFrame,seconds) end end
local guild, realm = 'Guild', 'Realm'
function IsInGuild() return guild~=nil end
function GetRealmName() return realm end
function GetGuildInfo() return guild,'Officer',1 end
function changeGuild(name,server) guild=name;realm=server or realm end
rights={view=true,public=true,officer=true,promote=true,demote=true}
function CanViewOfficerNote() return rights.view end
function CanEditPublicNote() return rights.public end
function CanEditOfficerNote() return rights.officer end
function CanGuildPromote() return rights.promote end
function CanGuildDemote() return rights.demote end
function GuildControlGetNumRanks() return 6 end
offline=true
function GetGuildRosterShowOffline() return offline end
function SetGuildRosterShowOffline(value) offline=value end
rows={
 {name='Янтарь',rank='Member',rankIndex=3,class='Маг',classFile='MAGE',publicNote='ЛЁД',officerNote='secret',online=false},
 {name='Alice',rank='Member',rankIndex=3,class='Воин',classFile='WARRIOR',publicNote='tank',officerNote='100,20',online=true}
}
function GetNumGuildMembers() return #rows end
function GetGuildRosterInfo(index)
 local row=rows[index];if not row or row.missing then return end
 return row.name,row.rank,row.rankIndex,80,row.class,'Zone',row.publicNote,row.officerNote,row.online,'',row.classFile
end
function CreateFrame()
 local frame={scripts={}}
 function frame:RegisterEvent() end
 function frame:SetScript(event,callback) self.scripts[event]=callback end
 eventFrame=frame;return frame
end
function event(name) eventFrame.scripts.OnEvent(eventFrame,name) end
requests=0
function GuildRoster() requests=requests+1 end
function QueryGuildEventLog() end
events={}
function GetNumGuildEvents() return #events end
function GetGuildEventInfo(index) return unpack(events[index]) end
writes={}
function GuildRosterSetPublicNote(index,text) writes[#writes+1]={index=index,text=text,kind='publicNote'} end
function GuildRosterSetOfficerNote(index,text) writes[#writes+1]={index=index,text=text,kind='officerNote'} end
function GuildPromote(name) writes[#writes+1]={name=name,kind='promote'} end
function GuildDemote(name) writes[#writes+1]={name=name,kind='demote'} end
`;

async function run(body: string, extraModules: string[] = [], extraSetup = "") {
  const lua = await Lua.create();
  try {
    lua.doStringSync(setup + extraSetup);
    for (const name of ["GuildManagement", "GuildRosterParser", "GuildRosterLinks", "GuildEPGP", ...extraModules]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise_Guild/${name}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync("G=Raidwise.GuildManagement; G.IsVisible=function() return true end\n" + body);
  } finally { lua.global.close(); }
}

test("guild snapshots preserve baselines, filter Cyrillic notes, and respect current read permissions", async () => {
  await run(`
    assert(G.Accept(G.Collect()))
    assert(#G.Entries()==0 and #G.Members()==2)
    assert(#G.Members('лёд','MAGE')==1 and #G.Members('ЯНТАРЬ')==1)
    assert(#G.Members('secret','WARRIOR')==0)
    local detached=G.Members();detached[1].publicNote='not stored'
    assert(G.Members()[1].publicNote~='not stored')
    rows[1].publicNote='new';rows[1].officerNote='new secret'
    G.Accept(G.Collect())
    assert(#G.Entries()==2 and #G.Entries('янтарь','officerNote')==1)
    rights.view=false
    assert(#G.Entries()==1 and #G.Members('secret')==0)
    assert(G.Members()[2].officerNote==nil)
    G.Accept(G.Collect());assert(#G.Entries()==1)
    rights.view=true;G.Accept(G.Collect())
    assert(#G.Entries()==2,'regaining read access must not manufacture a change')
    rows[2].missing=true;assert(G.Collect()==nil)
    assert(#G.Members()==2 and #G.Entries()==2)
    changeGuild('Other');G.Accept(G.Collect());assert(#G.Entries()==0)
    changeGuild('Guild');assert(#G.Entries()==2)
    changeGuild('Guild','OtherRealm');assert(#G.Entries()==0)
  `);
});

test("guild note commands resolve the live index, validate all edits and await confirmation", async () => {
  await run(`
    G.Accept(G.Collect());G.Initialize()
    local original=G.Members('alice')[1];original.key=G.Identity()
    rows[1],rows[2]=rows[2],rows[1]
    assert(G.Submit('Alice',original,{publicNote='healer',officerNote='200,20'}))
    assert(#writes==2 and writes[1].index==1 and writes[2].index==1)
    assert(G.Pending())
    local ok,reason=G.Submit('Alice',original,{publicNote='second'})
    assert(not ok and reason=='GUILD_PENDING' and #writes==2)
    rows[1].publicNote='healer';G.Accept(G.Collect());assert(G.Pending(),'partial application is not success')
    rows[1].officerNote='200,20';G.Accept(G.Collect());assert(not G.Pending() and G.Status()=='GUILD_SAVED')
    original=G.Members('alice')[1];original.key=G.Identity()
    rows[1].officerNote='other officer edit'
    ok,reason=G.Submit('Alice',original,{publicNote='would apply',officerNote='300,20'})
    assert(not ok and reason=='GUILD_CONFLICT' and #writes==2,'validate both fields before first write')
    rights.public=false
    ok,reason=G.Submit('Alice',original,{publicNote='blocked'})
    assert(not ok and reason=='GUILD_DENIED' and #writes==2)
    rights.public=true;changeGuild('New')
    ok,reason=G.Submit('Alice',original,{publicNote='wrong guild'})
    assert(not ok and reason=='GUILD_STALE' and #writes==2)
  `);
});

test("guild rank actions enforce hierarchy and time out without claiming success", async () => {
  await run(`
    G.Accept(G.Collect());local original=G.Members('Alice')[1];original.key=G.Identity()
    assert(G.CanRank(original,'promote') and G.CanRank(original,'demote'))
    rows[2].rankIndex=2
    local ok,reason=G.Submit('Alice',original,nil,'promote')
    assert(not ok and reason=='GUILD_DENIED' and #writes==0)
    rows[2].rankIndex=5;assert(not G.CanRank(G.Collect().members[2],'demote'))
    rows[2].rankIndex=3
    assert(G.Submit('Alice',original,nil,'promote') and writes[1].name=='Alice')
    G.IsVisible=function() return false end
    advance(13)
    assert(not G.Pending() and G.Status()=='GUILD_UNCERTAIN')
    local count=#writes;advance(60);assert(#writes==count,'never resend a mutation on timeout')
  `);
});

test("server journal imports occurrence counts, handles ageing windows and prunes all guild archives", async () => {
  await run(`
    events={{'join','Alice',nil,nil,0,0,0,2},{'join','Alice',nil,nil,0,0,0,2}}
    G.ImportEvents();G.ImportEvents();assert(#G.Entries()==2)
    advance(3600);events[1][8]=3;events[2][8]=3
    G.ImportEvents();assert(#G.Entries()==2,'ageing tuples are not new events')
    events[#events+1]={'join','Alice',nil,nil,0,0,0,0}
    G.ImportEvents();assert(#G.Entries()==3)
    events={};G.ImportEvents();assert(#G.Entries()==3)
    G.Accept(G.Collect())
    for index=1,150 do rows[1].publicNote=tostring(index);G.Accept(G.Collect()) end
    assert(#G.Entries()==153)
    changeGuild('Other');G.Accept(G.Collect())
    for index=1,150 do rows[1].publicNote='other'..index;G.Accept(G.Collect()) end
    assert(G.SetLimit(100) and #G.Entries()==100)
    changeGuild('Guild');assert(#G.Entries()==100)
    assert(G.Entries()[1].after=='150' and G.Entries()[100].after=='51')
    assert(not G.SetLimit(99) and not G.SetLimit(10001))
  `);
});

test("refresh requests coalesce, restore offline visibility and stop collecting when closed", async () => {
  await run(`
    offline=false
    assert(G.Request() and offline and requests==1)
    assert(not G.Request() and requests==1)
    event('GUILD_ROSTER_UPDATE');advance(0.3)
    assert(#G.Members()==2)
    G.IsVisible=function() return false end;G.Close();assert(not offline)
    rows[1].publicNote='while closed'
    event('GUILD_ROSTER_UPDATE');advance(35)
    assert(#G.Entries()==0 and requests==1)
    G.IsVisible=function() return true end
    assert(G.Request() and offline)
    event('GUILD_ROSTER_UPDATE');advance(0.3)
    assert(#G.Entries()==1)
    advance(30);assert(requests==3)
    changeGuild(nil);event('PLAYER_GUILD_UPDATE');advance(0.3)
    assert(#G.Members()==0)
  `);
});

const uiSetup = `
function region(parent)
 local result={parent=parent,scripts={},shown=true,text='',enabled=true}
 function result:SetScript(event,callback) self.scripts[event]=callback end
 function result:SetText(text)
  local changed=self.text~=text;self.text=text
  if changed and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
 end
 function result:GetText() return self.text end
 function result:SetPoint(...) self.point={...} end
 function result:ClearAllPoints() self.point=nil end
 function result:SetWidth(width) self.width=width end
 function result:SetMinMaxValues(minimum,maximum) self.minimum=minimum;self.maximum=maximum end
 function result:SetValue(value)
  local changed=self.value~=value;self.value=value
  if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
 end
 function result:SetVerticalScroll(value) self.verticalScroll=value end
 function result:SetHorizontalScroll(value) self.horizontalScroll=value end
 function result:SetTextColor(...) self.color={...} end
 function result:CreateTexture() return region(self) end
 function result:Show() self.shown=true end
 function result:Hide() self.shown=false end
 function result:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
 function result:Enable() self.enabled=true end
 function result:Disable() self.enabled=false end
 function result:EnableKeyboard(enabled) self.enabled=enabled end
 function result:RegisterEvent() eventFrame=self end
 return setmetatable(result,{__index=function(_,key)
  if key:match('^Set') or key=='EnableMouse' or key=='EnableMouseWheel' or key=='ClearFocus' then return function() end end
 end})
end
function CreateFrame(_,_,parent) return region(parent) end
Raidwise.Widgets={
 CreateFontString=function(parent) return region(parent) end,
 CreatePlainButton=function(parent) local button=region(parent);button.label=region(button);return button end,
 CreateTextInput=function(parent) local host=region(parent);return region(host),host end,
 CreateCooldownScrollBar=function(parent) return region(parent) end,
 CreateProgressBar=function(parent)
  local progress=region(parent)
  function progress:SetProgress(current,total) self.current=current;self.total=total end
  return progress
 end,
 SetPlainButtonTooltip=function(button,key) button.tooltipKey=key end,
 ClassColor=function(class) if class=='MAGE' then return 0.4,0.8,1 end;return 1,0.5,0.3 end,
 SetSpecOrClassIcon=function(texture,_,class) texture.class=class end,
 SetFontColor=function(label,color) label.color=color end,
 SetBackdropColor=function(frame,color) frame.background=color end,
}
Raidwise.UITheme={CONTENT_WIDTH=970,MENU_BAR_W=90,TEXT_BODY={1,1,1},GEAR_GOOD={0.4,0.9,0.4},
 CD_CURRENT_CHARACTER={0.25,0.22,0.14},BTN_IDLE={0.16,0.15,0.13},BTN_HOVER={0.2,0.2,0.2}}
function Raidwise:T(key) return key end
function Raidwise:FormatShortDateTime(value) return tostring(value) end
GameTooltip={Hide=function() end}
`;

test("guild table aligns individual headers with cells and preserves selection and class presentation", async () => {
  await run(`
    local page=Raidwise.Pages.Guild.Create(region())
    G.Accept(G.Collect())
    assert(page.headers and #page.headers==9,'column headers must be individual aligned cells')
    for index,header in ipairs(page.headers) do
      assert(header.point[2]==page.rows[1].cells[index].point[2] and header.width==page.rows[1].cells[index].width,'header/cell alignment')
    end
    local row=page.rows[1]
    assert(row.entry.name=='Alice' and row.classIcon.class=='WARRIOR' and row.classIcon.shown)
    assert(row.cells[2].text=='' and row.cells[1].color[1]==1 and row.cells[1].color[2]==0.5)
    assert(row.cells[4].color==Raidwise.UITheme.GEAR_GOOD)
    row.scripts.OnClick()
    assert(row.background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    row.scripts.OnLeave();assert(row.background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    page.rows[2].scripts.OnClick()
    assert(row.background==Raidwise.UITheme.BTN_IDLE and page.rows[2].background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    assert(page.rows[2].cells[4].color==Raidwise.UITheme.TEXT_BODY)
    rows[2].publicNote='journal entry';G.Accept(G.Collect())
    page.localizedButtons[2].scripts.OnClick()
    assert(not row.classIcon.shown and row.cells[1].color==Raidwise.UITheme.TEXT_BODY)
    for index=1,4 do assert(page.headers[index].point[2]==row.cells[index].point[2] and page.headers[index].width==row.cells[index].width) end
    page.localizedButtons[1].scripts.OnClick()
    assert(page.rows[2].classIcon.shown and page.rows[2].background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
  `, ["PageGuild"], uiSetup);
});

test("guild page preserves drafts across refreshes, exposes conflicts and hides officer history on rights loss", async () => {
  await run(`
    local page=Raidwise.Pages.Guild.Create(region())
    G.IsVisible=function() return page:IsVisible() end
    G.Accept(G.Collect())
    page.rows[1].scripts.OnClick()
    assert(page.selected=='Alice' and page.public:GetText()=='tank')
    page.public:SetText('my draft')
    rows[2].publicNote='external edit';G.Accept(G.Collect())
    assert(page.public:GetText()=='my draft','refresh must preserve an unsaved editor')
    page.save.scripts.OnClick()
    assert(page.editorMessage=='GUILD_CONFLICT' and #writes==0)
    page.cancel.scripts.OnClick()
    assert(page.public:GetText()=='external edit')
    page.public:SetText('saved draft');page.save.scripts.OnClick()
    assert(G.Pending() and not page.save.enabled)
    rows[2].publicNote='saved draft';G.Accept(G.Collect())
    assert(not G.Pending() and page.original.publicNote=='saved draft' and not page.save.enabled)
    page.officer:SetText('sensitive draft');rights.view=false
    G.Accept(G.Collect())
    assert(page.officer:GetText()=='' and not page.officer.enabled)
    rights.public=false;G.Accept(G.Collect())
    assert(not page.public.enabled and not page.save.enabled)
    changeGuild('Other');G.Accept(G.Collect())
    assert(page.selected==nil and page.public:GetText()=='')
  `, ["PageGuild"], uiSetup);
});

test("guild balances distinguish officer-note viewing from editing", async () => {
  await run(`
    rights.officer=false
    G.Accept(G.Collect())
    assert(G.Members('Alice')[1].ep==100)
    rights.view=false
    assert(G.Members('Alice')[1].ep==nil and G.Members('Alice')[1].pr==nil)
  `);
});

test("guild info base parsing handles defaults, other EPGP options and conflicting settings", async () => {
  await run(`
    local parse=Raidwise.GuildEPGP.ParseGuildInfo
    assert(parse(nil).minimumGP==500 and parse('guild description').baseStatus=='default')
    local valid=parse([[-EPGP-
@BASE_GP:500
@DECAY_P:20
@MIN_EP:90000
@EXTRAS_P:100
-EPGP-]])
    assert(valid.minimumGP==500 and valid.baseStatus=='guild')
    assert(parse('-EPGP-\\n@DECAY_P:20\\n-EPGP-').baseStatus=='default')
    for _,body in ipairs({'@BASE_GP:-1','@BASE_GP:1.5','@BASE_GP:abc','@BASE_GP:500\\n@BASE_GP:600'}) do
      local config=parse('-EPGP-\\n'..body..'\\n-EPGP-')
      assert(config.baseStatus=='invalid' and config.minimumGP==nil)
    end
    assert(parse('-EPGP-\\n@BASE_GP:500').baseStatus=='invalid')
    assert(parse('-EPGP-\\r\\n@BASE_GP:0\\r\\n-EPGP-').minimumGP==0)
  `);
});

test("guild balances resolve Cyrillic alt chains outside the active raid and separate roll eligibility from PR", async () => {
  await run(`
    local info='-EPGP-\\n@BASE_GP:500\\n@MIN_EP:99999\\n-EPGP-'
    function GetGuildInfoText() return info end
    rows={
      {name='Мейн',rank='Officer',rankIndex=1,class='Маг',classFile='MAGE',publicNote='',officerNote='10000,1000'},
      {name='Альт',rank='Member',rankIndex=3,class='Маг',classFile='MAGE',publicNote='find',officerNote='мЕЙН'},
      {name='Chain',rank='Member',rankIndex=3,class='Маг',classFile='MAGE',publicNote='',officerNote='альт'},
      {name='Reserve',rank='Member',rankIndex=3,class='Воин',classFile='WARRIOR',publicNote='',officerNote='20000,1000'},
      {name='Missing',rank='Member',rankIndex=3,class='Воин',classFile='WARRIOR',publicNote='',officerNote='Nobody'},
      {name='CycleA',rank='Member',rankIndex=3,class='Маг',classFile='MAGE',publicNote='',officerNote='CycleB'},
      {name='CycleB',rank='Member',rankIndex=3,class='Маг',classFile='MAGE',publicNote='',officerNote='CycleA'},
    }
    function GetNumRaidMembers() return 4 end
    function GetRaidRosterInfo(index)
      return ({'Альт','Chain','Reserve','Outsider'})[index],0,({1,5,6,2})[index]
    end
    G.Accept(G.Collect())
    local raid=G.Members(nil,nil,true)
    assert(#raid==2 and #G.Members('find','MAGE',true)==1)
    for _,member in ipairs(raid) do
      assert(member.ep==10000 and member.gp==1000 and member.effectiveGP==1500)
      assert(member.pr==10000/1500 and member.bisEligible and member.balanceName=='Мейн')
    end
    assert(G.SetRollMinimumEP(10001))
    assert(not G.Members('Альт')[1].bisEligible and G.Members('Альт')[1].pr==10000/1500)
    assert(not G.SetRollMinimumEP(-1) and not G.SetRollMinimumEP(1.5))
    changeGuild('Other');assert(G.RollMinimumEP()==4000)
    changeGuild('Guild');assert(G.RollMinimumEP()==10001)
    assert(G.Members('Missing')[1].ep==nil and G.Members('CycleA')[1].pr==nil)
    info='-EPGP-\\n@BASE_GP:broken\\n-EPGP-';G.Accept(G.Collect())
    local member=G.Members('Альт')[1]
    assert(member.ep==10000 and member.gp==1000 and member.pr==nil and member.prReason=='GUILD_REASON_BASE')
    info='-EPGP-\\n@BASE_GP:0\\n-EPGP-';rows[1].officerNote='10000,0';G.Accept(G.Collect())
    member=G.Members('Альт')[1]
    assert(member.ep==10000 and member.gp==0 and member.pr==nil and member.prReason=='GUILD_REASON_ZERO')
    assert(G.SetRollMinimumEP(4000) and G.Members('Альт')[1].bisEligible)
    rights.view=false
    assert(G.Members('Альт')[1].ep==nil and G.Members('Альт')[1].prReason=='GUILD_REASON_UNAVAILABLE')
  `);
});

test("guild numeric sorting keeps unknowns last, uses unrounded PR and starts new storage without migration", async () => {
  await run(`
    Raidwise.db.guildManagement={limit=100, guilds={old={entries={{kind='join'}}}}}
    Raidwise.db.epgp={bisMinimumEP=99999}
    assert(G.GetLimit()==1000 and G.RollMinimumEP()==4000 and #G.Entries()==0)
    rows[1].officerNote='4001,1000';rows[2].officerNote='4000,1000'
    G.Accept(G.Collect())
    assert(G.Members(nil,nil,false,'pr',true)[1].name=='Янтарь')
    assert(G.Members(nil,nil,false,'pr',false)[1].name=='Alice')
    rows[1].officerNote='4000,1000';G.Accept(G.Collect())
    assert(G.Members(nil,nil,false,'pr',true)[1].name=='Alice')
    rows[2].officerNote='Nobody';G.Accept(G.Collect())
    assert(G.Members(nil,nil,false,'ep',false)[2].name=='Alice')
    assert(G.Members(nil,nil,false,'gp',true)[2].name=='Alice')
    function GetNumRaidMembers() return 0 end
    assert(#G.Members(nil,nil,true)==0)
  `);
});

test("guild page sorts balances, applies the roll threshold and scrolls the whole aligned table", async () => {
  await run(`
    rows[1].officerNote='10000,1000'
    local page=Raidwise.Pages.Guild.Create(region())
    G.Accept(G.Collect())
    assert(page.hBar.maximum>0 and page.hBar.shown)
    page.sortButtons[5].scripts.OnClick()
    assert(page.rows[1].entry.name=='Янтарь' and page.rows[1].cells[5].text=='10000 V')
    assert(page.rows[1].cells[6].text=='1000 (+500)' and page.rows[1].cells[7].text=='6.67')
    page.rollMinimumEP:SetText('10001');page.applyRoll.scripts.OnClick()
    assert(page.rows[1].cells[5].text=='10000 X' and page.editorMessage==nil)
    page.sortButtons[5].scripts.OnClick();assert(page.rows[1].entry.name=='Alice')
    page.raidOnly.scripts.OnClick();assert(not page.rows[1].shown)
    page.raidOnly.scripts.OnClick();assert(page.rows[1].shown)
    page.localizedButtons[2].scripts.OnClick();assert(not page.hBar.shown and page.hBar.maximum==0)
  `, ["PageGuild"], uiSetup);
});

test("guild refresh reports real chunk progress and publishes only a complete snapshot", async () => {
  await run(`
    local page=Raidwise.Pages.Guild.Create(region())
    G.Accept(G.Collect())
    local oldRows=rows
    rows={}
    for index=1,120 do rows[index]={name='Member'..index,rank='Member',rankIndex=3,
      class='Mage',classFile='MAGE',publicNote='',officerNote='5000,0'} end
    local read=GetGuildRosterInfo;local reads=0
    function GetGuildRosterInfo(index) reads=reads+1;return read(index) end
    assert(G.Request() and G.Progress()=='waiting' and page.progress.shown)
    assert(page.progress.current==0 and reads==0)
    event('GUILD_ROSTER_UPDATE');advance(0.06)
    local phase,current,total=G.Progress()
    assert(phase=='scanning' and current==50 and total==120 and reads==50)
    assert(page.progress.current==50 and page.progress.total==120 and #G.Members()==#oldRows)
    advance(0.06);assert(select(2,G.Progress())==100 and #G.Members()==#oldRows)
    advance(0.06)
    assert(G.Progress()=='done' and #G.Members()==120 and reads==120)
    assert(page.progress.current==120 and page.progress.total==120)
    advance(1);assert(G.Progress()==nil and not page.progress.shown)
    advance(2);assert(G.Request());G.Close()
    assert(G.Progress()==nil and not page.progress.shown)
  `, ["PageGuild"], uiSetup);
});

test("guild refresh discards interrupted scans and clears progress on failure or guild change", async () => {
  await run(`
    G.Accept(G.Collect())
    rows={}
    for index=1,60 do rows[index]={name='Member'..index,rank='Member',rankIndex=3,
      class='Mage',classFile='MAGE',publicNote='',officerNote='5000,0'} end
    assert(G.Request());event('GUILD_ROSTER_UPDATE');advance(0.06)
    assert(select(2,G.Progress())==50)
    rows[55].missing=true;advance(0.06)
    assert(G.Progress()=='waiting' and #G.Members()==2)
    advance(13)
    assert(G.Progress()==nil and G.Status()=='GUILD_UNCERTAIN' and #G.Members()==2)
    rows[55].missing=nil;assert(G.Request());event('GUILD_ROSTER_UPDATE');advance(0.06)
    rights.view=false;advance(0.06)
    assert(G.Progress()=='waiting' and #G.Members()==2)
    changeGuild('Other');advance(0.06)
    assert(G.Progress()==nil and G.Status()=='GUILD_STALE' and #G.Members()==0)
  `);
});

test("guild controls highlight the active mode and paginate 25 players with independently scrolling rows", async () => {
  await run(`
    rows={}
    for index=1,30 do rows[index]={name=string.format('Name%02d',index),rank='Member',rankIndex=3,
      class='Mage',classFile='MAGE',publicNote='',officerNote='5000,0'} end
    local page=Raidwise.Pages.Guild.Create(region())
    G.Accept(G.Collect())
    assert(page.classButton==nil and #page.rows==25)
    assert(page.rosterTab.selected and not page.journalTab.selected)
    assert(page.rosterTab.background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    page.rosterTab.scripts.OnEnter(page.rosterTab);page.rosterTab.scripts.OnLeave(page.rosterTab)
    assert(page.rosterTab.background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    assert(page.rows[25].entry.name=='Name25' and page.vBar.shown and page.vBar.maximum>0)
    page.scroll.scripts.OnMouseWheel(page.scroll,-1)
    assert(page.scroll.verticalScroll>0 and page.headerScroll.verticalScroll==nil,'header stays fixed vertically')
    page.hBar:SetValue(80)
    assert(page.scroll.horizontalScroll==80 and page.headerScroll.horizontalScroll==80)
    page.rows[25].scripts.OnClick();assert(page.selected=='Name25')
    page.next.scripts.OnClick()
    assert(page.rows[1].entry.name=='Name26' and page.rows[5].entry.name=='Name30' and page.rows[6].entry==nil)
    assert(not page.vBar.shown and page.scroll.verticalScroll==0 and page.selected=='Name25')
    assert(not page.count.text:find(string.char(194,183),1,true))
    page.journalTab.scripts.OnClick()
    assert(page.journalTab.selected and not page.rosterTab.selected)
    assert(page.journalTab.background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    page.journalTab.scripts.OnEnter(page.journalTab);page.journalTab.scripts.OnLeave(page.journalTab)
    assert(page.journalTab.background==Raidwise.UITheme.CD_CURRENT_CHARACTER)
    page.rosterTab.scripts.OnClick()
    assert(page.rosterTab.selected and page.offset==0 and page.scroll.verticalScroll==0)
  `, ["PageGuild"], uiSetup);
});

test("guild row tooltip gives names and classes explicit readable colors", async () => {
  await run(`
    local lines={}
    GameTooltip={Hide=function() end,SetOwner=function() end,Show=function() end,
      AddLine=function(_,text,red,green,blue) lines[#lines+1]={text,red,green,blue} end}
    local page=Raidwise.Pages.Guild.Create(region())
    G.Accept(G.Collect())
    page.rows[1].scripts.OnEnter()
    assert(lines[1][1]=='Alice' and lines[2][1]=='Воин')
    for index=1,2 do
      assert(lines[index][2] and lines[index][2]>=0.8 and lines[index][3] and lines[index][3]>=0.8
        and lines[index][4] and lines[index][4]>=0.8,'tooltip name/class must stay readable on dark backgrounds')
    end
  `, ["PageGuild"], uiSetup);
});

test("mains-only mode excludes alt chains and unknown notes and combines with search and active raid groups", async () => {
  await run(`
    rows[1].officerNote='10000,500'
    rows[2].officerNote='янтарь'
    for _,entry in ipairs({{'Zero','0,0'},{'Chain','Alice'},{'Missing','Nobody'},{'Invalid','-1,2'}}) do
      rows[#rows+1]={name=entry[1],rank='Member',rankIndex=3,class='Mage',classFile='MAGE',
        publicNote='',officerNote=entry[2]}
    end
    function GetNumRaidMembers() return 3 end
    function GetRaidRosterInfo(index) return ({'Янтарь','Alice','Zero'})[index],0,({5,1,6})[index] end
    G.Accept(G.Collect())
    assert(#G.Members(nil,nil,false,nil,false,true)==2)
    assert(#G.Members('zero',nil,false,nil,false,true)==1)
    assert(#G.Members('alice',nil,false,nil,false,true)==0)
    local raid=G.Members(nil,nil,true,'ep',true,true)
    assert(#raid==1 and raid[1].name=='Янтарь')
    rights.view=false;assert(#G.Members(nil,nil,false,nil,false,true)==0)
    rights.view=true
    function GetGuildInfoText() return '-EPGP-\\n@BASE_GP:bad\\n-EPGP-' end
    G.Accept(G.Collect());assert(#G.Members(nil,nil,false,nil,false,true)==2,'main detection does not require valid PR')
    local page=Raidwise.Pages.Guild.Create(region());Raidwise.Pages.Guild.Refresh(page)
    page.offset=1;page.verticalOffset=100
    page.mainsOnly.scripts.OnClick()
    assert(page.filterMains and page.offset==0 and page.verticalOffset==0)
    assert(page.rows[1].entry.name=='Zero' and page.rows[2].entry.name=='Янтарь' and page.rows[3].entry==nil)
    page.raidOnly.scripts.OnClick();assert(page.rows[1].entry.name=='Янтарь' and page.rows[2].entry==nil)
    page.journalTab.scripts.OnClick();assert(not page.mainsOnly.shown)
    page.rosterTab.scripts.OnClick();assert(page.mainsOnly.shown and page.filterMains)
    page.mainsOnly.scripts.OnClick();assert(not page.filterMains and page.rows[1].entry.name=='Alice')
  `, ["PageGuild"], uiSetup);
});

test("core loads the renamed guild addon in TOC order and registers one guild page", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/wow-stubs.lua", import.meta.url), "utf8"));
    lua.doStringSync(`
      SlashCmdList={};GameTooltip={}
      function GetLocale() return 'enUS' end
      function GetAddOnMetadata() return '' end
      function GetRealmName() return 'Realm' end
      function UnitGUID() return 'SELF' end
      function UnitName() return 'Me' end
      function time() return 1000 end
      function ChatFrame_AddMessageEventFilter() end
      guildSources={}
    `);
    for (const addon of ["Raidwise", "Raidwise_Guild"]) {
      const toc = await readFile(new URL(`../${addon}/${addon}.toc`, import.meta.url), "utf8");
      for (const entry of toc.split(/\r?\n/).filter(line => line.endsWith(".lua"))) {
        const source = (await readFile(new URL(`../${addon}/${entry}`, import.meta.url), "utf8")).replace(/^\uFEFF/, "");
        assert(!source.includes("\u00b7"), `${addon}/${entry} must use font-compatible separators`);
        if (addon === "Raidwise") lua.doStringSync(source);
        else {
          lua.global.set("source", source);
          lua.doStringSync("assert(loadstring(source));guildSources[#guildSources+1]=source");
        }
      }
    }
    lua.doStringSync(`
      Raidwise.CreateMinimapButton=nil;Raidwise.InitializeClassicOpinionMarkers=nil
      local built=false
      Raidwise.CreateMainFrame=function()
        assert(Raidwise.Pages.Guild and not Raidwise.Pages.EPGP)
        assert(not Raidwise.ShowGuildRosterExport)
        local count=0
        for _,page in ipairs(Raidwise.MenuPages) do
          assert(page.id~='epgp');if page.id=='guild' then count=count+1;assert(page.group=='guild') end
        end
        assert(count==1);built=true
      end
      local requested
      function LoadAddOn(name)
        requested=name;assert(name=='Raidwise_Guild')
        for _,source in ipairs(guildSources) do assert(loadstring(source))() end
        return true
      end
      local messages={}
      function Raidwise:Print(text) messages[#messages+1]=text end
      Raidwise:OnInitialize()
      assert(requested=='Raidwise_Guild' and built and #messages==1,table.concat(messages,' | '))
    `);
  } finally { lua.global.close(); }
});
