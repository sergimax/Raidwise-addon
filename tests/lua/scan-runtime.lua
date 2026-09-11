-- Deterministic event/frame harness. Loaded before the production collector.
ScanRuntime = { frames = {}, elapsed = 0, notifications = {}, identities = { target = "A", raid1 = "A", raid2 = "B", player = "SELF" } }
function CreateFrame()
    local frame = { scripts = {}, events = {}, shown = true }
    function frame:SetScript(kind, handler) self.scripts[kind] = handler end
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:Hide() self.shown = false end
    function frame:Show() self.shown = true end
    ScanRuntime.frames[#ScanRuntime.frames + 1] = frame
    return frame
end
function ScanRuntime:Tick(seconds)
    self.elapsed = self.elapsed + seconds
    for _, frame in ipairs(self.frames) do
        if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, seconds) end
    end
end
function ScanRuntime:Ready(unit)
    for _, frame in ipairs(self.frames) do
        if frame.events.INSPECT_TALENT_READY and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, "INSPECT_TALENT_READY", unit)
        end
    end
end
function UnitGUID(unit) return ScanRuntime.identities[unit] end
function UnitExists(unit) return UnitGUID(unit) ~= nil end
function UnitIsUnit(left, right) return UnitGUID(left) ~= nil and UnitGUID(left) == UnitGUID(right) end
function UnitIsConnected(unit) return UnitExists(unit) end
function NotifyInspect(unit)
    ScanRuntime.notifications[#ScanRuntime.notifications + 1] = { unit = unit, guid = UnitGUID(unit), at = ScanRuntime.elapsed }
end
function ClearInspectPlayer() end
