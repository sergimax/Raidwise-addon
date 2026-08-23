-- PageCooldowns

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 3

local CD_INSTANCE_COL_W = 170
local CD_CHAR_COL_W = 90
local CD_CURRENCY_ROW_H = 72

local function FormatLastCheckTime(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then
		return "-"
	end
	if Addon.FormatShortDateTime then
		return Addon:FormatShortDateTime(timestamp)
	end
	return date("%d %b %H:%M", timestamp)
end

local function FormatLastCheckTooltip(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then
		return W.T("CD_LAST_CHECK_NONE")
	end
	if Addon.FormatHistoryTime then
		return W.T("CD_LAST_CHECK", Addon:FormatHistoryTime(timestamp))
	end
	return W.T("CD_LAST_CHECK", date("%Y-%m-%d %H:%M", timestamp))
end

local function CreateCooldownHeaderCell(parent)
	local cell = CreateFrame("Frame", nil, parent)
	cell:SetHeight(UI.CD_HEADER_H)

	local icon = cell:CreateTexture(nil, "ARTWORK")
	icon:SetSize(UI.CD_SPEC_ICON, UI.CD_SPEC_ICON)
	icon:SetPoint("TOPLEFT", 6, -4)
	cell.icon = icon

	local name = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 4, 0)
	name:SetPoint("RIGHT", cell, "RIGHT", -4, 0)
	name:SetHeight(14)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	cell.name = name

	local lastCheck = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lastCheck:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
	lastCheck:SetPoint("RIGHT", cell, "RIGHT", -4, 0)
	lastCheck:SetJustifyH("LEFT")
	W.SetFontColor(lastCheck, UI.TEXT_DISABLED)
	cell.lastCheck = lastCheck

	cell:EnableMouse(true)
	cell:SetScript("OnEnter", function(self)
		if not self.tooltipTitle then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tooltipTitle)
		if self.tooltipSpec then
			GameTooltip:AddLine(self.tooltipSpec, 0.8, 0.8, 0.8)
		end
		if self.tooltipLastCheck then
			GameTooltip:AddLine(self.tooltipLastCheck, 0.8, 0.8, 0.8)
		end
		GameTooltip:Show()
	end)
	cell:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return cell
end

local function CreateCooldownRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(UI.CD_ROW_H)
	W.ApplyPlainPanel(row, UI.CD_ROW_A)

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	name:SetPoint("TOPLEFT", 6, -4)
	name:SetPoint("RIGHT", row, "LEFT", CD_INSTANCE_COL_W - 4, 0)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("TOP")
	row.instanceName = name

	local typeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	typeLabel:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
	typeLabel:SetPoint("RIGHT", row, "LEFT", CD_INSTANCE_COL_W - 4, 0)
	typeLabel:SetJustifyH("LEFT")
	W.SetFontColor(typeLabel, UI.TEXT_IDLE)
	row.typeLabel = typeLabel

	row.cells = {}
	return row
end

local function RowHeight(rowData)
	if rowData and rowData.kind == "currency" then
		return CD_CURRENCY_ROW_H
	end
	return UI.CD_ROW_H
end

local function CreateCooldownValueCell(parent)
	local cell = CreateFrame("Frame", nil, parent)
	cell:SetHeight(UI.CD_ROW_H)

	local text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", 4, 0)
	text:SetPoint("RIGHT", -4, 0)
	text:SetJustifyH("CENTER")
	cell.text = text

	cell:EnableMouse(true)
	cell:SetScript("OnEnter", function(self)
		if not self.tooltipTitle then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tooltipTitle)
		if self.tooltipType and self.tooltipType ~= "" then
			GameTooltip:AddLine(self.tooltipType, 0.8, 0.8, 0.8)
		end
		if self.tooltipLines then
			for lineIndex = 1, #self.tooltipLines do
				GameTooltip:AddLine(self.tooltipLines[lineIndex], 1, 1, 1)
			end
		elseif self.tooltipBody then
			GameTooltip:AddLine(self.tooltipBody, 1, 1, 1)
		end
		GameTooltip:Show()
	end)
	cell:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return cell
end

