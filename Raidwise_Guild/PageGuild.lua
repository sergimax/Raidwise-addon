-- Officer QoL page. Drafts stay in memory; live reads and commands belong to GuildManagement.
local Addon = Raidwise
local Guild = Addon.GuildManagement
local W = Addon.Widgets
local LAYOUT_VERSION = 5
local currentPage
local kinds = { "invite", "join", "quit", "remove", "promote", "demote", "rank", "publicNote", "officerNote" }

local function T(key) return Addon:T(key) end
local function Safe(text) return tostring(text or ""):gsub("|", "||") end
local function Show(frame, shown) if shown then frame:Show() else frame:Hide() end end
local function Label(parent, x, y, width, text)
	local label = W.CreateFontString(parent, nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", x, y)
	label:SetWidth(width)
	label:SetJustifyH("LEFT")
	label:SetText(text or "")
	return label
end

local function Columns(page, isLog)
	if isLog then
		return { { "GUILD_NAME", 160 }, { "GUILD_EVENT", 180 }, { "GUILD_SOURCE", 300 }, { "GUILD_ACTOR", page.viewportWidth - 640 } }
	end
	return { { "GUILD_NAME", 80 }, { "GUILD_CLASS", 44 }, { "GUILD_RANK", 110 },
		{ "GUILD_STATUS", 76 }, { "GUILD_EP", 68 }, { "GUILD_GP", 87 }, { "GUILD_PR", 45 },
		{ "GUILD_PUBLIC", 248 }, { "GUILD_OFFICER", 258 } }
end

local sortKeys = { [5] = "ep", [6] = "gp", [7] = "pr" }

local function LayoutTable(page, columns, isLog, visibleRows)
	local width = 0
	for _, column in ipairs(columns) do width = width + column[2] end
	page.tableWidth = width
	page.tableContent:SetWidth(width)
	page.header:SetWidth(width)
	for _, row in ipairs(page.rows) do row:SetWidth(width) end
	local maximum = math.max(0, width - page.viewportWidth)
	page.hBar:SetMinMaxValues(0, maximum)
	page.scrollOffset = math.min(page.scrollOffset or 0, maximum)
	page.hBar:SetValue(page.scrollOffset)
	page.scroll:SetHorizontalScroll(page.scrollOffset)
	page.headerScroll:SetHorizontalScroll(page.scrollOffset)
	Show(page.hBar, maximum > 0)
	local height = math.max(1, visibleRows) * 25
	page.tableContent:SetHeight(height)
	local verticalMaximum = math.max(0, height - page.viewportHeight)
	page.verticalMaximum = verticalMaximum
	page.verticalOffset = math.min(page.verticalOffset or 0, verticalMaximum)
	page.vBar:SetMinMaxValues(0, verticalMaximum)
	page.vBar:SetValue(page.verticalOffset)
	page.scroll:SetVerticalScroll(page.verticalOffset)
	Show(page.vBar, verticalMaximum > 0)
	for index, button in pairs(page.sortButtons) do
		Show(button, not isLog)
		button:SetWidth(columns[index] and columns[index][2] - 8 or 0)
	end
end

local function FormatEP(member)
	if member.ep == nil then return "— ?" end
	return string.format("%.0f %s", member.ep, member.bisEligible and "V" or "X")
end

local function LayoutCells(cells, columns, y, headers)
	local offset = 0
	for index, cell in ipairs(cells) do
		local column = columns[index]
		Show(cell, column ~= nil)
		if column then
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", offset + 4, y)
			cell:SetWidth(column[2] - 8)
			if headers then cell:SetText(T(column[1])) end
			offset = offset + column[2]
		end
	end
end

local function PaintRow(row, hovering)
	local theme = Addon.UITheme
	W.SetBackdropColor(row, row.selected and theme.CD_CURRENT_CHARACTER or (hovering and theme.BTN_HOVER or theme.BTN_IDLE))
end

local function Button(parent, x, y, width, key, click)
	local button = W.CreatePlainButton(parent, width, 24, T(key))
	button:SetPoint("TOPLEFT", x, y)
	button.localeKey = key
	button:SetScript("OnClick", click)
	parent.localizedButtons = parent.localizedButtons or {}
	parent.localizedButtons[#parent.localizedButtons + 1] = button
	return button
end

local function Input(parent, x, y, width)
	local box, host = W.CreateTextInput(parent, width)
	host:SetPoint("TOPLEFT", x, y)
	return box
end

local function Enable(control, enabled, reason)
	if control.label then
		if enabled then control:Enable() else control:Disable() end
		local tooltip
		if not enabled then tooltip = reason or "GUILD_DENIED" end
		W.SetPlainButtonTooltip(control, tooltip)
	else
		control:EnableMouse(enabled and true or false)
		control:EnableKeyboard(enabled and true or false)
		if not enabled then control:ClearFocus() end
	end
end

local function SetEditor(page, member)
	page.selected = member and member.name or nil
	page.original = member
	if member then member.key = Guild.Identity() end
	page.editorKey = Guild.Identity()
	page.public:SetText(member and member.publicNote or "")
	page.officer:SetText(member and member.officerNote or "")
	page.editorMessage = nil
end

local function DateText(entry)
	if entry.source == "server" then
		-- Server returns relative ages, not an absolute event timestamp.
		return T("GUILD_SERVER") .. " / " .. Addon:FormatShortDateTime(entry.observedAt)
	end
	return T("GUILD_OBSERVED") .. " / " .. Addon:FormatShortDateTime(entry.observedAt)
end

local function Editor(page)
	local permissions = Guild.Permissions()
	local sameGuild = page.editorKey == Guild.Identity()
	local member = sameGuild and page.original or nil
	local live
	for _, candidate in ipairs(Guild.Members()) do if candidate.name == page.selected then live = candidate; break end end
	page.selectedLabel:SetText(member and Safe(member.name .. " — " .. (live and live.rank or member.rank)) or T("GUILD_SELECT"))
	local pending = Guild.Pending()
	Enable(page.public, member and permissions.public and not pending)
	Enable(page.officer, member and permissions.view and permissions.officer and not pending)
	if not permissions.view and page.officer:GetText() ~= "" then page.officer:SetText("") end
	local changed = member and ((permissions.public and page.public:GetText() ~= member.publicNote)
		or (permissions.view and permissions.officer and page.officer:GetText() ~= (member.officerNote or "")))
	Enable(page.save, changed and not pending, pending and "GUILD_PENDING" or "GUILD_UNCHANGED")
	Enable(page.promote, member and live and Guild.CanRank(live, "promote") and not pending)
	Enable(page.demote, member and live and Guild.CanRank(live, "demote") and not pending)
	page.message:SetText(T(page.editorMessage or Guild.Status() or "GUILD_READY"))
end

local function ShowDetail(page, entry)
	page.detailEntry = entry
	if not entry then page.detail:SetText(T("GUILD_LOG_HINT")); return end
	local text = T("GUILD_KIND_" .. entry.kind) .. " — " .. Safe(entry.name)
	if entry.actor then text = text .. "\n" .. T("GUILD_ACTOR") .. ": " .. Safe(entry.actor) end
	text = text .. "\n" .. DateText(entry)
	if entry.kind == "publicNote" or entry.kind == "officerNote" or entry.kind == "rank" then
		text = text .. "\n" .. T("GUILD_BEFORE") .. ": " .. Safe(entry.before)
	end
	if entry.after ~= nil then text = text .. "\n" .. T("GUILD_AFTER") .. ": " .. Safe(entry.after) end
	if entry.source == "server" then
		text = text .. "\n" .. T("GUILD_AGE") .. ": " .. tostring(entry.year or 0) .. "/"
			.. tostring(entry.month or 0) .. "/" .. tostring(entry.day or 0) .. "/" .. tostring(entry.hour or 0)
	else text = text .. "\n" .. T("GUILD_UNKNOWN_AUTHOR") end
	page.detail:SetText(text)
end

local function UpdateProgress(page)
	local phase, current, total = Guild.Progress()
	Show(page.progress, phase ~= nil)
	if not phase then return end
	page.progress:SetProgress(current, total or 1)
	if phase == "waiting" then page.progressLabel:SetText(T("GUILD_SCAN_WAITING"))
	else
		page.progressLabel:SetText(string.format(T("GUILD_SCAN_PROGRESS"), current, total, math.floor(current * 100 / total)))
	end
end

local function Refresh(page)
	if not page then return end
	local key = Guild.Identity()
	if page.editorKey ~= key then SetEditor(page, nil); page.offset = 0; page.detailEntry = nil end
	if not Guild.Permissions().view and page.detailEntry and page.detailEntry.kind == "officerNote" then page.detailEntry = nil end
	local isLog = page.mode == "log"
	Show(page.rosterPanel, not isLog)
	Show(page.logPanel, isLog)
	Show(page.kindButton, isLog)
	page.rosterTab.selected, page.journalTab.selected = not isLog, isLog
	PaintRow(page.rosterTab); PaintRow(page.journalTab)
	page.kindButton.label:SetText(page.kind and T("GUILD_KIND_" .. page.kind) or T("GUILD_ALL_EVENTS"))
	page.searchLabel:SetText(T(isLog and "GUILD_SEARCH_MEMBER" or "GUILD_SEARCH"))
	Show(page.raidOnly, not isLog)
	page.raidOnly.label:SetText((page.filterRaid and "[x] " or "[ ] ") .. T("GUILD_RAID_ONLY"))
	if page.settingsKey ~= key then
		page.settingsKey = key
		page.rollMinimumEP:SetText(tostring(Guild.RollMinimumEP()))
	end
	local balances = Guild.Balances()
	local settings = balances and balances.epgpSettings or Addon.GuildEPGP.ParseGuildInfo(nil)
	local baseLabel = settings.minimumGP ~= nil and tostring(settings.minimumGP) or "?"
	page.baseLabel:SetText("BASE_GP: " .. baseLabel .. " / " .. T("GUILD_BASE_" .. string.upper(settings.baseStatus)))
	local columns = Columns(page, isLog)
	LayoutCells(page.headers, columns, 0, true)
	if not isLog then
		for index, sortKey in pairs(sortKeys) do
			if page.sortKey == sortKey then page.headers[index]:SetText(T(columns[index][1]) .. (page.descending and " v" or " ^")) end
		end
	end
	local entries = isLog and Guild.Entries(page.search:GetText(), page.kind)
		or Guild.Members(page.search:GetText(), nil, page.filterRaid, page.sortKey, page.descending)
	local pages = math.max(1, math.ceil(#entries / #page.rows))
	page.offset = math.min(page.offset, pages - 1)
	local viewKey = table.concat({ tostring(key), page.mode, tostring(page.offset), page.search:GetText(),
		tostring(page.filterRaid), tostring(page.kind), tostring(page.sortKey), tostring(page.descending) }, "\031")
	if page.viewKey ~= viewKey then page.verticalOffset = 0; page.viewKey = viewKey end
	LayoutTable(page, columns, isLog, math.min(#page.rows, math.max(0, #entries - page.offset * #page.rows)))
	page.count:SetText(string.format("%d / %d / %d", page.offset + 1, pages, #entries))
	Enable(page.previous, page.offset > 0)
	Enable(page.next, page.offset < pages - 1)
	for index, row in ipairs(page.rows) do
		local entry = entries[page.offset * #page.rows + index]
		row.entry = entry
		row.selected = not isLog and entry and entry.name == page.selected or false
		PaintRow(row)
		LayoutCells(row.cells, columns, -5)
		Show(row.classIcon, entry and not isLog and entry.classFile ~= nil)
		Show(row, entry ~= nil)
		if entry then
			for _, cell in ipairs(row.cells) do W.SetFontColor(cell, Addon.UITheme.TEXT_BODY) end
			if isLog then
				row.cells[1]:SetText(Safe(entry.name))
				row.cells[2]:SetText(T("GUILD_KIND_" .. entry.kind))
				row.cells[3]:SetText(DateText(entry))
				row.cells[4]:SetText(Safe(entry.actor or ""))
				for cell = 5, 9 do row.cells[cell]:SetText("") end
			else
				local gp = entry.gp ~= nil and string.format("%.0f (+%s)", entry.gp, baseLabel) or "—"
				local values = { entry.name, "", entry.rank, T(entry.online and "GUILD_ONLINE" or "GUILD_OFFLINE"),
					FormatEP(entry), gp, entry.pr and string.format("%.2f", entry.pr) or "—",
					entry.publicNote, Guild.Permissions().view and entry.officerNote or T("GUILD_HIDDEN") }
				for cell, value in ipairs(values) do row.cells[cell]:SetText(Safe(value)) end
				row.cells[1]:SetTextColor(W.ClassColor(entry.classFile))
				W.SetFontColor(row.cells[4], entry.online and Addon.UITheme.GEAR_GOOD or Addon.UITheme.TEXT_BODY)
				W.SetSpecOrClassIcon(row.classIcon, nil, entry.classFile)
			end
		end
	end
	ShowDetail(page, page.detailEntry)
	Editor(page)
	UpdateProgress(page)
end

local function Submit(page, direction)
	local values = { publicNote = page.public:GetText() }
	if Guild.Permissions().view and Guild.Permissions().officer then values.officerNote = page.officer:GetText() end
	local ok, reason = Guild.Submit(page.selected, page.original, values, direction)
	page.editorMessage = not ok and reason or nil
	if ok then page.submitted = true end
	Refresh(page)
end

local function Cycle(page, field, choices)
	local nextIndex = 1
	for index, value in ipairs(choices) do if value == page[field] then nextIndex = index + 1 end end
	page[field] = choices[nextIndex]
	page.offset = 0
	Refresh(page)
end

local function Create(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)
	page.layoutVersion, page.mode, page.offset = LAYOUT_VERSION, "roster", 0
	currentPage = page
	local width = Addon.UITheme.CONTENT_WIDTH - Addon.UITheme.MENU_BAR_W - 24
	page.viewportWidth, page.viewportHeight = width - 14, 310
	local function Mode(mode) page.mode = mode; page.offset = 0; Refresh(page) end
	page.rosterTab = Button(page, 8, -8, 120, "GUILD_ROSTER", function() Mode("roster") end)
	page.journalTab = Button(page, 132, -8, 90, "GUILD_LOG", function() Mode("log") end)
	for _, tab in ipairs({ page.rosterTab, page.journalTab }) do
		tab:SetScript("OnEnter", function(button) PaintRow(button, true) end)
		tab:SetScript("OnLeave", function(button) PaintRow(button) end)
	end
	page.refresh = Button(page, 226, -8, 96, "GUILD_REFRESH", function() Guild.Request() end)
	page.progress = W.CreateProgressBar(page, 14)
	page.progress:SetPoint("TOPLEFT", 330, -13)
	page.progress:SetWidth(width - 322)
	page.progressLabel = Label(page.progress, 0, 0, width - 322, "")
	page.progressLabel:SetHeight(14)
	page.progressLabel:SetJustifyH("CENTER")
	page.progress:Hide()
	page.searchLabel = Label(page, 8, -38, 260, T("GUILD_SEARCH"))
	page.search = Input(page, 8, -54, 260)
	page.search:SetScript("OnTextChanged", function() page.offset = 0; Refresh(page) end)
	page.kindButton = Button(page, 274, -54, 142, "GUILD_ALL_EVENTS", function() Cycle(page, "kind", kinds) end)
	page.raidOnly = Button(page, 274, -54, 142, "GUILD_RAID_ONLY", function() page.filterRaid = not page.filterRaid; page.offset = 0; Refresh(page) end)
	page.rollLabel = Label(page, 422, -38, 176, T("GUILD_ROLL_MINIMUM"))
	page.rollMinimumEP = Input(page, 422, -54, 66)
	page.rollMinimumEP:SetNumeric(true)
	page.rollMinimumEP:SetText(tostring(Guild.RollMinimumEP()))
	page.applyRoll = Button(page, 494, -54, 100, "GUILD_APPLY", function()
		if Guild.SetRollMinimumEP(page.rollMinimumEP:GetText()) then page.editorMessage = nil
		else page.editorMessage = "GUILD_ROLL_ERROR" end
		Refresh(page)
	end)
	page.baseLabel = Label(page, 600, -38, width - 600, "")
	page.baseLabel:SetHeight(42)
	page.headerScroll = CreateFrame("ScrollFrame", nil, page)
	page.headerScroll:SetPoint("TOPLEFT", 8, -90)
	page.headerScroll:SetSize(page.viewportWidth, 18)
	page.scroll = CreateFrame("ScrollFrame", nil, page)
	page.scroll:SetPoint("TOPLEFT", 8, -108)
	page.scroll:SetSize(page.viewportWidth, page.viewportHeight)
	page.tableContent = CreateFrame("Frame", nil, page.scroll)
	page.tableContent:SetSize(width, 25 * 25)
	page.scroll:SetScrollChild(page.tableContent)
	page.hBar = W.CreateCooldownScrollBar(page, "HORIZONTAL")
	page.hBar:SetPoint("TOPLEFT", 8, -422)
	page.hBar:SetSize(page.viewportWidth, 10)
	page.hBar:SetScript("OnValueChanged", function(_, value)
		page.scrollOffset = value; page.scroll:SetHorizontalScroll(value); page.headerScroll:SetHorizontalScroll(value)
	end)
	page.vBar = W.CreateCooldownScrollBar(page, "VERTICAL")
	page.vBar:SetPoint("TOPLEFT", width - 2, -108)
	page.vBar:SetSize(10, page.viewportHeight)
	page.vBar:SetScript("OnValueChanged", function(_, value) page.verticalOffset = value; page.scroll:SetVerticalScroll(value) end)
	page.scroll:EnableMouseWheel(true)
	page.scroll:SetScript("OnMouseWheel", function(_, delta)
		page.vBar:SetValue(math.max(0, math.min(page.verticalMaximum or 0,
			(page.verticalOffset or 0) - delta * 25 * 3)))
	end)
	page.header = CreateFrame("Frame", nil, page.headerScroll)
	page.header:SetPoint("TOPLEFT", 0, 0)
	page.header:SetSize(width, 18)
	page.headerScroll:SetScrollChild(page.header)
	page.headers = {}
	page.sortButtons = {}
	for index = 1, 9 do
		page.headers[index] = Label(page.header, 0, 0, 1, "")
		page.headers[index]:SetHeight(14)
		local sortKey = sortKeys[index]
		if sortKey then
			local button = CreateFrame("Button", nil, page.header)
			button:SetPoint("TOPLEFT", page.headers[index], "TOPLEFT", 0, 0)
			button:SetHeight(18)
			button:SetScript("OnClick", function()
				if page.sortKey == sortKey then page.descending = not page.descending else page.sortKey, page.descending = sortKey, true end
				page.offset = 0; Refresh(page)
			end)
			page.sortButtons[index] = button
		end
	end
	page.rows = {}
	for index = 1, 25 do
		local row = W.CreatePlainButton(page.tableContent, width, 23, "")
		row:SetPoint("TOPLEFT", 0, -(index - 1) * 25)
		row.cells = {}
		for cell = 1, 9 do
			row.cells[cell] = Label(row, 0, -5, 1, "")
			row.cells[cell]:SetHeight(14)
		end
		row.classIcon = row:CreateTexture(nil, "ARTWORK")
		row.classIcon:SetSize(18, 18)
		row.classIcon:SetPoint("CENTER", row.cells[2], "CENTER", 0, 0)
		row:SetScript("OnClick", function()
			if page.mode == "log" then ShowDetail(page, row.entry)
			elseif not Guild.Pending() then SetEditor(page, row.entry); Refresh(page) end
		end)
		row:SetScript("OnEnter", function()
			PaintRow(row, true)
			if not row.entry then return end
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			if page.mode == "roster" then
				GameTooltip:AddLine(Safe(row.entry.name))
				GameTooltip:AddLine(Safe(row.entry.class))
				GameTooltip:AddLine(T("GUILD_PUBLIC") .. ": " .. Safe(row.entry.publicNote), 1, 1, 1, true)
				if Guild.Permissions().view then GameTooltip:AddLine(T("GUILD_OFFICER") .. ": " .. Safe(row.entry.officerNote), 1, 1, 1, true) end
				if row.entry.balanceName then GameTooltip:AddLine(T("GUILD_BALANCE_OWNER") .. ": " .. Safe(row.entry.balanceName)) end
				if row.entry.prReason then GameTooltip:AddLine(T(row.entry.prReason), 1, 0.6, 0.4, true) end
				if row.entry.pr then
					GameTooltip:AddLine(string.format("PR = %.0f / %.0f = %.2f", row.entry.ep, row.entry.effectiveGP, row.entry.pr))
				end
				GameTooltip:AddLine(T("GUILD_ROLL_HINT"), 1, 1, 1, true)
			else GameTooltip:AddLine(T("GUILD_LOG_HINT")) end
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function() PaintRow(row); GameTooltip:Hide() end)
		page.rows[index] = row
	end
	page.previous = Button(page, 8, -438, 84, "GUILD_PREVIOUS", function() page.offset = math.max(0, page.offset - 1); Refresh(page) end)
	page.next = Button(page, 96, -438, 84, "GUILD_NEXT", function() page.offset = page.offset + 1; Refresh(page) end)
	page.count = Label(page, 190, -445, 220, "")
	page.rosterPanel = CreateFrame("Frame", nil, page)
	page.rosterPanel:SetPoint("TOPLEFT", 8, -472)
	page.rosterPanel:SetSize(width, 160)
	page.selectedLabel = Label(page.rosterPanel, 0, 0, width, "")
	page.publicLabel = Label(page.rosterPanel, 0, -20, 350, T("GUILD_PUBLIC"))
	page.officerLabel = Label(page.rosterPanel, 366, -20, 350, T("GUILD_OFFICER"))
	page.public = Input(page.rosterPanel, 0, -36, 350)
	page.officer = Input(page.rosterPanel, 366, -36, 350)
	page.public:SetMaxLetters(31)
	page.officer:SetMaxLetters(31)
	page.public:SetScript("OnTextChanged", function() Editor(page) end)
	page.officer:SetScript("OnTextChanged", function() if not page.refreshingEditor then page.refreshingEditor = true; Editor(page); page.refreshingEditor = nil end end)
	page.save = Button(page.rosterPanel, 0, -66, 120, "GUILD_SAVE", function() Submit(page) end)
	page.cancel = Button(page.rosterPanel, 126, -66, 120, "GUILD_CANCEL", function()
		local member
		for _, candidate in ipairs(Guild.Members()) do if candidate.name == page.selected then member = candidate end end
		SetEditor(page, member); Refresh(page)
	end)
	page.promote = Button(page.rosterPanel, 366, -66, 120, "GUILD_PROMOTE", function() Submit(page, "promote") end)
	page.demote = Button(page.rosterPanel, 492, -66, 120, "GUILD_DEMOTE", function() Submit(page, "demote") end)
	page.message = Label(page.rosterPanel, 0, -96, width, "")
	page.message:SetHeight(44)
	page.logPanel = CreateFrame("Frame", nil, page)
	page.logPanel:SetPoint("TOPLEFT", 8, -472)
	page.logPanel:SetSize(width, 160)
	page.detail = Label(page.logPanel, 0, 0, width - 205, "")
	page.detail:SetHeight(156)
	page.detail:SetJustifyV("TOP")
	page.limitLabel = Label(page.logPanel, width - 195, 0, 190, T("GUILD_LIMIT"))
	page.limit = Input(page.logPanel, width - 195, -23, 90)
	page.limit:SetNumeric(true)
	page.limit:SetText(tostring(Guild.GetLimit()))
	page.applyLimit = Button(page.logPanel, width - 195, -53, 150, "GUILD_APPLY", function()
		if not Guild.SetLimit(page.limit:GetText()) then page.detail:SetText(T("GUILD_LIMIT_ERROR")); return end
		Refresh(page)
	end)
	page.localHint = Label(page.logPanel, width - 195, -88, 190, T("GUILD_LOCAL_HINT"))
	page.localHint:SetHeight(80)
	page:SetScript("OnShow", function() Guild.Initialize(); Guild.Request(); Refresh(page) end)
	page:SetScript("OnHide", function() Guild.Close(); GameTooltip:Hide() end)
	return page
end

Guild.IsVisible = function() return currentPage and currentPage:IsVisible() end
Guild.OnProgress = function() if currentPage then UpdateProgress(currentPage) end end
Guild.OnChange = function()
	local page = currentPage
	if not page then return end
	if page.submitted and not Guild.Pending() then
		page.submitted = nil
		if Guild.Status() == "GUILD_SAVED" then
			for _, member in ipairs(Guild.Members()) do if member.name == page.selected then SetEditor(page, member); break end end
		end
	end
	if page:IsVisible() then GameTooltip:Hide(); Refresh(page) end
end

Addon.Pages = Addon.Pages or {}
Addon.Pages.Guild = {
	id = "guild", LAYOUT_VERSION = LAYOUT_VERSION, Create = Create,
	Refresh = function(page, entering) if entering then Guild.Request() end; Refresh(page) end,
	ApplyLocale = function(page)
		for _, parent in ipairs({ page, page.rosterPanel, page.logPanel }) do
			for _, button in ipairs(parent.localizedButtons or {}) do button.label:SetText(T(button.localeKey)) end
		end
		page.publicLabel:SetText(T("GUILD_PUBLIC")); page.officerLabel:SetText(T("GUILD_OFFICER"))
		page.limitLabel:SetText(T("GUILD_LIMIT")); page.localHint:SetText(T("GUILD_LOCAL_HINT"))
		page.rollLabel:SetText(T("GUILD_ROLL_MINIMUM"))
		Refresh(page)
	end,
}

if Addon.MenuPages then
	local position = #Addon.MenuPages + 1
	for index, info in ipairs(Addon.MenuPages) do if info.group == "other" then position = index; break end end
	table.insert(Addon.MenuPages, position, { id = "guild", key = "Guild", labelKey = "GUILD_ROSTER",
		icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01", group = "guild" })
end
