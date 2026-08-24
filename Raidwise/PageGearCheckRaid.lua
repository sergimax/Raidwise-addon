-- PageGearCheckRaid — scan party/raid; grid by groups 1–5 / 6–8 (Raid roster layout).
-- Cell click opens Gear check (target) with the frozen report.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 3

local CELL_W = 168
local CELL_H = 68
local CELL_GAP = 2
local CELL_PAD = 4
local LINE_H = 14
local ICON = 18
local GROUP_LABEL_H = 16
local BLOCK_GAP = 12

local function OverallColor(status)
	if status == "BAD" then
		return UI.TEXT_ALERT
	end
	if status == "REPLACE" then
		return UI.GOLD
	end
	if status == "GOOD" then
		return UI.TEXT_GOOD
	end
	return UI.TEXT_IDLE
end

local function StatusLabelForEntry(entry)
	if not entry or not entry.report then
		if entry and entry.status == "too_far" then
			return W.T("GEAR_CHECK_RAID_STATUS_TOO_FAR")
		end
		if entry and entry.status == "cannot_inspect" then
			return W.T("GEAR_CHECK_RAID_STATUS_NO_INSPECT")
		end
		if entry and entry.status == "timeout" then
			return W.T("GEAR_CHECK_RAID_STATUS_TIMEOUT")
		end
		if entry and entry.status == "empty" then
			return W.T("GEAR_CHECK_RAID_CELL_EMPTY")
		end
		if entry then
			return W.T("GEAR_CHECK_RAID_ROW_FAIL")
		end
		return W.T("GEAR_CHECK_RAID_NOT_SCANNED")
	end
	local overall = entry.report.overall or {}
	return overall.status or "OK"
end

local function CountRaidSummary(results)
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

local function FormatSummaryLine(results)
	local counts = CountRaidSummary(results)
	return W.T(
		"GEAR_CHECK_RAID_SUMMARY",
		counts.bad,
		counts.replace,
		counts.ok,
		counts.good,
		counts.failed
	)
end

local function FormatCellCounts(report)
	if not report then
		return ""
	end
	local verdicts = report.verdicts or {}
	local issues = (report.overall and report.overall.issues) or {}
	local issueTotal = (issues.enchants or 0) + (issues.gems or 0) + (issues.meta or 0)
	return W.T(
		"GEAR_CHECK_RAID_CELL_COUNTS",
		verdicts.bad or 0,
		verdicts.replace or 0,
		issueTotal
	)
end

local function IndexResults(results)
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

local function EntryForMember(member, byGuid, byName)
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

local function ColumnOffset(columnIndex)
	return (columnIndex - 1) * (CELL_W + CELL_GAP)
end

local function BlockHeight()
	return GROUP_LABEL_H + CELL_H * 5 + CELL_GAP * 4
end

local function ContentSize()
	local width = CELL_W * 5 + CELL_GAP * 4
	local height = BlockHeight() * 2 + BLOCK_GAP
	return width, height
end

