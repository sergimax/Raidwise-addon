"""Run offline gear checks with Lupa's Lua 5.1 runtime.

Usage: python scripts/test-gear-check.py [directory containing lupa]
"""
import sys
from pathlib import Path

if len(sys.argv) > 1:
    sys.path.insert(0, sys.argv[1])
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
Raidwise = {}
function Raidwise:T(key) return key end
strlower = string.lower
function CreateFrame()
    return setmetatable({}, {__index = function() return function() end end})
end
''')
for name in ["GearCheckCatalog", "GearCheckSets", "GearCheckTrinkets",
             "GearCheckProfiles", "GearCheckBis", "GearCheckRules", "GearCheck"]:
    lua.execute((root / "Raidwise" / (name + ".lua")).read_text(encoding="utf-8-sig"))
results, passed, total = lua.eval("Raidwise:GearCheckRulesSelfTest()")
for result in results.values():
    if not result["ok"]:
        print("FAIL:", result["name"])
assert passed == total, f"Rule tests: {passed}/{total}"
print(f"Rule tests: {passed}/{total}")

# Inspect private closures without adding test hooks to the shipped namespace.
lua.execute('''
local function findUpvalue(root, wanted, visited)
    if type(root) ~= "function" or visited[root] then return end
    visited[root] = true
    for index = 1, 100 do
        local name, value = debug.getupvalue(root, index)
        if not name then break end
        if name == wanted then return value end
        local found = findUpvalue(value, wanted, visited)
        if found then return found end
    end
end
function private(name)
    for _, method in pairs(Raidwise) do
        local found = findUpvalue(method, name, {})
        if found then return found end
    end
    error("Missing private function: " .. name)
end
local parse = private("ParseItemLinkParts")
local collect = private("CollectGemsFromItemLink")
local normalize = private("NormalizeGem")
local link = "item:47674:3817:3625:3525:0:0:0:0:80"
local reads = {}
function GetItemGem(_, index) return nil, reads[index] end
function GetItemInfo(item)
    if item == 3525 then return "Wrong armor", nil, nil, nil, nil, "Armor", "Plate" end
end
local gems = collect(link, parse(link))
assert(#gems == 2 and gems[1].itemId == 0 and gems[2].enchantId == 3525)
local unresolved = normalize(gems[2])
assert(unresolved.state == "unresolved" and not unresolved.name)
reads[2] = "item:40111"
gems = collect(link, parse(link))
assert(#gems == 2 and gems[1].itemId == 0 and gems[2].itemId == 40111)
assert(normalize(gems[2]).state == "resolved")
local wrong = normalize({socketIndex=1, itemId=3525, enchantId=3525})
assert(wrong.itemId == 0 and not wrong.name and not next(wrong.stats))

local collectCached = private("CollectGemItemIds")
local clock = 1
function GetTime() return clock end
function UnitGUID() return "test-player" end
function GetInventoryItemLink() return link end
local cached = collectCached(link, parse(link), "target", nil, "head")
reads = {[1]="item:41398"}
cached = collectCached(link, parse(link), "target", nil, "head")
assert(cached[1].itemId == 41398 and cached[2].itemId == 40111)
link = "item:47674:3817:3625:3518:0:0:0:0:80"
cached = collectCached(link, parse(link), "target", nil, "head")
assert(cached[2].itemId == 0 and cached[2].enchantId == 3518)
reads = {}
clock = 20
cached = collectCached(link, parse(link), "target", nil, "head")
assert(cached[1].itemId == 0)

local normalizeItem = private("NormalizeItem")
function GetItemStats() return {EMPTY_SOCKET_META=1, EMPTY_SOCKET_RED=1} end
function UnitIsUnit() return false end
local info = {infoKnown=true, itemType="Armor", itemSubType="Plate", equipLoc="INVTYPE_HEAD"}
local item = normalizeItem(parse(link), link, info, nil, nil, "head")
assert(item.sockets.gemDataUncertain and not item.sockets.emptyConfirmed)
assert(item.sockets.states[1] == "unresolved")

local activate = private("EvaluateMetaActivation")
local evaluateGems = private("EvaluateGems")
local function has(findings, code)
    for _, finding in ipairs(findings) do
        if finding.code == code then return true end
    end
    return false
end
local profile = Raidwise:GetGearCheckProfile("WARRIOR", 2, true)
local head = {key="head", policy="CHECKED", item={
    sockets={meta=1,total=2}, gems={{itemId=0,color="unknown",socketIndex=1}}}}
local findings = {}
evaluateGems(findings, profile, head)
assert(has(findings,"META_NOT_CHECKABLE") and not has(findings,"META_NOT_META"))
head.item.gems = {{itemId=41398,isMeta=true,color="meta"}, {itemId=0,color="unknown"}}
local report = {}
findings = {}
activate(findings, report, {head})
assert(report.meta.active == nil and has(findings,"META_NOT_CHECKABLE"))
head.item.gems[3] = {itemId=49110,color="prismatic"}
findings = {}
activate(findings, report, {head})
assert(report.meta.active == true and not has(findings,"META_INACTIVE"))
head.item.gems = {{itemId=41398,isMeta=true,color="meta"}, {itemId=40111,color="red"}}
findings = {}
activate(findings, report, {head})
assert(report.meta.active == false and has(findings,"META_INACTIVE"))
head.item.sockets = {meta=1,total=2,empty=1,emptyConfirmed=true}
head.item.gems = {{itemId=41398,isMeta=true,color="meta"}}
findings = {}
evaluateGems(findings, profile, head)
assert(has(findings,"MISSING_GEM"))
''')
print("Gem collector, cache, and meta regression scenarios passed")