local function ConfigureCurrencyCell(cell)
	cell:SetHeight(CD_CURRENCY_ROW_H)
	cell.text:ClearAllPoints()
	cell.text:SetPoint("TOPLEFT", 4, -4)
	cell.text:SetPoint("BOTTOMRIGHT", -4, 4)
	cell.text:SetJustifyH("LEFT")
	cell.text:SetJustifyV("TOP")
	cell.text:SetWidth(CD_CHAR_COL_W - 8)
end

local function ConfigureLockoutCell(cell, rowHeight)
	cell:SetHeight(rowHeight)
	cell.text:ClearAllPoints()
	cell.text:SetPoint("LEFT", 4, 0)
	cell.text:SetPoint("RIGHT", -4, 0)
	cell.text:SetJustifyH("CENTER")
	cell.text:SetJustifyV("MIDDLE")
	cell.text:SetWidth(0)
end

local function CreateCooldownsPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -100, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText(W.T("CD_HINT"))

	local refreshBtn = W.CreatePlainButton(page, 96, UI.CD_TOOLBAR_H, W.T("BTN_REFRESH"))
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon.pendingLockoutTable = true
		RequestRaidInfo()
		Addon:RefreshCooldownTable()
	end)

	local tableTop = -W.CooldownTableTopOffset()

	local emptyLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	emptyLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	emptyLabel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	emptyLabel:SetJustifyH("CENTER")
	emptyLabel:SetJustifyV("MIDDLE")
	W.SetFontColor(emptyLabel, UI.TEXT_IDLE)
	emptyLabel:SetText(W.T("CD_EMPTY"))
	page.emptyLabel = emptyLabel

	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseCooldownScrollV" .. tostring(LAYOUT_VERSION), tableHost)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), UI.CD_HSCROLL_H + 2)
	scroll:EnableMouseWheel(true)
	page.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	page.tableContent = content
	page.headerCells = {}
	page.rowFrames = {}

	local headerBg = CreateFrame("Frame", nil, content)
	headerBg:SetPoint("TOPLEFT", 0, 0)
	headerBg:SetHeight(UI.CD_HEADER_H)
	W.ApplyPlainPanel(headerBg, UI.TITLE_BG)
	page.headerBg = headerBg

	local instanceHeader = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	instanceHeader:SetPoint("LEFT", 6, 0)
	instanceHeader:SetText(W.T("CD_INSTANCE"))
	W.SetFontColor(instanceHeader, UI.GOLD)
	page.instanceHeader = instanceHeader

	local noRowsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	noRowsLabel:SetPoint("TOPLEFT", headerBg, "BOTTOMLEFT", 8, -10)
	noRowsLabel:SetPoint("RIGHT", content, "RIGHT", -8, 0)
	noRowsLabel:SetJustifyH("LEFT")
	W.SetFontColor(noRowsLabel, UI.TEXT_IDLE)
	noRowsLabel:SetText(W.T("CD_NO_ROWS"))
	noRowsLabel:Hide()
	page.noRowsLabel = noRowsLabel

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

	page.hint = hint
	page.refreshBtn = refreshBtn
	page.layoutVersion = LAYOUT_VERSION
	return page
