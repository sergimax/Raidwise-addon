-- PageComposition

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 4

local COMP_COLS = 3
local COMP_COL_GAP = 12
local COMP_SECTION_GAP = 10
local COMP_HEADING_H = 20
local COMP_ROW_H = 20
local COMP_ICON = 16
local COMP_COUNT_W = 22
local COMP_CHIP_GAP = 6
local COMP_TOP_GAP = 12
local COMP_CLASS_ICON = 16
local COMP_CHIP_W = 34
local COMP_SUMMARY_COL_GAP = 24
local COMP_ROLES_COL_W = 4 * COMP_CHIP_W + 3 * COMP_CHIP_GAP

local COMP_ROLE_KEYS = {
	tank = "ROLE_TANKS",
	healer = "ROLE_HEALERS",
	melee = "ROLE_MELEE_SHORT",
	ranged = "ROLE_RANGE",
}

local function SpellTexture(spellId)
	if type(GetSpellInfo) == "function" and spellId then
		local _, _, icon = GetSpellInfo(spellId)
		if icon and icon ~= "" then
			return icon
		end
	end
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function JoinNames(names)
	if not names or #names == 0 then
		return W.T("COMP_NONE")
	end
	return table.concat(names, ", ")
end

local function LayoutCompositionScrollBars(page)
	local scroll = page.scroll
	local content = page.tableContent
	local vBar = page.vBar
	if not scroll or not content or not vBar then
		return
	end
	local viewH = scroll:GetHeight() or 0
	local childH = content:GetHeight() or 0
	local maxV = math.max(0, childH - viewH)
	vBar:SetMinMaxValues(0, maxV)
	if maxV > 0 then
		vBar:Show()
		local current = math.min(scroll:GetVerticalScroll() or 0, maxV)
		vBar:SetValue(current)
		scroll:SetVerticalScroll(current)
	else
		vBar:SetValue(0)
		vBar:Hide()
		scroll:SetVerticalScroll(0)
	end
end

local function CreateCompositionHeading(parent)
	local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	heading:SetHeight(COMP_HEADING_H)
	heading:SetJustifyH("LEFT")
	heading:SetJustifyV("MIDDLE")
	W.SetFontColor(heading, UI.GOLD)
	return heading
end

local function CreateCompositionRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(COMP_ROW_H)
	row:EnableMouse(true)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(COMP_ICON, COMP_ICON)
	icon:SetPoint("LEFT", 2, 0)
	row.icon = icon

	local count = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	count:SetPoint("RIGHT", -2, 0)
	count:SetWidth(COMP_COUNT_W)
	count:SetJustifyH("RIGHT")
	row.count = count

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	name:SetPoint("RIGHT", count, "LEFT", -4, 0)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	row.name = name

	row:SetScript("OnEnter", function(self)
		if not self.tooltipTitle then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tooltipTitle)
		if self.tooltipProviders then
			GameTooltip:AddLine(self.tooltipProviders, 0.8, 0.8, 0.8, true)
		end
		if self.tooltipSources then
			GameTooltip:AddLine(self.tooltipSources, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return row
end

local function CreateClassIconChip(parent)
	local chip = CreateFrame("Frame", nil, parent)
	chip:SetSize(COMP_CHIP_W, COMP_ROW_H)
	chip:EnableMouse(true)

	local icon = chip:CreateTexture(nil, "ARTWORK")
	icon:SetSize(COMP_CLASS_ICON, COMP_CLASS_ICON)
	icon:SetPoint("LEFT", 0, 0)
	chip.icon = icon

	local count = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	count:SetPoint("LEFT", icon, "RIGHT", 2, 0)
	count:SetPoint("RIGHT", chip, "RIGHT", 0, 0)
	count:SetJustifyH("LEFT")
	count:SetJustifyV("MIDDLE")
	chip.count = count

	chip:SetScript("OnEnter", function(self)
		if not self.tooltipTitle then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tooltipTitle)
		if self.tooltipProviders then
			GameTooltip:AddLine(self.tooltipProviders, 0.8, 0.8, 0.8, true)
		end
		GameTooltip:Show()
	end)
	chip:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return chip