local function CreatePlayerCell(parent)
	local cell = CreateFrame("Button", nil, parent)
	cell:SetSize(CELL_W, CELL_H)
	W.ApplyPlainPanel(cell, UI.CD_ROW_A)
	cell:EnableMouse(true)
	cell:RegisterForClicks("LeftButtonUp")

	cell.classIconHost = CreateFrame("Frame", nil, cell)
	cell.classIconHost:SetSize(ICON, ICON)
	cell.classIconHost:SetPoint("TOPLEFT", CELL_PAD, -CELL_PAD)
	cell.classIcon = cell.classIconHost:CreateTexture(nil, "ARTWORK")
	cell.classIcon:SetAllPoints(cell.classIconHost)

	cell.nameText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.nameText:SetPoint("LEFT", cell.classIconHost, "RIGHT", 4, 0)
	cell.nameText:SetPoint("RIGHT", cell, "RIGHT", -CELL_PAD, 0)
	cell.nameText:SetHeight(LINE_H)
	cell.nameText:SetJustifyH("LEFT")
	cell.nameText:SetJustifyV("MIDDLE")

	cell.specIconHost = CreateFrame("Frame", nil, cell)
	cell.specIconHost:SetSize(ICON, ICON)
	cell.specIconHost:SetPoint("TOPLEFT", cell.classIconHost, "BOTTOMLEFT", 0, -3)
	cell.specIcon = cell.specIconHost:CreateTexture(nil, "ARTWORK")
	cell.specIcon:SetAllPoints(cell.specIconHost)

	cell.overallText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.overallText:SetPoint("LEFT", cell.specIconHost, "RIGHT", 4, 0)
	cell.overallText:SetPoint("RIGHT", cell, "RIGHT", -CELL_PAD, 0)
	cell.overallText:SetHeight(LINE_H)
	cell.overallText:SetJustifyH("LEFT")
	cell.overallText:SetJustifyV("MIDDLE")

	cell.countsText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.countsText:SetPoint("TOPLEFT", cell.specIconHost, "BOTTOMLEFT", 0, -3)
	cell.countsText:SetPoint("RIGHT", cell, "RIGHT", -CELL_PAD, 0)
	cell.countsText:SetHeight(LINE_H)
	cell.countsText:SetJustifyH("LEFT")
	cell.countsText:SetJustifyV("MIDDLE")

	cell:SetScript("OnEnter", function(self)
		if not self.member then
			return
		end
		self:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		if self.entry and self.entry.report then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(W.T("GEAR_CHECK_RAID_CLICK_HINT"))
			GameTooltip:Show()
		end
	end)
	cell:SetScript("OnLeave", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		GameTooltip:Hide()
	end)
	cell:SetScript("OnClick", function(self)
		local entry = self.entry
		if entry and entry.report and Addon.ShowGearCheckReport then
			Addon:ShowGearCheckReport(entry.report, entry.status or "ok")
		end
	end)

	return cell
end

local function CreateGroupColumn(parent, groupIndex)
	local column = CreateFrame("Frame", nil, parent)
	column:SetSize(CELL_W, BlockHeight())

	local label = column:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 0, 0)
	label:SetPoint("TOPRIGHT", 0, 0)
	label:SetHeight(GROUP_LABEL_H)
	label:SetJustifyH("CENTER")
	label:SetText(tostring(groupIndex))
	W.SetFontColor(label, UI.GOLD)
	column.label = label

	column.cells = {}
	for slot = 1, 5 do
		local cell = CreatePlayerCell(column)
		cell:SetPoint("TOPLEFT", 0, -(GROUP_LABEL_H + (slot - 1) * (CELL_H + CELL_GAP)))
		column.cells[slot] = cell
	end

	return column
end

local function CreateBlock(parent, startGroup, endGroup)
	local columnCount = endGroup - startGroup + 1
	local block = CreateFrame("Frame", nil, parent)
	block:SetSize(
		CELL_W * columnCount + CELL_GAP * (columnCount - 1),
		BlockHeight()
	)

	block.columns = {}
	for groupIndex = startGroup, endGroup do
		local column = CreateGroupColumn(block, groupIndex)
		column:SetPoint("TOPLEFT", ColumnOffset(groupIndex - startGroup + 1), 0)
		block.columns[groupIndex] = column
	end

	return block
end

