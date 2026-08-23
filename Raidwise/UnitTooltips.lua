-- Append personal / community rating lines to the default unit GameTooltip.
-- Only add on a fresh SetUnit fill (OnTooltipSetUnit). Mouseover retries must
-- not AddLine when switching raid-frame units or lines stack on the same tooltip.

local Addon = Raidwise

local function FindHistoryEntryForUnit(unit)
	if not unit or not UnitExists(unit) then
		return nil, nil
	end
	local guid = UnitGUID(unit)
	if guid and guid ~= "" and Addon.GetHistoryEntry then
		local entry = Addon:GetHistoryEntry(guid)
		if entry then
			return entry, guid
		end
	end

	local name, realm = UnitName(unit)
	if not name or name == "" or not Addon.HistoryStore then
		return nil, guid
	end
	realm = realm or GetRealmName() or ""
	local store = Addon:HistoryStore()
	for _, entry in pairs(store) do
		if type(entry) == "table" and entry.name == name then
			local entryRealm = entry.realm or ""
			if entryRealm == "" or realm == "" or entryRealm == realm then
				return entry, entry.guid or guid
			end
		end
	end
	return nil, guid
end

local function ClearAppendMarker(tooltip)
	if tooltip then
		tooltip.rwRatingGuid = nil
		tooltip.rwRatingLineCount = nil
	end
end

local function ResolveTooltipUnit(tooltip)
	local _, unit = tooltip:GetUnit()
	if unit and UnitExists(unit) then
		return unit
	end
	if UnitExists("mouseover") and UnitIsPlayer("mouseover") then
		return "mouseover"
	end
	if UnitExists("target") and UnitIsPlayer("target") then
		return "target"
	end
	return nil
end

local function AppendRatingLines(tooltip, unit)
	if not tooltip or not unit or not UnitExists(unit) then
		return false
	end
	if type(UnitIsPlayer) == "function" and not UnitIsPlayer(unit) then
		return false
	end
	if not Addon.BuildUnitTooltipRatingLinesForMember then
		return false
	end

	local entry, guid = FindHistoryEntryForUnit(unit)
	if not guid or guid == "" then
		guid = UnitGUID(unit) or ""
	end
	if guid == "" then
		return false
	end

	-- Already appended for this exact tooltip fill.
	if tooltip.rwRatingGuid == guid then
		return false
	end

	-- Different unit still showing previous Raidwise block — do not stack.
	-- Caller must rebuild via SetUnit (OnTooltipSetUnit) instead of AddLine.
	if tooltip.rwRatingGuid and tooltip.rwRatingGuid ~= guid then
		return false
	end

	local member = entry or { guid = guid }
	if not member.guid or member.guid == "" then
		member.guid = guid
	end

	local lines = Addon:BuildUnitTooltipRatingLinesForMember(member)
	if #lines == 0 then
		return false
	end

	tooltip:AddLine(" ")
	for index = 1, #lines do
		tooltip:AddLine(lines[index], 1, 1, 1, true)
	end
	tooltip.rwRatingGuid = guid
	tooltip.rwRatingLineCount = tooltip.NumLines and tooltip:NumLines() or 0
	tooltip:Show()
	return true
end

local rebuilding
local function RebuildTooltipUnit(tooltip, unit)
	if rebuilding or not tooltip or not unit then
		return false
	end
	rebuilding = true
	ClearAppendMarker(tooltip)
	tooltip:SetUnit(unit)
	rebuilding = false
	return true
end

local function TryAppendFromTooltip(tooltip, opts)
	opts = opts or {}
	tooltip = tooltip or GameTooltip
	if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then
		return false
	end
	local unit = ResolveTooltipUnit(tooltip)
	if not unit then
		return false
	end

	local guid = UnitGUID(unit) or ""
	if guid ~= "" and tooltip.rwRatingGuid and tooltip.rwRatingGuid ~= guid then
		if opts.allowRebuild then
			return RebuildTooltipUnit(tooltip, unit)
		end
		return false
	end

	return AppendRatingLines(tooltip, unit)
end

local function OnTooltipSetUnit(tooltip)
	-- Fresh SetUnit fill (raid frame hover change, Shift refresh, etc.).
	ClearAppendMarker(tooltip)
	TryAppendFromTooltip(tooltip, { allowRebuild = false })
end

local function OnTooltipCleared(tooltip)
	ClearAppendMarker(tooltip)
end

local function OnTooltipHide(tooltip)
	ClearAppendMarker(tooltip)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:SetScript("OnEvent", function()
	-- Shift compare often wipes addon lines without a clean remount; rebuild once.
	if not GameTooltip:IsShown() then
		return
	end
	local lineCount = GameTooltip.NumLines and GameTooltip:NumLines() or 0
	if GameTooltip.rwRatingLineCount and lineCount < GameTooltip.rwRatingLineCount then
		local unit = ResolveTooltipUnit(GameTooltip)
		if unit then
			RebuildTooltipUnit(GameTooltip, unit)
		end
	end
end)

local function InstallTooltipHooks()
	if GameTooltip.rwRatingHooksInstalled then
		return
	end
	GameTooltip.rwRatingHooksInstalled = true

	if GameTooltip.HookScript then
		pcall(function()
			GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
		end)
		pcall(function()
			GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
		end)
		pcall(function()
			GameTooltip:HookScript("OnHide", OnTooltipHide)
		end)
	end
end

InstallTooltipHooks()

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
	InstallTooltipHooks()
	self:UnregisterEvent("PLAYER_LOGIN")
end)
