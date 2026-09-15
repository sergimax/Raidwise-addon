import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

test("extracted theme preserves palette references and bound colors across switches", async () => {
  const lua = await Lua.create();
  try {
    assert.equal(lua.doStringSync("return _VERSION"), "Lua 5.1");
    lua.doStringSync(`
      Raidwise={db={theme="dark"}}
      function hooksecurefunc(object, method, callback)
        local original=object[method]
        object[method]=function(self,...)
          original(self,...)
          callback(self,...)
        end
      end
    `);
    for (const module of ["UITheme", "UIWidgets", "RosterWidgets"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      local W, UI = Raidwise.Widgets, Raidwise.UITheme
      local color = UI.PANEL_BG
      local original = {unpack(color)}
      local region = {SetBackdropColor=function(self,...) self.color={...} end}
      W.SetBackdropColor(region,color)
      local width,height=UI.CONTENT_WIDTH,UI.CONTENT_HEIGHT
      Raidwise:SetTheme("light")
      assert(UI.PANEL_BG==color and color[1]~=original[1])
      assert(region.color[1]==color[1])
      Raidwise:SetTheme("dark")
      for index,value in ipairs(original) do assert(color[index]==value) end
      assert(region.color[1]==original[1])
      assert(UI.CONTENT_WIDTH==width and UI.CONTENT_HEIGHT==height)
      assert(type(W.CreatePlainButton)=="function" and type(W.ShowMemberRatingTooltip)=="function")
      assert(type(W.GearVerdictColor("A"))=="table")
      function CreateFrame(kind,name,parent,template)
        assert(template~="InputBoxTemplate", "Anonymous template input is unsafe on Wrath")
        local control={parent=parent,scripts={}}
        function control:SetBackdropColor(...) self.background={...} end
        function control:SetTextColor(...) self.foreground={...} end
        function control:SetFontObject(font) self.font=font end
        function control:SetScript(event,callback) self.scripts[event]=callback end
        function control:ClearFocus() self.cleared=true end
        return setmetatable(control,{__index=function(_,key)
          if key:match("^Set") or key=="EnableMouse" then return function() end end
        end})
      end
      local first,host=W.CreateTextInput({},150)
      local second,secondHost=W.CreateTextInput({},200)
      assert(first~=second and host~=secondHost and first.font and second.font)
      assert(first.foreground and host.background)
      Raidwise:SetTheme("light")
      assert(first.foreground[1]==UI.TEXT_BODY[1] and host.background[1]==UI.INPUT_BG[1])
      Raidwise:SetTheme("dark")
      assert(second.foreground[1]==UI.TEXT_BODY[1] and secondHost.background[1]==UI.INPUT_BG[1])
      first.scripts.OnEscapePressed(first); assert(first.cleared and not second.cleared)
    `);
  } finally { lua.global.close(); }
});
