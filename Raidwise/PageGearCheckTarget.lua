-- PageGearCheckTarget — summary, breakdown (incl. OK-not-GOOD), self-chat reports; dump behind Debug.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 7

local ApplyReportToPage
local RefreshSavedList

local FILTERS = {
	{ id = "all", labelKey = "GEAR_CHECK_FILTER_ALL" },
	{ id = "items", labelKey = "GEAR_CHECK_FILTER_ITEMS" },
	{ id = "enchants", labelKey = "GEAR_CHECK_FILTER_ENCHANTS" },
	{ id = "gems", labelKey = "GEAR_CHECK_FILTER_GEMS" },
	{ id = "ok", labelKey = "GEAR_CHECK_FILTER_OK" },
}

local REPORT_BUTTONS = {
	{ mode = "summary", labelKey = "GEAR_CHECK_REPORT_SUMMARY" },
	{ mode = "items", labelKey = "GEAR_CHECK_REPORT_ITEMS" },
	{ mode = "enchants", labelKey = "GEAR_CHECK_REPORT_ENCHANTS" },
	{ mode = "gems", labelKey = "GEAR_CHECK_REPORT_GEMS" },
	{ mode = "ok", labelKey = "GEAR_CHECK_REPORT_OK" },
}

local ITEM_CATEGORIES = {
	item = true,
	armor = true,
	weapon = true,
	stat = true,
}

local function StatusTextForScan(report, status)
	if not report then
		return W.T("GEAR_CHECK_STATUS_FAIL")
	end
	if status == "too_far" then
		return W.T("GEAR_CHECK_STATUS_TOO_FAR")
	end
	if status == "cannot_inspect" then
		return W.T("GEAR_CHECK_STATUS_NO_INSPECT")
	end
	if status == "timeout" then
		return W.T("GEAR_CHECK_STATUS_TIMEOUT")
	end
	if status == "empty" then
		return W.T("GEAR_CHECK_STATUS_EMPTY")
	end
	local character = report.character or {}
	local who = character.name or report.name or "?"
	local isSelf = character.isSelf
	if isSelf == nil then
		isSelf = report.isSelf
	end
	local where = isSelf and W.T("GEAR_CHECK_STATUS_SELF") or W.T("GEAR_CHECK_STATUS_TARGET")
	return W.T("GEAR_CHECK_STATUS_OK", who, where)
end

local function VerdictColor(verdict)
	if verdict == "BAD" then
		return UI.TEXT_ALERT
	end
	if verdict == "REPLACE" then
		return UI.GOLD
	end
	if verdict == "GOOD" then
		return UI.TEXT_GOOD
	end
	return UI.TEXT_IDLE
end

local function FindingMatchesFilter(finding, filterId)
	local category = finding.category
	if filterId == "all" then
		return true
	end
	if filterId == "items" then
		return ITEM_CATEGORIES[category] == true
	end
	if filterId == "enchants" then
		return category == "enchant"
	end
	if filterId == "gems" then
		return category == "gem" or category == "meta"
	end
	return false
end

local function SlotLabel(report, slotKey)
	if not slotKey then
		return W.T("GEAR_CHECK_SCOPE_GEAR")
	end
	local equipment = report.equipment or report.slots or {}
	for index = 1, #equipment do
		local slot = equipment[index]
		if slot.key == slotKey then
			local name = slot.slotName or slotKey
			local item = slot.item
			if item and item.name and item.name ~= "" then
				local id = item.itemId and tostring(item.itemId) or "-"
				local ilvl = item.itemLevel and tostring(item.itemLevel) or "-"
				return string.format("%s — %s  id=%s  ilvl=%s", name, item.name, id, ilvl)
			end
			return name
		end
	end
	return tostring(slotKey)
end

local function SlotVerdict(report, slotKey)
	if not slotKey then
		return nil
	end
	local equipment = report.equipment or report.slots or {}
	for index = 1, #equipment do
		local slot = equipment[index]
		if slot.key == slotKey then
			return slot.verdict
		end
	end
	return nil
end

