-- PageGearCheckTarget

local Addon = Raidwise
local W = Addon.Widgets

Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 1

local function CreateGearCheckTargetPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)

	local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 0, 0)
	desc:SetWidth(W.ContentInnerWidth())
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText(W.T("GEAR_CHECK_TARGET_DESC"))
	page.desc = desc

	page.layoutVersion = LAYOUT_VERSION
	return page
end

local function ApplyLocale(page)
	if page and page.desc then
		page.desc:SetText(W.T("GEAR_CHECK_TARGET_DESC"))
	end
end

Addon.Pages.GearCheckTarget = {
	id = "geartarget",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateGearCheckTargetPage,
	ApplyLocale = ApplyLocale,
}
