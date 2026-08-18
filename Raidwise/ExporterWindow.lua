-- Details-style shell: plain panels, left menu, tabbed content pages.

local Addon = Raidwise

-- Keep in sync with docs/UI-Sizes.md and docs/UI-Views.md
local UI = {
	-- Content panel (RaidwiseFrame)
	CONTENT_WIDTH = 890,
	CONTENT_HEIGHT = 690,
	PAD = 10,
	TITLE_H = 20,
	CLOSE_SIZE = 16,

	-- Left menu (RaidwiseMenu)
	MENU_WIDTH = 170,
	MENU_GAP = 2,
	MENU_BTN_H = 22,
	MENU_BTN_GAP = 2,

	-- Status bar (under menu + content)
	STATUS_H = 20,
	STATUS_PAD_X = 8,
	STATUS_GAP = 12,

	-- Export tab
	DESC_TO_CHECK = 8,
	CHECK_SIZE = 24,
	OPTIONS_H = 28,
	CHECK_TO_BUTTONS = 10,
	ACTION_BTN_H = 28,
	ACTION_BTN_GAP = 8,
	BUTTONS_TO_HINT = 8,
	HINT_TO_INSET = 6,
	COPY_SCROLLBAR_W = 20,
	COPY_PAD_L = 5,
	COPY_PAD_T = 6,
	COPY_PAD_R = 4,
	COPY_PAD_B = 4,
	COPY_MIN_H = 180,

	-- Info tab
	INFO_BLOCK_GAP = 14,
	INFO_HEADING_GAP = 8,
	URL_BOX_H = 28,

	-- Cooldowns tab
	CD_HINT_TO_TABLE = 8,
	CD_TOOLBAR_H = 28,
	CD_INSTANCE_COL_W = 170,
	CD_CHAR_COL_W = 90,
	CD_HEADER_H = 38,
	CD_ROW_H = 34,
	CD_SPEC_ICON = 14,
	ROSTER_ICON = 18,
	PROFILE_ICON = 24,
	CD_SCROLLBAR_W = 16,
	CD_HSCROLL_H = 16,
	CD_ROW_A = { 0.18, 0.18, 0.18, 0.90 },
	CD_ROW_B = { 0.14, 0.14, 0.14, 0.90 },

	-- Party tab
	PARTY_COL_NAME = 90,
	PARTY_COL_CLASS = 28,
	PARTY_COL_SPEC = 28,
	PARTY_COL_BUFFS = 166,
	PARTY_COL_GS = 52,
	PARTY_COL_ILVL = 44,
	PARTY_COL_KARMA = 52,
	PARTY_COL_TAGS = 100,
	PARTY_COL_GUILD = 184,
	ROSTER_STATS_H = 16,

	-- Raid roster tab
	RAID_CELL_W = 168,
	RAID_CELL_H = 106,
	RAID_CELL_GAP = 2,
	RAID_CELL_PAD = 4,
	RAID_LINE_H = 14,
	RAID_ICON = 20,
	RAID_BUFF_ICON = 18,
	RAID_GROUP_LABEL_H = 16,
	RAID_BLOCK_GAP = 12,
	RAID_KARMA_PLACEHOLDER = 4.3,
	RAID_DETAIL_W = 300,
	RAID_DETAIL_H = 360,
	RAID_BUFF_MAX = 8,
	RAID_BUFF_GAP = 2,
	RAID_STATS_H = 32,

	-- History tab
	HISTORY_COL_NAME = 90,
	HISTORY_COL_CLASS = 28,
	HISTORY_COL_SPEC = 28,
	HISTORY_COL_GS = 52,
	HISTORY_COL_ILVL = 44,
	HISTORY_COL_ZONE = 160,
	HISTORY_COL_MET = 130,
	HISTORY_COL_GUILD = 150,

	-- Colors
	GOLD = { 0.890, 0.729, 0.016 },
	TEXT_IDLE = { 0.80, 0.80, 0.80 },
	PANEL_BG = { 0.15, 0.15, 0.15, 0.96 },
	TITLE_BG = { 0.20, 0.20, 0.20, 1 },
	BTN_IDLE = { 0.18, 0.18, 0.18, 0.95 },
	BTN_HOVER = { 0.28, 0.28, 0.28, 1 },
	BTN_SELECTED = { 0.32, 0.28, 0.12, 1 },
	BTN_DISABLED = { 0.12, 0.12, 0.12, 0.90 },
	TEXT_HOVER = { 1.00, 1.00, 0.40 },
	TEXT_DISABLED = { 0.45, 0.45, 0.45 },
}

local GITHUB_URL = "https://github.com/sergimax/Raidwise-addon"

local PAGES = {
	{ id = "cooldowns", label = "Character cooldowns" },
	{ id = "party", label = "Party roster" },
	{ id = "raid", label = "Raid roster" },
	{ id = "history", label = "History" },
	{ id = "export", label = "Export gear and CDs" },
	{ id = "exportCooldowns", label = "Export cooldowns" },
	{ id = "info", label = "Info" },
}

