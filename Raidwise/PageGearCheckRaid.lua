-- PageGearCheckRaid — scan party/raid roster; row click opens Gear check (target).

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 2

local COL_NAME = 100
local COL_CLASS = 28
local COL_SPEC = 28
local COL_OVERALL = 64
local COL_BAD = 36
local COL_REPLACE = 44
local COL_ISSUES = 52

local COLUMN_WIDTHS = {
	COL_NAME,
	COL_CLASS,
	COL_SPEC,
	COL_OVERALL,
	COL_BAD,
	COL_REPLACE,
	COL_ISSUES,
}

local function TableWidth()
	local width = 0
	for index = 1, #COLUMN_WIDTHS do
		width = width + COLUMN_WIDTHS[index]
	end
	return width
end

local function ColumnOffset(index)
	local offset = 0
	for column = 1, index - 1 do
		offset = offset + COLUMN_WIDTHS[column]
	end
	return offset
end

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
		return W.T("GEAR_CHECK_RAID_ROW_FAIL")
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

local function CreateRaidRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(UI.CD_ROW_H)
	W.ApplyPlainPanel(row, UI.CD_ROW_A)
	row:EnableMouse(true)
	row:RegisterForClicks("LeftButtonUp")

	local function AddTextColumn(columnIndex, justify)
		local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("TOPLEFT", row, "TOPLEFT", ColumnOffset(columnIndex) + 4, -4)
		text:SetWidth(COLUMN_WIDTHS[columnIndex] - 8)
		text:SetJustifyH(justify or "LEFT")
		text:SetJustifyV("TOP")
		return text
	end

	row.nameText = AddTextColumn(1, "LEFT")

	row.classIconHost = CreateFrame("Frame", nil, row)
	row.classIconHost:SetSize(UI.ROSTER_ICON, UI.ROSTER_ICON)
	row.classIconHost:SetPoint(
		"TOPLEFT",
		row,
		"TOPLEFT",
		ColumnOffset(2) + W.TableIconInset(COL_CLASS, UI.ROSTER_ICON),
		W.TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.classIcon = row.classIconHost:CreateTexture(nil, "ARTWORK")
	row.classIcon:SetAllPoints(row.classIconHost)

	row.specIconHost = CreateFrame("Frame", nil, row)
	row.specIconHost:SetSize(UI.ROSTER_ICON, UI.ROSTER_ICON)
	row.specIconHost:SetPoint(
		"TOPLEFT",
		row,
		"TOPLEFT",
		ColumnOffset(3) + W.TableIconInset(COL_SPEC, UI.ROSTER_ICON),
		W.TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.specIcon = row.specIconHost:CreateTexture(nil, "ARTWORK")
	row.specIcon:SetAllPoints(row.specIconHost)

	row.overallText = AddTextColumn(4, "CENTER")
	row.badText = AddTextColumn(5, "CENTER")
	row.replaceText = AddTextColumn(6, "CENTER")
	row.issuesText = AddTextColumn(7, "CENTER")

	row.classIconHost:EnableMouse(true)
	row.classIconHost:SetScript("OnEnter", function(self)
		if not row.classLabel or row.classLabel == "" then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(row.classLabel)
		GameTooltip:Show()
	end)
	row.classIconHost:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	row.specIconHost:EnableMouse(true)
	row.specIconHost:SetScript("OnEnter", function(self)
		if not row.specLabel or row.specLabel == "" then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(row.specLabel)
		GameTooltip:Show()
	end)
	row.specIconHost:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	row:SetScript("OnEnter", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1] * 1.08, stripe[2] * 1.08, stripe[3] * 1.08, stripe[4])
		if self.entry and self.entry.report then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(W.T("GEAR_CHECK_RAID_CLICK_HINT"))
			GameTooltip:Show()
		end
	end)
	row:SetScript("OnLeave", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		GameTooltip:Hide()
	end)
	row:SetScript("OnClick", function(self)
		local entry = self.entry
		if entry and entry.report and Addon.ShowGearCheckReport then
			Addon:ShowGearCheckReport(entry.report, entry.status or "ok")
		end
	end)

	return row
end

