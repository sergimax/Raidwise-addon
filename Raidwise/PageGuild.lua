-- Officer QoL page. Drafts stay in memory; live reads and commands belong to GuildManagement.
local Addon = Raidwise
local Guild = Addon.GuildManagement
local W = Addon.Widgets
local LAYOUT_VERSION = 2
local currentPage
local kinds = { "invite", "join", "quit", "remove", "promote", "demote", "rank", "publicNote", "officerNote" }
local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

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
		return { { "GUILD_NAME", 160 }, { "GUILD_EVENT", 180 }, { "GUILD_SOURCE", 300 }, { "GUILD_ACTOR", page.tableWidth - 640 } }
	end
	return { { "GUILD_NAME", 120 }, { "GUILD_CLASS", 44 }, { "GUILD_RANK", 110 },
		{ "GUILD_STATUS", 76 }, { "GUILD_PUBLIC", 248 }, { "GUILD_OFFICER", page.tableWidth - 598 } }
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
		return T("GUILD_SERVER") .. " · " .. Addon:FormatShortDateTime(entry.observedAt)
	end
	return T("GUILD_OBSERVED") .. " · " .. Addon:FormatShortDateTime(entry.observedAt)
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

local function Refresh(page)
	if not page then return end
	local key = Guild.Identity()
	if page.editorKey ~= key then SetEditor(page, nil); page.offset = 0; page.detailEntry = nil end
	if not Guild.Permissions().view and page.detailEntry and page.detailEntry.kind == "officerNote" then page.detailEntry = nil end
	local isLog = page.mode == "log"
	Show(page.rosterPanel, not isLog)
	Show(page.logPanel, isLog)
	Show(page.classButton, not isLog)
	Show(page.kindButton, isLog)
	page.classButton.label:SetText(page.class and ((LOCALIZED_CLASS_NAMES_MALE or {})[page.class] or page.class) or T("GUILD_ALL_CLASSES"))
	page.kindButton.label:SetText(page.kind and T("GUILD_KIND_" .. page.kind) or T("GUILD_ALL_EVENTS"))
	page.searchLabel:SetText(T(isLog and "GUILD_SEARCH_MEMBER" or "GUILD_SEARCH"))
	local columns = Columns(page, isLog)
	LayoutCells(page.headers, columns, 0, true)
	local entries = isLog and Guild.Entries(page.search:GetText(), page.kind) or Guild.Members(page.search:GetText(), page.class)
	local pages = math.max(1, math.ceil(#entries / #page.rows))
	page.offset = math.min(page.offset, pages - 1)
	page.count:SetText(string.format("%d / %d · %d", page.offset + 1, pages, #entries))
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
				row.cells[5]:SetText("")
				row.cells[6]:SetText("")
			else
				local values = { entry.name, "", entry.rank, T(entry.online and "GUILD_ONLINE" or "GUILD_OFFLINE"),
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
	page.tableWidth = width
	local function Mode(mode) page.mode = mode; page.offset = 0; Refresh(page) end
	Button(page, 8, -8, 120, "GUILD_ROSTER", function() Mode("roster") end)
	Button(page, 134, -8, 120, "GUILD_LOG", function() Mode("log") end)
	page.refresh = Button(page, 260, -8, 120, "GUILD_REFRESH", function() Guild.Request() end)
	page.searchLabel = Label(page, 8, -42, width, T("GUILD_SEARCH"))
	page.search = Input(page, 8, -59, 350)
	page.search:SetScript("OnTextChanged", function() page.offset = 0; Refresh(page) end)
	page.classButton = Button(page, 366, -59, 180, "GUILD_ALL_CLASSES", function() Cycle(page, "class", classes) end)
	page.kindButton = Button(page, 366, -59, 180, "GUILD_ALL_EVENTS", function() Cycle(page, "kind", kinds) end)
	page.header = CreateFrame("Frame", nil, page)
	page.header:SetPoint("TOPLEFT", 8, -94)
	page.header:SetSize(width, 14)
	page.headers = {}
	for index = 1, 6 do
		page.headers[index] = Label(page.header, 0, 0, 1, "")
		page.headers[index]:SetHeight(14)
	end
	page.rows = {}
	for index = 1, 12 do
		local row = W.CreatePlainButton(page, width, 23, "")
		row:SetPoint("TOPLEFT", 8, -112 - (index - 1) * 25)
		row.cells = {}
		for cell = 1, 6 do
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
			else GameTooltip:AddLine(T("GUILD_LOG_HINT")) end
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function() PaintRow(row); GameTooltip:Hide() end)
		page.rows[index] = row
	end
	page.previous = Button(page, 8, -416, 90, "GUILD_PREVIOUS", function() page.offset = math.max(0, page.offset - 1); Refresh(page) end)
	page.next = Button(page, 104, -416, 90, "GUILD_NEXT", function() page.offset = page.offset + 1; Refresh(page) end)
	page.count = Label(page, 210, -423, 180, "")
	page.rosterPanel = CreateFrame("Frame", nil, page)
	page.rosterPanel:SetPoint("TOPLEFT", 8, -450)
	page.rosterPanel:SetSize(width, 176)
	page.selectedLabel = Label(page.rosterPanel, 0, 0, width, "")
	page.publicLabel = Label(page.rosterPanel, 0, -23, 350, T("GUILD_PUBLIC"))
	page.officerLabel = Label(page.rosterPanel, 366, -23, 350, T("GUILD_OFFICER"))
	page.public = Input(page.rosterPanel, 0, -41, 350)
	page.officer = Input(page.rosterPanel, 366, -41, 350)
	page.public:SetMaxLetters(31)
	page.officer:SetMaxLetters(31)
	page.public:SetScript("OnTextChanged", function() Editor(page) end)
	page.officer:SetScript("OnTextChanged", function() if not page.refreshingEditor then page.refreshingEditor = true; Editor(page); page.refreshingEditor = nil end end)
	page.save = Button(page.rosterPanel, 0, -76, 120, "GUILD_SAVE", function() Submit(page) end)
	page.cancel = Button(page.rosterPanel, 126, -76, 120, "GUILD_CANCEL", function()
		local member
		for _, candidate in ipairs(Guild.Members()) do if candidate.name == page.selected then member = candidate end end
		SetEditor(page, member); Refresh(page)
	end)
	page.promote = Button(page.rosterPanel, 366, -76, 120, "GUILD_PROMOTE", function() Submit(page, "promote") end)
	page.demote = Button(page.rosterPanel, 492, -76, 120, "GUILD_DEMOTE", function() Submit(page, "demote") end)
	page.message = Label(page.rosterPanel, 0, -110, width, "")
	page.message:SetHeight(44)
	page.logPanel = CreateFrame("Frame", nil, page)
	page.logPanel:SetPoint("TOPLEFT", 8, -450)
	page.logPanel:SetSize(width, 176)
	page.detail = Label(page.logPanel, 0, 0, width - 205, "")
	page.detail:SetHeight(168)
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
		Refresh(page)
	end,
}
