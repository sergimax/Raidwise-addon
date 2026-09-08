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
reads[2] = "item:40152"
gems = collect(link, parse(link))
assert(#gems == 2 and gems[1].itemId == 0 and gems[2].itemId == 40152)
local potent = normalize(gems[2])
assert(potent.state == "resolved" and potent.color == "orange")
assert(potent.stats.spellPower == 12 and potent.stats.critRating == 10)
assert(Raidwise:GetGearCheckGemInfo(3519) == nil)
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
assert(cached[1].itemId == 41398 and cached[2].itemId == 40152)
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

-- Inspect placeholders only establish empties after the inventory data is ready.
local tooltipLines = {}
local inventoryAvailable = true
function CreateFrame(_, name)
    return {
        Hide = function() end, SetOwner = function() end, ClearLines = function() end,
        SetInventoryItem = function() end, SetHyperlink = function() end,
        GetName = function() return name end,
        NumLines = function() return inventoryAvailable and #tooltipLines or 0 end,
    }
end
EMPTY_SOCKET_RED = "Красное гнездо"
EMPTY_SOCKET_META = "Особое гнездо"
local function setTooltip(lines)
    tooltipLines = lines
    for index, text in ipairs(lines) do
        local lineText = text
        _G["RaidwiseGearCheckScanTipTextLeft" .. index] = { GetText = function() return lineText end }
    end
end
reads = {}
link = "item:51137:0:0:0:0:0:0:0:80"
setTooltip({"Test helm", "|cffffffffОсобое гнездо|r", "  Красное гнездо  "})
item = normalizeItem(parse(link), link, info, "target", 1, "head", false)
assert(item.sockets.gemDataUncertain and not item.sockets.emptyConfirmed)
item = normalizeItem(parse(link), link, info, "target", 1, "head", true)
assert(item.sockets.empty == 2 and item.sockets.emptyConfirmed and not item.sockets.gemDataUncertain)
assert(item.sockets.states[1] == "empty" and item.sockets.states[2] == "empty")
findings = {}
evaluateGems(findings, profile, {key="head", policy="CHECKED", item=item})
assert(has(findings, "MISSING_GEM") and not has(findings, "GEM_NOT_CHECKABLE"))
local shortLink = "item:51137"
item = normalizeItem(parse(shortLink), shortLink, info, "target", 1, "head", true)
assert(item.sockets.gemDataUncertain and not item.sockets.emptyConfirmed)
inventoryAvailable = false
item = normalizeItem(parse(link), link, info, "target", 1, "head", true)
assert(item.sockets.gemDataUncertain and not item.sockets.emptyConfirmed)
inventoryAvailable = true

-- One filled socket plus one confirmed empty socket is still missing a gem.
link = "item:51137:0:3625:0:0:0:0:0:80"
reads = {[1]="item:41398"}
setTooltip({"Test helm", "Красное гнездо"})
item = normalizeItem(parse(link), link, info, "target", 1, "head", true)
assert(item.sockets.empty == 1 and item.sockets.emptyConfirmed and not item.sockets.gemDataUncertain)
-- A present but unresolved gem is never classified as empty.
reads = {}
link = "item:51137:0:99999:0:0:0:0:0:80"
item = normalizeItem(parse(link), link, info, "target", 1, "head", true)
assert(item.sockets.gemDataUncertain and item.sockets.states[1] == "unresolved")

-- Both Charred Twilight Scale variants: caster DPS, B-only Holy Paladin, C other healers.
for _, itemId in ipairs({54572, 54588}) do
    for _, spec in ipairs({{"PALADIN",1,"B"}, {"DRUID",3,"C"}, {"PRIEST",1,"C"}, {"PRIEST",2,"C"}, {"SHAMAN",3,"C"}, {"MAGE",1,"A"}}) do
        local trinketReport = {
            character={classFile=spec[1],specTab=spec[2],specKnown=true},
            equipment={{key="trinket1",policy="CHECKED",item={
                itemId=itemId,infoKnown=true,category="armor",armorType="misc",equipLoc="INVTYPE_TRINKET",
                stats={hasteRating=184},sockets={total=0},gems={},enchant={present=false},
            }}},
        }
        Raidwise:EvaluateGearCheck(trinketReport)
        local verdict = trinketReport.equipment[1].verdict
        if spec[1] == "MAGE" then
            assert(verdict == "A" or verdict == "S", verdict)
        else
            assert(verdict == spec[3], spec[1] .. " " .. tostring(verdict))
        end
    end
end
