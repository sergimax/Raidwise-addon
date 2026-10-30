import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("active opinions agree across chat, roster and live unit tooltips without Karma or private text", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    lua.doStringSync(`
      actor='SELF';filters={};tooltipUnit='target';tooltipHooks={}
      function UnitGUID(unit) return unit=='player' and actor or 'X' end
      function UnitName(unit) return unit=='player' and 'Me' or 'Rated','Realm' end
      function UnitExists(unit) return unit=='target' or unit=='player' end
      function ChatFrame_AddMessageEventFilter(event,fn) filters[event]=fn end
      Raidwise.Widgets={T=function(key) return key end}
      Raidwise.UITheme={TEXT_DISABLED={0.5,0.5,0.5},TEXT_IDLE={1,1,1}}
      GameTooltip={lines={},shown=true}
      function GameTooltip:HookScript(key,fn) tooltipHooks[key]=fn end
      function GameTooltip:GetUnit() return 'Rated',tooltipUnit end
      function GameTooltip:IsShown() return self.shown end
      function GameTooltip:Show() self.shown=true end
      function GameTooltip:AddLine(text) self.lines[#self.lines+1]=text end
      function GameTooltip:NumLines() return #self.lines end
      function GameTooltip:SetUnit(unit)
        tooltipUnit=unit;self.lines={'base'}
        if tooltipHooks.OnTooltipSetUnit then tooltipHooks.OnTooltipSetUnit(self) end
      end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "PlayerRecords", "CharacterLinks", "PlayerRecordBridge", "PlayerRecordLinks", "RatingPresentation", "RosterWidgets", "UnitTooltips", "ProfileEditor", "ProfileWindow"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local a=Raidwise;local w=a.Widgets;a:InitializeHistoryStore()
      local entry=a:EnsureHistoryEntryForGuid('X',{name='Rated',realm='Realm'})
      a:SaveProfileNotesForGuid('X',entry,'PRIVATE TEXT')
      entry.lastScannedAt=time()
      assert(filters.CHAT_MSG_SAY(nil,'CHAT_MSG_SAY','hello','Rated')==nil)
      assert(w.RatingOpinionIcon(entry)=='' and w.RatingOpinionSymbol(entry)=='—')
      assert(#a:BuildUnitTooltipRatingLinesForMember(entry)==0)
      for _,opinion in ipairs({'positive','neutral','negative'}) do
        assert(a:SavePersonalRatingForGuid('X',entry,opinion,{},{}))
        actor='ALT' -- selected version's author is another character
        assert(w.RatingOpinion(entry)==opinion and w.RatingOpinionIcon(entry)~='')
        local _,message=filters.CHAT_MSG_SAY(nil,'CHAT_MSG_SAY','hello','rated-Realm')
        assert(message and message:find('Rw|cffffffff>',1,true) and not message:find('51',1,true))
        assert(not message:find('PRIVATE',1,true))
        GameTooltip:SetUnit('target')
        assert(#GameTooltip.lines==3 and not table.concat(GameTooltip.lines):find('PRIVATE',1,true))
        local p=a:GetPersonalRating(entry);p.tags={'good_player'}
        assert(#a:BuildUnitTooltipRatingLines(p,{positivePercent=99,tags={'good_player'}},{},'stacked')==1)
        assert(#a:BuildUnitTooltipRatingLines(p,nil,{hidePersonal=true})==0)
        actor='SELF'
      end
      local item='|cffa335ee|Hitem:123:0|h[Item]|h|r'
      local achievement='|cffffff00|Hachievement:456:Player:1:0|h[Achievement]|h|r'
      local _,message=filters.CHAT_MSG_WHISPER(nil,'CHAT_MSG_WHISPER','before '..item..achievement..' after','Rated')
      assert(message:find(item,1,true) and message:find(achievement,1,true) and message:find('|cffff0000 after',1,true))
      assert(filters.CHAT_MSG_SAY(nil,'CHAT_MSG_SAY','hello','Rated-OtherRealm')==nil)
      assert(a:FindOpinionCharacter('Rated','X')==entry)
      a:DeleteCharacterDatabaseRecords({'X'})
      assert(#GameTooltip.lines==1 and GameTooltip.lines[1]=='base')
      assert(filters.CHAT_MSG_SAY(nil,'CHAT_MSG_SAY','hello','Rated')==nil)
      assert(w.RatingOpinionIcon(entry)=='' and w.RatingOpinionText(entry)=='PROFILE_RECORD_UNSET')
      tooltipUnit=nil;GameTooltip.lines={'item tooltip'};a:RefreshUnitOpinionTooltip()
      assert(GameTooltip.lines[1]=='item tooltip')
      local editor=a:OpenProfileEditor('X');editor.draft.opinion='neutral';a:MarkProfileEditorChanged(editor)
      assert(a:SaveProfileEditor(editor))
      assert(w.RatingOpinionSymbol(entry)=='=' and #a:BuildUnitTooltipRatingLinesForMember(entry)==1)
      local retained=a:GetPersonalRating(entry);retained.facts[1]='guild_master'
      assert(#a:GetPersonalRating(entry).facts==0)
    `);
  } finally { lua.global.close(); }
});
