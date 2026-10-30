import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("active profile: autosave, explicit save, event editing, retained errors and deletion", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    lua.doStringSync(`
      UIParent={};UISpecialFrames={};StaticPopupDialogs={};regionCount=0
      function date(_,value) return tostring(value) end
      function region(parent)
        regionCount=regionCount+1
        local r={scripts={},parent=parent,shown=true,height=245,width=600,text='',anchors={}}
        function r:SetScript(key,fn) self.scripts[key]=fn end
        function r:SetText(text) self.text=text; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
        function r:GetText() return self.text end
        function r:GetHeight() return self.height end
        function r:GetWidth() return self.width end
        function r:SetHeight(n) self.height=n end
        function r:SetWidth(n) self.width=n end
        function r:SetSize(w,h) self.width=w;self.height=h end
        function r:SetPoint(_,relative) if type(relative)=='table' then assert(relative~=self);self.anchors[#self.anchors+1]=relative end end
        function r:SetAllPoints(relative) assert(relative~=self) end
        function r:GetVerticalScroll() return 0 end
        function r:Hide() self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
        function r:Show() self.shown=true end
        function r:IsShown() return self.shown end
        function r:Enable() self.enabled=true end
        function r:Disable() self.enabled=false end
        return setmetatable(r,{__index=function(_,key) if key:match('^[A-Z]') then return function() end end end})
      end
      function CreateFrame(_,_,parent) return region(parent) end
      Raidwise.Widgets={}
      local w=Raidwise.Widgets
      function w.CreateFontString(parent) return region(parent) end
      function w.CreatePlainButton(parent,_,_,label) local b=region(parent);b.label=region(b);b.label:SetText(label);return b end
      function w.CreateCopyBox(parent) return region(parent),region(parent) end
      function w.SetMenuButtonState(b,selected) b.selected=selected end
      w.ApplyPlainPanel=function() end;w.ApplyOuterBorder=function() end;w.AttachDragHandle=function() end
      w.AttachLayoutVersionLabel=function() end;w.FitCopyBoxToText=function() end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "PlayerRecords", "CharacterLinks", "PlayerRecordBridge", "PlayerRecordLinks", "ProfileEditor", "ProfileWindow"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local a=Raidwise
      function a:FactSummary(facts) return table.concat(facts,',') end
      function a:RatingOpinionLabel(opinion) return opinion end
      function a:GetCharacterMeetingStats() return {count=0} end
      function a:GetCharacterEncounters() return {} end
      function a:RefreshProfileCharacters() end
      function a:CreateProfileCharactersPanel(frame,parent) frame.profilePanels.characters=region(parent) end
      a:InitializeHistoryStore();a.db.locale='enUS'
      local x=a:EnsureHistoryEntryForGuid('X',{name='Other',realm='Realm'})
      local y=a:EnsureHistoryEntryForGuid('Y',{name='Another',realm='Realm'})
      a:ShowRaidCharacterWindow(x)
      local f=a.raidDetailFrame
      assert(f.layoutVersion==37 and f.selectedProfileTab=='events' and not a:IsPlayerRecordFilled('X'))
      assert(#f.opinions==4 and #f.facts==4 and f.profilePanels.opinion==nil)
      f.notesBox:SetText('private')
      assert(f.editor.dirty and f.status:GetText()=='Unsaved changes')
      f.scripts.OnUpdate(f,0.5);assert(a:GetProfileNotes(x)=='')
      f.scripts.OnUpdate(f,0.5);assert(a:GetProfileNotes(x)=='private' and not f.editor.dirty)
      assert(not a:HasPersonalRatingData(a:GetPersonalRating(x)))
      f.opinions[2].scripts.OnClick();assert(f.editor.draft.opinion=='positive')
      f.save.scripts.OnClick();assert(a:GetPersonalRating(x).opinion=='positive')
      f.add.scripts.OnClick();f.save.scripts.OnClick()
      local event=a:GetHistoryEvents(x)[1];assert(event.author.guid=='SELF')
      local eventAt=event.eventAt
      f.typeIndex=2;f.eventList.rows[1].edit.scripts.OnClick();f.save.scripts.OnClick()
      assert(a:GetHistoryEvents(x)[1].type==f.eventTypes[2].id and a:GetHistoryEvents(x)[1].eventAt==eventAt)
      f.eventList.rows[1].remove.scripts.OnClick();f.save.scripts.OnClick();assert(#a:GetHistoryEvents(x)==0)
      f.notesBox:SetText('on close');f:Hide();assert(a:GetProfileNotes(x)=='on close')
      a:ShowRaidCharacterWindow(x);f.notesBox:SetText('before switch');a:ShowRaidCharacterWindow(y)
      assert(a:GetProfileNotes(x)=='before switch' and f.editor.draft.key=='Y')
      f.notesBox:SetText('retained')
      local other=a:CreatePlayerRecordDraft('Y');other.note='external';a:CommitPlayerRecordDraft(other)
      f:Hide();assert(f.editor.status=='error' and a:GetProfileNotes(y)=='external')
      a:ShowRaidCharacterWindow(y);assert(f.notesBox:GetText()=='retained')
      f.reload.scripts.OnClick();assert(f.notesBox:GetText()=='external')
      f.notesBox:SetText('pending delete');local editor=f.editor
      assert(a:DeleteCharacterDatabaseRecords({'Y'})==1)
      assert(editor.status=='discarded' and not editor.dirty and not f.profileMember)
      a:TickProfileEditor(editor,10);assert(a:GetProfileNotes(y)=='')
      local self=a:EnsureHistoryEntryForGuid('SELF',{name='Me',realm='Realm'})
      a:ShowRaidCharacterWindow(self);assert(not f.opinions[2].enabled and not f.add.enabled)
      f.notesBox:SetText('self note');f.save.scripts.OnClick();assert(a:GetProfileNotes(self)=='self note')
      local empty=a:EnsureHistoryEntryForGuid('EMPTY',{name='Empty',realm='Realm'})
      a:ShowRaidCharacterWindow(empty);f.notesBox:SetText('not yet saved')
      assert(a:DeleteCharacterDatabaseRecords({'EMPTY'})==1)
      a:TickProfileEditor(f.editor,10);assert(a:GetProfileNotes(empty)=='')
    `);
  } finally { lua.global.close(); }
});