local function ApplyEntryToRow(row, entry)
	local member = entry and entry.member or {}
	local report = entry and entry.report
	local character = report and report.character or {}

	row.entry = entry
	row.member = member
	row.classLabel = member.classLabel or character.className
	row.specLabel = member.spec or character.specName

	row.nameText:SetText(member.name or character.name or "?")
	row.nameText:SetTextColor(W.ClassColor(member.class or character.className))

	W.SetSpecOrClassIcon(row.classIcon, nil, member.class or character.className)
	local specIcon = member.specIcon or character.specIcon
	W.SetSpecOrClassIcon(row.specIcon, specIcon, member.class or character.className)

	local overallLabel = StatusLabelForEntry(entry)
	row.overallText:SetText(overallLabel)
	W.SetFontColor(row.overallText, report and OverallColor(overallLabel) or UI.TEXT_DISABLED)

	if report and report.verdicts then
		row.badText:SetText(tostring(report.verdicts.bad or 0))
		row.replaceText:SetText(tostring(report.verdicts.replace or 0))
		W.SetFontColor(row.badText, (report.verdicts.bad or 0) > 0 and UI.TEXT_ALERT or UI.TEXT_IDLE)
		W.SetFontColor(row.replaceText, (report.verdicts.replace or 0) > 0 and UI.GOLD or UI.TEXT_IDLE)
	else
		row.badText:SetText("-")
		row.replaceText:SetText("-")
		W.SetFontColor(row.badText, UI.TEXT_DISABLED)
		W.SetFontColor(row.replaceText, UI.TEXT_DISABLED)
	end

	if report and report.overall and report.overall.issues then
		local issues = report.overall.issues
		local total = (issues.enchants or 0) + (issues.gems or 0) + (issues.meta or 0)
		row.issuesText:SetText(tostring(total))
		W.SetFontColor(row.issuesText, total > 0 and UI.GOLD or UI.TEXT_IDLE)
	else
		row.issuesText:SetText("-")
		W.SetFontColor(row.issuesText, UI.TEXT_DISABLED)
	end
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

	if page.scanning and self.IsGearCheckScanBusy and self:IsGearCheckScanBusy() then
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

	if not page.tableHost then
		return
	end
	page.tableHost:Show()

	local content = page.tableContent
	local headerBg = page.headerBg
	local tableW = TableWidth()
	local rowCount = math.max(#results, 1)
	local tableH = UI.CD_HEADER_H + rowCount * UI.CD_ROW_H

	content:SetSize(tableW, tableH)
	headerBg:SetWidth(tableW)

	W.HidePoolFrom(page.rowFrames, #results + 1)
	for rowIndex = 1, #results do
		local entry = results[rowIndex]
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreateRaidRow(content)
			page.rowFrames[rowIndex] = row
		end

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(UI.CD_HEADER_H + (rowIndex - 1) * UI.CD_ROW_H))
		row:SetSize(tableW, UI.CD_ROW_H)
		local stripe = (rowIndex % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
		row.stripe = stripe
		row:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		ApplyEntryToRow(row, entry)
		row:Show()
	end

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
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	page.tableContent = content
	page.rowFrames = {}

	local headerBg = CreateFrame("Frame", nil, content)
	headerBg:SetPoint("TOPLEFT", 0, 0)
	headerBg:SetHeight(UI.CD_HEADER_H)
	W.ApplyPlainPanel(headerBg, UI.TITLE_BG)
	page.headerBg = headerBg

	local headerKeys = {
		"COL_NAME",
		"COL_CLASS",
		"COL_SPEC",
		"GEAR_CHECK_RAID_COL_OVERALL",
		"GEAR_CHECK_RAID_COL_BAD",
		"GEAR_CHECK_RAID_COL_REPLACE",
		"GEAR_CHECK_RAID_COL_ISSUES",
	}
	page.headerKeys = headerKeys
	page.headerLabels = {}
	for index = 1, #headerKeys do
		local label = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", headerBg, "TOPLEFT", ColumnOffset(index) + 4, -10)
		label:SetWidth(COLUMN_WIDTHS[index] - 8)
		local center = index >= 4
		label:SetJustifyH(center and "CENTER" or "LEFT")
		label:SetText(W.T(headerKeys[index]))
		W.SetFontColor(label, UI.GOLD)
		page.headerLabels[index] = label
	end

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
		local step = UI.CD_ROW_H
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
	if page and page.headerKeys and page.headerLabels then
		for index = 1, #page.headerKeys do
			local label = page.headerLabels[index]
			if label then
				label:SetText(W.T(page.headerKeys[index]))
			end
		end
	end
end

Addon.Pages.GearCheckRaid = {
	id = "gearraid",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateGearCheckRaidPage,
	ApplyLocale = ApplyLocale,
}
