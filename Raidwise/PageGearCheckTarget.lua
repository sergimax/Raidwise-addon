-- PageGearCheckTarget — Phase 4 dump (per-slot verdicts; overall status later).

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 2

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

local function ApplyDumpToPage(page, report, status)
	if not page then
		return
	end
	if page.statusLabel then
		page.statusLabel:SetText(StatusTextForScan(report, status))
	end
	if page.dumpBox and Addon.FormatGearCheckDump then
		page.dumpBox:SetText(Addon:FormatGearCheckDump(report))
	elseif page.dumpBox and Addon.FormatGearCheckPhase1Dump then
		page.dumpBox:SetText(Addon:FormatGearCheckPhase1Dump(report))
	end
	if page.selectBtn then
		if report and page.dumpBox and (page.dumpBox:GetText() or "") ~= "" then
			page.selectBtn:Enable()
		else
			page.selectBtn:Disable()
		end
	end
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
		ApplyDumpToPage(page, report, status)
		if page.scanBtn then
			page.scanBtn:Enable()
		end
	end)
end

local function CreateGearCheckTargetPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

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

	local buttonW = (innerW - UI.ACTION_BTN_GAP) / 2
	local scanBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("GEAR_CHECK_SCAN"))
	scanBtn:SetPoint("TOPLEFT", limit, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
	scanBtn:SetScript("OnClick", function()
		RunScan(page)
	end)
	page.scanBtn = scanBtn

	local selectBtn = W.CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, W.T("BTN_SELECT_ALL"))
	selectBtn:SetPoint("LEFT", scanBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
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

	local dumpBox, copyHost = W.CreateCopyBox(
		page,
		"RaidwiseGearCheckScrollV" .. tostring(LAYOUT_VERSION),
		"RaidwiseGearCheckBoxV" .. tostring(LAYOUT_VERSION)
	)
	copyHost:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	copyHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	page.dumpBox = dumpBox
	page.copyHost = copyHost

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
	if page.selectBtn and page.selectBtn.label then
		page.selectBtn.label:SetText(W.T("BTN_SELECT_ALL"))
	end
	if page.statusLabel and (not page.dumpBox or (page.dumpBox:GetText() or "") == "") then
		page.statusLabel:SetText(W.T("GEAR_CHECK_HINT"))
	end
end

function Addon:SelectGearCheckDump()
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.geartarget
	if not page or not page.dumpBox then
		return
	end
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
	elseif self.GetLastGearCheckReport and self.FormatGearCheckDump then
		local report = self:GetLastGearCheckReport()
		if report then
			ApplyDumpToPage(page, report, report.scanStatus or "ok")
		end
	elseif self.GetLastGearCheckReport and self.FormatGearCheckPhase1Dump then
		local report = self:GetLastGearCheckReport()
		if report then
			ApplyDumpToPage(page, report, report.scanStatus or "ok")
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