local function FillPlayerCell(cell, member, entry, stripe)
	cell.stripe = stripe
	cell:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])

	if not member then
		cell.member = nil
		cell.entry = nil
		cell.nameText:SetText("")
		cell.overallText:SetText("")
		cell.countsText:SetText("")
		cell.classIconHost:Hide()
		cell.specIconHost:Hide()
		cell:EnableMouse(false)
		cell:Show()
		return
	end

	cell.member = member
	cell.entry = entry
	cell:EnableMouse(true)

	local report = entry and entry.report
	local character = report and report.character or {}
	local classToken = member.class or character.classFile or ""
	local name = member.name or character.name or "?"

	cell.nameText:SetText(name)
	cell.nameText:SetTextColor(W.ClassColor(classToken))
	W.SetSpecOrClassIcon(cell.classIcon, nil, classToken)
	cell.classIconHost:Show()

	local specIcon = character.specIcon
	if not specIcon or specIcon == "" then
		specIcon = member.specIcon
	end
	if specIcon and specIcon ~= "" then
		W.SetSpecOrClassIcon(cell.specIcon, specIcon, classToken)
		cell.specIcon:Show()
	else
		cell.specIcon:SetTexture(nil)
		cell.specIcon:Hide()
	end
	cell.specIconHost:Show()

	local overallLabel = StatusLabelForEntry(entry)
	cell.overallText:SetText(overallLabel)
	if report then
		W.SetFontColor(cell.overallText, OverallColor(overallLabel))
	else
		W.SetFontColor(cell.overallText, UI.TEXT_DISABLED)
	end

	local counts = FormatCellCounts(report)
	cell.countsText:SetText(counts)
	if counts ~= "" then
		local verdicts = report.verdicts or {}
		local issues = (report.overall and report.overall.issues) or {}
		local issueTotal = (issues.enchants or 0) + (issues.gems or 0) + (issues.meta or 0)
		local hot = (verdicts.bad or 0) > 0 or (verdicts.replace or 0) > 0 or issueTotal > 0
		W.SetFontColor(cell.countsText, hot and UI.GOLD or UI.TEXT_IDLE)
	else
		W.SetFontColor(cell.countsText, UI.TEXT_DISABLED)
	end

	cell:Show()
end