local function ApplyPlainPanel(frame, color)
	color = color or UI.PANEL_BG
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true,
		tileSize = 16,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)

	if frame.rwBorderTop then
		return
	end

	local function Edge(layerPointA, relA, layerPointB, relB, width, height)
		local tex = frame:CreateTexture(nil, "BORDER")
		tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		tex:SetVertexColor(0, 0, 0, 1)
		tex:SetPoint(layerPointA, frame, relA)
		tex:SetPoint(layerPointB, frame, relB)
		if width then
			tex:SetWidth(width)
		end
		if height then
			tex:SetHeight(height)
		end
		return tex
	end

	frame.rwBorderTop = Edge("TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1)
	frame.rwBorderBottom = Edge("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1)
	frame.rwBorderLeft = Edge("TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil)
	frame.rwBorderRight = Edge("TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil)
end

local function SetFontColor(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function ContentInnerWidth()
	return UI.CONTENT_WIDTH - (UI.PAD * 2)
end

local function SetPlainButtonState(button, state)
	if state == "selected" then
		button:SetBackdropColor(UI.BTN_SELECTED[1], UI.BTN_SELECTED[2], UI.BTN_SELECTED[3], UI.BTN_SELECTED[4])
		SetFontColor(button.label, UI.GOLD)
	elseif state == "hover" then
		button:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		SetFontColor(button.label, UI.TEXT_HOVER)
	elseif state == "disabled" then
		button:SetBackdropColor(UI.BTN_DISABLED[1], UI.BTN_DISABLED[2], UI.BTN_DISABLED[3], UI.BTN_DISABLED[4])
		SetFontColor(button.label, UI.TEXT_DISABLED)
	else
		button:SetBackdropColor(UI.BTN_IDLE[1], UI.BTN_IDLE[2], UI.BTN_IDLE[3], UI.BTN_IDLE[4])
		SetFontColor(button.label, UI.TEXT_IDLE)
	end
end

local function ActionButtonState(button, hovering)
	if not button:IsEnabled() then
		return "disabled"
	end
	if hovering then
		return "hover"
	end
	return "idle"
end

-- Plain 1px-border button (same look as the left-menu items).
local function CreatePlainButton(parent, width, height, label)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, height)
	ApplyPlainPanel(button, UI.BTN_IDLE)

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 0)
	text:SetText(label)
	SetFontColor(text, UI.TEXT_IDLE)
	button.label = text

	button:SetScript("OnEnter", function(self)
		SetPlainButtonState(self, ActionButtonState(self, true))
	end)
	button:SetScript("OnLeave", function(self)
		SetPlainButtonState(self, ActionButtonState(self, false))
	end)
	button:SetScript("OnEnable", function(self)
		SetPlainButtonState(self, ActionButtonState(self, false))
	end)
	button:SetScript("OnDisable", function(self)
		SetPlainButtonState(self, "disabled")
	end)

	return button
end

-- WowSimsExporter-style copy box (AceGUI MultiLineEditBox look, no Ace).
local COPY_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 },
}

-- ChatFontNormal face size plus leading; EditBox rows are taller than a raw 12px guess.
local function ChatFontLineHeight()
	local _, fontSize = ChatFontNormal:GetFont()
	fontSize = tonumber(fontSize) or 14
	return fontSize + 2
end

local function FitCopyBoxToText(box)
	local text = box:GetText() or ""
	local width = box:GetWidth()
	local insets = 8
	local lineHeight = box.rwLineHeight
	if not lineHeight or lineHeight <= 0 then
		lineHeight = ChatFontLineHeight()
	end

	if text == "" then
		box:SetHeight(UI.COPY_MIN_H)
		return
	end

	if width > 1 then
		local probe = box.rwProbe
		if not probe then
			probe = box:CreateFontString(nil, "ARTWORK")
			probe:SetFontObject(ChatFontNormal)
			probe:SetJustifyH("LEFT")
			probe:Hide()
			box.rwProbe = probe
		end
		probe:SetWidth(width)
		probe:SetText(text)
		local measured = probe:GetStringHeight()
		if measured and measured > 0 then
			box:SetHeight(math.max(UI.COPY_MIN_H, measured + insets))
			return
		end
	end

	local lines = 1
	for _ in text:gmatch("\n") do
		lines = lines + 1
	end
	box:SetHeight(math.max(UI.COPY_MIN_H, lines * lineHeight + insets))
end

local function CreateCopyBox(parent, scrollName, boxName)
	local host = CreateFrame("Frame", nil, parent)

	local scrollBG = CreateFrame("Frame", nil, host)
	scrollBG:SetPoint("TOPLEFT", 0, 0)
	scrollBG:SetPoint("BOTTOMRIGHT", -UI.COPY_SCROLLBAR_W, 0)
	scrollBG:SetBackdrop(COPY_BACKDROP)
	scrollBG:SetBackdropColor(0, 0, 0, 1)
	scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	local scroll = CreateFrame("ScrollFrame", scrollName, host, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", UI.COPY_PAD_L, -UI.COPY_PAD_T)
	scroll:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -UI.COPY_PAD_R, UI.COPY_PAD_B)

	local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPLEFT", scrollBG, "TOPRIGHT", 2, -16)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBG, "BOTTOMRIGHT", 2, 16)

	local exportBox = CreateFrame("EditBox", boxName, scroll)
	exportBox:SetMultiLine(true)
	exportBox:SetFontObject(ChatFontNormal)
	exportBox:SetAutoFocus(false)
	exportBox:EnableMouse(true)
	exportBox:SetTextInsets(0, 0, 3, 3)
	scroll:SetScrollChild(exportBox)

	scroll:SetScript("OnSizeChanged", function(self, width)
		exportBox:SetWidth(width)
		FitCopyBoxToText(exportBox)
	end)
	scroll:SetScript("OnMouseUp", function()
		exportBox:SetFocus()
		if (exportBox:GetText() or "") ~= "" then
			exportBox:HighlightText()
		end
	end)
	scroll:HookScript("OnVerticalScroll", function(self, offset)
		local height = exportBox:GetHeight()
		exportBox:SetHitRectInsets(0, 0, offset, height - offset - self:GetHeight())
	end)

	exportBox:SetScript("OnEscapePressed", function(box)
		box:ClearFocus()
	end)
	exportBox:SetScript("OnEditFocusLost", function(box)
		box:HighlightText(0, 0)
	end)
	exportBox:SetScript("OnMouseUp", function(box)
		if (box:GetText() or "") ~= "" then
			box:HighlightText()
		end
	end)
	exportBox:SetScript("OnCursorChanged", function(box, _, y, _, cursorHeight)
		if cursorHeight and cursorHeight > 0 then
			box.rwLineHeight = cursorHeight
		end
		y = -y
		local offset = scroll:GetVerticalScroll()
		if y < offset then
			scroll:SetVerticalScroll(y)
		else
			y = y + cursorHeight - scroll:GetHeight()
			if y > offset then
				scroll:SetVerticalScroll(y)
			end
		end
	end)
	exportBox:SetScript("OnTextChanged", function(box)
		FitCopyBoxToText(box)
	end)

	return exportBox, host
end

-- Single-line copy field (same tooltip border as the export box).
local function CreateLineCopyBox(parent, boxName)
	local host = CreateFrame("Frame", nil, parent)
	host:SetHeight(UI.URL_BOX_H)
	host:SetBackdrop(COPY_BACKDROP)
	host:SetBackdropColor(0, 0, 0, 1)
	host:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	local box = CreateFrame("EditBox", boxName, host)
	box:SetPoint("TOPLEFT", 8, -4)
	box:SetPoint("BOTTOMRIGHT", -8, 4)
	box:SetFontObject(ChatFontNormal)
	box:SetAutoFocus(false)
	box:SetMultiLine(false)
	box:EnableMouse(true)
	box:SetScript("OnEscapePressed", function(edit)
		edit:ClearFocus()
	end)
	box:SetScript("OnEditFocusGained", function(edit)
		edit:HighlightText()
	end)
	box:SetScript("OnMouseUp", function(edit)
		edit:HighlightText()
	end)
	box:SetScript("OnEditFocusLost", function(edit)
		edit:HighlightText(0, 0)
		if (edit:GetText() or "") == "" then
			edit:SetText(GITHUB_URL)
		end
	end)

	return box, host
end

local function SetMenuButtonState(button, selected, hovering)
	if selected then
		SetPlainButtonState(button, "selected")
	elseif hovering then
		SetPlainButtonState(button, "hover")
	else
		SetPlainButtonState(button, "idle")
	end
end

function Addon:SelectTab(tabId)
	local frame = self.mainFrame
	if not frame then
		return
	end

	frame.selectedTab = tabId
	for id, page in pairs(frame.pages) do
		if id == tabId then
			page:Show()
		else
			page:Hide()
		end
	end
	for _, button in ipairs(frame.menuButtons) do
		SetMenuButtonState(button, button.tabId == tabId, false)
	end

	if tabId == "cooldowns" then
		self.pendingLockoutTable = true
		self:SaveCurrentCharacterLockouts()
		RequestRaidInfo()
		self:RefreshCooldownTable()
	elseif tabId == "party" or tabId == "raid" then
		self:RefreshPartyData(true)
	elseif tabId == "history" then
		if self.RecordCurrentGroupHistory then
			self:RecordCurrentGroupHistory(false)
		elseif self.RefreshHistoryView then
			self:RefreshHistoryView()
		end
	end
end

local function AttachDragHandle(handle, target)
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		target:StartMoving()
	end)
	handle:SetScript("OnDragStop", function()
		target:StopMovingOrSizing()
	end)
end

local function CreateTitleBar(parent)
	local titleBar = CreateFrame("Frame", nil, parent)
	titleBar:SetPoint("TOPLEFT", 1, -1)
	titleBar:SetPoint("TOPRIGHT", -1, -1)
	titleBar:SetHeight(UI.TITLE_H)
	ApplyPlainPanel(titleBar, UI.TITLE_BG)
	AttachDragHandle(titleBar, parent)

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("CENTER", 0, 0)
	title:SetText("Raidwise")
	SetFontColor(title, UI.GOLD)

	local close = CreateFrame("Button", nil, titleBar)
	close:SetSize(UI.CLOSE_SIZE, UI.CLOSE_SIZE)
	close:SetPoint("RIGHT", -3, 0)
	local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	closeText:SetPoint("CENTER", 1, 1)
	closeText:SetText("X")
	SetFontColor(closeText, UI.GOLD)
	close:SetScript("OnEnter", function()
		closeText:SetTextColor(1, 0.25, 0.25)
	end)
	close:SetScript("OnLeave", function()
		SetFontColor(closeText, UI.GOLD)
	end)
	close:SetScript("OnClick", function()
		parent:Hide()
	end)

	return titleBar
end

local function CreateMenuButton(parent, tabId, label, yOffset)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(UI.MENU_WIDTH - 12, UI.MENU_BTN_H)
	button:SetPoint("TOP", 0, yOffset)
	ApplyPlainPanel(button, UI.BTN_IDLE)
	button.tabId = tabId

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", 8, 0)
	text:SetText(label)
	SetFontColor(text, UI.TEXT_IDLE)
	button.label = text

	button:SetScript("OnEnter", function(self)
		SetMenuButtonState(self, Addon.mainFrame and Addon.mainFrame.selectedTab == tabId, true)
	end)
	button:SetScript("OnLeave", function(self)
		SetMenuButtonState(self, Addon.mainFrame and Addon.mainFrame.selectedTab == tabId, false)
	end)
	button:SetScript("OnClick", function()
		Addon:SelectTab(tabId)
	end)

	return button
end

local function CreateExportPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local innerW = ContentInnerWidth()

	local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 0, 0)
	desc:SetWidth(innerW)
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText("Export this character's gear, bags, and raid lockouts as JSON.")

	local namesCheck = CreateFrame("CheckButton", "RaidwiseIncludeNamesCheck", page, "UICheckButtonTemplate")
	namesCheck:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	namesCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -UI.DESC_TO_CHECK)
	namesCheck:SetChecked(Addon.db.includeGearNames ~= false)
	local templateCheckText = _G[namesCheck:GetName() .. "Text"]
	if templateCheckText then
		templateCheckText:SetText("")
		templateCheckText:Hide()
	end
	namesCheck:SetScript("OnClick", function(btn)
		Addon.db.includeGearNames = btn:GetChecked() and true or false
	end)

	local namesLabel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	namesLabel:SetPoint("LEFT", namesCheck, "RIGHT", 4, 0)
	namesLabel:SetText("Include item names")

	local namesHit = CreateFrame("Button", nil, page)
	namesHit:SetPoint("LEFT", namesCheck, "RIGHT", 0, 0)
	namesHit:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	namesHit:SetHeight(UI.OPTIONS_H)
	namesHit:SetScript("OnClick", function()
		namesCheck:Click()
	end)

	local buttonW = (innerW - UI.ACTION_BTN_GAP) / 2
	local exportBtn = CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, "Export character data")
	exportBtn:SetPoint("TOPLEFT", namesCheck, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
	exportBtn:SetScript("OnClick", function()
		Addon:FlushExportToWindow()
		Addon.pendingLockoutExport = true
		RequestRaidInfo()
	end)

	local selectBtn = CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, "Select all")
	selectBtn:SetPoint("LEFT", exportBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	selectBtn:Disable()
	selectBtn:SetScript("OnClick", function()
		Addon:SelectExportText()
	end)

	local statusLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusLabel:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -UI.BUTTONS_TO_HINT)
	statusLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	statusLabel:SetJustifyH("LEFT")
	statusLabel:SetText("After export, press Ctrl+C to copy.")

	local exportBox, copyHost = CreateCopyBox(page, "RaidwiseExportScroll", "RaidwiseExportBox")
	copyHost:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	copyHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	page.exportBox = exportBox
	page.statusLabel = statusLabel
	page.selectBtn = selectBtn
	return page
end

