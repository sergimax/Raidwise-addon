-- PageParty

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 1

local PARTY_COL_NAME = 90
local PARTY_COL_CLASS = 28
local PARTY_COL_SPEC = 28
local PARTY_COL_BUFFS = 166
local PARTY_COL_GS = 52
local PARTY_COL_ILVL = 44
local PARTY_COL_OPINION = 60
local PARTY_COL_TAGS = 100
local PARTY_COL_GUILD = 176

local function PartyTableWidth()
	return PARTY_COL_NAME + PARTY_COL_CLASS + PARTY_COL_SPEC + PARTY_COL_BUFFS
		+ PARTY_COL_GS + PARTY_COL_ILVL + PARTY_COL_OPINION + PARTY_COL_TAGS + PARTY_COL_GUILD
end

local function PartyColumnOffset(index)
	local widths = {
		PARTY_COL_NAME,
		PARTY_COL_CLASS,
		PARTY_COL_SPEC,
		PARTY_COL_BUFFS,
		PARTY_COL_GS,
		PARTY_COL_ILVL,
		PARTY_COL_OPINION,
		PARTY_COL_TAGS,
		PARTY_COL_GUILD,
	}
	local offset = 0
	for column = 1, index - 1 do
		offset = offset + widths[column]
	end
	return offset
end

local PARTY_COLUMN_WIDTHS = {
	PARTY_COL_NAME,
	PARTY_COL_CLASS,
	PARTY_COL_SPEC,
	PARTY_COL_BUFFS,
	PARTY_COL_GS,
	PARTY_COL_ILVL,
	PARTY_COL_OPINION,
	PARTY_COL_TAGS,
	PARTY_COL_GUILD,
}

local function FormatRosterAverages(gearScore, averageIlvl)
	local ilvlText = averageIlvl ~= nil and tostring(averageIlvl) or "-"
	local gsText = gearScore ~= nil and tostring(gearScore) or "-"
	return W.T("AVG_ILVL_GS", ilvlText, gsText)
end

local function CreateRosterStatsLabel(page)
	local stats = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	stats:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -(UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE))
	stats:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	stats:SetHeight(UI.ROSTER_STATS_H)
	stats:SetJustifyH("LEFT")
	stats:SetJustifyV("MIDDLE")
	W.SetFontColor(stats, UI.TEXT_IDLE)
	stats:SetText(FormatRosterAverages(nil, nil))
	page.statsLabel = stats
	return stats
end

local function UpdateRosterStatsLabel(page, members)
	if not page or not page.statsLabel then
		return
	end
	local averageGs, averageIlvl
	if Addon.AverageRosterStats then
		averageGs, averageIlvl = Addon:AverageRosterStats(members)
	end
	page.statsLabel:SetText(FormatRosterAverages(averageGs, averageIlvl))
end

local function CreatePartyRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(UI.CD_ROW_H)
	W.ApplyPlainPanel(row, UI.CD_ROW_A)
	row:EnableMouse(true)
	row:RegisterForClicks("LeftButtonUp")

	local function AddTextColumn(index, justify, insetLeft)
		local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("TOPLEFT", row, "TOPLEFT", PartyColumnOffset(index) + (insetLeft or 4), -4)
		text:SetWidth(PARTY_COLUMN_WIDTHS[index] - (insetLeft or 4) - 4)
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
		PartyColumnOffset(2) + W.TableIconInset(PARTY_COL_CLASS, UI.ROSTER_ICON),
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
		PartyColumnOffset(3) + W.TableIconInset(PARTY_COL_SPEC, UI.ROSTER_ICON),
		W.TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.specIcon = row.specIconHost:CreateTexture(nil, "ARTWORK")
	row.specIcon:SetAllPoints(row.specIconHost)

	row.buffHosts = {}
	for buffIndex = 1, UI.RAID_BUFF_MAX do
		local host = W.CreateBuffIconHost(row)
		local x = PartyColumnOffset(4) + 4 + (buffIndex - 1) * (UI.RAID_BUFF_ICON + UI.RAID_BUFF_GAP)
		host:SetPoint("TOPLEFT", row, "TOPLEFT", x, W.TableIconTopOffset(UI.RAID_BUFF_ICON))
		row.buffHosts[buffIndex] = host
	end

	row.gsText = AddTextColumn(5, "CENTER")
	row.ilvlText = AddTextColumn(6, "CENTER")
	row.opinionText = AddTextColumn(7, "CENTER")
	row.tagText = AddTextColumn(8, "LEFT")
	row.guildText = AddTextColumn(9, "LEFT")

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
		local stripe = UI.BTN_HOVER
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		W.ShowMemberRatingTooltip(self, self.member)
	end)
	row:SetScript("OnLeave", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		GameTooltip:Hide()
	end)
	row:SetScript("OnClick", function(self)
		if self.member then
			Addon:ShowRaidCharacterWindow(self.member)
		end
	end)

	return row
