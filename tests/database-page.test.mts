import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("database and history: membership, filters, sorting, pages, empty creation and deletion", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    lua.doStringSync(`
      party={'RECENT','FILLED'};observer='SELF'
      function UnitGUID(unit) if unit=='player' then return observer end;return party[tonumber(unit:match('%d+'))] or 'TARGET' end
      function UnitName(unit) return UnitGUID(unit),'Realm' end
      function UnitClass() return 'Mage','MAGE' end
      function UnitExists() return true end
      function GetNumRaidMembers() return 0 end
      function GetNumPartyMembers() return #party end
      function date(_,value) return tostring(value) end
      function GetRealZoneText() return 'Icecrown' end
      function region()
        local r={scripts={},text='',shown=true,height=800,width=860}
        function r:SetScript(key,fn) self.scripts[key]=fn end
        function r:SetText(value) self.text=value end
        function r:GetText() return self.text end
        function r:GetHeight() return self.height end
        function r:GetWidth() return self.width end
        function r:SetSize(w,h) self.width=w;self.height=h end
        function r:CreateTexture() return region() end
        function r:Show() self.shown=true end
        function r:Hide() self.shown=false end
        function r:IsShown() return self.shown end
        function r:Enable() self.enabled=true end
        function r:Disable() self.enabled=false end
        function r:GetValue() return 0 end
        function r:GetVerticalScroll() return 0 end
        return setmetatable(r,{__index=function(_,key) if key:match('^[A-Z]') then return function() end end end})
      end
      function CreateFrame() return region() end
      Raidwise.Widgets={};local w=Raidwise.Widgets
      function w.T(key,...) return key end
      function w.CreateFontString() return region() end
      function w.CreatePlainButton(_,_,_,label) local b=region();b.label=region();b.label:SetText(label);return b end
      function w.CreateTextInput() return region(),region() end
      function w.CreateCooldownScrollBar() return region() end
      w.ApplyPlainPanel=function() end;w.SetFontColor=function() end;w.SetBackdropColor=function() end
      w.LayoutTableScrollBars=function() end;w.ShowMemberRatingTooltip=function() end
      function w.ClassColor() return 1,1,1 end
      function w.FormatGuildDisplay(name) return name or '' end
      function w.HidePoolFrom(rows,start) for i=start,#rows do rows[i]:Hide() end end
      Raidwise.UITheme={CD_ROW_H=40,CD_HEADER_H=32,CD_SCROLLBAR_W=16,CD_HSCROLL_H=16,CD_TOOLBAR_H=24}
      GameTooltip={Hide=function() end}
      StaticPopupDialogs={};function StaticPopup_Show() popup={};return popup end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "PlayerRecords", "CharacterLinks", "PlayerRecordBridge", "PlayerRecordLinks", "PlayerEncounters", "PageHistory"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local a=Raidwise;a:InitializeHistoryStore()
      function a:RatingOpinionLabel(value) return value end
      function a:RatingOpinionColor() return {1,1,1} end
      function a:ShowRaidCharacterWindow(member) self.opened=member end
      local db=a.Pages.Database.Create(region());local history=a.Pages.History.Create(region())
      a.mainFrame=region();a.mainFrame.pages={database=db,history=history}
      local note=a:AddCharacterRecord('Note-Realm');assert(a:SaveProfileNotesForGuid(note.guid,note,'private'))
      now=now+1
      local neutral=a:AddCharacterRecord('Neutral-Realm');assert(a:SavePersonalRatingForGuid(neutral.guid,neutral,'neutral',{},{}))
      a:RecordCurrentGroupHistory(false)
      assert(a:SaveProfileNotesForGuid('FILLED',nil,'also saved'))
      local scan={guid='SCAN',name='Scanned',realm='Realm'};a:RecordTargetScanHistory({character=scan})
      a:RefreshHistoryView()
      assert(db.entryTotal==3 and history.entryTotal==2)
      assert(history.rowFrames[1].metText:GetText():find('Icecrown',1,true))
      assert(history.hint:GetText():find('SELF',1,true))
      assert(db.rowFrames[1].tagText==nil and db.rowFrames[1].gsText==nil and db.rowFrames[1].sourceText==nil)
      assert(db.rowFrames[1].authorText and db.rowFrames[1].countText)
      assert(history.rowFrames[1].deleteButton==nil)
      db.filters.opinion='neutral';a:RefreshHistoryView();assert(db.entryTotal==1)
      assert(db.rowFrames[1].member.guid==neutral.guid and db.rowFrames[1].authorText:GetText()=='SELF-Realm')
      db.filters.opinion='unset';a:RefreshHistoryView();assert(db.entryTotal==2)
      assert(db.rowFrames[1].opinionText:GetText()=='PROFILE_RECORD_UNSET')
      db.filters={name='note-realm'};a:RefreshHistoryView();assert(db.entryTotal==1)
      now=now+1;a:SaveProfileNotesForGuid(note.guid,note,'newest')
      db.filters={};a:RefreshHistoryView();assert(db.rowFrames[1].member.guid==note.guid)
      db.rowFrames[1].scripts.OnClick(db.rowFrames[1]);assert(a.opened.guid==note.guid)
      db.addName:SetText('Empty-Realm');db.addButton.scripts.OnClick()
      assert(a.opened.name=='Empty' and not a:IsPlayerRecordFilled(a.opened.guid) and db.entryTotal==3)
      db.addTargetButton.scripts.OnClick();assert(a.opened.guid=='TARGET' and not a:IsPlayerRecordFilled('TARGET'))
      for i=1,26 do local e=a:AddCharacterRecord('Extra'..i);a:SaveProfileNotesForGuid(e.guid,e,'saved') end
      a:RefreshHistoryView();assert(db.entryTotal==29 and db.pageCount==2)
      db.nextPageButton.scripts.OnClick();assert(db.currentPage==2)
      db.inputs.name:SetText('Neutral');db.inputs.name.scripts.OnTextChanged(db.inputs.name)
      assert(db.currentPage==1 and db.entryTotal==1)
      db.deleteAllButton.scripts.OnClick();assert(#popup.data==29)
      StaticPopupDialogs.RAIDWISE_DELETE_DATABASE.OnAccept(popup)
      assert(db.entryTotal==0 and history.entryTotal==2)
      observer='ALT';a:RefreshHistoryView();assert(history.entryTotal==0)
      observer='SELF';party={};a:RecordCurrentGroupHistory(false);now=now+14*86400+1;a:RefreshHistoryView()
      assert(history.entryTotal==0 and a:GetCharacterMeetingStats('RECENT').count==1)
    `);
  } finally { lua.global.close(); }
});
