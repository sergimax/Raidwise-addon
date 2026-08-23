-- Append personal / community rating lines to the default unit GameTooltip.
-- Uses OnTooltipSetUnit (GearScore-style) plus UPDATE_MOUSEOVER_UNIT /
-- PLAYER_TARGET_CHANGED (Reputation-style) for Wrath 3.3.5a reliability.

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

	-- Avoid stacking the same block when multiple hooks fire for one tooltip.
	if tooltip.rwRatingGuid == guid then
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

	tooltip.rwRatingGuid = guid
	tooltip:AddLine(" ")
	for index = 1, #lines do
		tooltip:AddLine(lines[index], 1, 1, 1, true)
	end
	tooltip:Show()
	return true
end

local function TryAppendFromTooltip(tooltip)
	tooltip = tooltip or GameTooltip
	if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then
		return false
	end
	local _, unit = tooltip:GetUnit()
	if not unit then
		if UnitExists("mouseover") then
			unit = "mouseover"
		elseif UnitExists("target") then
			unit = "target"
		end
	end
	if not unit then
		return false
	end
	return AppendRatingLines(tooltip, unit)
end

local function OnTooltipSetUnit(tooltip)
	TryAppendFromTooltip(tooltip)
end

local function OnTooltipHide(tooltip)
	tooltip.rwRatingGuid = nil
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function()
	-- Retry briefly so Blizzard / other addons finish filling the tooltip.
	eventFrame.elapsed = 0
	eventFrame.attempts = 0
	eventFrame.rwTicker = true
	eventFrame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed < 0.05 then
			return
		end
		self.elapsed = 0
		self.attempts = (self.attempts or 0) + 1
		if TryAppendFromTooltip(GameTooltip) or self.attempts >= 8 then
			self:SetScript("OnUpdate", nil)
			self.rwTicker = nil
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
