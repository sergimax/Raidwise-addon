-- PageRaid — raid groups grid with integrated gear-check scan and report rows.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 12

local RAID_CELL_W = 168
local RAID_CELL_H = 152
local RAID_CELL_GAP = 2
local RAID_CELL_PAD = 4
local RAID_LINE_H = 14
local RAID_ICON = 20
local RAID_BTN_H = 16
local RAID_BTN_GAP = 2
local RAID_GROUP_LABEL_H = 16
local RAID_BLOCK_GAP = 12
local RAID_TOOLBAR_BTN_GAP = 4
local RAID_TOOLBAR_COL_W = 104
local RAID_TOOLBAR_COL_GAP = 8
local RAID_TOOLBAR_ROWS = 3
local RAID_BTN_ROW_STEP = UI.CD_TOOLBAR_H + RAID_TOOLBAR_BTN_GAP
local RAID_TOOLBAR_H = (RAID_TOOLBAR_ROWS * UI.CD_TOOLBAR_H) + ((RAID_TOOLBAR_ROWS - 1) * RAID_TOOLBAR_BTN_GAP)

local SCAN_PHASE_KEYS = {
	inspect = "GEAR_CHECK_RAID_PHASE_INSPECT",
	spec = "GEAR_CHECK_RAID_PHASE_SPEC",
	gems = "GEAR_CHECK_RAID_PHASE_GEMS",
	evaluate = "GEAR_CHECK_RAID_PHASE_EVALUATE",
	done = "GEAR_CHECK_RAID_PHASE_DONE",
	export = "GEAR_CHECK_RAID_PHASE_EXPORT",
}

