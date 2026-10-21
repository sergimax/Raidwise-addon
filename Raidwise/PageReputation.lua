-- Separate ownership views for local opinions, received opinions, and Karma.
local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme
local LAYOUT_VERSION = 3
Addon.Pages = Addon.Pages or {}

local function line(parent, text, y)
	local label = W.CreateFontString(parent, nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", 0, y); label:SetPoint("RIGHT", parent, "RIGHT", 0, 0); label:SetJustifyH("LEFT"); label:SetText(text)
	return label
end

local function createList(parent, name)
	local host = CreateFrame("Frame", nil, parent)
	W.ApplyPlainPanel(host, UI.PANEL_BG)
	local scroll = CreateFrame("ScrollFrame", name, host, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 4, -4)
	scroll:SetPoint("BOTTOMRIGHT", -20, 4)
	scroll:EnableMouseWheel(true)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	scroll:SetScript("OnSizeChanged", function(self, width)
		content:SetWidth(width or 1)
	end)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local maxScroll = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
		self:SetVerticalScroll(math.max(0, math.min(maxScroll, (self:GetVerticalScroll() or 0) - delta * 20)))
	end)
	return {host=host, scroll=scroll, content=content, rows={}}
end

local function create(parent)
	local page = CreateFrame("Frame", nil, parent); page:SetAllPoints(parent); page.layoutVersion = LAYOUT_VERSION
	page.localTitle = line(page, "", 0)
	page.exchangeTitle = line(page, "", 0)
	page.exchangeTitle:ClearAllPoints(); page.exchangeTitle:SetPoint("TOPLEFT", page, "TOP", 4, 0); page.exchangeTitle:SetPoint("RIGHT", page, "RIGHT", 0, 0); page.exchangeTitle:SetJustifyH("LEFT")
	page.localList = createList(page, "RaidwiseReputationLocalScrollV3")
	page.localList.host:SetPoint("TOPLEFT", 0, -24); page.localList.host:SetPoint("RIGHT", page, "CENTER", -4, 0); page.localList.host:SetPoint("BOTTOM", page, "TOP", 0, -240)
	page.exchangeList = createList(page, "RaidwiseReputationExchangeScrollV3")
	page.exchangeList.host:SetPoint("TOPLEFT", page, "TOP", 4, -24); page.exchangeList.host:SetPoint("RIGHT", page, "RIGHT", 0, 0); page.exchangeList.host:SetPoint("BOTTOM", page, "TOP", 0, -240)
	page.karmaTitle = line(page, "", -252); page.karmaInfo = line(page, "", -274)
	page.karmaPaste, page.karmaPasteHost = W.CreateCopyBox(page, "RaidwiseKarmaPasteScrollV2", "RaidwiseKarmaPasteBoxV2")
	page.karmaPasteHost:SetPoint("TOPLEFT", 0, -296); page.karmaPasteHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 42)
	page.karmaReview = W.CreatePlainButton(page, 120, 24, W.T("REPUTATION_KARMA_REVIEW")); page.karmaReview:SetPoint("BOTTOMLEFT", 0, 8)
	page.karmaApply = W.CreatePlainButton(page, 120, 24, W.T("SYNC_APPLY")); page.karmaApply:SetPoint("LEFT", page.karmaReview, "RIGHT", 6, 0)
	page.karmaCancel = W.CreatePlainButton(page, 120, 24, W.T("SYNC_DECLINE")); page.karmaCancel:SetPoint("LEFT", page.karmaApply, "RIGHT", 6, 0)
	page.karmaReview:SetScript("OnClick", function() Addon:StageGlobalKarmaImport(page.karmaPaste:GetText(), "JSON"); Addon:RefreshReputationView() end)
	page.karmaApply:SetScript("OnClick", function() Addon:ApplyGlobalKarmaImport(); Addon:RefreshReputationView() end)
	page.karmaCancel:SetScript("OnClick", function() Addon:CancelGlobalKarmaImport(); Addon:RefreshReputationView() end)
	Addon.reputationPage = page
	return page
end

local function refreshList(list, count)
	list.content:SetHeight(math.max(1, count * 20))
	list.scroll:SetVerticalScroll(math.min(list.scroll:GetVerticalScroll() or 0, math.max(0, list.content:GetHeight() - list.scroll:GetHeight())))
	W.HidePoolFrom(list.rows, count + 1)
end

function Addon:RefreshReputationView()
	local page = self.reputationPage
	if not page then return end
	local store = self:GetReputationStore() or {}
	page.localTitle:SetText(W.T("REPUTATION_LOCAL"))
	local localCount = 0
	for guid, profile in pairs(store.localProfilesByGuid or {}) do
		localCount = localCount + 1; local row = page.localList.rows[localCount] or line(page.localList.content, "", -((localCount - 1) * 20)); page.localList.rows[localCount] = row
		row:SetText((profile.name or guid) .. " — " .. self:RatingOpinionLabel(profile.personal and profile.personal.opinion))
		row:Show()
	end
	refreshList(page.localList, localCount)
	page.exchangeTitle:SetText(W.T("REPUTATION_RECEIVED"))
	local exchangeCount = 0
	for _, source in pairs(store.exchangeProfilesBySource or {}) do for guid, profile in pairs(source.profilesByGuid or {}) do
		exchangeCount = exchangeCount + 1; local row = page.exchangeList.rows[exchangeCount] or W.CreatePlainButton(page.exchangeList.content, 1, 18, "")
		page.exchangeList.rows[exchangeCount] = row; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -((exchangeCount - 1) * 20)); row:SetPoint("RIGHT", page.exchangeList.content, "RIGHT", 0, 0)
		row.label:SetText((profile.name or guid) .. " — " .. (source.sender or "?") .. ": " .. self:RatingOpinionLabel(profile.opinion))
		row:SetScript("OnClick", function() local entry = Addon:GetHistoryEntry(guid); if entry and Addon.ShowRaidCharacterWindow then Addon:ShowRaidCharacterWindow(entry) end end)
		row:Show()
	end end
	refreshList(page.exchangeList, exchangeCount)
	page.karmaTitle:SetText(W.T("REPUTATION_GLOBAL"))
	local karma = store.globalKarma
	page.karmaInfo:SetText(karma and W.T("REPUTATION_KARMA_INFO", karma.datasetId, karma.revision, karma.publishedAt) or W.T("REPUTATION_KARMA_EMPTY"))
	if self.globalKarmaReview then page.karmaApply:Enable(); page.karmaCancel:Enable() else page.karmaApply:Disable(); page.karmaCancel:Disable() end
end

Addon.Pages.Reputation = {id="reputation", LAYOUT_VERSION=LAYOUT_VERSION, Create=create, Refresh=function() Addon:RefreshReputationView() end, ApplyLocale=function() Addon:RefreshReputationView() end}