end

local function CreatePartyPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -100, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText(W.T("PARTY_HINT"))

	local refreshBtn = W.CreatePlainButton(page, 96, UI.CD_TOOLBAR_H, W.T("BTN_REFRESH"))
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon:RefreshPartyData(true)
	end)

	CreateRosterStatsLabel(page)

	local tableTop = -W.RosterTableTopOffset()

	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwisePartyScrollV" .. tostring(LAYOUT_VERSION), tableHost)
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

	local headers = {
		W.T("COL_NAME"), W.T("COL_CLASS"), W.T("COL_SPEC"), W.T("COL_BUFFS"),
		W.T("COL_GS"), W.T("COL_ILVL"), W.T("COL_OPINION"), W.T("COL_TAGS"), W.T("COL_GUILD"),
	}
	page.headerKeys = {
		"COL_NAME", "COL_CLASS", "COL_SPEC", "COL_BUFFS",
		"COL_GS", "COL_ILVL", "COL_OPINION", "COL_TAGS", "COL_GUILD",
	}
	page.headerLabels = {}
	for index = 1, #headers do
		local label = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", headerBg, "TOPLEFT", PartyColumnOffset(index) + 4, -10)
		label:SetWidth(PARTY_COLUMN_WIDTHS[index] - 8)
		label:SetJustifyH((index >= 5 and index <= 7) and "CENTER" or "LEFT")
		label:SetText(headers[index])
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
		Addon:RefreshPartyView(true)
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
	page.layoutVersion = LAYOUT_VERSION
	return page
end

function Addon:RefreshPartyView(refreshGearScore)
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.party
	if not page then
		return
	end

	if not self.BuildPartyRoster then
		if page.hint then
			page.hint:SetText(W.T("PARTY_FAIL"))
		end
		return
	end

	page.tableHost:Show()

	local roster = self:BuildPartyRoster(refreshGearScore)
	UpdateRosterStatsLabel(page, roster)
	local content = page.tableContent
	local headerBg = page.headerBg
	local tableW = PartyTableWidth()
	local tableH = UI.CD_HEADER_H + math.max(#roster, 1) * UI.CD_ROW_H

	content:SetSize(tableW, tableH)
	headerBg:SetWidth(tableW)

	W.HidePoolFrom(page.rowFrames, #roster + 1)
	for rowIndex = 1, #roster do
		local member = roster[rowIndex]
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreatePartyRow(content)
			page.rowFrames[rowIndex] = row
		end

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(UI.CD_HEADER_H + (rowIndex - 1) * UI.CD_ROW_H))
		row:SetSize(tableW, UI.CD_ROW_H)
		local stripe = (rowIndex % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
		row.stripe = stripe
		row:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		row.member = member

		row.nameText:SetText(member.name)
		row.nameText:SetTextColor(W.ClassColor(member.class))
		row.classLabel = member.classLabel
		row.specLabel = member.spec
		W.SetSpecOrClassIcon(row.classIcon, nil, member.class)
		W.SetSpecOrClassIcon(row.specIcon, member.specIcon, member.class)
		W.FillRaidBuffIcons(row.buffHosts, member.raidBuffs)

		if member.gearScore then
			row.gsText:SetText(tostring(member.gearScore))
			W.SetFontColor(row.gsText, UI.GOLD)
		else
			row.gsText:SetText("-")
			W.SetFontColor(row.gsText, UI.TEXT_DISABLED)
		end

		if member.averageIlvl then
			row.ilvlText:SetText(tostring(member.averageIlvl))
			W.SetFontColor(row.ilvlText, UI.TEXT_IDLE)
		else
			row.ilvlText:SetText("-")
			W.SetFontColor(row.ilvlText, UI.TEXT_DISABLED)
		end

		row.opinionText:SetText(W.RatingOpinionSymbol(member))
		W.SetFontColor(row.opinionText, W.RatingOpinionColor(member))

		local tags = W.FormatTagLine(member)
		if tags ~= "" then
			row.tagText:SetText(tags)
			W.SetFontColor(row.tagText, UI.TEXT_IDLE)
		else
			row.tagText:SetText("-")
			W.SetFontColor(row.tagText, UI.TEXT_DISABLED)
		end

		row.guildText:SetText(W.FormatGuildDisplay(member.guildName, member.guildRank))
		W.SetFontColor(row.guildText, UI.TEXT_IDLE)
		row:Show()
	end

	W.LayoutTableScrollBars(page)
end

Addon.Pages.Party = {
	id = "party",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreatePartyPage,
}
