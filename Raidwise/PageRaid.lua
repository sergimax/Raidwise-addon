-- PageRaid

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 1

local RAID_CELL_W = 168
local RAID_CELL_H = 106
local RAID_CELL_GAP = 2
local RAID_CELL_PAD = 4
local RAID_LINE_H = 14
local RAID_ICON = 20
local RAID_GROUP_LABEL_H = 16
local RAID_BLOCK_GAP = 12

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
	local tank = roles.tank or {}
	local healer = roles.healer or {}
	local melee = roles.melee or {}
	local ranged = roles.ranged or {}

	page.statsLabel:SetText(FormatRaidAverageGs(overall.gearScore))

	if page.roleStatsLabel then
		page.roleStatsLabel:SetText(
			FormatRoleGsSummary(W.T("ROLE_TANKS"), tank)
				.. "     "
				.. FormatRoleGsSummary(W.T("ROLE_HEALERS"), healer)
				.. "     "
				.. FormatRoleGsSummary(W.T("ROLE_MELEE_SHORT"), melee)
				.. "     "
				.. FormatRoleGsSummary(W.T("ROLE_RANGE"), ranged)
		)
	end
end

local function CreateRaidStatsLabels(page)
	local stats = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	stats:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -(UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE))
	stats:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	stats:SetHeight(UI.ROSTER_STATS_H)
	stats:SetJustifyH("LEFT")
	stats:SetJustifyV("MIDDLE")
	W.SetFontColor(stats, UI.TEXT_IDLE)
	stats:SetText(FormatRaidAverageGs(nil))
	page.statsLabel = stats

	local roleStats = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	roleStats:SetPoint("TOPLEFT", page.statsLabel, "BOTTOMLEFT", 0, 0)
	roleStats:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	roleStats:SetHeight(UI.ROSTER_STATS_H)
	roleStats:SetJustifyH("LEFT")
	roleStats:SetJustifyV("MIDDLE")
	W.SetFontColor(roleStats, UI.TEXT_IDLE)
	roleStats:SetText(
		FormatRoleGsSummary(W.T("ROLE_TANKS"))
			.. "     "
			.. FormatRoleGsSummary(W.T("ROLE_HEALERS"))
			.. "     "
			.. FormatRoleGsSummary(W.T("ROLE_MELEE_SHORT"))
			.. "     "
			.. FormatRoleGsSummary(W.T("ROLE_RANGE"))
	)
	page.roleStatsLabel = roleStats
	return page.statsLabel
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

	cell:SetScript("OnEnter", function(self)
		if not self.member then
			return
		end
		self:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		W.ShowMemberRatingTooltip(self, self.member)
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

local function CreateRaidGroupColumn(parent, groupIndex)
	local column = CreateFrame("Frame", nil, parent)
	column:SetSize(RAID_CELL_W, RaidBlockHeight())

	local label = column:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 0, 0)
	label:SetPoint("TOPRIGHT", 0, 0)
	label:SetHeight(RAID_GROUP_LABEL_H)
	label:SetJustifyH("CENTER")
	label:SetText(tostring(groupIndex))
	W.SetFontColor(label, UI.GOLD)
	column.label = label

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

local function FillRaidPlayerCell(cell, member, stripe)
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
	cell:Show()
end

local function CreateRaidRosterPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -100, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText(W.T("RAID_HINT"))

	local refreshBtn = W.CreatePlainButton(page, 96, UI.CD_TOOLBAR_H, W.T("BTN_REFRESH"))
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon:RefreshPartyData(true)
	end)

	CreateRaidStatsLabels(page)

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

	page.hint = hint
	page.refreshBtn = refreshBtn
	page.layoutVersion = LAYOUT_VERSION
	W.AttachPageLayoutBadge(page, LAYOUT_VERSION, page.refreshBtn)
	return page
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
	local blocks = { page.topBlock, page.bottomBlock }
	for blockIndex = 1, #blocks do
		local block = blocks[blockIndex]
		for groupIndex, column in pairs(block.columns) do
			local slots = groups[groupIndex] or {}
			for slot = 1, 5 do
				local stripe = (slot % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
				FillRaidPlayerCell(column.cells[slot], slots[slot], stripe)
			end
		end
	end

	local contentW, contentH = RaidContentSize()
	page.tableContent:SetSize(contentW, contentH)
	W.LayoutTableScrollBars(page)
end

Addon.Pages.Raid = {
	id = "raid",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateRaidRosterPage,
}
