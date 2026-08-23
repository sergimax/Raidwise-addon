-- Append personal / community rating lines to the default unit GameTooltip.
-- Primary path: OnTooltipSetUnit (must not require IsShown — it often runs before Show).
-- Fallback: UPDATE_MOUSEOVER_UNIT only when nothing was appended yet, or rebuild on GUID change.

local Addon = Raidwise

-- REFACTOR candidate: GUID lookup then linear scan of entire history store by name/realm.
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
		return true
	end

	-- Different unit still has our previous block — do not stack AddLine.
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

-- opts.requireShown: mouseover fallback only (SetUnit path must run before Show).
-- opts.allowRebuild: if GUID changed with stale lines, SetUnit instead of stacking.
local function TryAppendFromTooltip(tooltip, opts)
	opts = opts or {}
	tooltip = tooltip or GameTooltip
	if not tooltip then
		return false
	end
	if opts.requireShown and (not tooltip.IsShown or not tooltip:IsShown()) then
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
	-- Fresh SetUnit fill. Do not require IsShown — Blizzard often fires this first.
	ClearAppendMarker(tooltip)
	TryAppendFromTooltip(tooltip, { requireShown = false, allowRebuild = false })
end

local function OnTooltipCleared(tooltip)
	ClearAppendMarker(tooltip)
end

local function OnTooltipHide(tooltip)
	ClearAppendMarker(tooltip)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
-- REFACTOR candidate: polling fallback + GUID-change rebuild + Shift refresh (subtle tooltip timing).
eventFrame:SetScript("OnEvent", function(_, event)
	if event == "MODIFIER_STATE_CHANGED" then
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
		return
	end

	-- Fallback when OnTooltipSetUnit ran too early or was skipped: append once
	-- after Show, or rebuild if the hovered GUID changed (raid frames).
	eventFrame.elapsed = 0
	eventFrame.attempts = 0
	eventFrame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed < 0.05 then
			return
		end
		self.elapsed = 0
		self.attempts = (self.attempts or 0) + 1

		local tooltip = GameTooltip
		local done = false
		if tooltip:IsShown() then
			local unit = ResolveTooltipUnit(tooltip)
			local guid = unit and UnitGUID(unit) or ""
			if guid ~= "" and tooltip.rwRatingGuid and tooltip.rwRatingGuid ~= guid then
				done = RebuildTooltipUnit(tooltip, unit)
			elseif not tooltip.rwRatingGuid then
				done = TryAppendFromTooltip(tooltip, { requireShown = true, allowRebuild = false })
			else
				done = true
			end
		end

		if done or self.attempts >= 8 then
			self:SetScript("OnUpdate", nil)
			self.attempts = 0
		end
	end)
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
