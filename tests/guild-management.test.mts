import { readFile } from "node:fs/promises";
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
    for (const name of ["GuildManagement", ...extraModules]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${name}.lua`, import.meta.url), "utf8"));
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
 function result:Show() self.shown=true end
 function result:Hide() self.shown=false end
 function result:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
 function result:Enable() self.enabled=true end
 function result:Disable() self.enabled=false end
 function result:EnableKeyboard(enabled) self.enabled=enabled end
 function result:RegisterEvent() eventFrame=self end
 return setmetatable(result,{__index=function(_,key)
  if key:match('^Set') or key=='EnableMouse' or key=='ClearFocus' then return function() end end
 end})
end
function CreateFrame(_,_,parent) return region(parent) end
Raidwise.Widgets={
 CreateFontString=function(parent) return region(parent) end,
 CreatePlainButton=function(parent) local button=region(parent);button.label=region(button);return button end,
 CreateTextInput=function(parent) local host=region(parent);return region(host),host end,
 SetPlainButtonTooltip=function(button,key) button.tooltipKey=key end,
}
Raidwise.UITheme={CONTENT_WIDTH=970,MENU_BAR_W=90}
function Raidwise:T(key) return key end
function Raidwise:FormatShortDateTime(value) return tostring(value) end
GameTooltip={Hide=function() end}
`;

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

test("EPGP export distinguishes officer-note viewing from editing", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(setup);
    lua.doStringSync(await readFile(new URL("../Raidwise_EPGP/GuildRosterExport.lua", import.meta.url), "utf8"));
    lua.doStringSync(`
      rights.officer=false
      local snapshot=Raidwise:CollectGuildRosterSnapshot()
      assert(snapshot.officerNotesStatus=='available' and snapshot.members[1].officerNote=='secret')
      rights.view=false
      assert(Raidwise:CollectGuildRosterSnapshot().officerNotesStatus=='unavailable')
    `);
  } finally { lua.global.close(); }
});
