-- One owner of the shared 3.3.5a inspect API. Consumers own their work lists.
local Addon = Raidwise
local active
local clock = 0
local frame = CreateFrame("Frame")
frame:RegisterEvent("INSPECT_TALENT_READY")
frame:Hide()

local function IdentityStatus(request)
	if not UnitExists(request.unit) then return "missing" end
	if UnitGUID(request.unit) ~= request.guid then return "unit_changed" end
end

local function Release(request, status)
	if active ~= request then return end
	active = nil
	frame:Hide()
	if type(ClearInspectPlayer) == "function" then pcall(ClearInspectPlayer) end
	if status and request.onStop then request.onStop(status) end
end

local function Notify(request)
	if type(ClearInspectPlayer) == "function" then pcall(ClearInspectPlayer) end
	if type(NotifyInspect) ~= "function" then return false end
	return pcall(NotifyInspect, request.unit)
end

function Addon:StartInspectRequest(owner, unit, callbacks)
	if active or not UnitExists(unit) then return false end
	local request = {
		owner = owner, unit = unit, guid = UnitGUID(unit), deadline = clock + 4,
		pollAt = clock + 0.25, onReady = callbacks.onReady, onPoll = callbacks.onPoll,
		onTimeout = callbacks.onTimeout, onStop = callbacks.onStop,
	}
	active = request
	frame:Show()
	if not Notify(request) then Release(request, "cannot_inspect") end
	return true
end

function Addon:CompleteInspectRequest(owner)
	if active and active.owner == owner then Release(active) end
end

function Addon:CancelInspectRequest(owner)
	if active and active.owner == owner then Release(active, "cancelled") end
end

function Addon:RetryInspectRequest(owner)
	local request = active
	if not request or request.owner ~= owner then return false end
	local status = IdentityStatus(request)
	if status then Release(request, status); return false end
	request.deadline = clock + 2
	request.pollAt = clock + 0.25
	if not Notify(request) then Release(request, "cannot_inspect"); return false end
	return true
end

frame:SetScript("OnEvent", function(_, _, unit)
	local request = active
	if not request then return end
	local status = IdentityStatus(request)
	if status then Release(request, status); return end
	if unit and not UnitIsUnit(unit, request.unit) then return end
	if request.onReady then request.onReady() end
end)

frame:SetScript("OnUpdate", function(_, elapsed)
	clock = clock + elapsed
	local request = active
	if not request then return end
	local status = IdentityStatus(request)
	if status then Release(request, status); return end
	if clock >= request.pollAt then
		request.pollAt = clock + 0.25
		if request.onPoll then request.onPoll() end
	end
	-- A callback may finish this request and start the next one.
	if active ~= request then return end
	if clock >= request.deadline then
		if request.onTimeout then request.onTimeout() end
		if active == request and clock >= request.deadline then Release(request, "timeout") end
	end
end)
