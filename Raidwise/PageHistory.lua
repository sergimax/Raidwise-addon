-- PageHistory

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 8
local DATABASE_LAYOUT_VERSION = 13
local ROWS_PER_PAGE = 25
local DATABASE_COLUMNS = {
	{field="nameText", key="COL_NAME", width=180},
	{field="classText", key="COL_CLASS", width=100},
	{field="opinionText", key="COL_OPINION", width=90},
	{field="authorText", key="PROFILE_RECORD_AUTHOR", width=170},
	{field="guildText", key="COL_GUILD", width=140},
	{field="countText", key="PROFILE_RECORD_MEETINGS", width=100},
	{field="actions", key="DATABASE_ACTIONS", width=80},
}
local HISTORY_COLUMNS = {
	{field="nameText", key="COL_NAME", width=180},
	{field="classText", key="COL_CLASS", width=100},
	{field="opinionText", key="COL_OPINION", width=90},
	{field="metText", key="PROFILE_RECORD_LAST_MEETING", width=330},
	{field="countText", key="PROFILE_RECORD_MEETINGS", width=140},
}
local function Columns(database) return database and DATABASE_COLUMNS or HISTORY_COLUMNS end
local function HistoryTableWidth(database)
	local width = 0
	for _, column in ipairs(Columns(database)) do width = width + column.width end
	return width
end