local function RunRaidScan(page)
	if not Addon.StartGearCheckRaidScan then
		if page.statusLabel then
			page.statusLabel:SetText(W.T("GEAR_CHECK_STATUS_FAIL"))
		end
		return
	end
	if Addon.IsGearCheckScanBusy and Addon:IsGearCheckScanBusy() then
		if page.statusLabel then
			page.statusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_BUSY"))
		end
		return
	end
	if page.scanBtn then
		page.scanBtn:Disable()
	end
	if page.statusLabel then
		page.statusLabel:SetText(W.T("GEAR_CHECK_STATUS_SCANNING"))
	end
	page.scanning = true
	page.results = {}

	local started = Addon:StartGearCheckRaidScan(
		function(entry, done, total)
			if page.statusLabel and entry and entry.member then
				page.statusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_SCANNING", done, total, entry.member.name or "?"))
			end
			page.results[#page.results + 1] = entry
			Addon:RefreshGearCheckRaidView(false)
		end,
		function(results, status)
			page.scanning = false
			page.results = results
			if page.scanBtn then
				page.scanBtn:Enable()
			end
			if page.statusLabel then
				if status == "empty" then
					page.statusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_EMPTY"))
				else
					page.statusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_DONE", #results))
				end
			end
			Addon:RefreshGearCheckRaidView(false)
		end
	)
	if not started then
		page.scanning = false
		if page.scanBtn then
			page.scanBtn:Enable()
		end
		if page.statusLabel then
			page.statusLabel:SetText(W.T("GEAR_CHECK_RAID_STATUS_BUSY"))
		end
	end
end

function Addon:RefreshGearCheckRaidView(autoScan)
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.gearraid
	if not page then
		return
	end

	if autoScan then
		RunRaidScan(page)
		return
	end

	local results = page.results
	if (not results or #results == 0) and self.GetLastGearCheckRaidResults then
		results = self:GetLastGearCheckRaidResults() or {}
		page.results = results
	end

	if page.summaryLabel then
		if results and #results > 0 then
			page.summaryLabel:SetText(FormatSummaryLine(results))
			W.SetFontColor(page.summaryLabel, UI.TEXT_IDLE)
		else
			page.summaryLabel:SetText(W.T("GEAR_CHECK_RAID_SUMMARY_EMPTY"))
			W.SetFontColor(page.summaryLabel, UI.TEXT_DISABLED)
		end
	end

	if not page.tableHost or not page.topBlock then
		return
	end
	page.tableHost:Show()

	local groups = (self.BuildRaidGroups and self:BuildRaidGroups(false)) or {}
	local byGuid, byName = IndexResults(results)
	local blocks = { page.topBlock, page.bottomBlock }
	for blockIndex = 1, #blocks do
		local block = blocks[blockIndex]
		for groupIndex, column in pairs(block.columns) do
			local slots = groups[groupIndex] or {}
			for slot = 1, 5 do
				local stripe = (slot % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
				local member = slots[slot]
				FillPlayerCell(column.cells[slot], member, EntryForMember(member, byGuid, byName), stripe)
			end
		end
	end

	local contentW, contentH = ContentSize()
	page.tableContent:SetSize(contentW, contentH)
	W.LayoutTableScrollBars(page)
end

local function CreateGearCheckRaidPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -110, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText(W.T("GEAR_CHECK_RAID_DESC"))
	page.hint = hint

	local scanBtn = W.CreatePlainButton(page, 104, UI.CD_TOOLBAR_H, W.T("GEAR_CHECK_SCAN"))
	scanBtn:SetPoint("TOPRIGHT", 0, 0)
	scanBtn:SetScript("OnClick", function()
		RunRaidScan(page)
	end)
	page.scanBtn = scanBtn

	local statusLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -6)
	statusLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	statusLabel:SetJustifyH("LEFT")
	statusLabel:SetJustifyV("TOP")
	statusLabel:SetText(W.T("GEAR_CHECK_RAID_HINT"))
	W.SetFontColor(statusLabel, UI.TEXT_IDLE)
	page.statusLabel = statusLabel

	local summaryLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	summaryLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -(UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE))
	summaryLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	summaryLabel:SetHeight(UI.ROSTER_STATS_H)
	summaryLabel:SetJustifyH("LEFT")
	summaryLabel:SetJustifyV("MIDDLE")
	summaryLabel:SetText(W.T("GEAR_CHECK_RAID_SUMMARY_EMPTY"))
	W.SetFontColor(summaryLabel, UI.TEXT_DISABLED)
	page.summaryLabel = summaryLabel

	local tableTop = -(W.RosterTableTopOffset())

	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseGearRaidScrollV" .. tostring(LAYOUT_VERSION), tableHost)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), UI.CD_HSCROLL_H + 2)
	scroll:EnableMouseWheel(true)
	page.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	local contentW, contentH = ContentSize()
	content:SetSize(contentW, contentH)
	scroll:SetScrollChild(content)
	page.tableContent = content

	local topBlock = CreateBlock(content, 1, 5)
	topBlock:SetPoint("TOPLEFT", 0, 0)
	page.topBlock = topBlock

	local bottomBlock = CreateBlock(content, 6, 8)
	bottomBlock:SetPoint("TOPLEFT", topBlock, "BOTTOMLEFT", 0, -BLOCK_GAP)
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
		local step = CELL_H
		local nextValue = math.max(0, math.min(maxV, (self:GetVerticalScroll() or 0) - delta * step))
		self:SetVerticalScroll(nextValue)
		vBar:SetValue(nextValue)
	end)
	scroll:SetScript("OnSizeChanged", function()
		W.LayoutTableScrollBars(page)
	end)

	page:SetScript("OnShow", function()
		Addon:RefreshGearCheckRaidView(false)
	end)

	page.results = {}
	page.scanning = false
	page.layoutVersion = LAYOUT_VERSION
	return page
end

local function ApplyLocale(page)
	if page and page.hint then
		page.hint:SetText(W.T("GEAR_CHECK_RAID_DESC"))
	end
	if page and page.scanBtn and page.scanBtn.label then
		page.scanBtn.label:SetText(W.T("GEAR_CHECK_SCAN"))
	end
	if page and page.statusLabel and not page.scanning then
		page.statusLabel:SetText(W.T("GEAR_CHECK_RAID_HINT"))
	end
	if page and page.summaryLabel then
		local results = page.results
		if results and #results > 0 then
			page.summaryLabel:SetText(FormatSummaryLine(results))
		else
			page.summaryLabel:SetText(W.T("GEAR_CHECK_RAID_SUMMARY_EMPTY"))
		end
	end
end

Addon.Pages.GearCheckRaid = {
	id = "gearraid",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateGearCheckRaidPage,
	ApplyLocale = ApplyLocale,
}
