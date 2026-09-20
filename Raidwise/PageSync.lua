-- Explicit profile sharing and reviewed imports; no background database merging.
local Addon = Raidwise
local W = Addon.Widgets
local LAYOUT_VERSION = 3
Addon.Pages = Addon.Pages or {}

local function text(parent, x, y, width, value)
	local label = W.CreateFontString(parent, nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(value or "")
	return label
end

local function input(parent, x, y, width)
	local box, host = W.CreateTextInput(parent, width)
	host:SetPoint("TOPLEFT", x, y)
	box:SetMaxLetters(150)
	return box
end

local function button(parent, x, y, width, key, callback)
	local control = W.CreatePlainButton(parent, width, 24, W.T(key))
	control:SetPoint("TOPLEFT", x, y); control:SetScript("OnClick", callback)
	control.syncKey = key
	parent.syncButtons = parent.syncButtons or {}; parent.syncButtons[#parent.syncButtons + 1] = control
	return control
end

local function result(ok, err)
	if not ok then Addon.syncStatus = W.T(err or "SYNC_INVALID") end
	Addon:RefreshSyncView()
end

function Addon:OpenSyncView(guid)
	self.syncSelectedGuid = guid
	self:SelectTab("sync")
	self:RefreshSyncView()
end

function Addon:ShowSyncShareMenu(anchor, guid)
	if not anchor then return end
	if self.syncShareMenu then
		local menu = self.syncShareMenu
		if menu:IsShown() and menu.anchor == anchor and menu.guid == guid then
			menu:Hide()
			return
		end
		menu.anchor, menu.guid, menu.age = anchor, guid, 0
		menu:ClearAllPoints(); menu:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
		for _, control in ipairs(menu.syncButtons) do control.label:SetText(W.T(control.syncKey)) end
		menu:Show(); return
	end
	local menu = CreateFrame("Frame", nil, UIParent)
	menu.anchor, menu.guid = anchor, guid
	menu:SetSize(170, 122); menu:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
	menu:SetFrameStrata("TOOLTIP"); W.ApplyPlainPanel(menu); W.ApplyOuterBorder(menu)
	menu:Hide()
	local close = CreateFrame("Button", nil, menu)
	close:SetSize(16, 16); close:SetPoint("TOPRIGHT", -2, -2)
	local closeText = W.CreateFontString(close, nil, "OVERLAY", "GameFontNormalSmall")
	closeText:SetPoint("CENTER", 0, 0); closeText:SetText("X")
	W.SetFontColor(closeText, Addon.UITheme.GOLD)
	close:SetScript("OnEnter", function() W.SetFontColor(closeText, Addon.UITheme.TEXT_ALERT) end)
	close:SetScript("OnLeave", function() W.SetFontColor(closeText, Addon.UITheme.GOLD) end)
	close:SetScript("OnClick", function() menu:Hide() end)
	menu.closeButton = close
	for index, channel in ipairs({"WHISPER", "GUILD", "RAID"}) do
		button(menu, 4, -4 - (index - 1) * 28, 162, "SYNC_TO_" .. channel, function()
			menu:Hide()
			local ok, err = Addon:ShareSyncData(menu.guid, channel)
			if Addon.Print then Addon:Print(W.T(ok and "SYNC_OFFER_SENT" or err)) end
		end)
	end
	button(menu, 4, -88, 162, "TAB_SYNC", function() menu:Hide(); Addon:OpenSyncView(menu.guid) end)
	menu:SetScript("OnUpdate", function(self, delta) self.age=(self.age or 0)+delta; if self.age > 15 or not self.anchor:IsShown() then self:Hide() end end)
	self.syncShareMenu = menu
	menu:Show()
end

function Addon:HideSyncShareMenu()
	if self.syncShareMenu then self.syncShareMenu:Hide() end
end

local function create(parent)
	local page = CreateFrame("Frame", nil, parent); page:SetAllPoints(parent); page.layoutVersion=LAYOUT_VERSION
	local width = W.ContentInnerWidth(); local half = math.floor((width - 24) / 2); local right = half + 24
	page.labels = {}
	local function label(key, x, y, size)
		local value = text(page, x, y, size, W.T(key)); page.labels[#page.labels + 1] = {value, key}; return value
	end
	label("SYNC_DESCRIPTION", 0, 0, width)
	label("SYNC_SEARCH", 0, -44, half)
	page.search = input(page, 0, -64, half)
	page.search:SetScript("OnTextChanged", function() Addon:RefreshSyncView() end)
	page.matches = {}
	for index = 1, 3 do
		local row = button(page, 0, -94 - (index - 1) * 25, half, "SYNC_SELECT", function()
			Addon.syncSelectedGuid = page.matches[index].guid; Addon:RefreshSyncView()
		end)
		row.syncKey = nil; page.matches[index] = row
	end
	page.selected = text(page, 0, -174, half)
	for index, channel in ipairs({"WHISPER", "GUILD", "RAID"}) do
		local x = (index - 1) * math.floor((half + 4) / 3)
		local share = button(page, x, -197, math.floor((half - 8) / 3), "SYNC_TO_" .. channel, function()
			if not Addon.syncSelectedGuid then result(nil, "SYNC_SELECT"); return end
			result(Addon:ShareSyncData(Addon.syncSelectedGuid, channel))
		end)
		page.selectedButtons = page.selectedButtons or {}; page.selectedButtons[#page.selectedButtons + 1] = share
		button(page, x, -228, math.floor((half - 8) / 3), "SYNC_ALL_" .. channel, function() result(Addon:ShareSyncData(nil, channel)) end)
	end
	label("SYNC_REQUESTS", right, -44, half)
	page.request = text(page, right, -66, half); page.request:SetHeight(48)
	page.accept = button(page, right, -118, 126, "SYNC_RECEIVE", function() result(Addon:AcceptSyncOffer()) end)
	page.reject = button(page, right + 132, -118, 126, "SYNC_DECLINE", function() Addon:RejectSyncOffer(false) end)
	page.ignore = button(page, right + 264, -118, half - 264, "SYNC_IGNORE", function() Addon:RejectSyncOffer(true) end)
	label("SYNC_IGNORE_NAME", right, -155, half)
	page.ignoreName = input(page, right, -175, half - 176)
	page.ignoreName:SetScript("OnTextChanged", function() page.ignoredOffset = 0; Addon:RefreshSyncView() end)
	button(page, right + half - 168, -175, 80, "SYNC_IGNORE", function() Addon:SetSyncSenderIgnored(page.ignoreName:GetText(), true) end)
	button(page, right + half - 82, -175, 82, "SYNC_UNIGNORE", function() Addon:SetSyncSenderIgnored(page.ignoreName:GetText(), false) end)
	page.ignoredHeading = text(page, right, -207, half)
	page.ignoredRows = {}
	for index = 1, 2 do
		local row = {label=text(page, right, -228 - (index - 1) * 25, half - 94)}
		row.remove = button(page, right + half - 88, -223 - (index - 1) * 25, 88, "SYNC_UNIGNORE", function()
			if row.name then Addon:SetSyncSenderIgnored(row.name, false) end
		end)
		page.ignoredRows[index] = row
	end
	page.ignoredPrevious = button(page, right, -278, 72, "SYNC_PREVIOUS", function()
		page.ignoredOffset = math.max(0, (page.ignoredOffset or 0) - 2); Addon:RefreshSyncView()
	end)
	page.ignoredNext = button(page, right + half - 72, -278, 72, "SYNC_NEXT", function()
		page.ignoredOffset = (page.ignoredOffset or 0) + 2; Addon:RefreshSyncView()
	end)
	page.ignoredCount = text(page, right + 80, -283, half - 160)
	page.disable = button(page, 0, -261, half, "SYNC_DISABLE", function()
		Addon:SetSyncRequestsDisabled(not (Addon.db.sync and Addon.db.sync.disabled))
	end)
	button(page, 0, -292, math.floor((half - 6)/2), "SYNC_STOP_SEND", function() Addon:CancelSyncSending() end)
	button(page, math.floor((half - 6)/2) + 6, -292, math.floor((half - 6)/2), "SYNC_STOP_RECEIVE", function() Addon:CancelSyncReceiving() end)
	page.status = text(page, 0, -323, width); page.status:SetHeight(30)
	label("SYNC_JSON", 0, -354, half)
	button(page, 0, -376, 126, "SYNC_EXPORT_ONE", function()
		if not Addon.syncSelectedGuid then result(nil, "SYNC_SELECT"); return end
		local value, err = Addon:BuildSyncExport(Addon.syncSelectedGuid)
		if value then page.json:SetText(value); page.json:SetFocus(); page.json:HighlightText() else result(nil, err) end
	end)
	button(page, 132, -376, 126, "SYNC_EXPORT_ALL", function()
		local value, err = Addon:BuildSyncExport()
		if value then page.json:SetText(value); page.json:SetFocus(); page.json:HighlightText() else result(nil, err) end
	end)
	button(page, 264, -376, half - 264, "SYNC_PREVIEW", function() result(Addon:StageSyncImport(page.json:GetText(), "JSON", "website")) end)
	local json, host = W.CreateCopyBox(page, "RaidwiseSyncJSONScrollV" .. LAYOUT_VERSION, "RaidwiseSyncJSONBoxV" .. LAYOUT_VERSION)
	host:SetPoint("TOPLEFT", 0, -408); host:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", half, 0)
	json:SetMaxLetters(Addon.SYNC_MAX_BYTES + 1); page.json = json
	label("SYNC_REVIEW", right, -354, half)
	page.apply = button(page, right, -376, 126, "SYNC_APPLY", function()
		local changed, err = Addon:ApplySyncImport()
		if changed then Addon.syncStatus = W.T("SYNC_APPLIED", changed); Addon:RefreshSyncView() else result(nil, err) end
	end)
	page.cancel = button(page, right + 132, -376, 126, "SYNC_DECLINE", function() Addon:CancelSyncImport() end)
	page.ignoreReview = button(page, right + 264, -376, half - 264, "SYNC_IGNORE", function()
		if Addon.syncReview then Addon:SetSyncSenderIgnored(Addon.syncReview.sender, true) end
	end)
	local review, reviewHost = W.CreateCopyBox(page, "RaidwiseSyncReviewScrollV" .. LAYOUT_VERSION, "RaidwiseSyncReviewBoxV" .. LAYOUT_VERSION)
	reviewHost:SetPoint("TOPLEFT", right, -408); reviewHost:SetPoint("BOTTOMRIGHT", 0, 0)
	page.review = review
	Addon.syncPage = page
	return page
end

function Addon:RefreshSyncView()
	local page = self.syncPage
	if not page then return end
	for _, pair in ipairs(page.labels) do pair[1]:SetText(W.T(pair[2])) end
	for _, control in ipairs(page.syncButtons) do if control.syncKey then control.label:SetText(W.T(control.syncKey)) end end
	local filters = {name=page.search:GetText() or ""}
	local candidates = self:BuildHistoryRoster(true, filters)
	local seen = {}; for _, entry in ipairs(candidates) do seen[entry.guid] = true end
	for _, entry in ipairs(self:BuildHistoryRoster(false, filters)) do
		if not seen[entry.guid] then candidates[#candidates + 1] = entry end
	end
	for index, row in ipairs(page.matches) do
		local entry = candidates[index]
		row.guid = entry and entry.guid
		if entry then row.label:SetText(self:LinkedCharacterName(entry)); row:Show() else row:Hide() end
	end
	local selected = self:GetHistoryEntry(self.syncSelectedGuid)
	page.selected:SetText(W.T("SYNC_SELECTED", selected and self:LinkedCharacterName(selected) or W.T("SYNC_SELECT")))
	for _, control in ipairs(page.selectedButtons) do if selected then control:Enable() else control:Disable() end end
	local offer = self.syncOffers[1]
	page.request:SetText(offer and W.T("SYNC_REQUEST_FROM", offer.sender, offer.count) or W.T("SYNC_NO_REQUEST"))
	for _, control in ipairs({page.accept, page.reject, page.ignore}) do if offer then control:Enable() else control:Disable() end end
	for _, control in ipairs({page.apply, page.cancel}) do if self.syncReview then control:Enable() else control:Disable() end end
	if self.syncReview and self.syncReview.source == "user" then page.ignoreReview:Enable() else page.ignoreReview:Disable() end
	page.review:SetText(self:GetSyncReviewText())
	page.status:SetText(self.syncStatus or W.T("SYNC_PRIVACY"))
	page.disable.label:SetText(W.T(self.db.sync and self.db.sync.disabled and "SYNC_ENABLE" or "SYNC_DISABLE"))
	local ignored = self:GetIgnoredSyncCharacters(page.ignoreName:GetText())
	local allIgnored = self:GetIgnoredSyncCharacters()
	page.ignoredHeading:SetText(W.T("SYNC_IGNORED_LIST", #allIgnored))
	local offset = math.min(page.ignoredOffset or 0, math.max(0, math.floor((#ignored - 1) / 2) * 2))
	page.ignoredOffset = offset
	for index, row in ipairs(page.ignoredRows) do
		row.name = ignored[offset + index]
		row.label:SetText(row.name or (index == 1 and W.T("SYNC_IGNORED_EMPTY") or ""))
		if row.name then row.remove:Show() else row.remove:Hide() end
	end
	page.ignoredCount:SetText(W.T("SYNC_IGNORED_PAGE", #ignored > 0 and offset + 1 or 0, math.min(offset + 2, #ignored), #ignored))
	if offset > 0 then page.ignoredPrevious:Enable() else page.ignoredPrevious:Disable() end
	if offset + 2 < #ignored then page.ignoredNext:Enable() else page.ignoredNext:Disable() end
end

Addon.Pages.Sync = {id="sync", LAYOUT_VERSION=LAYOUT_VERSION, Create=create,
	Refresh=function() Addon:RefreshSyncView() end, ApplyLocale=function() Addon:RefreshSyncView() end}
