-- Share collection only within one refresh pass; never cache unit tokens across events.
local Addon = Raidwise
local pending = false
local refreshScores = false
local frame = CreateFrame("Frame")
frame:Hide()

function Addon:BuildRosterSnapshot(refreshGearScore)
	local groups = self:BuildRaidGroups(refreshGearScore)
	local snapshot = { groups = groups, members = {}, byUnit = {} }
	for groupIndex = 1, 8 do
		for _, member in ipairs(groups[groupIndex] or {}) do
			if member.unit then snapshot.byUnit[member.unit] = member end
			if member.class and member.class ~= "" then
				snapshot.members[#snapshot.members + 1] = member
			end
		end
	end
	return snapshot
end

function Addon:ScheduleRosterRefresh(refreshGearScore)
	pending = true
	refreshScores = refreshScores or refreshGearScore == true
	frame:Show()
end

frame:SetScript("OnUpdate", function()
	if not pending then frame:Hide(); return end
	local refresh = refreshScores
	pending, refreshScores = false, false
	frame:Hide()
	local snapshot = Addon:BuildRosterSnapshot(refresh)
	-- History and the visible view consume this same pass; nothing is retained globally.
	if Addon.RecordCurrentGroupHistory then Addon:RecordCurrentGroupHistory(refresh, snapshot) end
	local shell = Addon.mainFrame
	if not shell or not shell:IsShown() then return end
	if shell.selectedTab == "raid" and Addon.RefreshRaidRosterView then
		Addon:RefreshRaidRosterView(refresh, snapshot)
	elseif shell.selectedTab == "composition" and Addon.RefreshCompositionView then
		Addon:RefreshCompositionView(refresh, snapshot)
	end
end)