local function CreateCooldownExportPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local innerW = ContentInnerWidth()

	local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 0, 0)
	desc:SetWidth(innerW)
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText("Export account-wide raid and dungeon lockouts as JSON.")

	local buttonW = (innerW - UI.ACTION_BTN_GAP) / 2
	local exportBtn = CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, "Export cooldowns")
	exportBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -UI.CHECK_TO_BUTTONS)
	exportBtn:SetScript("OnClick", function()
		Addon:FlushCooldownExportToWindow()
		Addon.pendingCooldownExport = true
		RequestRaidInfo()
	end)

	local selectBtn = CreatePlainButton(page, buttonW, UI.ACTION_BTN_H, "Select all")
	selectBtn:SetPoint("LEFT", exportBtn, "RIGHT", UI.ACTION_BTN_GAP, 0)
	selectBtn:Disable()
	selectBtn:SetScript("OnClick", function()
		Addon:SelectCooldownExportText()
	end)

	local statusLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statusLabel:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -UI.BUTTONS_TO_HINT)
	statusLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	statusLabel:SetJustifyH("LEFT")
	statusLabel:SetText("After export, press Ctrl+C to copy.")

	local exportBox, copyHost = CreateCopyBox(page, "RaidwiseCooldownExportScroll", "RaidwiseCooldownExportBox")
	copyHost:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -UI.HINT_TO_INSET)
	copyHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	page.exportBox = exportBox
	page.statusLabel = statusLabel
	page.selectBtn = selectBtn
	return page
end

local function CreateInfoPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local innerW = ContentInnerWidth()

	local aboutHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	aboutHeading:SetPoint("TOPLEFT", 0, 0)
	aboutHeading:SetText("About")
	SetFontColor(aboutHeading, UI.GOLD)

	local about = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	about:SetPoint("TOPLEFT", aboutHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	about:SetWidth(innerW)
	about:SetJustifyH("LEFT")
	about:SetJustifyV("TOP")
	about:SetText(
		"Raidwise is a raid-prep addon for Wrath of the Lich King 3.3.5a: party and raid rosters, account-wide lockouts, and character export.\n\n"
			.. "Character cooldowns shows raid and dungeon lockouts for every character saved on this account. "
			.. "Log in on each alt to record their lockouts.\n\n"
			.. "Party roster lists the current 5-player party with spec, GearScore, average item level, guild, karma, and tags. "
			.. "Raid roster shows raid groups 1–5 and 6–8 as player cards (class, name, spec, GearScore, iLvl). "
			.. "Click a filled card to open Character profile.\n\n"
			.. "History keeps party and raid players you have grouped with, including where and when you met them. "
			.. "That list is saved on this account and stays after logout.\n\n"
			.. "Export gear and CDs builds JSON with name, class, spec, equipped gear, bag items, and raid or dungeon lockouts. "
			.. "Turn on Include item names to add display names next to item ids. "
			.. "If the GearScore addon is loaded, the current score is included. "
			.. "Export cooldowns writes the same account-wide lockout data as JSON.\n\n"
			.. "Slash commands: /raidwise or /rw (help, version, status, show, hide)."
	)

	local repoHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	repoHeading:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -UI.INFO_BLOCK_GAP)
	repoHeading:SetText("GitHub")
	SetFontColor(repoHeading, UI.GOLD)

	local repoHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	repoHint:SetPoint("TOPLEFT", repoHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	repoHint:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	repoHint:SetJustifyH("LEFT")
	repoHint:SetText("Select the URL, then press Ctrl+C to copy.")

	local copyBtn = CreatePlainButton(page, 110, UI.ACTION_BTN_H, "Select all")
	copyBtn:SetPoint("TOPRIGHT", repoHint, "BOTTOMRIGHT", 0, -UI.INFO_HEADING_GAP)
	copyBtn:SetScript("OnClick", function()
		Addon:SelectRepoUrl()
	end)

	local repoBox, repoHost = CreateLineCopyBox(page, "RaidwiseRepoBox")
	repoHost:SetPoint("TOPLEFT", repoHint, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	repoHost:SetPoint("RIGHT", copyBtn, "LEFT", -UI.ACTION_BTN_GAP, 0)
	repoBox:SetText(GITHUB_URL)

	page.repoBox = repoBox
	page.repoHint = repoHint
	return page
end

local function ClassColor(classToken)
	local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
	if color then
		return color.r, color.g, color.b
	end
	return UI.TEXT_IDLE[1], UI.TEXT_IDLE[2], UI.TEXT_IDLE[3]
end

local ICON_TEX_INSET = 0.07
local ICON_TEX_MAX = 1 - ICON_TEX_INSET

local function SetSpellIconTexture(texture, iconPath)
	if not texture or not iconPath or iconPath == "" then
		return
	end
	texture:SetTexture(iconPath)
	texture:SetTexCoord(ICON_TEX_INSET, ICON_TEX_MAX, ICON_TEX_INSET, ICON_TEX_MAX)
end

local function SetSpecOrClassIcon(texture, specIcon, classToken)
	if specIcon and specIcon ~= "" then
		SetSpellIconTexture(texture, specIcon)
		return
	end
	texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
	local coords = CLASS_ICON_TCOORDS and classToken and CLASS_ICON_TCOORDS[classToken]
	if coords then
		texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

local function TableIconInset(columnWidth, iconSize)
	return math.floor((columnWidth - iconSize) / 2)
end

local function TableIconTopOffset(iconSize)
	return -math.floor((UI.CD_ROW_H - iconSize) / 2)
end

local function CreateBuffIconHost(parent)
	local host = CreateFrame("Frame", nil, parent)
	host:SetSize(UI.RAID_BUFF_ICON, UI.RAID_BUFF_ICON)
	host.icon = host:CreateTexture(nil, "ARTWORK")
	host.icon:SetAllPoints(host)
	host:EnableMouse(true)
	host:SetScript("OnEnter", function(self)
		if not self.buffName or self.buffName == "" then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.buffName)
		GameTooltip:Show()
	end)
	host:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	host:Hide()
	return host
end

local function FillRaidBuffIcons(hosts, buffs)
	buffs = buffs or {}
	for buffIndex = 1, UI.RAID_BUFF_MAX do
		local host = hosts[buffIndex]
		local buff = buffs[buffIndex]
		if host and buff and buff.icon then
			SetSpellIconTexture(host.icon, buff.icon)
			host.buffName = buff.name or ""
			host:Show()
		elseif host then
			host.icon:SetTexture(nil)
			host.buffName = nil
			host:Hide()
		end
	end
end

local function HidePoolFrom(pool, startIndex)
	for index = startIndex, #pool do
		pool[index]:Hide()
	end
end

local function CreateCooldownScrollBar(parent, orientation)
	local bar = CreateFrame("Slider", nil, parent)
	bar:SetOrientation(orientation)
	if orientation == "VERTICAL" then
		bar:SetWidth(UI.CD_SCROLLBAR_W)
	else
		bar:SetHeight(UI.CD_HSCROLL_H)
	end
	ApplyPlainPanel(bar, UI.BTN_IDLE)
	bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	local thumb = bar:GetThumbTexture()
	if thumb then
		if orientation == "VERTICAL" then
			thumb:SetSize(UI.CD_SCROLLBAR_W, 24)
		else
			thumb:SetSize(24, UI.CD_HSCROLL_H)
		end
	end
	bar:SetMinMaxValues(0, 0)
	bar:SetValueStep(1)
	bar:SetValue(0)
	return bar
end

local function CreateCooldownHeaderCell(parent)
	local cell = CreateFrame("Frame", nil, parent)
	cell:SetHeight(UI.CD_HEADER_H)

	local icon = cell:CreateTexture(nil, "ARTWORK")
	icon:SetSize(UI.CD_SPEC_ICON, UI.CD_SPEC_ICON)
	icon:SetPoint("TOPLEFT", 6, -6)
	cell.icon = icon

	local name = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	name:SetPoint("RIGHT", cell, "RIGHT", -4, 0)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	cell.name = name

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
	ApplyPlainPanel(row, UI.CD_ROW_A)

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	name:SetPoint("TOPLEFT", 6, -4)
	name:SetPoint("RIGHT", row, "LEFT", UI.CD_INSTANCE_COL_W - 4, 0)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("TOP")
	row.instanceName = name

	local typeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	typeLabel:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
	typeLabel:SetPoint("RIGHT", row, "LEFT", UI.CD_INSTANCE_COL_W - 4, 0)
	typeLabel:SetJustifyH("LEFT")
	SetFontColor(typeLabel, UI.TEXT_IDLE)
	row.typeLabel = typeLabel

	row.cells = {}
	return row
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
		if self.tooltipType then
			GameTooltip:AddLine(self.tooltipType, 0.8, 0.8, 0.8)
		end
		if self.tooltipBody then
			GameTooltip:AddLine(self.tooltipBody, 1, 1, 1)
		end
		GameTooltip:Show()
	end)
	cell:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return cell
end

local function LayoutCooldownScrollBars(page)
	local host = page.tableHost
	local scroll = page.scroll
	local content = page.tableContent
	local vBar = page.vBar
	local hBar = page.hBar
	if not host or not scroll or not content then
		return
	end

	local viewW = scroll:GetWidth() or 0
	local viewH = scroll:GetHeight() or 0
	local childW = content:GetWidth() or 0
	local childH = content:GetHeight() or 0
	local maxH = math.max(0, childW - viewW)
	local maxV = math.max(0, childH - viewH)

	if hBar then
		hBar:SetMinMaxValues(0, maxH)
		if maxH > 0 then
			hBar:Show()
			local current = math.min(scroll:GetHorizontalScroll() or 0, maxH)
			hBar:SetValue(current)
			scroll:SetHorizontalScroll(current)
		else
			hBar:SetValue(0)
			hBar:Hide()
			scroll:SetHorizontalScroll(0)
		end
	end
	if vBar then
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
end

local function CooldownTableTopOffset()
	return UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE
end

local function RosterTableTopOffset()
	return UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE + UI.ROSTER_STATS_H + UI.CD_HINT_TO_TABLE
end

local function RaidRosterTableTopOffset()
	return UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE + UI.RAID_STATS_H + UI.CD_HINT_TO_TABLE
end