-- Group hard/soft findings (and info not-checkable) by slot for the active filter.
-- All / OK also list slots that stayed OK (not GOOD), with why.
local function BuildBreakdownGroups(report, filterId)
	local findings = report.findings or {}
	local groups = {}
	local order = {}

	local function EnsureGroup(slotKey)
		local key = slotKey or "_gear"
		local group = groups[key]
		if not group then
			group = {
				slotKey = slotKey,
				label = SlotLabel(report, slotKey),
				verdict = SlotVerdict(report, slotKey),
				lines = {},
			}
			groups[key] = group
			order[#order + 1] = key
		end
		return group
	end

	local function AppendOkSlots()
		local equipment = report.equipment or report.slots or {}
		for index = 1, #equipment do
			local slot = equipment[index]
			if slot.policy == "CHECKED" and slot.item and slot.verdict == "OK" then
				local group = EnsureGroup(slot.key)
				group.verdict = "OK"
				if #group.lines == 0 then
					local reasons = Addon.ExplainGearCheckNotGood and Addon:ExplainGearCheckNotGood(report, slot) or {}
					if #reasons == 0 then
						group.lines[1] = {
							severity = "info",
							message = W.T("GEAR_CHECK_OK_REASON_GENERIC"),
						}
					else
						for reasonIndex = 1, #reasons do
							group.lines[#group.lines + 1] = {
								severity = "info",
								message = reasons[reasonIndex],
							}
						end
					end
				end
			end
		end
	end

	if filterId == "ok" then
		AppendOkSlots()
	else
		for index = 1, #findings do
			local finding = findings[index]
			if FindingMatchesFilter(finding, filterId) then
				local severity = finding.severity
				if severity == "hard" or severity == "soft"
					or finding.code == "ITEM_NOT_CHECKABLE"
					or finding.code == "ENCHANT_NOT_CHECKABLE"
					or finding.code == "GEM_NOT_CHECKABLE"
					or finding.code == "META_NOT_CHECKABLE"
				then
					local group = EnsureGroup(finding.slot)
					group.lines[#group.lines + 1] = {
						severity = severity,
						message = finding.message or finding.code or "?",
					}
					if severity == "hard" then
						group.verdict = "BAD"
					elseif severity == "soft" and group.verdict ~= "BAD" then
						group.verdict = "REPLACE"
					end
				end
			end
		end
		if filterId == "all" then
			AppendOkSlots()
		end
	end

	local list = {}
	for index = 1, #order do
		list[#list + 1] = groups[order[index]]
	end
	return list
end

local function FormatSetsBrief(sets)
	if not sets or #sets == 0 then
		return W.T("GEAR_CHECK_SETS_NONE")
	end
	local parts = {}
	for index = 1, #sets do
		local row = sets[index]
		parts[#parts + 1] = string.format("%s %d/%d", row.key, row.equipped or 0, row.pieces or 5)
	end
	return table.concat(parts, ", ")
end

local function FormatMetaBrief(meta)
	if not meta or not meta.present then
		return W.T("GEAR_CHECK_META_NONE")
	end
	if meta.active == true then
		return W.T("GEAR_CHECK_META_ACTIVE")
	end
	if meta.active == false then
		return W.T("GEAR_CHECK_META_INACTIVE")
	end
	return W.T("GEAR_CHECK_META_UNKNOWN")
end

local function EnsureBreakdownRows(page, needed)
	page.breakRows = page.breakRows or {}
	while #page.breakRows < needed do
		local row = CreateFrame("Frame", nil, page.breakContent)
		row:SetHeight(18)
		local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", 0, 0)
		title:SetJustifyH("LEFT")
		row.title = title
		local detail = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 12, -2)
		detail:SetJustifyH("LEFT")
		detail:SetJustifyV("TOP")
		row.detail = detail
		page.breakRows[#page.breakRows + 1] = row
	end
	for index = needed + 1, #page.breakRows do
		page.breakRows[index]:Hide()
	end
end

local function SetFilterSelected(page, filterId)
	page.activeFilter = filterId
	local buttons = page.filterButtons or {}
	for index = 1, #buttons do
		local btn = buttons[index]
		local selected = btn.filterId == filterId
		if selected then
			btn:SetBackdropColor(UI.BTN_SELECTED[1], UI.BTN_SELECTED[2], UI.BTN_SELECTED[3], UI.BTN_SELECTED[4] or 1)
			if btn.label then
				W.SetFontColor(btn.label, UI.GOLD)
			end
		else
			btn:SetBackdropColor(UI.BTN_IDLE[1], UI.BTN_IDLE[2], UI.BTN_IDLE[3], UI.BTN_IDLE[4] or 1)
			if btn.label then
				W.SetFontColor(btn.label, UI.TEXT_IDLE)
			end
		end
	end
end

local function UpdateDebugVisibility(page)
	local debug = page.debugMode == true
	if page.summaryHost then
		if debug then
			page.summaryHost:Hide()
		else
			page.summaryHost:Show()
		end
	end
	if page.reportHost then
		if debug then
			page.reportHost:Hide()
		else
			page.reportHost:Show()
		end
	end
	if page.filterHost then
		if debug then
			page.filterHost:Hide()
		else
			page.filterHost:Show()
		end
	end
	if page.breakHost then
		if debug then
			page.breakHost:Hide()
		else
			page.breakHost:Show()
		end
	end
	if page.savedHost then
		if debug then
			page.savedHost:Hide()
		else
			page.savedHost:Show()
		end
	end
	if page.copyHost then
		if debug then
			page.copyHost:Show()
		else
			page.copyHost:Hide()
		end
	end
	if page.debugBtn and page.debugBtn.label then
		page.debugBtn.label:SetText(debug and W.T("GEAR_CHECK_DEBUG_ON") or W.T("GEAR_CHECK_DEBUG"))
	end
	if page.selectBtn then
		if debug and page.dumpBox and (page.dumpBox:GetText() or "") ~= "" then
			page.selectBtn:Enable()
		else
			page.selectBtn:Disable()
		end
	end
	if page.saveBtn then
		if page.lastReport and not page.debugMode then
			page.saveBtn:Enable()
		else
			page.saveBtn:Disable()
		end
	end
	if page.savedDeleteBtn then
		if page.viewingSavedId then
			page.savedDeleteBtn:Enable()
		else
			page.savedDeleteBtn:Disable()
		end
	end
end

local function EnsureSavedRows(page, needed)
	page.savedRows = page.savedRows or {}
	while #page.savedRows < needed do
		local row = W.CreatePlainButton(page.savedContent, 200, 20, "")
		row:SetScript("OnClick", function(self)
			if self.savedId and page then
				local entry = Addon.GetGearCheckSavedReport and Addon:GetGearCheckSavedReport(self.savedId)
				if entry and entry.report then
					ApplyReportToPage(page, entry.report, "saved", entry)
				end
			end
		end)
		page.savedRows[#page.savedRows + 1] = row
	end
	for index = needed + 1, #page.savedRows do
		page.savedRows[index]:Hide()
	end
end

RefreshSavedList = function(page)
	if not page or not page.savedContent then
		return
	end
	local list = Addon.ListGearCheckSavedReports and Addon:ListGearCheckSavedReports() or {}
	local innerW = W.ContentInnerWidth()
	local rowW = math.max(100, innerW - 16)
	if #list == 0 then
		EnsureSavedRows(page, 0)
		if page.savedEmptyLabel then
			page.savedEmptyLabel:Show()
		end
		page.savedContent:SetHeight(18)
		return
	end
	if page.savedEmptyLabel then
		page.savedEmptyLabel:Hide()
	end
	local maxRows = math.min(#list, 4)
	EnsureSavedRows(page, maxRows)
	local y = 0
	for index = 1, maxRows do
		local entry = list[index]
		local row = page.savedRows[index]
		row:SetWidth(rowW)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", page.savedContent, "TOPLEFT", 0, y)
		row.savedId = entry.id
		local label = Addon.FormatGearCheckSavedLabel and Addon:FormatGearCheckSavedLabel(entry) or entry.id
		if page.viewingSavedId == entry.id then
			label = "> " .. label
		end
		if row.label then
			row.label:SetText(label)
		end
		row:Show()
		y = y - 22
	end
	page.savedContent:SetHeight(math.max(18, -y))
end

local function SaveCurrentReport(page)
	if not page or not page.lastReport then
		Addon:Print(W.T("GEAR_CHECK_SAVED_FAIL"))
		return
	end
	if not Addon.SaveGearCheckReport then
		Addon:Print(W.T("GEAR_CHECK_STATUS_FAIL"))
		return
	end
	local id, err = Addon:SaveGearCheckReport(page.lastReport)
	if not id then
		Addon:Print(W.T("GEAR_CHECK_SAVED_FAIL"))
		return
	end
	local entry = Addon:GetGearCheckSavedReport(id)
	local label = entry and Addon:FormatGearCheckSavedLabel(entry) or id
	Addon:Print(W.T("GEAR_CHECK_SAVED_SAVED", label))
	if entry and entry.report then
		ApplyReportToPage(page, entry.report, "saved", entry)
	else
		RefreshSavedList(page)
	end
end

local function DeleteViewingSaved(page)
	if not page or not page.viewingSavedId then
		Addon:Print(W.T("GEAR_CHECK_SAVED_NONE"))
		return
	end
	if Addon.DeleteGearCheckSavedReport and Addon:DeleteGearCheckSavedReport(page.viewingSavedId) then
		page.viewingSavedId = nil
		Addon:Print(W.T("GEAR_CHECK_SAVED_DELETED"))
		RefreshSavedList(page)
		local live = Addon.GetLastGearCheckReport and Addon:GetLastGearCheckReport()
		if live then
			ApplyReportToPage(page, live, page.lastStatus or "ok")
		else
			ApplyReportToPage(page, nil, "empty")
		end
	else
		Addon:Print(W.T("GEAR_CHECK_SAVED_NONE"))
	end
end

local function ApplySummary(page, report)
	if not page.summaryHost then
		return
	end
	if not report then
		page.overallLabel:SetText(W.T("GEAR_CHECK_OVERALL_NONE"))
		W.SetFontColor(page.overallLabel, UI.TEXT_DISABLED)
		page.whoLabel:SetText("")
		if page.statsLabel then
			page.statsLabel:SetText("")
		end
		page.issuesLabel:SetText("")
		page.metaLabel:SetText("")
		page.setsLabel:SetText("")
		return
	end

	local overall = report.overall or {}
	local status = overall.status or "OK"
	page.overallLabel:SetText(W.T("GEAR_CHECK_OVERALL", status))
	W.SetFontColor(page.overallLabel, VerdictColor(status))

	local character = report.character or {}
	local who = character.name or report.name or "?"
	local className = character.className or character.classFile or "?"
	local spec = "?"
	if character.specKnown and character.specName and character.specName ~= "" then
		spec = character.specName
	elseif report.profile and report.profile.name then
		spec = report.profile.name .. " (" .. tostring(report.profile.source or "?") .. ")"
	else
		spec = W.T("GEAR_CHECK_SPEC_UNKNOWN")
	end
	page.whoLabel:SetText(W.T("GEAR_CHECK_WHO", who, className, spec))
	W.SetFontColor(page.whoLabel, UI.TEXT_IDLE)

	if page.statsLabel then
		local stats = report.stats or {}
		local gearScore = stats.gearScore or character.gearScore
		local averageIlvl = stats.averageIlvl or character.averageIlvl
		page.statsLabel:SetText(W.T(
			"GEAR_CHECK_GS_ILVL",
			gearScore ~= nil and tostring(gearScore) or "-",
			averageIlvl ~= nil and tostring(averageIlvl) or "-"
		))
		W.SetFontColor(page.statsLabel, UI.TEXT_IDLE)
	end

	local issues = overall.issues or {}
	local verdicts = report.verdicts or {}
	page.issuesLabel:SetText(W.T(
		"GEAR_CHECK_ISSUES",
		verdicts.bad or 0,
		verdicts.replace or 0,
		verdicts.ok or 0,
		verdicts.good or 0,
		issues.enchants or 0,
		issues.gems or 0,
		(issues.meta or 0) == 0 and W.T("GEAR_CHECK_META_OK_SHORT") or tostring(issues.meta or 0)
	))
	W.SetFontColor(page.issuesLabel, UI.TEXT_DISABLED)

	page.metaLabel:SetText(W.T("GEAR_CHECK_META_LINE", FormatMetaBrief(report.meta)))
	W.SetFontColor(page.metaLabel, UI.TEXT_DISABLED)

	page.setsLabel:SetText(W.T("GEAR_CHECK_SETS_LINE", FormatSetsBrief(report.sets)))
	W.SetFontColor(page.setsLabel, UI.TEXT_DISABLED)

	if overall.summary and overall.summary ~= "" then
		page.summaryNote:SetText(overall.summary)
		page.summaryNote:Show()
	else
		page.summaryNote:SetText("")
		page.summaryNote:Hide()
	end
end

local function ApplyBreakdown(page, report)
	local content = page.breakContent
	local scroll = page.breakScroll
	if not content or not scroll then
		return
	end

	local filterId = page.activeFilter or "all"
	local groups = report and BuildBreakdownGroups(report, filterId) or {}
	local emptyText = W.T("GEAR_CHECK_BREAK_EMPTY_SCAN")
	if report then
		if #groups == 0 then
			if filterId == "ok" then
				emptyText = W.T("GEAR_CHECK_BREAK_EMPTY_OK")
			else
				emptyText = W.T("GEAR_CHECK_BREAK_EMPTY_FILTER")
			end
		end
	end

	if not report or #groups == 0 then
		EnsureBreakdownRows(page, 1)
		local row = page.breakRows[1]
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
		row.title:SetText(emptyText)
		W.SetFontColor(row.title, UI.TEXT_DISABLED)
		row.detail:SetText("")
		row.detail:Hide()
		row:SetHeight(18)
		row:Show()
		content:SetHeight(24)
		scroll:SetVerticalScroll(0)
		if page.breakBar then
			page.breakBar:SetMinMaxValues(0, 0)
			page.breakBar:SetValue(0)
		end
		return
	end

	EnsureBreakdownRows(page, #groups)
	local y = 0
	local width = math.max(100, (content:GetWidth() or W.ContentInnerWidth()) - 4)
	for index = 1, #groups do
		local group = groups[index]
		local row = page.breakRows[index]
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
		row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
		row.title:SetWidth(width)
		local verdict = group.verdict or "OK"
		row.title:SetText(string.format("[%s] %s", verdict, group.label))
		W.SetFontColor(row.title, VerdictColor(verdict))

		local detailParts = {}
		for lineIndex = 1, #group.lines do
			detailParts[#detailParts + 1] = "• " .. group.lines[lineIndex].message
		end
		local detailText = table.concat(detailParts, "\n")
		row.detail:SetWidth(width - 12)
		row.detail:SetText(detailText)
		row.detail:Show()
		W.SetFontColor(row.detail, UI.TEXT_DISABLED)

		local titleH = row.title:GetStringHeight() or 14
		local detailH = row.detail:GetStringHeight() or 0
		local rowH = titleH + 2 + detailH + 8
		row:SetHeight(rowH)
		row:Show()
		y = y - rowH
	end
	local contentH = math.max(24, -y + 4)
	content:SetHeight(contentH)
	local viewH = scroll:GetHeight() or 0
	local maxV = math.max(0, contentH - viewH)
	scroll:SetVerticalScroll(0)
	if page.breakBar then
		page.breakBar:SetMinMaxValues(0, maxV)
		page.breakBar:SetValue(0)
	end
end

ApplyReportToPage = function(page, report, status, savedEntry)
	if not page then
		return
	end
	page.lastReport = report
	page.lastStatus = status
	if savedEntry then
		page.viewingSavedId = savedEntry.id
	else
		page.viewingSavedId = nil
	end
	if page.statusLabel then
		if status == "saved" and savedEntry and Addon.FormatGearCheckSavedLabel then
			page.statusLabel:SetText(W.T("GEAR_CHECK_STATUS_SAVED", Addon:FormatGearCheckSavedLabel(savedEntry)))
		else
			page.statusLabel:SetText(StatusTextForScan(report, status))
		end
	end
	if page.dumpBox and Addon.FormatGearCheckDump then
		page.dumpBox:SetText(report and Addon:FormatGearCheckDump(report) or "")
	end
	ApplySummary(page, report)
	ApplyBreakdown(page, report)
	UpdateDebugVisibility(page)
	RefreshSavedList(page)
end

local function RunScan(page)
	if not Addon.StartGearCheckScan then
		if page.statusLabel then
			page.statusLabel:SetText(W.T("GEAR_CHECK_STATUS_FAIL"))
		end
		return
	end
	if page.statusLabel then
		page.statusLabel:SetText(W.T("GEAR_CHECK_STATUS_SCANNING"))
	end
	if page.scanBtn then
		page.scanBtn:Disable()
	end
	Addon:StartGearCheckScan(function(report, status)
		ApplyReportToPage(page, report, status)
		if page.scanBtn then
			page.scanBtn:Enable()
		end
	end)
end

local function RunChatReport(page, mode)
	if not Addon.PrintGearCheckReport then
		Addon:Print(W.T("GEAR_CHECK_STATUS_FAIL"))
		return
	end
	local report = page.lastReport or (Addon.GetLastGearCheckReport and Addon:GetLastGearCheckReport())
	if report then
		Addon:PrintGearCheckReport(mode, report)
		return
	end
	if not Addon.StartGearCheckScan then
		Addon:Print(W.T("CHAT_GEARCHECK_NO_REPORT"))
		return
	end
	if page.statusLabel then
		page.statusLabel:SetText(W.T("GEAR_CHECK_STATUS_SCANNING"))
	end
	if page.scanBtn then
		page.scanBtn:Disable()
	end
	Addon:Print(W.T("CHAT_GEARCHECK_SCANNING"))
	Addon:StartGearCheckScan(function(scanned, status)
		ApplyReportToPage(page, scanned, status)
		if page.scanBtn then
			page.scanBtn:Enable()
		end
		if scanned then
			Addon:PrintGearCheckReport(mode, scanned)
		else
			Addon:Print(W.T("CHAT_GEARCHECK_NO_REPORT"))
		end
	end)
end

local function CreateGearCheckTargetPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)
	page.debugMode = false
	page.activeFilter = "all"

	local innerW = W.ContentInnerWidth()

	local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 0, 0)
	desc:SetWidth(innerW)
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText(W.T("GEAR_CHECK_TARGET_DESC"))
	page.desc = desc

	local limit = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	limit:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	limit:SetWidth(innerW)
	limit:SetJustifyH("LEFT")
	limit:SetJustifyV("TOP")
	limit:SetText(W.T("GEAR_CHECK_LIMITATION"))
	W.SetFontColor(limit, UI.TEXT_DISABLED)
	page.limit = limit

	local buttonW = (innerW - UI.ACTION_BTN_GAP * 3) / 4
	local scanBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("GEAR_CHECK_SCAN"))
	scanBtn:SetPoint("TOPLEFT", limit, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
	scanBtn:SetScript("OnClick", function()
		RunScan(page)
	end)
	page.scanBtn = scanBtn

	local saveBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("GEAR_CHECK_SAVE"))
	saveBtn:SetPoint("LEFT", scanBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	saveBtn:Disable()
	saveBtn:SetScript("OnClick", function()
		SaveCurrentReport(page)
	end)
	page.saveBtn = saveBtn

	local debugBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("GEAR_CHECK_DEBUG"))
	debugBtn:SetPoint("LEFT", saveBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	debugBtn:SetScript("OnClick", function()
		page.debugMode = not page.debugMode
		UpdateDebugVisibility(page)
	end)
	page.debugBtn = debugBtn

	local selectBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("BTN_SELECT_ALL"))
	selectBtn:SetPoint("LEFT", debugBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	selectBtn:Disable()
	selectBtn:SetScript("OnClick", function()
		if Addon.SelectGearCheckDump then
			Addon:SelectGearCheckDump()
		end
	end)
	page.selectBtn = selectBtn

	local statusLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusLabel:SetPoint("TOPLEFT", scanBtn, "BOTTOMLEFT", 0, -UI.BUTTONS_TO_HINT)
	statusLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	statusLabel:SetJustifyH("LEFT")
	statusLabel:SetText(W.T("GEAR_CHECK_HINT"))
	page.statusLabel = statusLabel

	-- Summary band
	local summaryHost = CreateFrame("Frame", nil, page)
	summaryHost:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	summaryHost:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	summaryHost:SetHeight(124)
	W.ApplyPlainPanel(summaryHost, UI.PANEL_BG)
	page.summaryHost = summaryHost

	local overallLabel = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	overallLabel:SetPoint("TOPLEFT", 8, -8)
	overallLabel:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	overallLabel:SetJustifyH("LEFT")
	page.overallLabel = overallLabel

	local whoLabel = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	whoLabel:SetPoint("TOPLEFT", overallLabel, "BOTTOMLEFT", 0, -4)
	whoLabel:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	whoLabel:SetJustifyH("LEFT")
	page.whoLabel = whoLabel

	local statsLabel = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statsLabel:SetPoint("TOPLEFT", whoLabel, "BOTTOMLEFT", 0, -4)
	statsLabel:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	statsLabel:SetJustifyH("LEFT")
	page.statsLabel = statsLabel

	local issuesLabel = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	issuesLabel:SetPoint("TOPLEFT", statsLabel, "BOTTOMLEFT", 0, -4)
	issuesLabel:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	issuesLabel:SetJustifyH("LEFT")
	page.issuesLabel = issuesLabel

	local metaLabel = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	metaLabel:SetPoint("TOPLEFT", issuesLabel, "BOTTOMLEFT", 0, -2)
	metaLabel:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	metaLabel:SetJustifyH("LEFT")
	page.metaLabel = metaLabel

	local setsLabel = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	setsLabel:SetPoint("TOPLEFT", metaLabel, "BOTTOMLEFT", 0, -2)
	setsLabel:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	setsLabel:SetJustifyH("LEFT")
	page.setsLabel = setsLabel

	local summaryNote = summaryHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	summaryNote:SetPoint("TOPLEFT", setsLabel, "BOTTOMLEFT", 0, -2)
	summaryNote:SetPoint("RIGHT", summaryHost, "RIGHT", -8, 0)
	summaryNote:SetJustifyH("LEFT")
	W.SetFontColor(summaryNote, UI.TEXT_DISABLED)
	page.summaryNote = summaryNote

	-- Self-chat report buttons (Phase 7)
	local reportHost = CreateFrame("Frame", nil, page)
	reportHost:SetPoint("TOPLEFT", summaryHost, "BOTTOMLEFT", 0, -8)
	reportHost:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	reportHost:SetHeight(UI.ACTION_BTN_H)
	page.reportHost = reportHost

	page.reportButtons = {}
	local reportW = (innerW - UI.ACTION_BTN_GAP * (#REPORT_BUTTONS - 1)) / #REPORT_BUTTONS
	for index = 1, #REPORT_BUTTONS do
		local info = REPORT_BUTTONS[index]
		local btn = W.CreatePlainButton(reportHost, reportW, UI.ACTION_BTN_H, W.T(info.labelKey))
		if index == 1 then
			btn:SetPoint("TOPLEFT", 0, 0)
		else
			btn:SetPoint("LEFT", page.reportButtons[index - 1], "RIGHT", UI.ACTION_BTN_GAP, 0)
		end
		btn.reportMode = info.mode
		btn:SetScript("OnClick", function()
			RunChatReport(page, info.mode)
		end)
		page.reportButtons[index] = btn
	end

	-- Filter tabs
	local filterHost = CreateFrame("Frame", nil, page)
	filterHost:SetPoint("TOPLEFT", reportHost, "BOTTOMLEFT", 0, -6)
	filterHost:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	filterHost:SetHeight(UI.ACTION_BTN_H)
	page.filterHost = filterHost

	page.filterButtons = {}
	local filterW = (innerW - UI.ACTION_BTN_GAP * (#FILTERS - 1)) / #FILTERS
	for index = 1, #FILTERS do
		local info = FILTERS[index]
		local btn = W.CreatePlainButton(filterHost, filterW, UI.ACTION_BTN_H, W.T(info.labelKey))
		if index == 1 then
			btn:SetPoint("TOPLEFT", 0, 0)
		else
			btn:SetPoint("LEFT", page.filterButtons[index - 1], "RIGHT", UI.ACTION_BTN_GAP, 0)
		end
		btn.filterId = info.id
		btn:SetScript("OnClick", function()
			SetFilterSelected(page, info.id)
			ApplyBreakdown(page, page.lastReport)
		end)
		page.filterButtons[index] = btn
	end
	SetFilterSelected(page, "all")

	-- Saved reports (manual, ~14 days)
	local savedHost = CreateFrame("Frame", nil, page)
	savedHost:SetPoint("TOPLEFT", filterHost, "BOTTOMLEFT", 0, -6)
	savedHost:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	savedHost:SetHeight(74)
	W.ApplyPlainPanel(savedHost, UI.PANEL_BG)
	page.savedHost = savedHost

	local savedTitle = savedHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	savedTitle:SetPoint("TOPLEFT", 8, -6)
	savedTitle:SetJustifyH("LEFT")
	savedTitle:SetText(W.T("GEAR_CHECK_SAVED_TITLE"))
	page.savedTitle = savedTitle

	local savedDeleteBtn = W.CreatePlainButton(savedHost, 88, 20, W.T("GEAR_CHECK_SAVED_DELETE"))
	savedDeleteBtn:SetPoint("TOPRIGHT", -8, -4)
	savedDeleteBtn:Disable()
	savedDeleteBtn:SetScript("OnClick", function()
		DeleteViewingSaved(page)
	end)
	page.savedDeleteBtn = savedDeleteBtn

	local savedScroll = CreateFrame("ScrollFrame", nil, savedHost)
	savedScroll:SetPoint("TOPLEFT", 8, -26)
	savedScroll:SetPoint("BOTTOMRIGHT", -8, 6)
	page.savedScroll = savedScroll

	local savedContent = CreateFrame("Frame", nil, savedScroll)
	savedContent:SetWidth(math.max(100, innerW - 32))
	savedContent:SetHeight(18)
	savedScroll:SetScrollChild(savedContent)
	page.savedContent = savedContent

	local savedEmptyLabel = savedContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	savedEmptyLabel:SetPoint("TOPLEFT", 0, 0)
	savedEmptyLabel:SetWidth(savedContent:GetWidth())
	savedEmptyLabel:SetJustifyH("LEFT")
	savedEmptyLabel:SetText(W.T("GEAR_CHECK_SAVED_EMPTY"))
	W.SetFontColor(savedEmptyLabel, UI.TEXT_DISABLED)
	page.savedEmptyLabel = savedEmptyLabel

	-- Breakdown scroll
	local breakHost = CreateFrame("Frame", nil, page)
	breakHost:SetPoint("TOPLEFT", savedHost, "BOTTOMLEFT", 0, -6)
	breakHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(breakHost, UI.PANEL_BG)
	page.breakHost = breakHost

	local breakScrollName = "RaidwiseGearCheckBreakScrollV" .. tostring(LAYOUT_VERSION)
	local existingBreak = _G[breakScrollName]
	if existingBreak then
		existingBreak:Hide()
		existingBreak:SetParent(nil)
	end
	local breakScroll = CreateFrame("ScrollFrame", breakScrollName, breakHost)
	breakScroll:SetPoint("TOPLEFT", 8, -8)
	breakScroll:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 6), 8)
	breakScroll:EnableMouseWheel(true)
	page.breakScroll = breakScroll

	local breakContent = CreateFrame("Frame", nil, breakScroll)
	breakContent:SetWidth(math.max(100, innerW - UI.CD_SCROLLBAR_W - 28))
	breakContent:SetHeight(1)
	breakScroll:SetScrollChild(breakContent)
	page.breakContent = breakContent
	page.breakRows = {}

	local breakBar
	if W.CreateCooldownScrollBar then
		breakBar = W.CreateCooldownScrollBar(breakHost, "VERTICAL")
	else
		breakBar = CreateFrame("Slider", nil, breakHost)
		breakBar:SetOrientation("VERTICAL")
		breakBar:SetWidth(UI.CD_SCROLLBAR_W)
	end
	breakBar:SetPoint("TOPRIGHT", -2, -2)
	breakBar:SetPoint("BOTTOMRIGHT", -2, 2)
	breakBar:SetMinMaxValues(0, 0)
	breakBar:SetValue(0)
	breakBar:SetScript("OnValueChanged", function(self)
		breakScroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.breakBar = breakBar

	breakScroll:SetScript("OnMouseWheel", function(self, delta)
		local maxV = math.max(0, (breakContent:GetHeight() or 0) - (self:GetHeight() or 0))
		local nextValue = math.max(0, math.min(maxV, (self:GetVerticalScroll() or 0) - delta * 36))
		self:SetVerticalScroll(nextValue)
		breakBar:SetValue(nextValue)
	end)
	breakScroll:SetScript("OnSizeChanged", function()
		if page.breakContent then
			page.breakContent:SetWidth(math.max(100, (breakScroll:GetWidth() or innerW) - 4))
		end
		if page.lastReport then
			ApplyBreakdown(page, page.lastReport)
		end
	end)

	-- Debug dump (hidden by default)
	local dumpBox, copyHost = W.CreateCopyBox(
		page,
		"RaidwiseGearCheckScrollV" .. tostring(LAYOUT_VERSION),
		"RaidwiseGearCheckBoxV" .. tostring(LAYOUT_VERSION)
	)
	copyHost:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	copyHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	copyHost:Hide()
	page.dumpBox = dumpBox
	page.copyHost = copyHost

	ApplySummary(page, nil)
	ApplyBreakdown(page, nil)
	UpdateDebugVisibility(page)
	RefreshSavedList(page)

	page.layoutVersion = LAYOUT_VERSION
	return page
end

local function ApplyLocale(page)
	if not page then
		return
	end
	if page.desc then
		page.desc:SetText(W.T("GEAR_CHECK_TARGET_DESC"))
	end
	if page.limit then
		page.limit:SetText(W.T("GEAR_CHECK_LIMITATION"))
	end
	if page.scanBtn and page.scanBtn.label then
		page.scanBtn.label:SetText(W.T("GEAR_CHECK_SCAN"))
	end
	if page.saveBtn and page.saveBtn.label then
		page.saveBtn.label:SetText(W.T("GEAR_CHECK_SAVE"))
	end
	if page.debugBtn and page.debugBtn.label then
		page.debugBtn.label:SetText(page.debugMode and W.T("GEAR_CHECK_DEBUG_ON") or W.T("GEAR_CHECK_DEBUG"))
	end
	if page.selectBtn and page.selectBtn.label then
		page.selectBtn.label:SetText(W.T("BTN_SELECT_ALL"))
	end
	local buttons = page.filterButtons or {}
	for index = 1, #buttons do
		local btn = buttons[index]
		local info = FILTERS[index]
		if btn and btn.label and info then
			btn.label:SetText(W.T(info.labelKey))
		end
	end
	local reportButtons = page.reportButtons or {}
	for index = 1, #reportButtons do
		local btn = reportButtons[index]
		local info = REPORT_BUTTONS[index]
		if btn and btn.label and info then
			btn.label:SetText(W.T(info.labelKey))
		end
	end
	if page.savedTitle then
		page.savedTitle:SetText(W.T("GEAR_CHECK_SAVED_TITLE"))
	end
	if page.savedDeleteBtn and page.savedDeleteBtn.label then
		page.savedDeleteBtn.label:SetText(W.T("GEAR_CHECK_SAVED_DELETE"))
	end
	if page.savedEmptyLabel then
		page.savedEmptyLabel:SetText(W.T("GEAR_CHECK_SAVED_EMPTY"))
	end
	if page.statusLabel and not page.lastReport then
		page.statusLabel:SetText(W.T("GEAR_CHECK_HINT"))
	end
	if page.lastReport then
		ApplyReportToPage(page, page.lastReport, page.lastStatus or "ok")
	else
		ApplySummary(page, nil)
		ApplyBreakdown(page, nil)
	end
end

function Addon:SelectGearCheckDump()
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.geartarget
	if not page or not page.dumpBox then
		return
	end
	page.debugMode = true
	UpdateDebugVisibility(page)
	local text = page.dumpBox:GetText() or ""
	if text == "" then
		return
	end
	self:SelectTab("geartarget")
	page.dumpBox:SetFocus()
	page.dumpBox:HighlightText()
end

function Addon:RefreshGearCheckTargetView(autoScan)
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.geartarget
	if not page then
		return
	end
	if autoScan then
		RunScan(page)
	elseif self.GetLastGearCheckReport then
		local report = self:GetLastGearCheckReport()
		if report then
			ApplyReportToPage(page, report, report.scanStatus or "ok")
		end
	end
end

function Addon:OpenGearCheckTarget(autoScan)
	self:ShowMainFrame()
	self:SelectTab("geartarget")
	if autoScan ~= false then
		self:RefreshGearCheckTargetView(true)
	end
end

Addon.Pages.GearCheckTarget = {
	id = "geartarget",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateGearCheckTargetPage,
	ApplyLocale = ApplyLocale,
}
