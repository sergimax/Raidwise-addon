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
    `);
  } finally { lua.global.close(); }
});