local function CreateCooldownsPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -90, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText("Lockouts for every character saved on this account.")

	local refreshBtn = CreatePlainButton(page, 80, UI.CD_TOOLBAR_H, "Refresh")
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon.pendingLockoutTable = true
		RequestRaidInfo()
		Addon:RefreshCooldownTable()
	end)

	local tableTop = -CooldownTableTopOffset()

	local emptyLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	emptyLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	emptyLabel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	emptyLabel:SetJustifyH("CENTER")
	emptyLabel:SetJustifyV("MIDDLE")
	SetFontColor(emptyLabel, UI.TEXT_IDLE)
	emptyLabel:SetText("Log in on each character to record raid and dungeon lockouts.")
	page.emptyLabel = emptyLabel

	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseCooldownScroll", tableHost)
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
	ApplyPlainPanel(headerBg, UI.TITLE_BG)
	page.headerBg = headerBg

	local instanceHeader = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	instanceHeader:SetPoint("LEFT", 6, 0)
	instanceHeader:SetText("Raid / Dungeon")
	SetFontColor(instanceHeader, UI.GOLD)
	page.instanceHeader = instanceHeader

	local noRowsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	noRowsLabel:SetPoint("TOPLEFT", headerBg, "BOTTOMLEFT", 8, -10)
	noRowsLabel:SetPoint("RIGHT", content, "RIGHT", -8, 0)
	noRowsLabel:SetJustifyH("LEFT")
	SetFontColor(noRowsLabel, UI.TEXT_IDLE)
	noRowsLabel:SetText("No current lockouts.")
	noRowsLabel:Hide()
	page.noRowsLabel = noRowsLabel

	local vBar = CreateCooldownScrollBar(tableHost, "VERTICAL")
	vBar:SetPoint("TOPRIGHT", -1, -1)
	vBar:SetPoint("BOTTOMRIGHT", -1, UI.CD_HSCROLL_H + 2)
	vBar:SetScript("OnValueChanged", function(self)
		scroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.vBar = vBar

	local hBar = CreateCooldownScrollBar(tableHost, "HORIZONTAL")
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
		LayoutCooldownScrollBars(page)
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
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
	local content = page.tableContent
	local headerBg = page.headerBg

	if #characters == 0 then
		page.emptyLabel:ClearAllPoints()
		page.emptyLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -CooldownTableTopOffset())
		page.emptyLabel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
		page.emptyLabel:SetText("Log in on each character to record raid and dungeon lockouts.")
		page.emptyLabel:Show()
		page.tableHost:Hide()
		return
	end

	page.emptyLabel:Hide()
	page.tableHost:Show()

	local tableW = UI.CD_INSTANCE_COL_W + (#characters * UI.CD_CHAR_COL_W)
	local tableH = UI.CD_HEADER_H + math.max(#rows, 1) * UI.CD_ROW_H
	content:SetSize(tableW, tableH)
	headerBg:SetWidth(tableW)

	HidePoolFrom(page.headerCells, #characters + 1)
	for index = 1, #characters do
		local character = characters[index]
		local cell = page.headerCells[index]
		if not cell then
			cell = CreateCooldownHeaderCell(headerBg)
			page.headerCells[index] = cell
		end
		cell:ClearAllPoints()
		cell:SetPoint("TOPLEFT", headerBg, "TOPLEFT", UI.CD_INSTANCE_COL_W + (index - 1) * UI.CD_CHAR_COL_W, 0)
		cell:SetWidth(UI.CD_CHAR_COL_W)
		cell.name:SetText(character.displayName)
		cell.name:SetTextColor(ClassColor(character.class))
		SetSpecOrClassIcon(cell.icon, character.specIcon, character.class)
		cell.tooltipTitle = character.displayName
		cell.tooltipSpec = character.spec ~= "" and character.spec or nil
		cell:Show()
	end

	HidePoolFrom(page.rowFrames, #rows + 1)
	for rowIndex = 1, #rows do
		local rowData = rows[rowIndex]
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreateCooldownRow(content)
			page.rowFrames[rowIndex] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(UI.CD_HEADER_H + (rowIndex - 1) * UI.CD_ROW_H))
		row:SetSize(tableW, UI.CD_ROW_H)
		local stripe = (rowIndex % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
		row:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		row.instanceName:SetText(rowData.name)
		row.typeLabel:SetText(rowData.typeLabel)

		HidePoolFrom(row.cells, #characters + 1)
		for colIndex = 1, #characters do
			local character = characters[colIndex]
			local cell = row.cells[colIndex]
			if not cell then
				cell = CreateCooldownValueCell(row)
				row.cells[colIndex] = cell
			end
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", row, "TOPLEFT", UI.CD_INSTANCE_COL_W + (colIndex - 1) * UI.CD_CHAR_COL_W, 0)
			cell:SetWidth(UI.CD_CHAR_COL_W)

			local saved = rowData.cells[character.key]
			cell.tooltipTitle = rowData.name
			cell.tooltipType = rowData.typeLabel
			if saved and saved.remainingText then
				cell.text:SetText(saved.remainingText)
				SetFontColor(cell.text, UI.GOLD)
				cell.tooltipBody = "Saved - resets in " .. saved.remainingText
			else
				cell.text:SetText("-")
				SetFontColor(cell.text, UI.TEXT_DISABLED)
				cell.tooltipBody = "Not saved"
			end
			cell:Show()
		end
		row:Show()
	end

	if page.noRowsLabel then
		if #rows == 0 then
			page.noRowsLabel:Show()
		else
			page.noRowsLabel:Hide()
		end
	end

	page.emptyLabel:Hide()
	LayoutCooldownScrollBars(page)
end

local function PartyTableWidth()
	return UI.PARTY_COL_NAME + UI.PARTY_COL_CLASS + UI.PARTY_COL_SPEC + UI.PARTY_COL_BUFFS
		+ UI.PARTY_COL_GS + UI.PARTY_COL_ILVL + UI.PARTY_COL_KARMA + UI.PARTY_COL_TAGS + UI.PARTY_COL_GUILD
end

local function PartyColumnOffset(index)
	local widths = {
		UI.PARTY_COL_NAME,
		UI.PARTY_COL_CLASS,
		UI.PARTY_COL_SPEC,
		UI.PARTY_COL_BUFFS,
		UI.PARTY_COL_GS,
		UI.PARTY_COL_ILVL,
		UI.PARTY_COL_KARMA,
		UI.PARTY_COL_TAGS,
		UI.PARTY_COL_GUILD,
	}
	local offset = 0
	for column = 1, index - 1 do
		offset = offset + widths[column]
	end
	return offset
end

local PARTY_COLUMN_WIDTHS = {
	UI.PARTY_COL_NAME,
	UI.PARTY_COL_CLASS,
	UI.PARTY_COL_SPEC,
	UI.PARTY_COL_BUFFS,
	UI.PARTY_COL_GS,
	UI.PARTY_COL_ILVL,
	UI.PARTY_COL_KARMA,
	UI.PARTY_COL_TAGS,
	UI.PARTY_COL_GUILD,
}

local function FormatGuildDisplay(guildName, guildRank)
	if not guildName or guildName == "" then
		return "-"
	end
	if guildRank and guildRank ~= "" then
		return guildName .. " (" .. guildRank .. ")"
	end
	return guildName
end

local function KarmaValue(karma)
	if karma == nil then
		karma = UI.RAID_KARMA_PLACEHOLDER
	end
	return tostring(karma)
end

local function FormatKarmaLine(karma)
	return KarmaValue(karma) .. " Karma"
end

local function FormatTagLine(tags)
	if type(tags) ~= "table" or #tags == 0 then
		return ""
	end
	local parts = {}
	for index = 1, #tags do
		local tag = tags[index]
		local name = type(tag) == "table" and tag.name or nil
		if name and name ~= "" then
			parts[#parts + 1] = "#" .. name
		end
	end
	return table.concat(parts, " ")
end

local function FormatRosterAverages(gearScore, averageIlvl)
	local ilvlText = averageIlvl ~= nil and tostring(averageIlvl) or "-"
	local gsText = gearScore ~= nil and tostring(gearScore) or "-"
	return "Average iLvl: " .. ilvlText .. "     Average GS: " .. gsText
end

local function CreateRosterStatsLabel(page)
	local stats = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	stats:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -(UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE))
	stats:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	stats:SetHeight(UI.ROSTER_STATS_H)
	stats:SetJustifyH("LEFT")
	stats:SetJustifyV("MIDDLE")
	SetFontColor(stats, UI.TEXT_IDLE)
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

local function FormatRaidAverageGs(gearScore)
	local gsText = gearScore ~= nil and tostring(gearScore) or "-"
	return "Average GS: " .. gsText
end

local function FormatRoleGsSummary(label, bucket)
	bucket = bucket or {}
	local gsText = bucket.gearScore ~= nil and tostring(bucket.gearScore) or "-"
	return label .. ": " .. tostring(bucket.count or 0) .. " (" .. gsText .. " gs)"
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
			FormatRoleGsSummary("Tanks", tank)
				.. "     "
				.. FormatRoleGsSummary("Healers", healer)
				.. "     "
				.. FormatRoleGsSummary("Melee", melee)
				.. "     "
				.. FormatRoleGsSummary("Range", ranged)
		)
	end
end

local function CreateRaidStatsLabels(page)
	CreateRosterStatsLabel(page)
	page.statsLabel:SetText(FormatRaidAverageGs(nil))
	local roleStats = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	roleStats:SetPoint("TOPLEFT", page.statsLabel, "BOTTOMLEFT", 0, 0)
	roleStats:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	roleStats:SetHeight(UI.ROSTER_STATS_H)
	roleStats:SetJustifyH("LEFT")
	roleStats:SetJustifyV("MIDDLE")
	SetFontColor(roleStats, UI.TEXT_IDLE)
	roleStats:SetText(
		FormatRoleGsSummary("Tanks")
			.. "     "
			.. FormatRoleGsSummary("Healers")
			.. "     "
			.. FormatRoleGsSummary("Melee")
			.. "     "
			.. FormatRoleGsSummary("Range")
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

local function CreatePartyRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(UI.CD_ROW_H)
	ApplyPlainPanel(row, UI.CD_ROW_A)

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
		"LEFT",
		row,
		"TOPLEFT",
		PartyColumnOffset(2) + TableIconInset(UI.PARTY_COL_CLASS, UI.ROSTER_ICON),
		TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.classIcon = row.classIconHost:CreateTexture(nil, "ARTWORK")
	row.classIcon:SetAllPoints(row.classIconHost)

	row.specIconHost = CreateFrame("Frame", nil, row)
	row.specIconHost:SetSize(UI.ROSTER_ICON, UI.ROSTER_ICON)
	row.specIconHost:SetPoint(
		"LEFT",
		row,
		"TOPLEFT",
		PartyColumnOffset(3) + TableIconInset(UI.PARTY_COL_SPEC, UI.ROSTER_ICON),
		TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.specIcon = row.specIconHost:CreateTexture(nil, "ARTWORK")
	row.specIcon:SetAllPoints(row.specIconHost)

	row.buffHosts = {}
	for buffIndex = 1, UI.RAID_BUFF_MAX do
		local host = CreateBuffIconHost(row)
		local x = PartyColumnOffset(4) + 4 + (buffIndex - 1) * (UI.RAID_BUFF_ICON + UI.RAID_BUFF_GAP)
		host:SetPoint("LEFT", row, "TOPLEFT", x, TableIconTopOffset(UI.RAID_BUFF_ICON))
		row.buffHosts[buffIndex] = host
	end

	row.gsText = AddTextColumn(5, "CENTER")
	row.ilvlText = AddTextColumn(6, "CENTER")
	row.karmaText = AddTextColumn(7, "CENTER")
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

	return row
end

local function CreatePartyPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -90, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText("Current party (5 players max). Refresh after gear or spec changes.")

	local refreshBtn = CreatePlainButton(page, 80, UI.CD_TOOLBAR_H, "Refresh")
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon:RefreshPartyData(true)
	end)

	CreateRosterStatsLabel(page)

	local tableTop = -RosterTableTopOffset()

	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwisePartyScroll", tableHost)
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
	ApplyPlainPanel(headerBg, UI.TITLE_BG)
	page.headerBg = headerBg

	local headers = { "Name", "Class", "Spec", "Buffs", "GS", "iLvl", "Karma", "Tags", "Guild" }
	page.headerLabels = {}
	for index = 1, #headers do
		local label = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", headerBg, "TOPLEFT", PartyColumnOffset(index) + 4, -10)
		label:SetWidth(PARTY_COLUMN_WIDTHS[index] - 8)
		label:SetJustifyH((index >= 5 and index <= 7) and "CENTER" or "LEFT")
		label:SetText(headers[index])
		SetFontColor(label, UI.GOLD)
		page.headerLabels[index] = label
	end

	local vBar = CreateCooldownScrollBar(tableHost, "VERTICAL")
	vBar:SetPoint("TOPRIGHT", -1, -1)
	vBar:SetPoint("BOTTOMRIGHT", -1, UI.CD_HSCROLL_H + 2)
	vBar:SetScript("OnValueChanged", function(self)
		scroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.vBar = vBar

	local hBar = CreateCooldownScrollBar(tableHost, "HORIZONTAL")
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
		LayoutCooldownScrollBars(page)
	end)

	page:SetScript("OnShow", function()
		Addon:RefreshPartyView(true)
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
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
			page.hint:SetText("Party module failed to load. Reload UI (/reload).")
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

	HidePoolFrom(page.rowFrames, #roster + 1)
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
		row:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])

		row.nameText:SetText(member.name)
		row.nameText:SetTextColor(ClassColor(member.class))
		row.classLabel = member.classLabel
		row.specLabel = member.spec
		SetSpecOrClassIcon(row.classIcon, nil, member.class)
		SetSpecOrClassIcon(row.specIcon, member.specIcon, member.class)
		FillRaidBuffIcons(row.buffHosts, member.raidBuffs)

		if member.gearScore then
			row.gsText:SetText(tostring(member.gearScore))
			SetFontColor(row.gsText, UI.GOLD)
		else
			row.gsText:SetText("-")
			SetFontColor(row.gsText, UI.TEXT_DISABLED)
		end

		if member.averageIlvl then
			row.ilvlText:SetText(tostring(member.averageIlvl))
			SetFontColor(row.ilvlText, UI.TEXT_IDLE)
		else
			row.ilvlText:SetText("-")
			SetFontColor(row.ilvlText, UI.TEXT_DISABLED)
		end

		row.karmaText:SetText(KarmaValue(member.karma))
		SetFontColor(row.karmaText, UI.TEXT_IDLE)

		local tags = FormatTagLine(member.tags)
		if tags ~= "" then
			row.tagText:SetText(tags)
			SetFontColor(row.tagText, UI.TEXT_IDLE)
		else
			row.tagText:SetText("-")
			SetFontColor(row.tagText, UI.TEXT_DISABLED)
		end

		row.guildText:SetText(FormatGuildDisplay(member.guildName, member.guildRank))
		SetFontColor(row.guildText, UI.TEXT_IDLE)
		row:Show()
	end

	LayoutCooldownScrollBars(page)
end

local function FormatRaidStatsLine(gearScore, averageIlvl)
	local parts = {}
	if gearScore then
		parts[#parts + 1] = tostring(gearScore) .. "gs"
	end
	if averageIlvl then
		parts[#parts + 1] = tostring(averageIlvl) .. "ilvl"
	end
	if #parts == 0 then
		return ""
	end
	return table.concat(parts, " ")
end

local function RaidColumnOffset(columnIndex)
	return (columnIndex - 1) * (UI.RAID_CELL_W + UI.RAID_CELL_GAP)
end

local function RaidBlockHeight()
	return UI.RAID_GROUP_LABEL_H + UI.RAID_CELL_H * 5 + UI.RAID_CELL_GAP * 4
end

local function RaidContentSize()
	local width = UI.RAID_CELL_W * 5 + UI.RAID_CELL_GAP * 4
	local height = RaidBlockHeight() * 2 + UI.RAID_BLOCK_GAP
	return width, height
end

local function CreateRaidCharacterWindow()
	local frame = CreateFrame("Frame", "RaidwiseRaidCharacterFrame", UIParent)
	frame:SetSize(UI.RAID_DETAIL_W, UI.RAID_DETAIL_H)
	frame:SetPoint("CENTER", 40, 20)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:Hide()
	ApplyPlainPanel(frame)
	tinsert(UISpecialFrames, "RaidwiseRaidCharacterFrame")

	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 1, -1)
	titleBar:SetPoint("TOPRIGHT", -1, -1)
	titleBar:SetHeight(UI.TITLE_H)
	ApplyPlainPanel(titleBar, UI.TITLE_BG)
	AttachDragHandle(titleBar, frame)

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", 8, 0)
	title:SetPoint("RIGHT", -24, 0)
	title:SetJustifyH("LEFT")
	SetFontColor(title, UI.GOLD)
	frame.titleText = title

	local close = CreateFrame("Button", nil, titleBar)
	close:SetSize(UI.CLOSE_SIZE, UI.CLOSE_SIZE)
	close:SetPoint("RIGHT", -3, 0)
	local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	closeText:SetPoint("CENTER", 1, 1)
	closeText:SetText("X")
	SetFontColor(closeText, UI.GOLD)
	close:SetScript("OnEnter", function()
		closeText:SetTextColor(1, 0.25, 0.25)
	end)
	close:SetScript("OnLeave", function()
		SetFontColor(closeText, UI.GOLD)
	end)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local body = CreateFrame("Frame", nil, frame)
	body:SetPoint("TOPLEFT", UI.PAD, -(UI.TITLE_H + UI.PAD))
	body:SetPoint("BOTTOMRIGHT", -UI.PAD, UI.PAD)

	local classIcon = body:CreateTexture(nil, "ARTWORK")
	classIcon:SetSize(UI.PROFILE_ICON, UI.PROFILE_ICON)
	classIcon:SetPoint("TOPLEFT", 0, 0)
	frame.classIcon = classIcon

	local classText = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	classText:SetPoint("LEFT", classIcon, "RIGHT", 6, 0)
	classText:SetPoint("RIGHT", body, "RIGHT", 0, 0)
	classText:SetJustifyH("LEFT")
	frame.classText = classText

	local specIcon = body:CreateTexture(nil, "ARTWORK")
	specIcon:SetSize(UI.PROFILE_ICON, UI.PROFILE_ICON)
	specIcon:SetPoint("TOPLEFT", classIcon, "BOTTOMLEFT", 0, -8)
	frame.specIcon = specIcon

	local specText = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	specText:SetPoint("LEFT", specIcon, "RIGHT", 6, 0)
	specText:SetPoint("RIGHT", body, "RIGHT", 0, 0)
	specText:SetJustifyH("LEFT")
	frame.specText = specText

	local function AddBodyLine(anchor)
		local text = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
		text:SetPoint("RIGHT", body, "RIGHT", 0, 0)
		text:SetJustifyH("LEFT")
		SetFontColor(text, UI.TEXT_IDLE)
		return text
	end

	frame.gsText = AddBodyLine(specIcon)
	frame.ilvlText = AddBodyLine(frame.gsText)
	frame.guildText = AddBodyLine(frame.ilvlText)
	frame.karmaText = AddBodyLine(frame.guildText)
	frame.tagText = AddBodyLine(frame.karmaText)
	frame.metZoneText = AddBodyLine(frame.tagText)
	frame.metAtText = AddBodyLine(frame.metZoneText)
	frame.metRealmText = AddBodyLine(frame.metAtText)
	frame.guidText = AddBodyLine(frame.metRealmText)

	return frame
end

function Addon:ShowRaidCharacterWindow(member)
	if not member then
		return
	end

	if self.HistoryProfileForMember then
		member = self:HistoryProfileForMember(member)
	end

	local frame = self.raidDetailFrame
	if not frame then
		frame = CreateRaidCharacterWindow()
		self.raidDetailFrame = frame
	end

	frame.titleText:SetText((member.name or "?") .. " - Character profile")
	SetSpecOrClassIcon(frame.classIcon, nil, member.class)
	frame.classText:SetText(member.classLabel ~= "" and member.classLabel or "-")
	frame.classText:SetTextColor(ClassColor(member.class))

	if member.specIcon and member.specIcon ~= "" then
		SetSpecOrClassIcon(frame.specIcon, member.specIcon, member.class)
		frame.specIcon:Show()
	else
		SetSpecOrClassIcon(frame.specIcon, nil, member.class)
		frame.specIcon:Show()
	end
	frame.specText:SetText((member.spec and member.spec ~= "") and member.spec or "-")
	SetFontColor(frame.specText, UI.TEXT_IDLE)

	if member.gearScore then
		frame.gsText:SetText("GearScore: " .. tostring(member.gearScore))
		SetFontColor(frame.gsText, UI.GOLD)
	else
		frame.gsText:SetText("GearScore: -")
		SetFontColor(frame.gsText, UI.TEXT_DISABLED)
	end

	if member.averageIlvl then
		frame.ilvlText:SetText("iLvl: " .. tostring(member.averageIlvl))
		SetFontColor(frame.ilvlText, UI.TEXT_IDLE)
	else
		frame.ilvlText:SetText("iLvl: -")
		SetFontColor(frame.ilvlText, UI.TEXT_DISABLED)
	end

	frame.guildText:SetText("Guild: " .. FormatGuildDisplay(member.guildName, member.guildRank))
	SetFontColor(frame.guildText, UI.TEXT_IDLE)
	frame.karmaText:SetText(FormatKarmaLine(member.karma))
	SetFontColor(frame.karmaText, UI.TEXT_IDLE)

	local tags = FormatTagLine(member.tags)
	if tags ~= "" then
		frame.tagText:SetText(tags)
		SetFontColor(frame.tagText, UI.TEXT_IDLE)
	else
		frame.tagText:SetText("#")
		SetFontColor(frame.tagText, UI.TEXT_DISABLED)
	end

	if member.metZone and member.metZone ~= "" then
		frame.metZoneText:SetText("Met: " .. member.metZone)
		SetFontColor(frame.metZoneText, UI.TEXT_IDLE)
	else
		frame.metZoneText:SetText("Met: -")
		SetFontColor(frame.metZoneText, UI.TEXT_DISABLED)
	end

	local metWhen = (self.FormatHistoryTime and self:FormatHistoryTime(member.metAt)) or "-"
	if metWhen ~= "-" then
		frame.metAtText:SetText("When: " .. metWhen)
		SetFontColor(frame.metAtText, UI.TEXT_IDLE)
	else
		frame.metAtText:SetText("When: -")
		SetFontColor(frame.metAtText, UI.TEXT_DISABLED)
	end

	if member.metRealm and member.metRealm ~= "" then
		frame.metRealmText:SetText("Realm: " .. member.metRealm)
		SetFontColor(frame.metRealmText, UI.TEXT_IDLE)
	else
		frame.metRealmText:SetText("Realm: -")
		SetFontColor(frame.metRealmText, UI.TEXT_DISABLED)
	end

	if member.guid and member.guid ~= "" then
		frame.guidText:SetText("GUID: " .. member.guid)
		SetFontColor(frame.guidText, UI.TEXT_IDLE)
	else
		frame.guidText:SetText("GUID: -")
		SetFontColor(frame.guidText, UI.TEXT_DISABLED)
	end

	frame:Show()
	frame:Raise()
end

local function CreateRaidPlayerCell(parent)
	local cell = CreateFrame("Button", nil, parent)
	cell:SetSize(UI.RAID_CELL_W, UI.RAID_CELL_H)
	ApplyPlainPanel(cell, UI.CD_ROW_A)
	cell:EnableMouse(true)
	cell:RegisterForClicks("LeftButtonUp")

	cell.classIconHost = CreateFrame("Frame", nil, cell)
	cell.classIconHost:SetSize(UI.RAID_ICON, UI.RAID_ICON)
	cell.classIconHost:SetPoint("TOPLEFT", UI.RAID_CELL_PAD, -UI.RAID_CELL_PAD)
	cell.classIcon = cell.classIconHost:CreateTexture(nil, "ARTWORK")
	cell.classIcon:SetAllPoints(cell.classIconHost)

	cell.nameText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.nameText:SetPoint("LEFT", cell.classIconHost, "RIGHT", 4, 0)
	cell.nameText:SetPoint("RIGHT", cell, "RIGHT", -UI.RAID_CELL_PAD, 0)
	cell.nameText:SetHeight(UI.RAID_LINE_H)
	cell.nameText:SetJustifyH("LEFT")
	cell.nameText:SetJustifyV("MIDDLE")

	cell.roleIconHost = CreateFrame("Frame", nil, cell)
	cell.roleIconHost:SetSize(UI.RAID_ICON, UI.RAID_ICON)
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
	cell.specIconHost:SetSize(UI.RAID_ICON, UI.RAID_ICON)
	cell.specIconHost:SetPoint("LEFT", cell.roleIconHost, "RIGHT", 3, 0)
	cell.specIcon = cell.specIconHost:CreateTexture(nil, "ARTWORK")
	cell.specIcon:SetAllPoints(cell.specIconHost)

	cell.statsText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.statsText:SetPoint("LEFT", cell.specIconHost, "RIGHT", 4, 0)
	cell.statsText:SetPoint("RIGHT", cell, "RIGHT", -UI.RAID_CELL_PAD, 0)
	cell.statsText:SetHeight(UI.RAID_LINE_H)
	cell.statsText:SetJustifyH("LEFT")
	cell.statsText:SetJustifyV("MIDDLE")

	cell.buffHosts = {}
	for buffIndex = 1, UI.RAID_BUFF_MAX do
		local host = CreateBuffIconHost(cell)
		if buffIndex == 1 then
			host:SetPoint("TOPLEFT", cell.roleIconHost, "BOTTOMLEFT", 0, -3)
		else
			host:SetPoint("LEFT", cell.buffHosts[buffIndex - 1], "RIGHT", UI.RAID_BUFF_GAP, 0)
		end
		cell.buffHosts[buffIndex] = host
	end

	cell.karmaText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.karmaText:SetPoint("TOPLEFT", cell.buffHosts[1], "BOTTOMLEFT", 0, -2)
	cell.karmaText:SetPoint("RIGHT", cell, "RIGHT", -UI.RAID_CELL_PAD, 0)
	cell.karmaText:SetHeight(UI.RAID_LINE_H)
	cell.karmaText:SetJustifyH("LEFT")

	cell.tagText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.tagText:SetPoint("TOPLEFT", cell.karmaText, "BOTTOMLEFT", 0, -1)
	cell.tagText:SetPoint("RIGHT", cell, "RIGHT", -UI.RAID_CELL_PAD, 0)
	cell.tagText:SetHeight(UI.RAID_LINE_H)
	cell.tagText:SetJustifyH("LEFT")

	cell:SetScript("OnEnter", function(self)
		if not self.member then
			return
		end
		self:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
	end)
	cell:SetScript("OnLeave", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
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
	column:SetSize(UI.RAID_CELL_W, RaidBlockHeight())

	local label = column:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 0, 0)
	label:SetPoint("TOPRIGHT", 0, 0)
	label:SetHeight(UI.RAID_GROUP_LABEL_H)
	label:SetJustifyH("CENTER")
	label:SetText(tostring(groupIndex))
	SetFontColor(label, UI.GOLD)
	column.label = label

	column.cells = {}
	for slot = 1, 5 do
		local cell = CreateRaidPlayerCell(column)
		cell:SetPoint("TOPLEFT", 0, -(UI.RAID_GROUP_LABEL_H + (slot - 1) * (UI.RAID_CELL_H + UI.RAID_CELL_GAP)))
		column.cells[slot] = cell
	end

	return column
end

local function CreateRaidBlock(parent, startGroup, endGroup)
	local columnCount = endGroup - startGroup + 1
	local block = CreateFrame("Frame", nil, parent)
	block:SetSize(
		UI.RAID_CELL_W * columnCount + UI.RAID_CELL_GAP * (columnCount - 1),
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
		cell.karmaText:SetText("")
		cell.tagText:SetText("")
		cell.classIconHost:Hide()
		cell.roleIconHost:Hide()
		cell.specIconHost:Hide()
		FillRaidBuffIcons(cell.buffHosts, nil)
		cell:EnableMouse(false)
		cell:Show()
		return
	end

	cell.member = member
	cell:EnableMouse(true)
	cell.nameText:SetText(member.name or "")
	cell.nameText:SetTextColor(ClassColor(member.class))
	SetSpecOrClassIcon(cell.classIcon, nil, member.class)
	cell.classIconHost:Show()

	local role = member.role or "unknown"
	cell.roleLabel = (Addon.RaidRoleLabel and Addon:RaidRoleLabel(role)) or ""
	if Addon.RaidRoleIcon then
		SetSpellIconTexture(cell.roleIcon, Addon:RaidRoleIcon(role))
	else
		SetSpellIconTexture(cell.roleIcon, "Interface\\Icons\\INV_Misc_QuestionMark")
	end
	cell.roleIconHost:Show()

	if member.specIcon and member.specIcon ~= "" then
		SetSpecOrClassIcon(cell.specIcon, member.specIcon, member.class)
		cell.specIcon:Show()
	else
		cell.specIcon:SetTexture(nil)
		cell.specIcon:Hide()
	end
	cell.specIconHost:Show()

	local stats = FormatRaidStatsLine(member.gearScore, member.averageIlvl)
	cell.statsText:SetText(stats)
	if member.gearScore then
		SetFontColor(cell.statsText, UI.GOLD)
	else
		SetFontColor(cell.statsText, UI.TEXT_IDLE)
	end

	FillRaidBuffIcons(cell.buffHosts, member.raidBuffs)

	cell.karmaText:SetText(FormatKarmaLine(member.karma))
	SetFontColor(cell.karmaText, UI.TEXT_IDLE)

	local tags = FormatTagLine(member.tags)
	cell.tagText:SetText(tags)
	if tags ~= "" then
		SetFontColor(cell.tagText, UI.TEXT_IDLE)
	else
		SetFontColor(cell.tagText, UI.TEXT_DISABLED)
	end
	cell:Show()
end

local function CreateRaidRosterPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -90, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText("Raid groups 1–5 and 6–8. Refresh after gear or spec changes.")

	local refreshBtn = CreatePlainButton(page, 80, UI.CD_TOOLBAR_H, "Refresh")
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		Addon:RefreshPartyData(true)
	end)

	CreateRaidStatsLabels(page)

	local tableTop = -RaidRosterTableTopOffset()
	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseRaidRosterScroll", tableHost)
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
	bottomBlock:SetPoint("TOPLEFT", topBlock, "BOTTOMLEFT", 0, -UI.RAID_BLOCK_GAP)
	page.bottomBlock = bottomBlock

	local vBar = CreateCooldownScrollBar(tableHost, "VERTICAL")
	vBar:SetPoint("TOPRIGHT", -1, -1)
	vBar:SetPoint("BOTTOMRIGHT", -1, UI.CD_HSCROLL_H + 2)
	vBar:SetScript("OnValueChanged", function(self)
		scroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.vBar = vBar

	local hBar = CreateCooldownScrollBar(tableHost, "HORIZONTAL")
	hBar:SetPoint("BOTTOMLEFT", 1, 1)
	hBar:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), 1)
	hBar:SetScript("OnValueChanged", function(self)
		scroll:SetHorizontalScroll(self:GetValue() or 0)
	end)
	page.hBar = hBar

	scroll:SetScript("OnMouseWheel", function(self, delta)
		local maxV = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
		local step = UI.RAID_CELL_H
		local nextValue = math.max(0, math.min(maxV, (self:GetVerticalScroll() or 0) - delta * step))
		self:SetVerticalScroll(nextValue)
		vBar:SetValue(nextValue)
	end)
	scroll:SetScript("OnSizeChanged", function()
		LayoutCooldownScrollBars(page)
	end)

	page:SetScript("OnShow", function()
		Addon:RefreshRaidRosterView(true)
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
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
			page.hint:SetText("Raid roster module failed to load. Reload UI (/reload).")
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
	LayoutCooldownScrollBars(page)
end

local function HistoryTableWidth()
	return UI.HISTORY_COL_NAME + UI.HISTORY_COL_CLASS + UI.HISTORY_COL_SPEC + UI.HISTORY_COL_GS
		+ UI.HISTORY_COL_ILVL + UI.HISTORY_COL_ZONE + UI.HISTORY_COL_MET + UI.HISTORY_COL_GUILD
end

local HISTORY_COLUMN_WIDTHS = {
	UI.HISTORY_COL_NAME,
	UI.HISTORY_COL_CLASS,
	UI.HISTORY_COL_SPEC,
	UI.HISTORY_COL_GS,
	UI.HISTORY_COL_ILVL,
	UI.HISTORY_COL_ZONE,
	UI.HISTORY_COL_MET,
	UI.HISTORY_COL_GUILD,
}

local function HistoryColumnOffset(index)
	local offset = 0
	for columnIndex = 1, index - 1 do
		offset = offset + HISTORY_COLUMN_WIDTHS[columnIndex]
	end
	return offset
end

local function CreateHistoryRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(UI.CD_ROW_H)
	ApplyPlainPanel(row, UI.CD_ROW_A)
	row:EnableMouse(true)
	row:RegisterForClicks("LeftButtonUp")

	local function AddTextColumn(index, justify, insetLeft)
		local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("TOPLEFT", row, "TOPLEFT", HistoryColumnOffset(index) + (insetLeft or 4), -4)
		text:SetWidth(HISTORY_COLUMN_WIDTHS[index] - (insetLeft or 4) - 4)
		text:SetJustifyH(justify or "LEFT")
		text:SetJustifyV("TOP")
		return text
	end

	row.nameText = AddTextColumn(1, "LEFT")

	row.classIconHost = CreateFrame("Frame", nil, row)
	row.classIconHost:SetSize(UI.ROSTER_ICON, UI.ROSTER_ICON)
	row.classIconHost:SetPoint(
		"LEFT",
		row,
		"TOPLEFT",
		HistoryColumnOffset(2) + TableIconInset(UI.HISTORY_COL_CLASS, UI.ROSTER_ICON),
		TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.classIcon = row.classIconHost:CreateTexture(nil, "ARTWORK")
	row.classIcon:SetAllPoints(row.classIconHost)

	row.specIconHost = CreateFrame("Frame", nil, row)
	row.specIconHost:SetSize(UI.ROSTER_ICON, UI.ROSTER_ICON)
	row.specIconHost:SetPoint(
		"LEFT",
		row,
		"TOPLEFT",
		HistoryColumnOffset(3) + TableIconInset(UI.HISTORY_COL_SPEC, UI.ROSTER_ICON),
		TableIconTopOffset(UI.ROSTER_ICON)
	)
	row.specIcon = row.specIconHost:CreateTexture(nil, "ARTWORK")
	row.specIcon:SetAllPoints(row.specIconHost)

	row.gsText = AddTextColumn(4, "CENTER")
	row.ilvlText = AddTextColumn(5, "CENTER")
	row.zoneText = AddTextColumn(6, "LEFT")
	row.metText = AddTextColumn(7, "LEFT")
	row.guildText = AddTextColumn(8, "LEFT")

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
		self:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
	end)
	row:SetScript("OnLeave", function(self)
		local stripe = self.stripe or UI.CD_ROW_A
		self:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
	end)
	row:SetScript("OnClick", function(self)
		if self.member then
			Addon:ShowRaidCharacterWindow(self.member)
		end
	end)

	return row
end

local function CreateHistoryPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", page, "RIGHT", -90, 0)
	hint:SetJustifyH("LEFT")
	hint:SetJustifyV("TOP")
	hint:SetText("Players from your parties and raids. Saved on this account.")

	local refreshBtn = CreatePlainButton(page, 80, UI.CD_TOOLBAR_H, "Refresh")
	refreshBtn:SetPoint("TOPRIGHT", 0, 0)
	refreshBtn:SetScript("OnClick", function()
		if Addon.RecordCurrentGroupHistory then
			Addon:RecordCurrentGroupHistory(true)
		end
		Addon:RefreshHistoryView()
	end)

	local tableTop = -CooldownTableTopOffset()
	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableTop)
	tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	ApplyPlainPanel(tableHost, UI.PANEL_BG)
	page.tableHost = tableHost

	local scroll = CreateFrame("ScrollFrame", "RaidwiseHistoryScroll", tableHost)
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
	ApplyPlainPanel(headerBg, UI.TITLE_BG)
	page.headerBg = headerBg

	local headers = { "Name", "Class", "Spec", "GS", "iLvl", "Met in", "When", "Guild" }
	page.headerLabels = {}
	for index = 1, #headers do
		local label = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", headerBg, "TOPLEFT", HistoryColumnOffset(index) + 4, -10)
		label:SetWidth(HISTORY_COLUMN_WIDTHS[index] - 8)
		label:SetJustifyH((index >= 4 and index <= 5) and "CENTER" or "LEFT")
		label:SetText(headers[index])
		SetFontColor(label, UI.GOLD)
		page.headerLabels[index] = label
	end

	local vBar = CreateCooldownScrollBar(tableHost, "VERTICAL")
	vBar:SetPoint("TOPRIGHT", -1, -1)
	vBar:SetPoint("BOTTOMRIGHT", -1, UI.CD_HSCROLL_H + 2)
	vBar:SetScript("OnValueChanged", function(self)
		scroll:SetVerticalScroll(self:GetValue() or 0)
	end)
	page.vBar = vBar

	local hBar = CreateCooldownScrollBar(tableHost, "HORIZONTAL")
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
		LayoutCooldownScrollBars(page)
	end)

	page:SetScript("OnShow", function()
		Addon:RefreshHistoryView()
	end)

	page.hint = hint
	page.refreshBtn = refreshBtn
	return page
end

function Addon:RefreshHistoryView()
	local frame = self.mainFrame
	local page = frame and frame.pages and frame.pages.history
	if not page then
		return
	end

	if not self.BuildHistoryRoster then
		if page.hint then
			page.hint:SetText("History module failed to load. Reload UI (/reload).")
		end
		return
	end

	page.tableHost:Show()

	local roster = self:BuildHistoryRoster()
	local content = page.tableContent
	local headerBg = page.headerBg
	local tableW = HistoryTableWidth()
	local tableH = UI.CD_HEADER_H + math.max(#roster, 1) * UI.CD_ROW_H

	content:SetSize(tableW, tableH)
	headerBg:SetWidth(tableW)

	HidePoolFrom(page.rowFrames, #roster + 1)
	for rowIndex = 1, #roster do
		local member = roster[rowIndex]
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreateHistoryRow(content)
			page.rowFrames[rowIndex] = row
		end

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(UI.CD_HEADER_H + (rowIndex - 1) * UI.CD_ROW_H))
		row:SetSize(tableW, UI.CD_ROW_H)
		local stripe = (rowIndex % 2 == 1) and UI.CD_ROW_A or UI.CD_ROW_B
		row.stripe = stripe
		row:SetBackdropColor(stripe[1], stripe[2], stripe[3], stripe[4])
		row.member = member

		row.nameText:SetText(member.name or "")
		row.nameText:SetTextColor(ClassColor(member.class))
		row.classLabel = member.classLabel
		row.specLabel = member.spec
		SetSpecOrClassIcon(row.classIcon, nil, member.class)
		SetSpecOrClassIcon(row.specIcon, member.specIcon, member.class)

		if member.gearScore then
			row.gsText:SetText(tostring(member.gearScore))
			SetFontColor(row.gsText, UI.GOLD)
		else
			row.gsText:SetText("-")
			SetFontColor(row.gsText, UI.TEXT_DISABLED)
		end

		if member.averageIlvl then
			row.ilvlText:SetText(tostring(member.averageIlvl))
			SetFontColor(row.ilvlText, UI.TEXT_IDLE)
		else
			row.ilvlText:SetText("-")
			SetFontColor(row.ilvlText, UI.TEXT_DISABLED)
		end

		if member.metZone and member.metZone ~= "" then
			row.zoneText:SetText(member.metZone)
			SetFontColor(row.zoneText, UI.TEXT_IDLE)
		else
			row.zoneText:SetText("-")
			SetFontColor(row.zoneText, UI.TEXT_DISABLED)
		end

		local metWhen = self:FormatHistoryTime(member.metAt)
		row.metText:SetText(metWhen)
		if metWhen ~= "-" then
			SetFontColor(row.metText, UI.TEXT_IDLE)
		else
			SetFontColor(row.metText, UI.TEXT_DISABLED)
		end

		row.guildText:SetText(FormatGuildDisplay(member.guildName, member.guildRank))
		SetFontColor(row.guildText, UI.TEXT_IDLE)
		row:Show()
	end

	LayoutCooldownScrollBars(page)
end

-- Build the main frame once; store on Addon.mainFrame.
function Addon:CreateMainFrame()
	if self.mainFrame then
		return self.mainFrame
	end

	local frame = CreateFrame("Frame", "RaidwiseFrame", UIParent)
	frame:SetSize(UI.CONTENT_WIDTH, UI.CONTENT_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetClampRectInsets(-(UI.MENU_WIDTH + UI.MENU_GAP), 0, 0, -(UI.STATUS_H + UI.MENU_GAP))
	frame:Hide()
	ApplyPlainPanel(frame)
	tinsert(UISpecialFrames, "RaidwiseFrame")

	CreateTitleBar(frame)

	local menu = CreateFrame("Frame", "RaidwiseMenu", frame)
	menu:SetWidth(UI.MENU_WIDTH)
	menu:SetPoint("TOPRIGHT", frame, "TOPLEFT", -UI.MENU_GAP, 0)
	menu:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -UI.MENU_GAP, 0)
	ApplyPlainPanel(menu)
	menu:EnableMouse(true)

	local menuTitleBar = CreateFrame("Frame", nil, menu)
	menuTitleBar:SetPoint("TOPLEFT", 1, -1)
	menuTitleBar:SetPoint("TOPRIGHT", -1, -1)
	menuTitleBar:SetHeight(UI.TITLE_H)
	ApplyPlainPanel(menuTitleBar, UI.TITLE_BG)
	AttachDragHandle(menuTitleBar, frame)

	local menuTitle = menuTitleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	menuTitle:SetPoint("CENTER", 0, 0)
	menuTitle:SetText("Menu")
	SetFontColor(menuTitle, UI.GOLD)

	frame.menuButtons = {}
	local menuY = -(UI.TITLE_H + 8)
	for i = 1, #PAGES do
		local pageInfo = PAGES[i]
		local button = CreateMenuButton(menu, pageInfo.id, pageInfo.label, menuY)
		frame.menuButtons[#frame.menuButtons + 1] = button
		menuY = menuY - UI.MENU_BTN_H - UI.MENU_BTN_GAP
	end

	local statusBar = CreateFrame("Frame", nil, frame)
	statusBar:SetHeight(UI.STATUS_H)
	statusBar:SetPoint("TOPLEFT", menu, "BOTTOMLEFT", 0, -UI.MENU_GAP)
	statusBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -UI.MENU_GAP)
	ApplyPlainPanel(statusBar, UI.TITLE_BG)

	local nameLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameLabel:SetPoint("LEFT", UI.STATUS_PAD_X, 0)
	nameLabel:SetText("Raidwise")
	SetFontColor(nameLabel, UI.GOLD)

	local versionLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	versionLabel:SetPoint("LEFT", nameLabel, "RIGHT", UI.STATUS_GAP, 0)
	versionLabel:SetText("v" .. tostring(Addon.version))
	SetFontColor(versionLabel, UI.TEXT_IDLE)

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", UI.PAD, -(UI.TITLE_H + UI.PAD))
	content:SetPoint("BOTTOMRIGHT", -UI.PAD, UI.PAD)

	frame.pages = {}
	local cooldownsPage = CreateCooldownsPage(content)
	frame.pages.cooldowns = cooldownsPage
	cooldownsPage:Hide()

	local partyPage = CreatePartyPage(content)
	frame.pages.party = partyPage
	partyPage:Hide()

	local raidPage = CreateRaidRosterPage(content)
	frame.pages.raid = raidPage
	raidPage:Hide()

	local historyPage = CreateHistoryPage(content)
	frame.pages.history = historyPage
	historyPage:Hide()

	local exportPage = CreateExportPage(content)
	frame.pages.export = exportPage
	frame.exportBox = exportPage.exportBox
	frame.statusLabel = exportPage.statusLabel
	frame.selectBtn = exportPage.selectBtn
	exportPage:Hide()

	local cooldownExportPage = CreateCooldownExportPage(content)
	frame.pages.exportCooldowns = cooldownExportPage
	frame.cooldownExportBox = cooldownExportPage.exportBox
	frame.cooldownExportStatus = cooldownExportPage.statusLabel
	frame.cooldownExportSelectBtn = cooldownExportPage.selectBtn
	cooldownExportPage:Hide()

	local infoPage = CreateInfoPage(content)
	frame.pages.info = infoPage
	frame.repoBox = infoPage.repoBox
	frame.repoHint = infoPage.repoHint
	infoPage:Hide()

	self.mainFrame = frame
	self:SelectTab("cooldowns")
	return frame
end

-- Focus the export box and highlight all text for Ctrl+C.
function Addon:SelectExportText()
	local frame = self.mainFrame
	if not frame or not frame.exportBox then
		return
	end
	local exportBox = frame.exportBox
	if (exportBox:GetText() or "") == "" then
		return
	end
	self:SelectTab("export")
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.statusLabel then
		frame.statusLabel:SetText("Selected — press Ctrl+C to copy.")
	end
end

-- Focus the cooldown export box and highlight all text for Ctrl+C.
function Addon:SelectCooldownExportText()
	local frame = self.mainFrame
	if not frame or not frame.cooldownExportBox then
		return
	end
	local exportBox = frame.cooldownExportBox
	if (exportBox:GetText() or "") == "" then
		return
	end
	self:SelectTab("exportCooldowns")
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.cooldownExportStatus then
		frame.cooldownExportStatus:SetText("Selected — press Ctrl+C to copy.")
	end
end

-- Write the account-wide cooldown export into the main window EditBox.
function Addon:FlushCooldownExportToWindow()
	local frame = self.mainFrame
	if not frame or not frame.cooldownExportBox then
		return
	end
	self:SelectTab("exportCooldowns")
	local exportBox = frame.cooldownExportBox
	local text = self:FormatCooldownsExport()
	exportBox:SetText(text)
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.cooldownExportSelectBtn then
		frame.cooldownExportSelectBtn:Enable()
	end
	if frame.cooldownExportStatus then
		frame.cooldownExportStatus:SetText("Export ready — press Ctrl+C to copy.")
	end
end

-- Write the current character export into the main window EditBox.
function Addon:FlushExportToWindow()
	local frame = self.mainFrame
	if not frame or not frame.exportBox then
		return
	end
	self:SelectTab("export")
	local exportBox = frame.exportBox
	local text = self:FormatEquippedGearExport()
	exportBox:SetText(text)
	exportBox:SetFocus()
	exportBox:HighlightText()
	if frame.selectBtn then
		frame.selectBtn:Enable()
	end
	if frame.statusLabel then
		frame.statusLabel:SetText("Export ready — press Ctrl+C to copy.")
	end
end

function Addon:SelectRepoUrl()
	local frame = self.mainFrame
	if not frame or not frame.repoBox then
		return
	end
	self:SelectTab("info")
	local repoBox = frame.repoBox
	repoBox:SetText(GITHUB_URL)
	repoBox:SetFocus()
	repoBox:HighlightText()
	if frame.repoHint then
		frame.repoHint:SetText("Selected — press Ctrl+C to copy.")
	end
end

-- Show the main window (creates it if needed).
function Addon:ShowMainFrame()
	local frame = self:CreateMainFrame()
	self:SelectTab(frame.selectedTab or "cooldowns")
	frame:Show()
	frame:Raise()
end

-- Hide the main window if it exists.
function Addon:HideMainFrame()
	if self.mainFrame then
		self.mainFrame:Hide()
	end
end

-- Toggle the main window visibility.
function Addon:ToggleMainFrame()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:HideMainFrame()
	else
		self:ShowMainFrame()
	end
end
