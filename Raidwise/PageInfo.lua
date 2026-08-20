-- PageInfo

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 1

local GITHUB_URL = "https://github.com/sergimax/Raidwise-addon"

local function CreateInfoPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local innerW = W.ContentInnerWidth()

	local aboutHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	aboutHeading:SetPoint("TOPLEFT", 0, 0)
	aboutHeading:SetText(W.T("INFO_ABOUT"))
	W.SetFontColor(aboutHeading, UI.GOLD)
	page.aboutHeading = aboutHeading

	local about = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	about:SetPoint("TOPLEFT", aboutHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	about:SetWidth(innerW)
	about:SetJustifyH("LEFT")
	about:SetJustifyV("TOP")
	about:SetText(W.T("INFO_BODY"))
	page.about = about

	local repoHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	repoHeading:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -UI.INFO_BLOCK_GAP)
	repoHeading:SetText(W.T("INFO_GITHUB"))
	W.SetFontColor(repoHeading, UI.GOLD)
	page.repoHeading = repoHeading

	local repoHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	repoHint:SetPoint("TOPLEFT", repoHeading, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	repoHint:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	repoHint:SetJustifyH("LEFT")
	repoHint:SetText(W.T("INFO_REPO_HINT"))

	local copyBtn = W.CreatePlainButton(page, 130, UI.ACTION_BTN_H, W.T("BTN_SELECT_ALL"))
	copyBtn:SetPoint("TOPRIGHT", repoHint, "BOTTOMRIGHT", 0, -UI.INFO_HEADING_GAP)
	copyBtn:SetScript("OnClick", function()
		Addon:SelectRepoUrl()
	end)

	local repoBox, repoHost = W.CreateLineCopyBox(page, "RaidwiseRepoBoxV" .. tostring(LAYOUT_VERSION))
	repoHost:SetPoint("TOPLEFT", repoHint, "BOTTOMLEFT", 0, -UI.INFO_HEADING_GAP)
	repoHost:SetPoint("RIGHT", copyBtn, "LEFT", -UI.ACTION_BTN_GAP, 0)
	repoBox:SetText(GITHUB_URL)
	repoBox:SetScript("OnEditFocusLost", function(edit)
		edit:HighlightText(0, 0)
		if (edit:GetText() or "") == "" then
			edit:SetText(GITHUB_URL)
		end
	end)

	page.repoBox = repoBox
	page.repoHint = repoHint
	page.copyBtn = copyBtn
	page.repoHost = repoHost
	page.layoutVersion = LAYOUT_VERSION
	W.AttachPageLayoutBadge(page, LAYOUT_VERSION)
	return page
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
		frame.repoHint:SetText(W.T("INFO_REPO_SELECTED"))
	end
end

Addon.Pages.Info = {
	id = "info",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateInfoPage,
}
