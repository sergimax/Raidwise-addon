-- Separate ownership views for local opinions, received opinions, and Karma.
local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme
local LAYOUT_VERSION = 1
Addon.Pages = Addon.Pages or {}

local function line(parent, text, y)
	local label = W.CreateFontString(parent, nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", 0, y); label:SetPoint("RIGHT", parent, "RIGHT", 0, 0); label:SetJustifyH("LEFT"); label:SetText(text)
	return label
end

local function create(parent)
	local page = CreateFrame("Frame", nil, parent); page:SetAllPoints(parent); page.layoutVersion = LAYOUT_VERSION
	page.localTitle = line(page, "", 0); page.localRows = {}
	page.exchangeTitle = line(page, "", -150); page.exchangeRows = {}
	page.karmaTitle = line(page, "", -300); page.karmaInfo = line(page, "", -326)
	Addon.reputationPage = page
	return page
end

function Addon:RefreshReputationView()
	local page = self.reputationPage
	if not page then return end
	local store = self:GetReputationStore() or {}
	page.localTitle:SetText(W.T("REPUTATION_LOCAL"))
	local localCount = 0
	for guid, profile in pairs(store.localProfilesByGuid or {}) do
		localCount = localCount + 1; local row = page.localRows[localCount] or line(page, "", -22 - localCount * 18); page.localRows[localCount] = row
		row:SetText((profile.name or guid) .. " — " .. self:RatingOpinionLabel(profile.personal and profile.personal.opinion))
	end
	for index = localCount + 1, #page.localRows do page.localRows[index]:SetText("") end
	page.exchangeTitle:SetText(W.T("REPUTATION_RECEIVED"))
	local exchangeCount = 0
	for _, source in pairs(store.exchangeProfilesBySource or {}) do for guid, profile in pairs(source.profilesByGuid or {}) do
		exchangeCount = exchangeCount + 1; local row = page.exchangeRows[exchangeCount] or W.CreatePlainButton(page, 360, 18, "")
		page.exchangeRows[exchangeCount] = row; row:SetPoint("TOPLEFT", 0, -172 - exchangeCount * 20)
		row.label:SetText((profile.name or guid) .. " — " .. (source.sender or "?") .. ": " .. self:RatingOpinionLabel(profile.opinion))
		row:SetScript("OnClick", function() local entry = Addon:GetHistoryEntry(guid); if entry and Addon.ShowRaidCharacterWindow then Addon:ShowRaidCharacterWindow(entry) end end)
	end end
	for index = exchangeCount + 1, #page.exchangeRows do page.exchangeRows[index]:Hide() end
	page.karmaTitle:SetText(W.T("REPUTATION_GLOBAL"))
	local karma = store.globalKarma
	page.karmaInfo:SetText(karma and W.T("REPUTATION_KARMA_INFO", karma.datasetId, karma.revision, karma.publishedAt) or W.T("REPUTATION_KARMA_EMPTY"))
end

Addon.Pages.Reputation = {id="reputation", LAYOUT_VERSION=LAYOUT_VERSION, Create=create, Refresh=function() Addon:RefreshReputationView() end, ApplyLocale=function() Addon:RefreshReputationView() end}
