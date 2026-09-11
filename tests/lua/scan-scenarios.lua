-- Mock collection only: scheduling, events, retry handling and raid progression
-- execute the production GearCheck.lua code. Gem normalization has its own fixture.
local runtime = ScanRuntime
local completed = {}
local resumed = 0
local specKnown = true
local uncertain = false
function Raidwise:EvaluateGearCheck(report) report.evaluated = true end
function Raidwise:QueuePartyInspects() resumed = resumed + 1 end
function Raidwise:CollectGearCheck(unit)
    if not UnitExists(unit) then return nil end
    return {
        character = { guid = UnitGUID(unit), isSelf = unit == "player", specKnown = specKnown },
        inspect = { canInspect = true, needed = unit ~= "player" },
        collection = { counts = { filledCheckedSlots = 1 } },
        equipment = { { policy = "CHECKED", item = { sockets = { gemDataUncertain = uncertain } } } },
    }
end
local function start(unit)
    return Raidwise:StartGearCheckUnitScan(unit or "target", function(report, status)
        completed[#completed + 1] = { report = report, status = status, at = runtime.elapsed }
    end)
end
function RunScanScenario(scenario)
    if scenario == "repeated" then
        for index = 1, 2 do
            assert(start())
            assert(not start(), "Overlapping request accepted")
            assert(#completed == index - 1, "Completed before inspect event")
            runtime:Ready()
            assert(#completed == index and completed[index].report.character.guid == "A")
            assert(completed[index].status == "ok" and completed[index].report.inspect.complete)
        end
        runtime:Ready()
        runtime:Tick(10)
        assert(#completed == 2 and resumed == 2 and not Raidwise:IsGearCheckScanBusy())
    elseif scenario == "event-order" then
        runtime:Ready()
        assert(start())
        runtime:Ready("raid2")
        runtime:Tick(0.25)
        assert(#completed == 0, "Unrelated event completed request")
        runtime:Ready("raid1")
        assert(#completed == 1 and completed[1].status == "ok")
    elseif scenario == "missing" then
        assert(start())
        runtime.identities.target = nil
        runtime:Tick(0.25)
        assert(#completed == 1 and completed[1].status == "missing")
        assert(not Raidwise:IsGearCheckScanBusy() and resumed == 1)
        runtime.identities.target = "A"
        assert(start())
        runtime:Ready()
        assert(#completed == 2 and completed[2].status == "ok")
    elseif scenario == "deadline" then
        assert(start())
        for index = 1, 15 do runtime:Tick(0.25) end
        assert(#completed == 0)
        runtime:Tick(0.25)
        assert(#completed == 1 and completed[1].at == 4)
        assert(not Raidwise:IsGearCheckScanBusy())
    elseif scenario == "raid" then
        function Raidwise:CompositionMembers() return { {unit = "raid1"}, {unit = "raid2"} } end
        local results
        assert(Raidwise:StartGearCheckRaidScan(nil, function(entries) results = entries end))
        assert(#runtime.notifications == 1)
        runtime:Tick(0.25)
        runtime:Ready("raid1")
        assert(not results and #runtime.notifications == 2 and resumed == 0)
        runtime:Tick(0.25)
        runtime:Ready("raid2")
        assert(#results == 2 and results[1].report.character.guid == "A" and results[2].report.character.guid == "B")
        assert(runtime.elapsed == 0.5 and resumed == 1 and not Raidwise:IsGearCheckScanBusy())
    elseif scenario == "identity" then
        assert(start())
        runtime.identities.target = "B"
        runtime:Ready()
        assert(#completed == 0 or completed[1].status ~= "ok", "Reassigned target accepted as successful original request")
    elseif scenario == "spec-retry" or scenario == "gem-retry" then
        specKnown = scenario ~= "spec-retry"
        uncertain = scenario == "gem-retry"
        assert(start())
        runtime:Ready()
        for index = 1, 16 do runtime:Tick(0.25) end
        assert(#runtime.notifications == 2, "Retry inspect was not requested")
        assert(#completed == 0 and Raidwise:IsGearCheckScanBusy(), "Retry finalized before its extra budget elapsed")
        specKnown = true
        uncertain = false
        runtime:Tick(0.25)
        runtime:Ready()
        assert(#completed == 1 and completed[1].status == "ok")
    else
        error("Unknown scan scenario: " .. tostring(scenario))
    end
end
