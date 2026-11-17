import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("active profile: autosave, explicit save, event editing, retained errors and deletion", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    lua.doStringSync(`
      UIParent={};UISpecialFrames={};StaticPopupDialogs={};regionCount=0;profileScrollCount=0
      function date(_,value) return tostring(value) end
      local function depends(value,wanted,seen)
        if value==wanted then return true end
        seen=seen or {};if seen[value] then return false end;seen[value]=true
        for _,anchor in pairs(value.anchors or {}) do if depends(anchor,wanted,seen) then return true end end
        return false
      end
      function region(parent)
        regionCount=regionCount+1
        local r={scripts={},parent=parent,shown=true,height=245,width=600,text='',anchors={}}
        function r:SetScript(key,fn) self.scripts[key]=fn end
        function r:SetText(text) self.text=text; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
        function r:GetText() return self.text end
        function r:GetHeight() return self.height end
        function r:GetWidth() return self.width end
        function r:GetFrameLevel() return 1 end
        function r:SetHeight(n) self.height=n end
        function r:SetWidth(n) self.width=n end
        function r:SetSize(w,h) self.width=w;self.height=h end
        function r:SetPoint(point,relative)
          if type(relative)~='table' then relative=self.parent end
          if relative then assert(not depends(relative,self),'circular anchor');self.anchors[point]=relative end
        end
        function r:ClearAllPoints() self.anchors={} end
        function r:SetAllPoints(relative) assert(relative~=self) end
        function r:GetVerticalScroll() return 0 end
        function r:Hide() self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
        function r:Show() self.shown=true end
        function r:IsShown() return self.shown end
        function r:Enable() self.enabled=true end
        function r:Disable() self.enabled=false end
        return setmetatable(r,{__index=function(_,key) if key:match('^[A-Z]') then return function() end end end})
      end
      function CreateFrame(_,name,parent,template)
        if template=="UIPanelScrollFrameTemplate" then
          assert(type(name)=="string" and name~="","Wrath template scroll frames need names")
          profileScrollCount=profileScrollCount+1
        end
        return region(parent)
      end
      Raidwise.Widgets={}
      local w=Raidwise.Widgets
      function w.IconMarkup(path) return path and ('|T'..path..':14|t') or '' end
      function w.CharacterIconMarkup(member) return w.IconMarkup(member.specIcon) end
      function w.CreateFontString(parent) return region(parent) end
      function w.CreatePlainButton(parent,_,_,label) local b=region(parent);b.label=region(b);b.label:SetText(label);return b end
      function w.CreateCopyBox(parent) return region(parent),region(parent) end
      function w.CreateTextInput(parent) return region(parent),region(parent) end
      function w.T(key) return key end
      function w.SetFontColor() end
      Raidwise.UITheme={TEXT_IDLE={1,1,1}}
      function w.SetMenuButtonState(b,selected) b.selected=selected end
      w.ApplyPlainPanel=function() end;w.ApplyOuterBorder=function() end;w.AttachDragHandle=function() end
      w.AttachLayoutVersionLabel=function() end;w.FitCopyBoxToText=function() end
    `);
    for (const module of ["PlayerRecords", "PlayerRecordSupport", "PlayerRecordBridge", "PlayerRecordLinks", "ProfileEditor", "ProfileCharacters", "ProfileWindow"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local a=Raidwise
      function a:FactSummary(facts) return table.concat(facts,',') end
      function a:RatingOpinionIcon(opinion) return 'icon-'..opinion end
      function a:RatingWrapColor(label) return label end
      function a:RatingOpinionColor() return {1,1,1} end
      function a:RatingOpinionLabel(opinion) return opinion end
      function a:GetCharacterMeetingStats() return {count=0} end
      function a:GetCharacterEncounters() return {} end
      a:InitializeHistoryStore();a.db.locale='enUS'
      local x=a:EnsureHistoryEntryForGuid('X',{name='Other',realm='Realm'})
      local y=a:EnsureHistoryEntryForGuid('Y',{name='Another',realm='Realm'})
      a:ShowRaidCharacterWindow(x)
      local f=a.raidDetailFrame
      assert(f.selectedProfileTab=='overview' and not a:IsPlayerRecordFilled('X'))
      assert(not f.overviewList.scroll:IsShown())
      assert(f.guidLabel:GetText()=='GUID: X' and not f.actionsMenu:IsShown())
      assert(f.profileTabs.overview.selected and not f.profileTabs.events.selected)
      f.editOpinion.scripts.OnClick();assert(f.opinionEditor:IsShown())
      f.editOpinion.scripts.OnClick();assert(not f.opinionEditor:IsShown())
      f.profileTabs.characters.scripts.OnClick()
      assert(not f.characterSearchPanel:IsShown())
      f.characterSearchToggle.scripts.OnClick();assert(f.characterSearchPanel:IsShown())
      assert(#f.characterCandidateRows>0)
      f.characterSearchToggle.scripts.OnClick();assert(not f.characterSearchPanel:IsShown())
      f.journalButton.scripts.OnClick();assert(f.selectedProfileTab=='history')
      f.journalBack.scripts.OnClick();assert(f.selectedProfileTab=='characters')
      f.toNote.scripts.OnClick();assert(f.selectedProfileTab=='overview')
      f.profileTabs.events.scripts.OnClick()
      assert(f.opinions[1].label:GetText()=='Clear opinion')
      f.typeButton.scripts.OnClick();assert(f.eventMenu:IsShown() and f.typeIndex==nil)
      assert(not f.add.enabled)
      f.eventSearch:SetText('zzzz');assert(f.noChoices:GetText()=='No matching events')
      f.eventSearch:SetText('');f.eventChoices[3].scripts.OnClick()
      assert(f.typeIndex==3 and f.eventMenu:IsShown() and #f.editor.draft.events==0)
      assert(#f.opinions==4 and #f.facts==4 and f.profilePanels.opinion==nil)
      f.notesBox:SetText('private')
      assert(f.editor.dirty and f.status:GetText()=='Saving…')
      f.scripts.OnUpdate(f,0.5);assert(a:GetProfileNotes(x)=='')
      f.scripts.OnUpdate(f,0.5);assert(a:GetProfileNotes(x)=='private' and not f.editor.dirty)
      assert(not a:HasPersonalRatingData(a:GetPersonalRating(x)))
      assert(not f.save:IsShown())
      f.notesBox:SetText('before linking')
      f.profileTabs.characters.scripts.OnClick();f.characterSearchToggle.scripts.OnClick()
      local candidate=a:GetCharacterLinkCandidates('X','')[1]
      f.characterCandidateRows[1].buttons.CHAR_LINK_ADD.scripts.OnClick()
      assert(#a:GetLinkedCharacters('X')==2 and f.editor.draft.note=='before linking')
      local linkedRow
      for _,row in ipairs(f.characterRows) do
        if row.name:GetText():find(candidate.name,1,true) then linkedRow=row end
      end
      assert(linkedRow)
      linkedRow.buttons.OPEN_PROFILE.scripts.OnClick()
      assert(f.editor.draft.key==candidate.guid and a:GetProfileNotes(x)=='before linking')
      a:ShowRaidCharacterWindow(x);f.profileTabs.events.scripts.OnClick()
      f.typeButton.scripts.OnClick();f.eventChoices[3].scripts.OnClick()
      f.opinions[2].scripts.OnClick();assert(f.editor.draft.opinion=='positive')
      assert(f.opinions[2].label:GetText():find('|Ticon-positive:14|t',1,true))
      f.save.scripts.OnClick();assert(a:GetPersonalRating(x).opinion=='positive')
      f.add.scripts.OnClick();f.save.scripts.OnClick()
      local event=a:GetHistoryEvents(x)[1];assert(event.author.guid=='SELF')
      local eventAt=event.eventAt
      f.eventList.rows[1].edit.scripts.OnClick();f.eventChoices[2].scripts.OnClick();f.add.scripts.OnClick();f.save.scripts.OnClick()
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
      a:ShowRaidCharacterWindow(self);assert(not f.opinions[2].enabled and not f.typeButton:IsShown() and not f.editOpinion:IsShown())
      f.notesBox:SetText('self note');f.save.scripts.OnClick();assert(a:GetProfileNotes(self)=='self note')
      local empty=a:EnsureHistoryEntryForGuid('EMPTY',{name='Empty',realm='Realm'})
      a:ShowRaidCharacterWindow(empty);f.notesBox:SetText('not yet saved')
      assert(a:DeleteCharacterDatabaseRecords({'EMPTY'})==1)
      a:TickProfileEditor(f.editor,10);assert(a:GetProfileNotes(empty)=='')
      local draft=a:CreatePlayerRecordDraft('X')
      for index=1,60 do
        draft.opinion=index%2==0 and 'positive' or 'negative'
        assert(a:CommitPlayerRecordDraft(draft))
      end
      local wholeRecord=a.GetPlayerRecord
      a.GetPlayerRecord=function() error('UI must not copy the entire journal') end
      local getPage=a.GetPlayerRecordChangePage
      local requestedPage,returnedRows
      a.GetPlayerRecordChangePage=function(self,key,page)
        local rows=getPage(self,key,page)
        requestedPage,returnedRows=page,#rows
        return rows
      end
      a:ShowRaidCharacterWindow(x)
      assert(requestedPage==nil)
      f.journalButton.scripts.OnClick();assert(requestedPage==1 and returnedRows==25)
      f.historyPage=2;f.journalButton.scripts.OnClick()
      assert(requestedPage==2 and returnedRows==25 and f.historyPages:GetText():find('2 / ',1,true))
      f.historyPage=999;f.journalButton.scripts.OnClick()
      assert(requestedPage==f.maxHistoryPage and returnedRows>0 and returnedRows<=25)
      local journalPage=f.historyPage
      function a:GetCharacterEncounters()
        local result={}
        for index=1,60 do result[index]={startedAt=index,lastSeenAt=index,places={}} end
        return result
      end
      f.profileTabs.meetings.scripts.OnClick();f.meetingPage=2
      f.profileTabs.meetings.scripts.OnClick()
      assert(f.meetingPage==2 and f.historyPage==journalPage)
      assert(f.meetingList.rows[1].label:GetText():find('35',1,true))
      f.journalButton.scripts.OnClick();assert(f.meetingPage==2 and f.historyPage==journalPage)
      a.GetPlayerRecord=wholeRecord;a.GetPlayerRecordChangePage=getPage
      assert(profileScrollCount>0,"The active profile created no template scroll frames")
    `);
  } finally { lua.global.close(); }
});
