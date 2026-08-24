-- Details-style shell: plain panels, left menu, tabbed content pages.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

local SHELL_LAYOUT_VERSION = 5

local MENU_ICON_SIZE = 16

-- WotLK Interface\Icons paths (one per left-menu category).
local PAGES = {
	{ id = "cooldowns", key = "Cooldowns", labelKey = "TAB_COOLDOWNS", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
	{ id = "export", key = "Export", labelKey = "TAB_EXPORT", icon = "Interface\\Icons\\INV_Misc_Note_01" },
	{ id = "party", key = "Party", labelKey = "TAB_PARTY", icon = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude" },
	{ id = "raid", key = "Raid", labelKey = "TAB_RAID", icon = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider" },
	{ id = "composition", key = "Composition", labelKey = "TAB_COMPOSITION", icon = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings" },
	{ id = "geartarget", key = "GearCheckTarget", labelKey = "TAB_GEAR_CHECK_TARGET", icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
	{ id = "gearraid", key = "GearCheckRaid", labelKey = "TAB_GEAR_CHECK_RAID", icon = "Interface\\Icons\\INV_Chest_Plate_23" },
	{ id = "history", key = "History", labelKey = "TAB_HISTORY", icon = "Interface\\Icons\\INV_Misc_Book_11" },
	{ id = "settings", key = "Settings", labelKey = "TAB_SETTINGS", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
	{ id = "info", key = "Info", labelKey = "TAB_INFO", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
}

Addon.MenuPages = PAGES

local function PageInfoById(tabId)
	for index = 1, #PAGES do
		if PAGES[index].id == tabId then
			return PAGES[index]
		end
	end
	return nil
end

-- Info is reference-only; not a valid /raidwise startup page.
local function IsAllowedStartupTab(tabId)
	return type(tabId) == "string" and tabId ~= "info" and PageInfoById(tabId) ~= nil
end

function Addon:GetStartupTab()
	local tabId = self.db and self.db.startupTab
	if IsAllowedStartupTab(tabId) then
		return tabId
	end
	if self.db and self.db.startupTab == "info" then
		self.db.startupTab = "cooldowns"
	end
	return "cooldowns"
end

function Addon:SetStartupTab(tabId)
	if not self.db or not IsAllowedStartupTab(tabId) then
		return
	end
	self.db.startupTab = tabId
end

function Addon:IsAllowedStartupTab(tabId)
	return IsAllowedStartupTab(tabId)
end

local function UpdateShellHeader(frame, tabId)
	if not frame then
		return
	end
	local pageInfo = PageInfoById(tabId)
	if frame.titleText then
		if pageInfo then
			frame.titleText:SetText(W.T(pageInfo.labelKey))
		else
			frame.titleText:SetText("Raidwise")
		end
	end
	if not frame.pageLayoutVersionText then
		return
	end
	local version
	local page = frame.pages and frame.pages[tabId]
	if page and page.layoutVersion then
		version = page.layoutVersion
	elseif pageInfo and Addon.Pages and Addon.Pages[pageInfo.key] then
		version = Addon.Pages[pageInfo.key].LAYOUT_VERSION
	end
	if version then
		frame.pageLayoutVersionText:SetText("v" .. tostring(version))
		frame.pageLayoutVersionText:Show()
	else
		frame.pageLayoutVersionText:Hide()
	end
end

local function PageLayoutStale(frame)
	if not frame or not frame.pages then
		return true
	end
	for index = 1, #PAGES do
		local pageInfo = PAGES[index]
		local pageModule = Addon.Pages and Addon.Pages[pageInfo.key]
		local page = frame.pages[pageInfo.id]
		if not pageModule or not page then
			return true
		end
		if page.layoutVersion ~= pageModule.LAYOUT_VERSION then
			return true
		end
	end
	return false
end

local function ShellNeedsRebuild(frame)
	if not frame then
		return true
	end
	if frame.layoutVersion ~= SHELL_LAYOUT_VERSION then
		return true
	end
	return PageLayoutStale(frame)
end

local function TearDownMainFrame(frame)
	if not frame then
		return
	end
	frame:Hide()
	W.DetachFrameChildren(frame)
	frame:SetParent(nil)
end

local function EnsureSpecialFrame(name, flagOwner)
	if flagOwner and flagOwner.rwInSpecialFrames then
		return
	end
	local found = false
	for index = 1, #UISpecialFrames do
		if UISpecialFrames[index] == name then
			found = true
			break
		end
	end
	if not found then
		tinsert(UISpecialFrames, name)
	end
	if flagOwner then
		flagOwner.rwInSpecialFrames = true
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
		W.SetMenuButtonState(button, button.tabId == tabId, false)
	end
	UpdateShellHeader(frame, tabId)

	if tabId == "cooldowns" then
		self.pendingLockoutTable = true
		self:SaveCurrentCharacterLockouts()
		RequestRaidInfo()
		self:RefreshCooldownTable()
	elseif tabId == "party" or tabId == "raid" or tabId == "composition" then
		self:RefreshPartyData(true)
	elseif tabId == "history" then
		if self.RecordCurrentGroupHistory then
			self:RecordCurrentGroupHistory(false)
		elseif self.RefreshHistoryView then
			self:RefreshHistoryView()
		end
	elseif tabId == "geartarget" then
		if self.RefreshGearCheckTargetView then
			self:RefreshGearCheckTargetView(false)
		end
	elseif tabId == "gearraid" then
		if self.RefreshGearCheckRaidView then
			self:RefreshGearCheckRaidView(false)
		end
	end
end

local function CreateTitleBar(frame)
	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 1, -1)
	titleBar:SetPoint("TOPRIGHT", -1, -1)
	titleBar:SetHeight(UI.TITLE_H)
	W.ApplyPlainPanel(titleBar, UI.TITLE_BG)
	W.AttachDragHandle(titleBar, frame)

	local close = CreateFrame("Button", nil, titleBar)
	close:SetSize(UI.CLOSE_SIZE, UI.CLOSE_SIZE)
	close:SetPoint("RIGHT", -3, 0)
	local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	closeText:SetPoint("CENTER", 1, 1)
	closeText:SetText("X")
	W.SetFontColor(closeText, UI.GOLD)
	close:SetScript("OnEnter", function()
		closeText:SetTextColor(1, 0.25, 0.25)
	end)
	close:SetScript("OnLeave", function()
		W.SetFontColor(closeText, UI.GOLD)
	end)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", 8, 0)
	title:SetJustifyH("LEFT")
	title:SetText("Raidwise")
	W.SetFontColor(title, UI.GOLD)

	local pageLayoutVersionText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	pageLayoutVersionText:SetPoint("LEFT", title, "RIGHT", 8, 0)
	pageLayoutVersionText:SetJustifyH("LEFT")
	pageLayoutVersionText:SetText("")
	W.SetFontColor(pageLayoutVersionText, UI.TEXT_DISABLED)

	frame.titleBar = titleBar
	frame.titleText = title
	frame.pageLayoutVersionText = pageLayoutVersionText
	return titleBar
end

local function CreateMenuButton(parent, tabId, label, yOffset, iconPath)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(UI.MENU_WIDTH - 12, UI.MENU_BTN_H)
	button:SetPoint("TOP", 0, yOffset)
	W.ApplyPlainPanel(button, UI.BTN_IDLE)
	button.tabId = tabId

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(MENU_ICON_SIZE, MENU_ICON_SIZE)
	icon:SetPoint("LEFT", 4, 0)
	if iconPath and iconPath ~= "" then
		icon:SetTexture(iconPath)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end
	button.icon = icon

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
	text:SetPoint("RIGHT", -4, 0)
	text:SetJustifyH("LEFT")
	text:SetText(label)
	W.SetFontColor(text, UI.TEXT_IDLE)
	button.label = text

	button:SetScript("OnEnter", function(self)
		W.SetMenuButtonState(self, Addon.mainFrame and Addon.mainFrame.selectedTab == tabId, true)
	end)
	button:SetScript("OnLeave", function(self)
		W.SetMenuButtonState(self, Addon.mainFrame and Addon.mainFrame.selectedTab == tabId, false)
	end)
	button:SetScript("OnClick", function()
		Addon:SelectTab(tabId)
	end)

	return button
end

local function ApplyPageHeaders(page)
	if not page or not page.headerLabels or not page.headerKeys then
		return
	end
	for index = 1, #page.headerKeys do
		local label = page.headerLabels[index]
		if label then
			label:SetText(W.T(page.headerKeys[index]))
		end
	end
end

-- REFACTOR candidate: shell rebuild — menu, status bar, all pages, layout-version checks.
function Addon:CreateMainFrame()
	if self.mainFrame and not ShellNeedsRebuild(self.mainFrame) then
		return self.mainFrame
	end

	local previousTab = self.mainFrame and self.mainFrame.selectedTab

	if self.mainFrame then
		TearDownMainFrame(self.mainFrame)
		self.mainFrame = nil
	end

	-- Named frames are reused by CreateFrame; clear leftover children first.
	local frame = CreateFrame("Frame", "RaidwiseFrame", UIParent)
	W.DetachFrameChildren(frame)
	frame:SetSize(UI.CONTENT_WIDTH, UI.CONTENT_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetClampRectInsets(-(UI.MENU_WIDTH + UI.MENU_GAP), 0, 0, -(UI.STATUS_H + UI.MENU_GAP))
	frame:Hide()
	W.ApplyPlainPanel(frame)
	frame.layoutVersion = SHELL_LAYOUT_VERSION
	EnsureSpecialFrame("RaidwiseFrame", frame)

	CreateTitleBar(frame)

	local menu = CreateFrame("Frame", "RaidwiseMenu", frame)
	W.DetachFrameChildren(menu)
	menu:SetWidth(UI.MENU_WIDTH)
	menu:SetPoint("TOPRIGHT", frame, "TOPLEFT", -UI.MENU_GAP, 0)
	menu:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -UI.MENU_GAP, 0)
	W.ApplyPlainPanel(menu)
	menu:EnableMouse(true)

	local menuTitleBar = CreateFrame("Frame", nil, menu)
	menuTitleBar:SetPoint("TOPLEFT", 1, -1)
	menuTitleBar:SetPoint("TOPRIGHT", -1, -1)
	menuTitleBar:SetHeight(UI.TITLE_H)
	W.ApplyPlainPanel(menuTitleBar, UI.TITLE_BG)
	W.AttachDragHandle(menuTitleBar, frame)

	local menuTitle = menuTitleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	menuTitle:SetPoint("CENTER", 0, 0)
	menuTitle:SetText(W.T("MENU"))
	W.SetFontColor(menuTitle, UI.GOLD)
	frame.menuTitle = menuTitle

	frame.menuButtons = {}
	local menuY = -(UI.TITLE_H + 8)
	for index = 1, #PAGES do
		local pageInfo = PAGES[index]
		local button = CreateMenuButton(menu, pageInfo.id, W.T(pageInfo.labelKey), menuY, pageInfo.icon)
		frame.menuButtons[#frame.menuButtons + 1] = button
		menuY = menuY - UI.MENU_BTN_H - UI.MENU_BTN_GAP
	end

	local statusBar = CreateFrame("Frame", nil, frame)
	statusBar:SetHeight(UI.STATUS_H)
	statusBar:SetPoint("TOPLEFT", menu, "BOTTOMLEFT", 0, -UI.MENU_GAP)
	statusBar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -UI.MENU_GAP)
	W.ApplyPlainPanel(statusBar, UI.TITLE_BG)

	local nameLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameLabel:SetPoint("LEFT", UI.STATUS_PAD_X, 0)
	nameLabel:SetText("Raidwise")
	W.SetFontColor(nameLabel, UI.GOLD)

	local versionLabel = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	versionLabel:SetPoint("LEFT", nameLabel, "RIGHT", UI.STATUS_GAP, 0)
	versionLabel:SetText("v" .. tostring(Addon.version))
	W.SetFontColor(versionLabel, UI.TEXT_IDLE)

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", UI.PAD, -(UI.TITLE_H + UI.PAD))
	content:SetPoint("BOTTOMRIGHT", -UI.PAD, UI.PAD)

	frame.pages = {}
	for index = 1, #PAGES do
		local pageInfo = PAGES[index]
		local pageModule = Addon.Pages and Addon.Pages[pageInfo.key]
		if pageModule and pageModule.Create then
			local page = pageModule.Create(content)
			frame.pages[pageInfo.id] = page
			page:Hide()
			if pageInfo.id == "export" then
				frame.exportBox = page.exportBox
				frame.statusLabel = page.statusLabel
				frame.selectBtn = page.selectBtn
			elseif pageInfo.id == "info" then
				frame.repoBox = page.repoBox
				frame.repoHint = page.repoHint
			end
		end
	end

	self.mainFrame = frame
	self:SelectTab(previousTab or self:GetStartupTab())
	return frame
end

-- REFACTOR candidate: repetitive per-page string refresh; easy to miss a tab when adding pages.
function Addon:RefreshLocalizedUI()
	local frame = self.mainFrame
	if not frame then
		return
	end

	if frame.menuTitle then
		frame.menuTitle:SetText(W.T("MENU"))
	end
	for index = 1, #PAGES do
		local button = frame.menuButtons[index]
		if button and PAGES[index] then
			button.label:SetText(W.T(PAGES[index].labelKey))
			W.SetMenuButtonState(button, button.tabId == frame.selectedTab, false)
		end
	end
	UpdateShellHeader(frame, frame.selectedTab)

	local exportPage = frame.pages.export
	if exportPage then
		if exportPage.desc then
			exportPage.desc:SetText(W.T("EXPORT_DESC"))
		end
		if exportPage.namesLabel then
			exportPage.namesLabel:SetText(W.T("EXPORT_INCLUDE_NAMES"))
		end
		if exportPage.exportBtn then
			exportPage.exportBtn.label:SetText(W.T("BTN_EXPORT_DATA"))
		end
		if exportPage.selectBtn then
			exportPage.selectBtn.label:SetText(W.T("BTN_SELECT_ALL"))
		end
		if exportPage.statusLabel then
			local exported = frame.exportBox and (frame.exportBox:GetText() or "") ~= ""
			exportPage.statusLabel:SetText(exported and W.T("EXPORT_READY") or W.T("EXPORT_HINT"))
		end
	end

	local settingsPage = frame.pages.settings
	if settingsPage then
		local settingsModule = Addon.Pages and Addon.Pages.Settings
		if settingsModule and settingsModule.ApplyLocale then
			settingsModule.ApplyLocale(settingsPage)
		else
			if settingsPage.heading then
				settingsPage.heading:SetText(W.T("SETTINGS_LANGUAGE"))
			end
			if settingsPage.hint then
				settingsPage.hint:SetText(W.T("SETTINGS_LANGUAGE_HINT"))
			end
			if settingsPage.enBtn then
				settingsPage.enBtn.label:SetText(W.T("LOCALE_EN"))
			end
			if settingsPage.ruBtn then
				settingsPage.ruBtn.label:SetText(W.T("LOCALE_RU"))
			end
			if settingsModule and settingsModule.UpdateLocaleButtons then
				settingsModule.UpdateLocaleButtons(settingsPage)
			end
		end
	end

	local infoPage = frame.pages.info
	if infoPage then
		local infoModule = Addon.Pages and Addon.Pages.Info
		if infoModule and infoModule.Refresh then
			infoModule.Refresh(infoPage)
		end
	end

	local cooldownsPage = frame.pages.cooldowns
	if cooldownsPage then
		if cooldownsPage.hint then
			cooldownsPage.hint:SetText(W.T("CD_HINT"))
		end
		if cooldownsPage.refreshBtn then
			cooldownsPage.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
		end
		if cooldownsPage.emptyLabel then
			cooldownsPage.emptyLabel:SetText(W.T("CD_EMPTY"))
		end
		if cooldownsPage.instanceHeader then
			cooldownsPage.instanceHeader:SetText(W.T("CD_INSTANCE"))
		end
		if cooldownsPage.noRowsLabel then
			cooldownsPage.noRowsLabel:SetText(W.T("CD_NO_ROWS"))
		end
	end

	local partyPage = frame.pages.party
	if partyPage then
		if partyPage.hint then
			partyPage.hint:SetText(W.T("PARTY_HINT"))
		end
		if partyPage.refreshBtn then
			partyPage.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
		end
		ApplyPageHeaders(partyPage)
	end

	local raidPage = frame.pages.raid
	if raidPage then
		if raidPage.hint then
			raidPage.hint:SetText(W.T("RAID_HINT"))
		end
		if raidPage.refreshBtn then
			raidPage.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
		end
	end

	local compositionPage = frame.pages.composition
	if compositionPage then
		if compositionPage.hint then
			compositionPage.hint:SetText(W.T("COMP_HINT"))
		end
		if compositionPage.refreshBtn then
			compositionPage.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
		end
		if compositionPage.reportBtn then
			compositionPage.reportBtn.label:SetText(W.T("BTN_COMP_REPORT"))
		end
	end

	local gearTargetPage = frame.pages.geartarget
	if gearTargetPage then
		local gearTargetModule = Addon.Pages and Addon.Pages.GearCheckTarget
		if gearTargetModule and gearTargetModule.ApplyLocale then
			gearTargetModule.ApplyLocale(gearTargetPage)
		end
	end

	local gearRaidPage = frame.pages.gearraid
	if gearRaidPage then
		local gearRaidModule = Addon.Pages and Addon.Pages.GearCheckRaid
		if gearRaidModule and gearRaidModule.ApplyLocale then
			gearRaidModule.ApplyLocale(gearRaidPage)
		end
	end

	local historyPage = frame.pages.history
	if historyPage then
		if historyPage.hint then
			historyPage.hint:SetText(W.T("HISTORY_HINT"))
		end
		if historyPage.refreshBtn then
			historyPage.refreshBtn.label:SetText(W.T("BTN_REFRESH"))
		end
		ApplyPageHeaders(historyPage)
	end

	if self.RefreshCooldownTable then
		self:RefreshCooldownTable()
	end
	if self.RefreshPartyView then
		self:RefreshPartyView(false)
	end
	if self.RefreshRaidRosterView then
		self:RefreshRaidRosterView(false)
	end
	if self.RefreshCompositionView then
		self:RefreshCompositionView(false)
	end
	if self.RefreshHistoryView then
		self:RefreshHistoryView()
	end

	if self.raidDetailFrame and self.raidDetailFrame:IsShown() and self.raidDetailFrame.profileMember then
		self:ShowRaidCharacterWindow(self.raidDetailFrame.profileMember)
	end
end

function Addon:ShowMainFrame()
	local frame = self:CreateMainFrame()
	-- Prefer configured startup tab each time the window is opened.
	self:SelectTab(self:GetStartupTab())
	frame:Show()
	frame:Raise()
end

function Addon:HideMainFrame()
	if self.mainFrame then
		self.mainFrame:Hide()
	end
end

-- DELETE candidate: no callers; slash handler uses ShowMainFrame / HideMainFrame directly.
function Addon:ToggleMainFrame()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:HideMainFrame()
	else
		self:ShowMainFrame()
	end
end