local function FormatRaidStatsLine(gearScore, averageIlvl)
	local parts = {}
	if gearScore then
		parts[#parts + 1] = W.T("STATS_GS", tostring(gearScore))
	end
	if averageIlvl then
		parts[#parts + 1] = W.T("STATS_ILVL", tostring(averageIlvl))
	end
	if #parts == 0 then
		return ""
	end
	return table.concat(parts, " ")
end

local function FormatRaidAverageGs(gearScore)
	local gsText = gearScore ~= nil and tostring(gearScore) or "-"
	return W.T("AVG_GS", gsText)
end

local function FormatRoleGsSummary(label, bucket)
	bucket = bucket or {}
	local gsText = bucket.gearScore ~= nil and tostring(bucket.gearScore) or "-"
	return W.T("ROLE_SUMMARY", label, tostring(bucket.count or 0), gsText)
end

local function IsGearVerdictLabel(label)
	return label == "BAD" or label == "REPLACE" or label == "OK" or label == "GOOD"
end

local function GearStatusLabelForEntry(entry)
	local failLabel = Addon.GetGearCheckRaidEntryStatusLabel and Addon:GetGearCheckRaidEntryStatusLabel(entry)
	if failLabel then
		return failLabel
	end
	if not entry or not entry.report then
		return W.T("GEAR_CHECK_RAID_NOT_SCANNED")
	end
	local overall = entry.report.overall or {}
	return overall.status or "OK"
end

local function CountGearRaidSummary(results)
	local counts = { bad = 0, replace = 0, ok = 0, good = 0, failed = 0 }
	if not results then
		return counts
	end
	for index = 1, #results do
		local entry = results[index]
		local report = entry and entry.report
		if not report then
			counts.failed = counts.failed + 1
		else
			local status = (report.overall and report.overall.status) or "OK"
			if status == "BAD" then
				counts.bad = counts.bad + 1
			elseif status == "REPLACE" then
				counts.replace = counts.replace + 1
			elseif status == "GOOD" then
				counts.good = counts.good + 1
			else
				counts.ok = counts.ok + 1
			end
		end
	end
	return counts
end

local function FormatRaidCategoryGradeLine(localeKey, grade)
	if not grade or grade == "" then
		return ""
	end
	return W.T(localeKey, W.WrapGearGradation(grade))
end

local function FormatGearRaidSummaryLine(results)
	local counts = CountGearRaidSummary(results)
	local failedSuffix = " · Failed " .. tostring(counts.failed)
	return W.FormatGearVerdictCountsLine(nil, counts.bad, counts.replace, counts.ok, counts.good, failedSuffix)
end

local function IndexGearResults(results)
	local byGuid = {}
	local byName = {}
	if type(results) ~= "table" then
		return byGuid, byName
	end
	for index = 1, #results do
		local entry = results[index]
		local member = entry and entry.member or {}
		local character = entry and entry.report and entry.report.character or {}
		local guid = member.guid or character.guid
		if type(guid) == "string" and guid ~= "" then
			byGuid[guid] = entry
		end
		local name = member.name or character.name
		if type(name) == "string" and name ~= "" then
			byName[name] = entry
		end
	end
	return byGuid, byName
end

local function GearEntryForMember(member, byGuid, byName)
	if not member then
		return nil
	end
	if member.guid and byGuid[member.guid] then
		return byGuid[member.guid]
	end
	if member.name and byName[member.name] then
		return byName[member.name]
	end
	return nil
end

local function ResolveGearCheckResults(page)
	local results = page and page.gearCheckResults
	if (not results or #results == 0) and Addon.GetLastGearCheckRaidResults then
		results = Addon:GetLastGearCheckRaidResults() or {}
		if page then
			page.gearCheckResults = results
		end
	end
	return results or {}
end

local function UpdateGearCheckSummaryLabel(page, results)
	if not page or not page.gearCheckSummaryLabel then
		return
	end
	if results and #results > 0 then
		page.gearCheckSummaryLabel:SetText(FormatGearRaidSummaryLine(results))
		W.SetFontColor(page.gearCheckSummaryLabel, UI.TEXT_IDLE)
	else
		page.gearCheckSummaryLabel:SetText(W.T("GEAR_CHECK_RAID_SUMMARY_EMPTY"))
		W.SetFontColor(page.gearCheckSummaryLabel, UI.TEXT_DISABLED)
	end
end

local function FormatRaidRosterStatsLine(gearScore, roles)
	roles = roles or {}
	return FormatRaidAverageGs(gearScore)
		.. "     "
		.. FormatRoleGsSummary(W.T("ROLE_TANKS"), roles.tank or {})
		.. "     "
		.. FormatRoleGsSummary(W.T("ROLE_HEALERS"), roles.healer or {})
		.. "     "
		.. FormatRoleGsSummary(W.T("ROLE_MELEE_SHORT"), roles.melee or {})
		.. "     "
		.. FormatRoleGsSummary(W.T("ROLE_RANGE"), roles.ranged or {})
end

local function UpdateRaidRosterStatsLabels(page, members)
	if not page or not page.statsLabel then
		return
	end

	local overall, roles
	if Addon.AverageRosterStatsByRole then
		overall, roles = Addon:AverageRosterStatsByRole(members)
	end
	overall = overall or {}
	roles = roles or {}

	page.statsLabel:SetText(FormatRaidRosterStatsLine(overall.gearScore, roles))
end

local function RaidDescLeftRowY(rowIndex)
	return -rowIndex * RAID_BTN_ROW_STEP
end

local function RaidDescHeaderHeight()
	return RAID_TOOLBAR_H
		+ UI.CD_HINT_TO_TABLE
		+ UI.RAID_PROGRESS_STATUS_H
		+ UI.RAID_PROGRESS_STATUS_GAP
		+ UI.RAID_PROGRESS_H
end

local function CreateRaidDescriptionLeft(page, toolbarAnchor)
	local descLeftCol = CreateFrame("Frame", nil, page)
	descLeftCol:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	descLeftCol:SetPoint("RIGHT", toolbarAnchor, "LEFT", -RAID_TOOLBAR_COL_GAP, 0)
	descLeftCol:SetHeight(RaidDescHeaderHeight())
	page.descLeftCol = descLeftCol

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", descLeftCol, "TOPLEFT", 0, 0)
	hint:SetPoint("BOTTOMRIGHT", descLeftCol, "TOPRIGHT", 0, RaidDescLeftRowY(1))
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetWordWrap(true)
	hint:SetNonSpaceWrap(false)
	hint:SetText(W.ColorizeGearGradation(W.T("RAID_HINT")))
	page.hint = hint

	local stats = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	stats:SetPoint("TOPLEFT", descLeftCol, "TOPLEFT", 0, RaidDescLeftRowY(1))
	stats:SetPoint("RIGHT", descLeftCol, "RIGHT", 0, 0)
	stats:SetHeight(UI.ROSTER_STATS_H)
	stats:SetJustifyH("LEFT")
	stats:SetJustifyV("MIDDLE")
	W.SetFontColor(stats, UI.TEXT_IDLE)
	stats:SetText(FormatRaidRosterStatsLine(nil, {}))
	page.statsLabel = stats

	local gearSummary = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	gearSummary:SetPoint("TOPLEFT", descLeftCol, "TOPLEFT", 0, RaidDescLeftRowY(2))
	gearSummary:SetPoint("RIGHT", descLeftCol, "RIGHT", 0, 0)
	gearSummary:SetHeight(UI.ROSTER_STATS_H)
	gearSummary:SetJustifyH("LEFT")
	gearSummary:SetJustifyV("MIDDLE")
	gearSummary:SetText(W.T("GEAR_CHECK_RAID_SUMMARY_EMPTY"))
	W.SetFontColor(gearSummary, UI.TEXT_DISABLED)
	page.gearCheckSummaryLabel = gearSummary

	local gearCheckStatusLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	gearCheckStatusLabel:SetPoint("TOPLEFT", descLeftCol, "TOPLEFT", 0, -(RAID_TOOLBAR_H + UI.CD_HINT_TO_TABLE))
	gearCheckStatusLabel:SetPoint("RIGHT", descLeftCol, "RIGHT", 0, 0)
	gearCheckStatusLabel:SetHeight(UI.RAID_PROGRESS_STATUS_H)
	gearCheckStatusLabel:SetJustifyH("LEFT")
	gearCheckStatusLabel:SetJustifyV("TOP")
	gearCheckStatusLabel:SetWordWrap(true)
	gearCheckStatusLabel:SetNonSpaceWrap(false)
	gearCheckStatusLabel:SetText(W.ColorizeGearGradation(W.T("GEAR_CHECK_RAID_HINT")))
	W.SetFontColor(gearCheckStatusLabel, UI.TEXT_IDLE)
	page.gearCheckStatusLabel = gearCheckStatusLabel

	local progressHost = W.CreateProgressBar(descLeftCol, UI.RAID_PROGRESS_H)
	progressHost:SetPoint("TOPLEFT", gearCheckStatusLabel, "BOTTOMLEFT", 0, -UI.RAID_PROGRESS_STATUS_GAP)
	progressHost:SetPoint("RIGHT", descLeftCol, "RIGHT", 0, 0)
	progressHost:Show()
	page.gearCheckProgressHost = progressHost

	return descLeftCol
end

local function SetRaidProgress(page, value, maxValue, visible)
	local host = page and page.gearCheckProgressHost
	if not host then
		return
	end
	if visible then
		host:SetProgress(value, maxValue)
	else
		host:SetProgress(0, 1)
	end
end

local function RaidScanPhaseLabel(phase)
	local key = phase and SCAN_PHASE_KEYS[phase]
	if key then
		return W.T(key)
	end
	return W.T("GEAR_CHECK_RAID_PHASE_INSPECT")
end

local function SetRaidBusyButtons(page, busy)
	if page.gearCheckScanBtn then
		if busy then
			page.gearCheckScanBtn:Disable()
		else
			page.gearCheckScanBtn:Enable()
		end
	end
	if page.gearCheckExportBtn then
		if busy then
			page.gearCheckExportBtn:Disable()
		else
			page.gearCheckExportBtn:Enable()
		end
	end
	local blocks = { page.topBlock, page.bottomBlock }
	for blockIndex = 1, #blocks do
		local block = blocks[blockIndex]
		if block and block.columns then
			for _, column in pairs(block.columns) do
				for slot = 1, 5 do
					local cell = column.cells and column.cells[slot]
					if cell and cell.rescanBtn and cell.member then
						if busy then
							cell.rescanBtn:Disable()
						else
							cell.rescanBtn:Enable()
						end
					end
				end
			end
		end
	end
end

local function PageGearActionsBusy(page)
	return page
		and (page.gearCheckScanning or page.gearCheckExporting or page.gearCheckMemberScanning)
end

local function UpsertRaidGearResult(page, entry)
	if not page or not entry or not entry.member then
		return
	end
	local results = page.gearCheckResults
	if type(results) ~= "table" then
		results = {}
		page.gearCheckResults = results
	end

	local member = entry.member
	local character = entry.report and entry.report.character or {}
	local guid = member.guid or character.guid
	local name = member.name or character.name
	local replaced = false
	for index = 1, #results do
		local existing = results[index]
		local existingMember = existing and existing.member or {}
		local existingCharacter = existing and existing.report and existing.report.character or {}
		local existingGuid = existingMember.guid or existingCharacter.guid
		local existingName = existingMember.name or existingCharacter.name
		if guid and existingGuid and guid == existingGuid then
			results[index] = entry
			replaced = true
			break
		end
		if name and existingName and name == existingName then
			results[index] = entry
			replaced = true
			break
		end
	end
	if not replaced then
		results[#results + 1] = entry
	end
	if Addon.SetLastGearCheckRaidResults then
		Addon:SetLastGearCheckRaidResults(results)
	end
end

local function MembersFromRaidGroups(groups)
	local members = {}
	if type(groups) ~= "table" then
		return members
	end
	for groupIndex = 1, 8 do
		local slots = groups[groupIndex]
		if slots then
			for slot = 1, #slots do
				members[#members + 1] = slots[slot]
			end
		end
	end
	return members
end

local function RaidColumnOffset(columnIndex)
	return (columnIndex - 1) * (RAID_CELL_W + RAID_CELL_GAP)
end

local function RaidBlockHeight()
	return RAID_GROUP_LABEL_H + RAID_CELL_H * 5 + RAID_CELL_GAP * 4
end

local function RaidContentSize()
	local width = RAID_CELL_W * 5 + RAID_CELL_GAP * 4
	local height = RaidBlockHeight() * 2 + RAID_BLOCK_GAP
	return width, height
end

local function CreateRaidPlayerCell(parent)
	local cell = CreateFrame("Button", nil, parent)
	cell:SetSize(RAID_CELL_W, RAID_CELL_H)
	W.ApplyPlainPanel(cell, UI.CD_ROW_A)
	cell:EnableMouse(true)
	cell:RegisterForClicks("LeftButtonUp")

	cell.classIconHost = CreateFrame("Frame", nil, cell)
	cell.classIconHost:SetSize(RAID_ICON, RAID_ICON)
	cell.classIconHost:SetPoint("TOPLEFT", RAID_CELL_PAD, -RAID_CELL_PAD)
	cell.classIcon = cell.classIconHost:CreateTexture(nil, "ARTWORK")
	cell.classIcon:SetAllPoints(cell.classIconHost)

	cell.nameText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.nameText:SetPoint("LEFT", cell.classIconHost, "RIGHT", 4, 0)
	cell.nameText:SetPoint("RIGHT", cell, "RIGHT", -RAID_CELL_PAD, 0)
	cell.nameText:SetHeight(RAID_LINE_H)
	cell.nameText:SetJustifyH("LEFT")
	cell.nameText:SetJustifyV("MIDDLE")

	cell.roleIconHost = CreateFrame("Frame", nil, cell)
	cell.roleIconHost:SetSize(RAID_ICON, RAID_ICON)
	cell.roleIconHost:SetPoint("TOPLEFT", cell.classIconHost, "BOTTOMLEFT", 0, -3)
	cell.roleIcon = cell.roleIconHost:CreateTexture(nil, "ARTWORK")
	cell.roleIcon:SetAllPoints(cell.roleIconHost)
	cell.roleIconHost:EnableMouse(true)
	cell.roleIconHost:SetScript("OnEnter", function(self)
		if not cell.roleLabel or cell.roleLabel == "" then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(cell.roleLabel)
		GameTooltip:Show()
	end)
	cell.roleIconHost:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	cell.specIconHost = CreateFrame("Frame", nil, cell)
	cell.specIconHost:SetSize(RAID_ICON, RAID_ICON)
	cell.specIconHost:SetPoint("LEFT", cell.roleIconHost, "RIGHT", 3, 0)
	cell.specIcon = cell.specIconHost:CreateTexture(nil, "ARTWORK")
	cell.specIcon:SetAllPoints(cell.specIconHost)

	cell.statsText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.statsText:SetPoint("LEFT", cell.specIconHost, "RIGHT", 4, 0)
	cell.statsText:SetPoint("RIGHT", cell, "RIGHT", -RAID_CELL_PAD, 0)
	cell.statsText:SetHeight(RAID_LINE_H)
	cell.statsText:SetJustifyH("LEFT")
	cell.statsText:SetJustifyV("MIDDLE")

	cell.buffHosts = {}
	for buffIndex = 1, UI.RAID_BUFF_MAX do
		local host = W.CreateBuffIconHost(cell)
		if buffIndex == 1 then
			host:SetPoint("TOPLEFT", cell.roleIconHost, "BOTTOMLEFT", 0, -3)
		else
			host:SetPoint("LEFT", cell.buffHosts[buffIndex - 1], "RIGHT", UI.RAID_BUFF_GAP, 0)
		end
		cell.buffHosts[buffIndex] = host
	end

	cell.opinionText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.opinionText:SetPoint("TOPLEFT", cell.buffHosts[1], "BOTTOMLEFT", 0, -2)
	cell.opinionText:SetPoint("RIGHT", cell, "RIGHT", -RAID_CELL_PAD, 0)
	cell.opinionText:SetHeight(RAID_LINE_H)
	cell.opinionText:SetJustifyH("LEFT")

	cell.tagText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.tagText:SetPoint("TOPLEFT", cell.opinionText, "BOTTOMLEFT", 0, -1)
	cell.tagText:SetPoint("RIGHT", cell, "RIGHT", -RAID_CELL_PAD, 0)
	cell.tagText:SetHeight(RAID_LINE_H)
	cell.tagText:SetJustifyH("LEFT")

	cell.gearGradeText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.gearGradeText:SetPoint("TOPLEFT", cell.tagText, "BOTTOMLEFT", 0, -1)
	cell.gearGradeText:SetPoint("RIGHT", cell, "RIGHT", -RAID_CELL_PAD, 0)
	cell.gearGradeText:SetHeight(RAID_LINE_H)
	cell.gearGradeText:SetJustifyH("LEFT")

	cell.enchantSocketGradeText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.enchantSocketGradeText:SetPoint("TOPLEFT", cell.gearGradeText, "BOTTOMLEFT", 0, -1)
	cell.enchantSocketGradeText:SetPoint("RIGHT", cell, "RIGHT", -RAID_CELL_PAD, 0)
	cell.enchantSocketGradeText:SetHeight(RAID_LINE_H)
	cell.enchantSocketGradeText:SetJustifyH("LEFT")

	local btnCount = 3
	local btnWidth = math.floor((RAID_CELL_W - RAID_CELL_PAD * 2 - RAID_BTN_GAP * (btnCount - 1)) / btnCount)
	local profileBtn = W.CreatePlainButton(cell, btnWidth, RAID_BTN_H, W.T("BTN_RAID_PROFILE"))
	profileBtn:SetPoint("BOTTOMLEFT", RAID_CELL_PAD, RAID_CELL_PAD)
	W.SetPlainButtonTooltip(profileBtn, "BTN_RAID_PROFILE_TIP")
	profileBtn:SetScript("OnClick", function()
		if cell.member then
			Addon:ShowRaidCharacterWindow(cell.member)
		end
	end)
	profileBtn:Hide()
	cell.profileBtn = profileBtn

	local gearBtn = W.CreatePlainButton(cell, btnWidth, RAID_BTN_H, W.T("BTN_RAID_GEAR"))
	gearBtn:SetPoint("LEFT", profileBtn, "RIGHT", RAID_BTN_GAP, 0)
	W.SetPlainButtonTooltip(gearBtn, "BTN_RAID_GEAR_TIP")
	gearBtn:SetScript("OnClick", function()
		local gearEntry = cell.gearEntry
		if gearEntry and gearEntry.report and Addon.ShowGearCheckReport then
			Addon:ShowGearCheckReport(gearEntry.report, gearEntry.status or "ok")
		end
	end)
	gearBtn:Hide()
	cell.gearBtn = gearBtn

	local rescanBtn = W.CreatePlainButton(cell, btnWidth, RAID_BTN_H, W.T("BTN_RAID_RESCAN"))
	rescanBtn:SetPoint("LEFT", gearBtn, "RIGHT", RAID_BTN_GAP, 0)
	W.SetPlainButtonTooltip(rescanBtn, "BTN_RAID_RESCAN_TIP")
	rescanBtn:SetScript("OnClick", function()
		local frame = Addon.mainFrame
		local page = frame and frame.pages and frame.pages.raid
		if page and cell.member then
			Addon:RunGearCheckMemberRescan(page, cell.member)
		end
	end)
	rescanBtn:Hide()
	cell.rescanBtn = rescanBtn

	cell:SetScript("OnEnter", function(self)
		if not self.member then
			return
		end
		self:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		W.ShowMemberRatingTooltip(self, self.member, { gearCheck = true, gearEntry = self.gearEntry })
	end)
	cell:SetScript("OnLeave", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		GameTooltip:Hide()
	end)
	cell:SetScript("OnClick", function(self)
		if self.member then
			Addon:ShowRaidCharacterWindow(self.member)
		end
	end)

	return cell
end

local function CollectGroupMembers(slots)
	local members = {}
	if not slots then
		return members
	end
	for slot = 1, 5 do
		local member = slots[slot]
		if member then
			members[#members + 1] = member
		end
	end
	return members
end

local function UpdateRaidGroupHeader(column, slots)
	if not column then
		return
	end
	local coverage
	if Addon.PartyBuffCoverageForGroup then
		coverage = Addon:PartyBuffCoverageForGroup(CollectGroupMembers(slots))
	end
	W.FillPartyBuffStatusIcons(column.partyBuffHosts, coverage)
end

local function CreateRaidGroupColumn(parent, groupIndex)
	local column = CreateFrame("Frame", nil, parent)
	column:SetSize(RAID_CELL_W, RaidBlockHeight())

	local header = CreateFrame("Frame", nil, column)
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)
	header:SetHeight(RAID_GROUP_LABEL_H)
	column.header = header

	local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", 0, 0)
	label:SetWidth(10)
	label:SetHeight(RAID_GROUP_LABEL_H)
	label:SetJustifyH("LEFT")
	label:SetText(tostring(groupIndex))
	W.SetFontColor(label, UI.GOLD)
	column.label = label

	column.partyBuffHosts = {}
	for buffIndex = 1, UI.PARTY_BUFF_MAX do
		local host = W.CreatePartyBuffStatusHost(header)
		if buffIndex == 1 then
			host:SetPoint("LEFT", label, "RIGHT", 2, 0)
		else
			host:SetPoint("LEFT", column.partyBuffHosts[buffIndex - 1], "RIGHT", UI.PARTY_BUFF_GAP, 0)
		end
		column.partyBuffHosts[buffIndex] = host
	end

	column.cells = {}
	for slot = 1, 5 do
		local cell = CreateRaidPlayerCell(column)
		cell:SetPoint("TOPLEFT", 0, -(RAID_GROUP_LABEL_H + (slot - 1) * (RAID_CELL_H + RAID_CELL_GAP)))
		column.cells[slot] = cell
	end

	return column
end

local function CreateRaidBlock(parent, startGroup, endGroup)
	local columnCount = endGroup - startGroup + 1
	local block = CreateFrame("Frame", nil, parent)
	block:SetSize(
		RAID_CELL_W * columnCount + RAID_CELL_GAP * (columnCount - 1),
		RaidBlockHeight()
	)

	block.columns = {}
	for groupIndex = startGroup, endGroup do
		local column = CreateRaidGroupColumn(block, groupIndex)
		column:SetPoint("TOPLEFT", RaidColumnOffset(groupIndex - startGroup + 1), 0)
		block.columns[groupIndex] = column
	end

	return block
end

local function FillGearReportRows(cell, member, entry)
	if not member then
		cell.gearEntry = nil
		cell.gearGradeText:SetText("")
		cell.enchantSocketGradeText:SetText("")
		if cell.gearBtn then
			cell.gearBtn:Disable()
		end
		return
	end

	cell.gearEntry = entry
	local report = entry and entry.report
	local character = report and report.character or {}

	if not report then
		local statusLabel = GearStatusLabelForEntry(entry)
		cell.gearGradeText:SetText(statusLabel)
		cell.enchantSocketGradeText:SetText("")
		if IsGearVerdictLabel(statusLabel) then
			cell.gearGradeText:SetText(W.WrapGearGradation(statusLabel))
			W.SetFontColor(cell.gearGradeText, UI.TEXT_IDLE)
		else
			W.SetFontColor(cell.gearGradeText, UI.TEXT_DISABLED)
		end
		if cell.gearBtn then
			cell.gearBtn:Disable()
		end
		return
	end

	local overall = report.overall or {}
	local gearGrade = overall.gearGrade or overall.status or "OK"
	local enchantSocketGrade = overall.enchantSocketGrade or "OK"
	cell.gearGradeText:SetText(FormatRaidCategoryGradeLine("GEAR_CHECK_RAID_CELL_GEAR", gearGrade))
	cell.enchantSocketGradeText:SetText(FormatRaidCategoryGradeLine("GEAR_CHECK_RAID_CELL_ENCHANT", enchantSocketGrade))
	W.SetFontColor(cell.gearGradeText, UI.TEXT_IDLE)
	W.SetFontColor(cell.enchantSocketGradeText, UI.TEXT_IDLE)

	if cell.gearBtn then
		cell.gearBtn:Enable()
	end

	if report and character.specIcon and character.specIcon ~= "" and member.specIcon ~= character.specIcon then
		W.SetSpecOrClassIcon(cell.specIcon, character.specIcon, member.class)
		cell.specIcon:Show()
	end
end

local function FillRaidPlayerCell(cell, member, gearEntry, stripe)
	cell.stripe = stripe
	cell:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])

	if not member then
		cell.member = nil
		cell.roleLabel = nil
		cell.nameText:SetText("")
		cell.statsText:SetText("")
		cell.opinionText:SetText("")
		cell.tagText:SetText("")
		cell.classIconHost:Hide()
		cell.roleIconHost:Hide()
		cell.specIconHost:Hide()
		W.FillRaidBuffIcons(cell.buffHosts, nil)
		FillGearReportRows(cell, nil, nil)
		if cell.profileBtn then
			cell.profileBtn:Hide()
		end
		if cell.gearBtn then
			cell.gearBtn:Hide()
		end
		if cell.rescanBtn then
			cell.rescanBtn:Hide()
		end
		cell:EnableMouse(false)
		cell:Show()
		return
	end

	cell.member = member
	cell:EnableMouse(true)
	cell.nameText:SetText(member.name or "")
	cell.nameText:SetTextColor(W.ClassColor(member.class))
	W.SetSpecOrClassIcon(cell.classIcon, nil, member.class)
	cell.classIconHost:Show()

	local role = member.role or "unknown"
	cell.roleLabel = (Addon.RaidRoleLabel and Addon:RaidRoleLabel(role)) or ""
	if Addon.RaidRoleIcon then
		W.SetSpellIconTexture(cell.roleIcon, Addon:RaidRoleIcon(role))
	else
		W.SetSpellIconTexture(cell.roleIcon, "Interface\\Icons\\INV_Misc_QuestionMark")
	end
	cell.roleIconHost:Show()

	if member.specIcon and member.specIcon ~= "" then
		W.SetSpecOrClassIcon(cell.specIcon, member.specIcon, member.class)
		cell.specIcon:Show()
	else
		cell.specIcon:SetTexture(nil)
		cell.specIcon:Hide()
	end
	cell.specIconHost:Show()

	local stats = FormatRaidStatsLine(member.gearScore, member.averageIlvl)
	cell.statsText:SetText(stats)
	if member.gearScore then
		W.SetFontColor(cell.statsText, UI.GOLD)
	else
		W.SetFontColor(cell.statsText, UI.TEXT_IDLE)
	end

	W.FillRaidBuffIcons(cell.buffHosts, member.raidBuffs)

	cell.opinionText:SetText(W.FormatOpinionLine(member))
	W.SetFontColor(cell.opinionText, W.RatingOpinionColor(member))

	local tags = W.FormatTagLine(member)
	cell.tagText:SetText(tags)
	if tags ~= "" then
		W.SetFontColor(cell.tagText, UI.TEXT_IDLE)
	else
		W.SetFontColor(cell.tagText, UI.TEXT_DISABLED)
	end

	FillGearReportRows(cell, member, gearEntry)
	if cell.profileBtn then
		cell.profileBtn:Show()
		cell.profileBtn:Enable()
	end
	if cell.gearBtn then
		cell.gearBtn:Show()
	end
	if cell.rescanBtn then
		cell.rescanBtn:Show()
		local frame = Addon.mainFrame
		local page = frame and frame.pages and frame.pages.raid
		if PageGearActionsBusy(page) then
			cell.rescanBtn:Disable()
		else
			cell.rescanBtn:Enable()
		end
	end
	cell:Show()
end

local function RunGearCheckRaidScan(page)
	if not Addon.StartGearCheckRaidScan then
		if page.gearCheckStatusLabel then
			page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_STATUS_FAIL"))
		end
		return
	end
	if page.gearCheckExporting or page.gearCheckMemberScanning then
		return
	end
	if Addon.IsGearCheckScanBusy and Addon:IsGearCheckScanBusy() then
		if page.gearCheckStatusLabel then
			page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_BUSY"))
		end
		return
	end
	SetRaidBusyButtons(page, true)
	if page.gearCheckStatusLabel then
		page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_STATUS_SCANNING"))
	end
	SetRaidProgress(page, 0, 1, true)
	page.gearCheckScanning = true
	page.gearCheckResults = {}

	local started = Addon:StartGearCheckRaidScan(
		function(entry, done, total)
			local name = (entry and entry.member and entry.member.name) or "?"
			local phase = entry and entry.phase
			if entry and entry.live then
				if page.gearCheckStatusLabel then
					page.gearCheckStatusLabel:SetText(
						W.T(
							"GEAR_CHECK_RAID_STATUS_SCANNING_PHASE",
							done,
							total,
							name,
							RaidScanPhaseLabel(phase)
						)
					)
				end
				-- Live update: current player in progress counts as a half step.
				SetRaidProgress(page, done + 0.5, total, true)
				return
			end
			if page.gearCheckStatusLabel then
				page.gearCheckStatusLabel:SetText(
					W.T("GEAR_CHECK_RAID_STATUS_SCANNING", done, total, name)
				)
			end
			SetRaidProgress(page, done, total, true)
			page.gearCheckResults[#page.gearCheckResults + 1] = entry
			Addon:RefreshRaidRosterView(false)
		end,
		function(results, status)
			page.gearCheckScanning = false
			page.gearCheckResults = results
			SetRaidBusyButtons(page, false)
			SetRaidProgress(page, 0, 1, false)
			if page.gearCheckStatusLabel then
				if status == "empty" then
					page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_EMPTY"))
				else
					page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_DONE", #results))
				end
			end
			Addon:RefreshRaidRosterView(false)
		end
	)
	if not started then
		page.gearCheckScanning = false
		SetRaidBusyButtons(page, false)
		SetRaidProgress(page, 0, 1, false)
		if page.gearCheckStatusLabel then
			page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_BUSY"))
		end
	end
end

function Addon:RunGearCheckMemberRescan(page, member)
	if not page or not member or not member.unit then
		return false
	end
	if page.gearCheckScanning or page.gearCheckExporting or page.gearCheckMemberScanning then
		return false
	end
	if Addon.IsGearCheckScanBusy and Addon:IsGearCheckScanBusy() then
		if page.gearCheckStatusLabel then
			page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_BUSY"))
		end
		return false
	end
	if not Addon.StartGearCheckUnitScan then
		if page.gearCheckStatusLabel then
			page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_STATUS_FAIL"))
		end
		return false
	end

	page.gearCheckMemberScanning = true
	SetRaidBusyButtons(page, true)
	SetRaidProgress(page, 0.5, 1, true)
	if page.gearCheckStatusLabel then
		page.gearCheckStatusLabel:SetText(
			W.T("GEAR_CHECK_RAID_STATUS_RESCANNING", member.name or "?")
		)
	end

	local started = Addon:StartGearCheckUnitScan(member.unit, function(report, status)
		page.gearCheckMemberScanning = false
		SetRaidBusyButtons(page, false)
		SetRaidProgress(page, 0, 1, false)
		UpsertRaidGearResult(page, {
			member = member,
			report = report,
			status = status or (report and "ok") or "failed",
			phase = "done",
		})
		if page.gearCheckStatusLabel then
			if report then
				page.gearCheckStatusLabel:SetText(
					W.T("GEAR_CHECK_RAID_STATUS_RESCAN_DONE", member.name or "?")
				)
			else
				page.gearCheckStatusLabel:SetText(
					W.T("GEAR_CHECK_RAID_STATUS_RESCAN_FAIL", member.name or "?")
				)
			end
		end
		Addon:RefreshRaidRosterView(false)
	end)

	if not started then
		page.gearCheckMemberScanning = false
		SetRaidBusyButtons(page, false)
		SetRaidProgress(page, 0, 1, false)
		if page.gearCheckStatusLabel then
			page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_BUSY"))
		end
		return false
	end
	return true
end

local function RunGearCheckRaidExport(page)
	if page.gearCheckScanning or page.gearCheckExporting or page.gearCheckMemberScanning then
		return
	end
	if Addon.IsGearCheckRaidDumpBusy and Addon:IsGearCheckRaidDumpBusy() then
		return
	end
	local results = ResolveGearCheckResults(page)
	if type(results) ~= "table" or #results == 0 then
		Addon:Print(W.T("GEAR_CHECK_RAID_EXPORT_EMPTY"))
		return
	end
	if not Addon.BuildGearCheckRaidDumpAsync then
		if Addon.ShowGearCheckRaidDump then
			Addon:ShowGearCheckRaidDump(results)
		end
		return
	end

	page.gearCheckExporting = true
	SetRaidBusyButtons(page, true)
	SetRaidProgress(page, 0, #results, true)
	if page.gearCheckStatusLabel then
		page.gearCheckStatusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_EXPORTING", 0, #results))
	end

	local started = Addon:BuildGearCheckRaidDumpAsync(
		results,
		function(done, total, member)
			if page.gearCheckStatusLabel then
				page.gearCheckStatusLabel:SetText(
					W.T(
						"GEAR_CHECK_RAID_STATUS_EXPORTING_PHASE",
						done,
						total,
						(member and member.name) or "?",
						RaidScanPhaseLabel("export")
					)
				)
			end
			SetRaidProgress(page, done, total, true)
		end,
		function(text)
			page.gearCheckExporting = false
			SetRaidBusyButtons(page, false)
			SetRaidProgress(page, 0, 1, false)
			if page.gearCheckStatusLabel then
				page.gearCheckStatusLabel:SetText(W.ColorizeGearGradation(W.T("GEAR_CHECK_RAID_HINT")))
			end
			if not text or text == "" then
				if text == "" then
					Addon:Print(W.T("GEAR_CHECK_RAID_EXPORT_EMPTY"))
				end
				return
			end
			-- Defer SetText to the next frame so the progress bar can clear first.
			local pendingText = text
			local defer = CreateFrame("Frame")
			defer:SetScript("OnUpdate", function(self)
				self:SetScript("OnUpdate", nil)
				if Addon.ShowGearCheckDumpText then
					Addon:ShowGearCheckDumpText(pendingText)
				else
					Addon:Print(W.T("GEAR_CHECK_STATUS_FAIL"))
				end
			end)
		end
	)
	if not started then
		page.gearCheckExporting = false
		SetRaidBusyButtons(page, false)
		SetRaidProgress(page, 0, 1, false)
		if Addon.ShowGearCheckRaidDump then
			Addon:ShowGearCheckRaidDump(results)
		end
	end
end

function Addon:RefreshGearCheckRaidView(_autoScan)
	self:RefreshRaidRosterView(false)
end

function Addon:RefreshRaidRosterView(refreshGearScore)
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.raid
	if not page then
		return
	end

	if not self.BuildRaidGroups then
		if page.hint then
			page.hint:SetText(W.T("RAID_FAIL"))
		end
		return
	end

	page.tableHost:Show()

	local groups = self:BuildRaidGroups(refreshGearScore)
	UpdateRaidRosterStatsLabels(page, MembersFromRaidGroups(groups))

	local results = ResolveGearCheckResults(page)
	UpdateGearCheckSummaryLabel(page, results)
	local byGuid, byName = IndexGearResults(results)

	local blocks = { page.topBlock, page.bottomBlock }
	for blockIndex = 1, #blocks do
		local block = blocks[blockIndex]
		for groupIndex, column in pairs(block.columns) do
			local slots = groups[groupIndex] or {}
			UpdateRaidGroupHeader(column, slots)
			for slot = 1, 5 do
				local stripe = (slot % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
				local member = slots[slot]
				FillRaidPlayerCell(column.cells[slot], member, GearEntryForMember(member, byGuid, byName), stripe)
			end
		end
	end

	local contentW, contentH = RaidContentSize()
	page.tableContent:SetSize(contentW, contentH)
	W.LayoutTableScrollBars(page)
end

local function CreateRaidRosterPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local scanBtn = W.CreatePlainButton(page, RAID_TOOLBAR_COL_W, UI.CD_TOOLBAR_H, W.T("GEAR_CHECK_SCAN"))
	scanBtn:SetPoint("TOPRIGHT", 0, 0)
	W.SetPlainButtonTooltip(scanBtn, "RAID_SCAN_TIP")
	scanBtn:SetScript("OnClick", function()
		RunGearCheckRaidScan(page)
	end)

	local exportBtn = W.CreatePlainButton(page, RAID_TOOLBAR_COL_W, UI.CD_TOOLBAR_H, W.T("GEAR_CHECK_RAID_EXPORT"))
	exportBtn:SetPoint("TOPRIGHT", scanBtn, "BOTTOMRIGHT", 0, -RAID_TOOLBAR_BTN_GAP)
	W.SetPlainButtonTooltip(exportBtn, "GEAR_CHECK_RAID_EXPORT_TIP")
	exportBtn:SetScript("OnClick", function()
		RunGearCheckRaidExport(page)
	end)

	local refreshBtn = W.CreatePlainButton(page, 96, UI.CD_TOOLBAR_H, W.T("BTN_REFRESH"))
	refreshBtn:SetPoint("TOPRIGHT", exportBtn, "BOTTOMRIGHT", 0, -RAID_TOOLBAR_BTN_GAP)
	W.SetPlainButtonTooltip(refreshBtn, "RAID_REFRESH_TIP")
	refreshBtn:SetScript("OnClick", function()
		Addon:RefreshPartyData(true)
	end)

	page.gearCheckScanBtn = scanBtn
	page.gearCheckExportBtn = exportBtn
	page.refreshBtn = refreshBtn

	CreateRaidDescriptionLeft(page, scanBtn)

	local tableTop = -W.RaidRosterTableTopOffset()
	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseRaidRosterScrollV" .. tostring(LAYOUT_VERSION), tableHost)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), UI.CD_HSCROLL_H + 2)
	scroll:EnableMouseWheel(true)
	page.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	local contentW, contentH = RaidContentSize()
	content:SetSize(contentW, contentH)
	scroll:SetScrollChild(content)
	page.tableContent = content

	local topBlock = CreateRaidBlock(content, 1, 5)
	topBlock:SetPoint("TOPLEFT", 0, 0)
	page.topBlock = topBlock

	local bottomBlock = CreateRaidBlock(content, 6, 8)
	bottomBlock:SetPoint("TOPLEFT", topBlock, "BOTTOMLEFT", 0, -RAID_BLOCK_GAP)
	page.bottomBlock = bottomBlock

	local vBar = W.CreateCooldownScrollBar(tableHost, "VERTICAL")
	vBar:SetPoint("TOPRIGHT", -1, -1)
	vBar:SetPoint("BOTTOMRIGHT", -1, UI.CD_HSCROLL_H + 2)
	vBar:SetScript("OnValueChanged", function(self)
		scroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.vBar = vBar

	local hBar = W.CreateCooldownScrollBar(tableHost, "HORIZONTAL")
	hBar:SetPoint("BOTTOMLEFT", 1, 1)
	hBar:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), 1)
	hBar:SetScript("OnValueChanged", function(self)
		scroll:SetHorizontalScroll(self:GetValue() or 0)
	end)
	page.hBar = hBar

	scroll:SetScript("OnMouseWheel", function(self, delta)
		local maxV = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
		local step = RAID_CELL_H
		local nextValue = math.max(0, math.min(maxV, (self:GetVerticalScroll() or 0) - delta * step))
		self:SetVerticalScroll(nextValue)
		vBar:SetValue(nextValue)
	end)
	scroll:SetScript("OnSizeChanged", function()
		W.LayoutTableScrollBars(page)
	end)

	page:SetScript("OnShow", function()
		Addon:RefreshRaidRosterView(true)
	end)

	page.gearCheckResults = {}
	page.gearCheckScanning = false
	page.gearCheckExporting = false
	page.gearCheckMemberScanning = false
	page.layoutVersion = LAYOUT_VERSION
	return page
end

local function ApplyLocale(page)
	if not page then
		return
	end
	if page.hint then
		page.hint:SetText(W.ColorizeGearGradation(W.T("RAID_HINT")))
	end
	if page.refreshBtn and page.refreshBtn.label then
		page.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
	end
	if page.gearCheckScanBtn and page.gearCheckScanBtn.label then
		page.gearCheckScanBtn.label:SetText(W.T("GEAR_CHECK_SCAN"))
	end
	if page.gearCheckExportBtn and page.gearCheckExportBtn.label then
		page.gearCheckExportBtn.label:SetText(W.T("GEAR_CHECK_RAID_EXPORT"))
	end
	if page.gearCheckStatusLabel and not page.gearCheckScanning and not page.gearCheckExporting and not page.gearCheckMemberScanning then
		page.gearCheckStatusLabel:SetText(W.ColorizeGearGradation(W.T("GEAR_CHECK_RAID_HINT")))
	end
	UpdateGearCheckSummaryLabel(page, ResolveGearCheckResults(page))

	local blocks = { page.topBlock, page.bottomBlock }
	for blockIndex = 1, #blocks do
		local block = blocks[blockIndex]
		if block and block.columns then
			for _, column in pairs(block.columns) do
				for slot = 1, 5 do
					local cell = column.cells and column.cells[slot]
					if cell and cell.profileBtn and cell.profileBtn.label then
						cell.profileBtn.label:SetText(W.T("BTN_RAID_PROFILE"))
					end
					if cell and cell.gearBtn and cell.gearBtn.label then
						cell.gearBtn.label:SetText(W.T("BTN_RAID_GEAR"))
					end
					if cell and cell.rescanBtn and cell.rescanBtn.label then
						cell.rescanBtn.label:SetText(W.T("BTN_RAID_RESCAN"))
					end
				end
			end
		end
	end
end

Addon.Pages.Raid = {
	id = "raid",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateRaidRosterPage,
	ApplyLocale = ApplyLocale,
}