function Addon:ConfirmDeleteCharacterDatabase(guid)
	local guids = {}
	if guid then
		if not self:IsCharacterDatabaseEntry(self:GetHistoryEntry(guid)) then return end
		guids[1] = guid
	else
		for _, entry in ipairs(self:BuildHistoryRoster(true)) do guids[#guids + 1] = entry.guid end
	end
	if #guids == 0 then return end
	local name = guid and self:LinkedCharacterName(self:GetHistoryEntry(guid)) or nil
	StaticPopupDialogs.RAIDWISE_DELETE_DATABASE = {
		text = self:T(guid and "DATABASE_DELETE_CONFIRM" or "DATABASE_DELETE_ALL_CONFIRM", name or #guids),
		button1 = self:T("DATABASE_DELETE"), button2 = self:T("CHAR_LINK_CANCEL"),
		OnAccept = function(dialog)
			if dialog.data then Addon:DeleteCharacterDatabaseRecords(dialog.data) end
		end,
		timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
	}
	local dialog = StaticPopup_Show("RAIDWISE_DELETE_DATABASE")
	if dialog then dialog.data = guids end
end

local function CreateHistoryRow(parent, database)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(UI.CD_ROW_H)
	W.ApplyPlainPanel(row, UI.CD_ROW_A)
	row:RegisterForClicks("LeftButtonUp")
	local offset = 0
	for _, column in ipairs(Columns(database)) do
		if column.field == "actions" then
			row.deleteButton = W.CreatePlainButton(row, 72, UI.CD_ROW_H - 8, W.T("DATABASE_DELETE"))
			row.deleteButton:SetPoint("TOPLEFT", offset + 4, -4)
			row.deleteButton:SetScript("OnClick", function()
				if row.member then Addon:ConfirmDeleteCharacterDatabase(row.member.guid) end
			end)
		else
			local label = W.CreateFontString(row, nil, "OVERLAY", "GameFontNormalSmall")
			label:SetPoint("TOPLEFT", offset + 4, -4); label:SetWidth(column.width - 8)
			label:SetHeight(UI.CD_ROW_H - 6); label:SetJustifyH("LEFT"); label:SetJustifyV("TOP")
			row[column.field] = label
		end
		offset = offset + column.width
	end
	row:SetScript("OnClick", function() if row.member then Addon:ShowRaidCharacterWindow(row.member) end end)
	row:SetScript("OnEnter", function(self) W.SetBackdropColor(self, UI.BTN_HOVER); W.ShowMemberRatingTooltip(self, self.member) end)
	row:SetScript("OnLeave", function(self) W.SetBackdropColor(self, self.stripe or UI.CD_ROW_A); GameTooltip:Hide() end)
	return row
end

-- Avoid InputBoxTemplate's named texture regions on anonymous sibling inputs.
local function CreateHistoryInput(parent, width, x, y)
	local input, host = W.CreateTextInput(parent, width)
	host:SetPoint("TOPLEFT", x, y)
	return input, host
end

local function CreateInputLabel(page, key, iconPath, x, y)
	local icon = page:CreateTexture(nil, "ARTWORK")
	icon:SetSize(14, 14)
	icon:SetPoint("TOPLEFT", x, y)
	icon:SetTexture(iconPath)
	local label = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	label:SetText(W.T(key))
	page.filterLabels[#page.filterLabels + 1] = {label=label, key=key}
end

local function RefreshOpinionButton(page)
	if not page.opinionButton then return end
	local _, opinions = Addon:RatingOpinions()
	local data = opinions[page.filters.opinion]
	page.opinionButton.label:SetText(W.T(page.filters.opinion == "unset" and "PROFILE_RECORD_UNSET" or (data and data.labelKey or "FILTER_OPINION_ALL")))
	page.opinionIcon:SetTexture(data and data.icon or "Interface\\Icons\\INV_Misc_GroupLooking")
	W.SetFontColor(page.opinionButton.label, data and data.color or UI.TEXT_BODY)
end

local function CreateHistoryPage(parent, database)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)
	page.database = database
	page.filters = {}
	page.inputs = {}
	page.currentPage = 1

	local hint = W.CreateFontString(page, nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -100, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText(W.T(page.database and "DATABASE_HINT" or "HISTORY_HINT"))

	local refreshBtn = W.CreatePlainButton(page, 96, UI.CD_TOOLBAR_H, W.T("BTN_REFRESH"))
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		if Addon.RecordCurrentGroupHistory then
			Addon:RecordCurrentGroupHistory(true)
		end
		Addon:RefreshHistoryView()
	end)

	page.filterLabels = {}
	page.filterHeading = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormal")
	page.filterHeading:SetPoint("TOPLEFT", 0, -36)
	page.filterHeading:SetText(W.T("HISTORY_FILTERS"))
	local fields = {
		{"name", "COL_NAME", "Interface\\Icons\\INV_Misc_Note_01"},
		{"class", "COL_CLASS", "Interface\\Icons\\INV_Misc_GroupLooking"},
		{"guildName", "COL_GUILD", "Interface\\Icons\\INV_Shirt_GuildTabard_01"},
	}
	for index, field in ipairs(fields) do
		local x = (index - 1) * 166
		CreateInputLabel(page, field[2], field[3], x, -60)
		local input = CreateHistoryInput(page, 150, x, -80)
		page.inputs[field[1]] = input
		input:SetScript("OnTextChanged", function(self)
			page.filters[field[1]] = self:GetText()
			page.currentPage = 1
			Addon:RefreshHistoryView()
		end)
	end
	if database then

		local opinions = {"", "positive", "neutral", "negative", "unset"}
		local opinionIndex = 1
		local opinion = W.CreatePlainButton(page, 160, 24, W.T("FILTER_OPINION_ALL"))
		opinion:SetPoint("TOPLEFT", 498, -80)
		CreateInputLabel(page, "COL_OPINION", "Interface\\Icons\\INV_Misc_Book_11", 498, -60)
		page.opinionIcon = opinion:CreateTexture(nil, "ARTWORK")
		page.opinionIcon:SetSize(16, 16)
		page.opinionIcon:SetPoint("LEFT", 8, 0)
		opinion.label:ClearAllPoints()
		opinion.label:SetPoint("LEFT", page.opinionIcon, "RIGHT", 6, 0)
		opinion.label:SetPoint("RIGHT", opinion, "RIGHT", -6, 0)
		page.opinionButton = opinion
		RefreshOpinionButton(page)
		opinion:SetScript("OnClick", function()
			opinionIndex = opinionIndex % #opinions + 1
			page.filters.opinion = opinions[opinionIndex]
			page.currentPage = 1
			RefreshOpinionButton(page)
			Addon:RefreshHistoryView()
		end)
		page.addHeading = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormal")
		page.addHeading:SetPoint("TOPLEFT", 0, -120)
		page.addHeading:SetText(W.T("DATABASE_ADD"))
		CreateInputLabel(page, "COL_NAME", "Interface\\Icons\\INV_Misc_Note_01", 0, -144)
		local name, nameHost = CreateHistoryInput(page, 230, 0, -164)
		local add = W.CreatePlainButton(page, 150, 24, W.T("DATABASE_ADD"))
		add:SetPoint("LEFT", nameHost, "RIGHT", 12, 0)
		page.addButton = add
		page.addName = name
		local addTarget = W.CreatePlainButton(page, 150, 24, W.T("DATABASE_ADD_TARGET"))
		addTarget:SetPoint("LEFT", add, "RIGHT", 12, 0)
		page.addTargetButton = addTarget
		page.deleteAllButton = W.CreatePlainButton(page, 180, 24, W.T("DATABASE_DELETE_ALL"))
		page.deleteAllButton:SetPoint("LEFT", addTarget, "RIGHT", 12, 0)
		page.deleteAllButton:SetScript("OnClick", function() Addon:ConfirmDeleteCharacterDatabase() end)
		local function AddRecord()
			local entry = Addon:AddCharacterRecord(name:GetText())
			if not entry then page.hint:SetText(W.T("DATABASE_INVALID_NAME")); return end
			name:SetText("")
			name:ClearFocus()
			page.hint:SetText(W.T("DATABASE_HINT"))
			Addon:RefreshHistoryView()
			Addon:ShowRaidCharacterWindow(entry)
		end
		add:SetScript("OnClick", AddRecord)
		name:SetScript("OnEnterPressed", AddRecord)
		addTarget:SetScript("OnClick", function()
			local entry, errorKey = Addon:AddTargetCharacterRecord()
			if not entry then page.hint:SetText(W.T(errorKey or "DATABASE_TARGET_MISSING")); return end
			page.hint:SetText(W.T("DATABASE_HINT"))
			Addon:RefreshHistoryView()
			Addon:ShowRaidCharacterWindow(entry)
		end)
	end

	local entryCount = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	entryCount:SetPoint("TOPLEFT", 0, -20)
	entryCount:SetJustifyH("LEFT")
	page.entryCount = entryCount

	local nextPage = W.CreatePlainButton(page, 56, 24, W.T("HISTORY_NEXT"))
	nextPage:SetPoint("TOPRIGHT", 0, -36)
	nextPage:SetScript("OnClick", function()
		page.currentPage = page.currentPage + 1
		Addon:RefreshHistoryView()
	end)
	page.nextPageButton = nextPage
	local pageLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	pageLabel:SetPoint("RIGHT", nextPage, "LEFT", -6, 0)
	page.pageLabel = pageLabel
	local previousPage = W.CreatePlainButton(page, 56, 24, W.T("HISTORY_PREVIOUS"))
	previousPage:SetPoint("RIGHT", pageLabel, "LEFT", -6, 0)
	previousPage:SetScript("OnClick", function()
		page.currentPage = math.max(1, page.currentPage - 1)
		Addon:RefreshHistoryView()
	end)
	page.previousPageButton = previousPage

	local tableTop = database and -200 or -116
	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "Raidwise" .. (database and "Database" or "History") .. "ScrollV" .. tostring(database and DATABASE_LAYOUT_VERSION or LAYOUT_VERSION), tableHost)
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

	local offset = 0
	page.headerKeys, page.headerLabels = {}, {}
	for index, column in ipairs(Columns(database)) do
		local label = W.CreateFontString(headerBg, nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", offset + 4, -10); label:SetWidth(column.width - 8)
		label:SetJustifyH("LEFT"); label:SetText(W.T(column.key)); W.SetFontColor(label, UI.GOLD)
		page.headerKeys[index], page.headerLabels[index] = column.key, label
		offset = offset + column.width
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
		Addon:RefreshHistoryView()
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
	page.layoutVersion = database and DATABASE_LAYOUT_VERSION or LAYOUT_VERSION
	return page
end

-- REFACTOR candidate: standard row-pool refresh pattern shared with History.
local function HistoryHint(page)
	local hint = W.T(page.database and "DATABASE_HINT" or "HISTORY_HINT")
	if not page.database and type(UnitName) == "function" then
		local name, realm = UnitName("player")
		hint = hint .. " — " .. Addon:LinkedCharacterName({name=name, realm=realm or GetRealmName()})
	end
	return hint
end

local function RefreshPage(self, page)
	if not page then
		return
	end

	if not self.BuildHistoryRoster then
		if page.hint then
			page.hint:SetText(W.T("HISTORY_FAIL"))
		end
		return
	end

	page.tableHost:Show()
	page.hint:SetText(HistoryHint(page))

	local roster = self:BuildHistoryRoster(page.database, page.filters)
	local content = page.tableContent
	local headerBg = page.headerBg
	local tableW = HistoryTableWidth(page.database)
	local pageCount = math.max(1, math.ceil(#roster / ROWS_PER_PAGE))
	page.currentPage = math.min(math.max(page.currentPage or 1, 1), pageCount)
	local firstRow = (page.currentPage - 1) * ROWS_PER_PAGE + 1
	local lastRow = math.min(#roster, firstRow + ROWS_PER_PAGE - 1)
	local visibleRows = math.max(0, lastRow - firstRow + 1)
	local tableH = UI.CD_HEADER_H + math.max(visibleRows, 1) * UI.CD_ROW_H

	content:SetSize(tableW, tableH)
	headerBg:SetWidth(tableW)
	page.entryTotal = #roster
	page.pageCount = pageCount
	if page.entryCount then page.entryCount:SetText(W.T("HISTORY_ENTRY_COUNT", page.entryTotal)) end
	if page.pageLabel then page.pageLabel:SetText(W.T("HISTORY_PAGE", page.currentPage, page.pageCount)) end
	if page.previousPageButton then
		if page.currentPage > 1 then page.previousPageButton:Enable() else page.previousPageButton:Disable() end
	end
	if page.nextPageButton then
		if page.currentPage < pageCount then page.nextPageButton:Enable() else page.nextPageButton:Disable() end
	end

	W.HidePoolFrom(page.rowFrames, visibleRows + 1)
	for rowIndex = 1, visibleRows do
		local member = roster[firstRow + rowIndex - 1]
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreateHistoryRow(content, page.database)
			page.rowFrames[rowIndex] = row
		end

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(UI.CD_HEADER_H + (rowIndex - 1) * UI.CD_ROW_H))
		row:SetSize(tableW, UI.CD_ROW_H)
		local stripe = (rowIndex % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
		row.stripe = stripe
		W.SetBackdropColor(row, stripe)
		row.member = member
		if row.deleteButton then row.deleteButton.label:SetText(W.T("DATABASE_DELETE")) end

		row.nameText:SetText(self:LinkedCharacterName(member))
		row.nameText:SetTextColor(W.ClassColor(member.class))
		row.classText:SetText(W.CharacterIconMarkup(member, 14) .. (member.classLabel or member.class or "—") .. (member.spec and ("\n" .. member.spec) or ""))
		local personal = self:GetPersonalRating(member)
		if self:HasPersonalRatingData(personal) then
			row.opinionText:SetText(W.IconMarkup(self:RatingOpinionIcon(personal.opinion), 14) .. " " .. self:RatingWrapColor(self:RatingOpinionLabel(personal.opinion), self:RatingOpinionColor(personal.opinion)))
			W.SetFontColor(row.opinionText, self:RatingOpinionColor(personal.opinion))
		else
			row.opinionText:SetText(W.T("PROFILE_RECORD_UNSET"))
			W.SetFontColor(row.opinionText, UI.TEXT_DISABLED)
		end
		row.countText:SetText(tostring(member.meetCount or 0))
		if page.database then
			row.authorText:SetText(member.profileAuthor and self:LinkedCharacterName(member.profileAuthor) or "—")
			row.guildText:SetText(W.FormatGuildDisplay(member.guildName, member.guildRank))
		else
			row.metText:SetText(self:FormatHistoryTime(member.lastSeenAt) .. "\n" .. (member.lastSeenZone or ""))
		end
		row:Show()
	end

	W.LayoutTableScrollBars(page)
end

function Addon:RefreshHistoryView()
	local pages = self.mainFrame and self.mainFrame.pages
	if not pages then return end
	self:PruneHistory()
	for _, id in ipairs({"history", "database"}) do
		local page = pages[id]
		if page and page:IsShown() then RefreshPage(self, page) end
	end
end

local function ApplyLocale(page)
	if page then
		if page.deleteAllButton then page.deleteAllButton.label:SetText(W.T("DATABASE_DELETE_ALL")) end
		for _, field in ipairs(page.filterLabels or {}) do field.label:SetText(W.T(field.key)) end
		if page.addButton then page.addButton.label:SetText(W.T("DATABASE_ADD")) end
		if page.addTargetButton then page.addTargetButton.label:SetText(W.T("DATABASE_ADD_TARGET")) end
		RefreshOpinionButton(page)
		if page.filterHeading then page.filterHeading:SetText(W.T("HISTORY_FILTERS")) end
		if page.addHeading then page.addHeading:SetText(W.T("DATABASE_ADD")) end
		if page.hint then
			page.hint:SetText(HistoryHint(page))
		end
		if page.refreshBtn then
			page.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
		end
		if page.previousPageButton then page.previousPageButton.label:SetText(W.T("HISTORY_PREVIOUS")) end
		if page.nextPageButton then page.nextPageButton.label:SetText(W.T("HISTORY_NEXT")) end
		if page.entryCount then page.entryCount:SetText(W.T("HISTORY_ENTRY_COUNT", page.entryTotal or 0)) end
		if page.pageLabel then page.pageLabel:SetText(W.T("HISTORY_PAGE", page.currentPage or 1, page.pageCount or 1)) end
		for index, key in ipairs(page.headerKeys or {}) do
			if page.headerLabels[index] then page.headerLabels[index]:SetText(W.T(key)) end
		end
	end
end

Addon.Pages.History = {
	id = "history",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Refresh = function(_, entering)
		if entering and Addon.RecordCurrentGroupHistory then
			Addon:RecordCurrentGroupHistory(false)
		else
			Addon:RefreshHistoryView()
		end
	end,
	ApplyLocale = ApplyLocale,
	Create = CreateHistoryPage,
}

Addon.Pages.Database = {
	id = "database",
	LAYOUT_VERSION = DATABASE_LAYOUT_VERSION,
	Create = function(parent) return CreateHistoryPage(parent, true) end,
	Refresh = function() Addon:RefreshHistoryView() end,
	ApplyLocale = ApplyLocale,
}