end
-- Rebuild the cooldowns table from account SavedVariables.
function Addon:RefreshCooldownTable()
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.cooldowns
	if not page then
		return
	end

	self:SaveCurrentCharacterLockouts()

	local model = self:BuildCooldownTable()
	local characters = model.characters
	local rows = model.rows
	local lockoutRowCount = model.lockoutRowCount or 0
	local content = page.tableContent
	local headerBg = page.headerBg

	if #characters == 0 then
		page.emptyLabel:ClearAllPoints()
		page.emptyLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -W.CooldownTableTopOffset())
		page.emptyLabel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
		page.emptyLabel:SetText(W.T("CD_EMPTY"))
		page.emptyLabel:Show()
		page.tableHost:Hide()
		return
	end

	page.emptyLabel:Hide()
	page.tableHost:Show()

	local tableW = CD_INSTANCE_COL_W + (#characters * CD_CHAR_COL_W)
	local tableH = UI.CD_HEADER_H
	for rowIndex = 1, #rows do
		tableH = tableH + RowHeight(rows[rowIndex])
	end
	if tableH <= UI.CD_HEADER_H then
		tableH = UI.CD_HEADER_H + UI.CD_ROW_H
	end
	content:SetSize(tableW, tableH)
	headerBg:SetWidth(tableW)

	W.HidePoolFrom(page.headerCells, #characters + 1)
	for index = 1, #characters do
		local character = characters[index]
		local cell = page.headerCells[index]
		if not cell then
			cell = CreateCooldownHeaderCell(headerBg)
			page.headerCells[index] = cell
		end
		cell:ClearAllPoints()
		cell:SetPoint("TOPLEFT", headerBg, "TOPLEFT", CD_INSTANCE_COL_W + (index - 1) * CD_CHAR_COL_W, 0)
		cell:SetWidth(CD_CHAR_COL_W)
		cell.name:SetText(character.displayName)
		cell.name:SetTextColor(W.ClassColor(character.class))
		W.SetSpecOrClassIcon(cell.icon, character.specIcon, character.class)
		cell.lastCheck:SetText(FormatLastCheckTime(character.updatedAt))
		cell.tooltipTitle = character.displayName
		cell.tooltipSpec = character.spec ~= "" and character.spec or nil
		cell.tooltipLastCheck = FormatLastCheckTooltip(character.updatedAt)
		cell:Show()
	end

	W.HidePoolFrom(page.rowFrames, #rows + 1)
	local yOffset = UI.CD_HEADER_H
	for rowIndex = 1, #rows do
		local rowData = rows[rowIndex]
		local rowHeight = RowHeight(rowData)
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreateCooldownRow(content)
			page.rowFrames[rowIndex] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
		row:SetSize(tableW, rowHeight)
		yOffset = yOffset + rowHeight
		local stripe = (rowIndex % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
		row.stripe = stripe
		row:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		row.instanceName:SetText(rowData.name)
		row.typeLabel:SetText(rowData.typeLabel or "")

		W.HidePoolFrom(row.cells, #characters + 1)
		for colIndex = 1, #characters do
			local character = characters[colIndex]
			local cell = row.cells[colIndex]
			if not cell then
				cell = CreateCooldownValueCell(row)
				row.cells[colIndex] = cell
			end
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", row, "TOPLEFT", CD_INSTANCE_COL_W + (colIndex - 1) * CD_CHAR_COL_W, 0)
			cell:SetWidth(CD_CHAR_COL_W)

			local saved = rowData.cells[character.key]
			cell.tooltipTitle = rowData.name
			cell.tooltipType = rowData.typeLabel
			cell.tooltipLines = nil
			cell.tooltipBody = nil
			if rowData.kind == "currency" then
				ConfigureCurrencyCell(cell)
				if saved and saved.text then
					cell.text:SetText(saved.text)
					if saved.hasValue then
						W.SetFontColor(cell.text, UI.GOLD)
					else
						W.SetFontColor(cell.text, UI.TEXT_IDLE)
					end
					cell.tooltipLines = saved.tooltipLines
				else
					cell.text:SetText("-")
					W.SetFontColor(cell.text, UI.TEXT_DISABLED)
					cell.tooltipBody = W.T("CD_CURRENCY_NONE")
				end
			else
				ConfigureLockoutCell(cell, rowHeight)
				if saved and saved.remainingText then
					cell.text:SetText(saved.remainingText)
					W.SetFontColor(cell.text, UI.GOLD)
					cell.tooltipBody = W.T("CD_SAVED_RESETS", saved.remainingText)
				else
					cell.text:SetText("-")
					W.SetFontColor(cell.text, UI.TEXT_DISABLED)
					cell.tooltipBody = W.T("CD_NOT_SAVED")
				end
			end
			cell:Show()
		end
		row:Show()
	end

	if page.noRowsLabel then
		if lockoutRowCount == 0 then
			page.noRowsLabel:Show()
		else
			page.noRowsLabel:Hide()
		end
	end

	page.emptyLabel:Hide()
	W.LayoutTableScrollBars(page)
end

Addon.Pages.Cooldowns = {
	id = "cooldowns",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateCooldownsPage,
}