end

local function CreateRoleChip(parent)
	local chip = CreateFrame("Frame", nil, parent)
	chip:SetSize(COMP_CHIP_W, COMP_ROW_H)
	chip:EnableMouse(true)

	local icon = chip:CreateTexture(nil, "ARTWORK")
	icon:SetSize(COMP_ICON, COMP_ICON)
	icon:SetPoint("LEFT", 0, 0)
	chip.icon = icon

	local count = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	count:SetPoint("LEFT", icon, "RIGHT", 2, 0)
	count:SetPoint("RIGHT", chip, "RIGHT", 0, 0)
	count:SetJustifyH("LEFT")
	count:SetJustifyV("MIDDLE")
	chip.count = count

	chip:SetScript("OnEnter", function(self)
		if not self.tooltipTitle then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tooltipTitle)
		if self.tooltipProviders then
			GameTooltip:AddLine(self.tooltipProviders, 0.8, 0.8, 0.8, true)
		end
		GameTooltip:Show()
	end)
	chip:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return chip
end

local function CreateCompositionPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -100, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText(W.T("COMP_HINT"))

	local refreshBtn = W.CreatePlainButton(page, 96, UI.CD_TOOLBAR_H, W.T("BTN_REFRESH"))
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon:RefreshPartyData(true)
	end)

	local tableTop = -W.CooldownTableTopOffset()

	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseCompositionScrollV" .. tostring(LAYOUT_VERSION), tableHost)
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 4), 6)
	scroll:EnableMouseWheel(true)
	page.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	page.tableContent = content
	page.headings = {}
	page.rows = {}
	page.classIcons = {}
	page.roleChips = {}

	local vBar = W.CreateCooldownScrollBar(tableHost, "VERTICAL")
	vBar:SetPoint("TOPRIGHT", -1, -1)
	vBar:SetPoint("BOTTOMRIGHT", -1, 1)
	vBar:SetScript("OnValueChanged", function(self)
		scroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.vBar = vBar

	scroll:SetScript("OnMouseWheel", function(self, delta)
		local maxV = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
		local step = COMP_ROW_H * 3
		local nextValue = math.max(0, math.min(maxV, (self:GetVerticalScroll() or 0) - delta * step))
		self:SetVerticalScroll(nextValue)
		vBar:SetValue(nextValue)
	end)
	scroll:SetScript("OnSizeChanged", function()
		if Addon.RefreshCompositionView then
			Addon:RefreshCompositionView(false)
		end
	end)

	page:SetScript("OnShow", function()
		if Addon.RefreshCompositionView then
			Addon:RefreshCompositionView(false)
		end
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
	page.layoutVersion = LAYOUT_VERSION
	return page
end

function Addon:RefreshCompositionView(refreshGearScore)
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.composition
	if not page then
		return
	end
	if page.layouting then
		return
	end
	page.layouting = true

	if not self.AnalyzeRaidComposition or not self.CompositionMembers then
		if page.hint then
			page.hint:SetText(W.T("COMP_FAIL"))
		end
		page.layouting = nil
		return
	end

	if page.hint then
		page.hint:SetText(W.T("COMP_HINT"))
	end

	local analysis = self:AnalyzeRaidComposition(self:CompositionMembers(refreshGearScore))
	local content = page.tableContent
	local viewW = page.scroll:GetWidth() or W.ContentInnerWidth()
	if viewW < 100 then
		viewW = W.ContentInnerWidth() - UI.CD_SCROLLBAR_W - 10
	end
	local cols = COMP_COLS
	local colW = math.floor((viewW - COMP_COL_GAP * (cols - 1)) / cols)
	if colW < 80 then
		colW = 80
	end

	page.classIcons = page.classIcons or {}
	page.roleChips = page.roleChips or {}

	local headingIndex = 0
	local function NextHeading()
		headingIndex = headingIndex + 1
		local heading = page.headings[headingIndex]
		if not heading then
			heading = CreateCompositionHeading(content)
			page.headings[headingIndex] = heading
		end
		return heading
	end

	local yTop = 0
	local classesX = COMP_ROLES_COL_W + COMP_SUMMARY_COL_GAP

	-- Roles (left) + Classes (right) on one summary band
	local rolesHeading = NextHeading()
	rolesHeading:ClearAllPoints()
	rolesHeading:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yTop)
	rolesHeading:SetWidth(COMP_ROLES_COL_W)
	rolesHeading:SetText(W.T("COMP_SECTION_ROLES"))
	rolesHeading:Show()

	local classHeading = NextHeading()
	classHeading:ClearAllPoints()
	classHeading:SetPoint("TOPLEFT", content, "TOPLEFT", classesX, yTop)
	classHeading:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, yTop)
	classHeading:SetText(W.T("COMP_SECTION_CLASSES"))
	classHeading:Show()
	yTop = yTop - COMP_HEADING_H

	local roleOrder = analysis.roleOrder or {}
	W.HidePoolFrom(page.roleChips, #roleOrder + 1)
	for roleIndex = 1, #roleOrder do
		local role = roleOrder[roleIndex]
		local bucket = (analysis.roles and analysis.roles[role]) or {}
		local count = bucket.count or 0
		local chip = page.roleChips[roleIndex]
		if not chip then
			chip = CreateRoleChip(content)
			page.roleChips[roleIndex] = chip
		end
		chip:ClearAllPoints()
		chip:SetPoint(
			"TOPLEFT",
			content,
			"TOPLEFT",
			(roleIndex - 1) * (COMP_CHIP_W + COMP_CHIP_GAP),
			yTop
		)
		chip.icon:SetTexture(
			(self.RaidRoleIcon and self:RaidRoleIcon(role)) or "Interface\\Icons\\INV_Misc_QuestionMark"
		)
		chip.count:SetText(tostring(count))
		local roleName = W.T(COMP_ROLE_KEYS[role] or "ROLE_UNKNOWN")
		chip.tooltipTitle = roleName
		if count > 0 then
			W.SetFontColor(chip.count, UI.GOLD)
			chip.icon:SetVertexColor(1, 1, 1, 1)
			chip.tooltipProviders = W.T("COMP_PROVIDERS", JoinNames(bucket.names))
		else
			W.SetFontColor(chip.count, UI.TEXT_DISABLED)
			chip.icon:SetVertexColor(
				UI.TEXT_DISABLED[1],
				UI.TEXT_DISABLED[2],
				UI.TEXT_DISABLED[3],
				1
			)
			chip.tooltipProviders = W.T("COMP_MISSING")
		end
		chip:Show()
	end

	local classes = analysis.classes or {}
	W.HidePoolFrom(page.classIcons, #classes + 1)
	for classIndex = 1, #classes do
		local entry = classes[classIndex]
		local count = entry.count or 0
		local chip = page.classIcons[classIndex]
		if not chip then
			chip = CreateClassIconChip(content)
			page.classIcons[classIndex] = chip
		end
		chip:ClearAllPoints()
		chip:SetPoint(
			"TOPLEFT",
			content,
			"TOPLEFT",
			classesX + (classIndex - 1) * (COMP_CHIP_W + COMP_CHIP_GAP),
			yTop
		)
		W.SetSpecOrClassIcon(chip.icon, nil, entry.class)
		chip.count:SetText(tostring(count))
		chip.tooltipTitle = entry.label or entry.class
		if entry.present then
			chip.icon:SetVertexColor(1, 1, 1, 1)
			W.SetFontColor(chip.count, UI.GOLD)
			chip.tooltipProviders = W.T("COMP_PROVIDERS", JoinNames(entry.names))
		else
			chip.icon:SetVertexColor(
				UI.TEXT_DISABLED[1],
				UI.TEXT_DISABLED[2],
				UI.TEXT_DISABLED[3],
				1
			)
			W.SetFontColor(chip.count, UI.TEXT_DISABLED)
			chip.tooltipProviders = W.T("COMP_MISSING")
		end
		chip:Show()
	end
	yTop = yTop - COMP_ROW_H - COMP_TOP_GAP

	-- Masonry effect sections (no Roles)
	local blocks = {}
	for sectionIndex = 1, #analysis.sections do
		local section = analysis.sections[sectionIndex]
		local block = {
			headingKey = section.labelKey,
			rows = {},
		}
		for effectIndex = 1, #section.effects do
			local effect = section.effects[effectIndex]
			block.rows[#block.rows + 1] = {
				name = effect.label or W.T(effect.labelKey),
				count = effect.count or 0,
				icon = SpellTexture(effect.spellId),
				providers = effect.providers,
				sources = effect.sourceLabels,
			}
		end
		blocks[#blocks + 1] = block
	end

	local rowNeeded = 0
	for blockIndex = 1, #blocks do
		rowNeeded = rowNeeded + #blocks[blockIndex].rows
	end
	W.HidePoolFrom(page.rows, rowNeeded + 1)

	local colHeights = {}
	for col = 1, cols do
		colHeights[col] = -yTop
	end

	local rowIndex = 0

	local function PlaceHeight(height)
		local best = 1
		for col = 2, cols do
			if colHeights[col] < colHeights[best] then
				best = col
			end
		end
		local x = (best - 1) * (colW + COMP_COL_GAP)
		local y = -colHeights[best]
		colHeights[best] = colHeights[best] + height + COMP_SECTION_GAP
		return x, y
	end

	for blockIndex = 1, #blocks do
		local block = blocks[blockIndex]
		local blockH = COMP_HEADING_H + #block.rows * COMP_ROW_H
		local x, y = PlaceHeight(blockH)

		local heading = NextHeading()
		heading:ClearAllPoints()
		heading:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
		heading:SetWidth(colW)
		heading:SetText(W.T(block.headingKey))
		heading:Show()

		for itemIndex = 1, #block.rows do
			rowIndex = rowIndex + 1
			local item = block.rows[itemIndex]
			local row = page.rows[rowIndex]
			if not row then
				row = CreateCompositionRow(content)
				page.rows[rowIndex] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", content, "TOPLEFT", x, y - COMP_HEADING_H - (itemIndex - 1) * COMP_ROW_H)
			row:SetSize(colW, COMP_ROW_H)
			row.icon:SetTexture(item.icon)
			row.icon:SetVertexColor(1, 1, 1, 1)
			row.name:SetText(item.name)
			row.count:SetText(tostring(item.count or 0))
			if (item.count or 0) > 0 then
				W.SetFontColor(row.name, UI.GOLD)
				W.SetFontColor(row.count, UI.GOLD)
			else
				W.SetFontColor(row.name, UI.TEXT_DISABLED)
				W.SetFontColor(row.count, UI.TEXT_DISABLED)
			end
			row.tooltipTitle = item.name
			if (item.count or 0) > 0 then
				row.tooltipProviders = W.T("COMP_PROVIDERS", JoinNames(item.providers))
			else
				row.tooltipProviders = W.T("COMP_MISSING")
			end
			if item.sources then
				row.tooltipSources = W.T("COMP_CAN_BRING", JoinNames(item.sources))
			else
				row.tooltipSources = nil
			end
			row:Show()
		end
	end

	W.HidePoolFrom(page.headings, headingIndex + 1)

	local contentH = 0
	for col = 1, cols do
		if colHeights[col] > contentH then
			contentH = colHeights[col]
		end
	end
	content:SetSize(viewW, math.max(contentH, 1))
	LayoutCompositionScrollBars(page)
	page.layouting = nil
end

Addon.Pages.Composition = {
	id = "composition",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateCompositionPage,
}
