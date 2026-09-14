import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("native opinion marks follow row identities, scrolling, mailbox pages and saved edits", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync(`
      Raidwise={db={history={}}}
      function Raidwise:T(key) return key end
      function GetRealmName() return "My Realm" end
      function UnitGUID() return "SELF" end
      function time() return 1000 end
      function ChatFrame_AddMessageEventFilter() end
      hooks={}
      function hooksecurefunc(name,callback)
        hooks[name]=hooks[name] or {}
        table.insert(hooks[name],callback)
      end
      function fire(name,...)
        for _,callback in ipairs(hooks[name] or {}) do callback(...) end
      end
      function CreateFrame()
        local frame={scripts={}}
        function frame:RegisterEvent() end
        function frame:SetScript(name,callback) self.scripts[name]=callback end
        lastFrame=frame
        return frame
      end
      function label(text)
        return {text=text,GetText=function(self) return self.text end,
          SetText=function(self,value) self.text=value end}
      end
      function row(name)
        return {name=label(name),shown=true,IsShown=function(self) return self.shown end}
      end
      FRIENDS_BUTTON_TYPE_WOW=3
      SQUELCH_TYPE_IGNORE=1
      IGNORES_TO_DISPLAY=3
      INBOXITEMS_TO_DISPLAY=7
      friends={"Good", "Bad", "Unknown"}
      ignored={"Bad", "Neutral"}
      function GetFriendInfo(index) return friends[index] end
      function GetIgnoreName(index) return ignored[index] end
      function FriendsList_Update() end
      function IgnoreList_Update() end
      function DynamicScrollFrame_Update() end
      FriendsFrameFriendsScrollFrame={buttons={row("Good, Level 80"),row("Unknown"),row("Real ID")},
        topIndex=1,usedButtons=3,nextButtonOffset=0}
      for index,button in ipairs(FriendsFrameFriendsScrollFrame.buttons) do
        button.buttonType=3; button.id=index
      end
      FriendsFrameFriendsScrollFrame.buttons[2].id=3
      FriendsFrameFriendsScrollFrame.buttons[3].buttonType=2
      FriendsFrameIgnoreButton1=row("") -- native section header
      FriendsFrameIgnoreButton2=row("Bad")
      FriendsFrameIgnoreButton2.type=1; FriendsFrameIgnoreButton2.index=1
      FriendsFrameIgnoreButton3=row("Neutral")
      FriendsFrameIgnoreButton3.type=1; FriendsFrameIgnoreButton3.index=2
      function GetInboxNumItems() return mailCount or 0 end
      function GetInboxHeaderInfo(index) return nil,nil,senders[index] end
      function saved(name,opinion,realm)
        return {guid=name,name=name,realm=realm or "My Realm",
          rating={personal={opinion=opinion,updatedAt=100}}}
      end
    `);
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "RatingPresentation", "ClassicOpinionMarkers"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local addon=Raidwise
      addon.db.history={good=saved("Good","positive"),bad=saved("Bad","negative"),
        neutral=saved("Neutral","neutral"),other=saved("Unknown","negative","Other Realm"),
        met={guid="Met",name="Met",realm="My Realm"}}
      addon:InitializeClassicOpinionMarkers()
      addon:InitializeClassicOpinionMarkers()
      assert(#hooks.FriendsList_Update==1 and #hooks.DynamicScrollFrame_Update==1)
      assert(not hooks.InboxFrame_Update) -- mail UI loads later
      local button=FriendsFrameFriendsScrollFrame.buttons[1]
      assert(button.name.text:find("QirajiCrystal_03",1,true) and button.name.text:find("[+]",1,true))
      local marked=button.name.text
      fire("FriendsList_Update"); fire("DynamicScrollFrame_Update",FriendsFrameFriendsScrollFrame)
      assert(button.name.text==marked, "Refresh stacked opinion prefixes")
      assert(FriendsFrameFriendsScrollFrame.buttons[2].name.text=="Unknown")
      assert(FriendsFrameFriendsScrollFrame.buttons[3].name.text=="Real ID")
      assert(FriendsFrameIgnoreButton1.name.text=="")
      assert(FriendsFrameIgnoreButton2.name.text:find("QirajiCrystal_02",1,true))
      assert(FriendsFrameIgnoreButton3.name.text:find("[=]",1,true))
      button.name:SetText("Bad, Level 80"); button.id=2
      fire("DynamicScrollFrame_Update",FriendsFrameFriendsScrollFrame)
      assert(button.name.text:find("[-]",1,true) and not button.name.text:find("Good",1,true))
      FriendsFrameFriendsScrollFrame.topIndex=2 -- recycled first button becomes a spacer
      fire("DynamicScrollFrame_Update",FriendsFrameFriendsScrollFrame)
      assert(button.name.text=="Bad, Level 80")
      FriendsFrameFriendsScrollFrame.topIndex=1
      fire("FriendsList_Update")
      button.buttonType=1; button.name:SetText("") -- offline header
      fire("FriendsList_Update")
      assert(button.name.text=="")
      FriendsFrameIgnoreButton2.type=nil; FriendsFrameIgnoreButton2.name:SetText("")
      fire("IgnoreList_Update")
      assert(FriendsFrameIgnoreButton2.name.text=="")

      InboxFrame=row(""); InboxFrame.pageNum=1
      MailItem1=row(""); MailItem1Sender=label("Bad")
      MailItem2=row(""); MailItem2Sender=label("Met")
      mailCount=8; senders={[1]="Bad",[2]="Met",[8]="good-MyRealm"}
      function InboxFrame_Update() end
      lastFrame.scripts.OnEvent(lastFrame,"ADDON_LOADED")
      assert(#hooks.InboxFrame_Update==1)
      assert(MailItem1Sender.text:find("[-]",1,true))
      assert(MailItem2Sender.text=="Met", "Encounter-only record was marked neutral")
      InboxFrame.pageNum=2; MailItem1Sender:SetText("good-MyRealm")
      fire("InboxFrame_Update")
      assert(MailItem1Sender.text:find("[+]",1,true))
      addon:SavePersonalRatingForGuid("good",nil,"negative",{}, {})
      addon:RefreshClassicOpinionMarkers()
      assert(MailItem1Sender.text:find("[-]",1,true) and not MailItem1Sender.text:find("[+]",1,true))
      mailCount=0
      fire("InboxFrame_Update")
      assert(MailItem1Sender.text=="good-MyRealm", "Empty inbox retained a recycled marker")
      addon.db=nil
      addon:RefreshClassicOpinionMarkers()
      assert(addon.db==nil, "Native UI reads initialized SavedVariables")
    `);
  } finally {
    lua.global.close();
  }
});
