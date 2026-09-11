-- Shared UI helpers for Raidwise windows and pages.

local Addon = Raidwise

Addon.UITheme = {
	-- Content panel (RaidwiseFrame)
	CONTENT_WIDTH = 890,
	CONTENT_HEIGHT = 940,
	PAD = 10,
	TITLE_H = 20,
	CLOSE_SIZE = 16,

	-- Left menu (RaidwiseMenu)
	MENU_WIDTH = 170,
	MENU_GAP = 0,
	MENU_BTN_H = 28,
	MENU_BTN_GAP = 3,
	MENU_ICON = 18,
	MENU_GROUP_HEADING_H = 16,
	MENU_GROUP_HEADING_GAP = 2,
	MENU_GROUP_GAP = 8,
	MENU_SEP_H = 1,

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
	INFO_SECTION_GAP = 16,
	INFO_HEADING_SIZE = 16,
	INFO_BODY_SIZE = 15,
	INFO_LINE_SPACING = 2,
	URL_BOX_H = 28,

	-- Cooldowns tab
	CD_HINT_TO_TABLE = 8,
	CD_TOOLBAR_H = 28,
	CD_HEADER_H = 52,
	CD_ROW_H = 34,
	CD_SPEC_ICON = 14,
	ROSTER_ICON = 18,
	PROFILE_ICON = 24,
	CD_SCROLLBAR_W = 16,
	CD_HSCROLL_H = 16,
	CD_ROW_A = { 0.094, 0.094, 0.141, 0.95 },
	CD_ROW_B = { 0.078, 0.078, 0.118, 0.95 },

	-- Raid roster tab
	RAID_BUFF_ICON = 18,
	RAID_BUFF_MAX = 8,
	RAID_BUFF_GAP = 2,
	PARTY_BUFF_ICON = 14,
	PARTY_BUFF_MAX = 3,
	PARTY_BUFF_GAP = 1,
	ROSTER_STATS_H = 16,
	RAID_STATS_H = 28,
	RAID_PROGRESS_H = 14,
	RAID_PROGRESS_STATUS_H = 28,
	RAID_PROGRESS_STATUS_GAP = 4,
	RAID_DESC_LINE_GAP = 2,
	RAID_DESC_BLOCK_GAP = 4,
	RAID_CONSUMABLE_ROW_H = 28,
	RAID_GRADE_LEGEND_H = 28,
	RAID_GRADE_CHIPS_W = 72,
	RAID_HINT_H = 28,
	RAID_HEADER_COL_COUNT = 4,
	RAID_HEADER_COL_GAP = 8,
	RAID_HEADER_ROW_GAP = 4,
	RAID_SUMMARY_COL_COUNT = 4,
	RAID_SUMMARY_COL_GAP = 8,
	RAID_SUMMARY_HEADING_H = 14,
	RAID_SUMMARY_BODY_H = 32,
	RAID_SUMMARY_REPORT_ICON = 16,
	RAID_SUMMARY_BAND_H = 20,
	RAID_TOOLBAR_BTN_COUNT = 4,
	RAID_TOOLBAR_BTN_GAP = 4,

	TEXT_BODY = { 1, 1, 1 },
	INPUT_BG = { 0, 0, 0, 1 },
	-- Colors — Classic theme (preview/themes.html #classic)
	GOLD = { 1.000, 0.824, 0.000 },
	GOLD_DIM = { 0.769, 0.627, 0.290 }, -- Menu group headings / separators
	BORDER = { 0.420, 0.341, 0.188, 1 },
	BORDER_W = 2,
	TEXT_IDLE = { 1.000, 0.933, 0.733 },
	TEXT_GOOD = { 0.350, 0.850, 0.400 },
	PANEL_BG = { 0.071, 0.071, 0.110, 0.98 },
	TITLE_BG = { 0.110, 0.110, 0.165, 1 },
	BTN_IDLE = { 0.125, 0.110, 0.165, 0.98 },
	BTN_HOVER = { 0.180, 0.150, 0.200, 1 },
	BTN_SELECTED = { 0.230, 0.188, 0.125, 1 },
	BTN_DISABLED = { 0.055, 0.055, 0.078, 0.95 },
	TEXT_HOVER = { 1.000, 0.910, 0.550 },
	TEXT_DISABLED = { 0.690, 0.627, 0.439 },
	TEXT_ALERT = { 1.000, 0.251, 0.251 },
	-- Gear Check gradation: S gold, then A green through D red. Spec ranks share A–D.
	GEAR_S = { 1.000, 0.824, 0.000 },
	GEAR_BAD = { 1.000, 0.251, 0.251 },
	GEAR_REPLACE = { 1.000, 0.600, 0.200 },
	GEAR_OK = { 0.950, 0.780, 0.350 },
	GEAR_GOOD = { 0.350, 0.850, 0.400 },
}

Addon.Widgets = {}
local W = Addon.Widgets
local UI = Addon.UITheme

-- Keep color tables stable: page modules retain references to them.
local lightPalette = {
	PANEL_BG = { 0.94, 0.93, 0.90, 1 },
	TITLE_BG = { 0.84, 0.82, 0.77, 1 },
	INPUT_BG = { 1, 0.99, 0.97, 1 },
	CD_ROW_A = { 0.88, 0.87, 0.83, 1 },
	CD_ROW_B = { 0.96, 0.95, 0.92, 1 },
	BTN_IDLE = { 0.85, 0.83, 0.78, 1 },
	BTN_HOVER = { 0.78, 0.75, 0.67, 1 },
	BTN_SELECTED = { 0.75, 0.65, 0.43, 1 },
	BTN_DISABLED = { 0.89, 0.88, 0.85, 1 },
	TEXT_BODY = { 0.12, 0.12, 0.15 },
	TEXT_IDLE = { 0.20, 0.18, 0.14 },
	TEXT_HOVER = { 0.12, 0.10, 0.06 },
	TEXT_DISABLED = { 0.43, 0.40, 0.35 },
	GOLD = { 0.38, 0.25, 0.02 },
	GOLD_DIM = { 0.46, 0.34, 0.14 },
	BORDER = { 0.51, 0.44, 0.29, 1 },
	TEXT_GOOD = { 0.12, 0.42, 0.17 },
	TEXT_ALERT = { 0.72, 0.12, 0.12 },
	GEAR_S = { 0.48, 0.32, 0.00 },
	GEAR_BAD = { 0.72, 0.12, 0.12 },
	GEAR_REPLACE = { 0.66, 0.29, 0.03 },
	GEAR_OK = { 0.48, 0.38, 0.09 },
	GEAR_GOOD = { 0.12, 0.42, 0.17 },
}
local darkPalette = {}
for key in pairs(lightPalette) do
	darkPalette[key] = { unpack(UI[key]) }
end

local themeBindings = setmetatable({}, { __mode = "k" })
local fontShadows = setmetatable({}, { __mode = "k" })
local inlineTextBindings = setmetatable({}, { __mode = "k" })
local applyingText = false

local function Luminance(color)
	local function Linear(value)
		return value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * Linear(color[1]) + 0.7152 * Linear(color[2]) + 0.0722 * Linear(color[3])
end

local function TextBackgroundLuminance()
	local light = Addon:GetTheme() == "light"
	local value = Luminance(UI.PANEL_BG)
	for _, key in ipairs({ "TITLE_BG", "INPUT_BG", "CD_ROW_A", "CD_ROW_B", "BTN_IDLE", "BTN_HOVER", "BTN_SELECTED", "BTN_DISABLED" }) do
		local background = Luminance(UI[key])
		value = light and math.min(value, background) or math.max(value, background)
	end
	return value
end

-- Preserve the source hue as far as possible while keeping small UI text legible.
-- Only addon text is adjusted; icons, class definitions, and game tooltips retain their colors.
function W.ReadableTextColor(color)
	local background = TextBackgroundLuminance()
	local function Contrast(candidate)
		local foreground = Luminance(candidate)
		return (math.max(foreground, background) + 0.05) / (math.min(foreground, background) + 0.05)
	end
	if Contrast(color) >= 4.5 then
		return color
	end
	local target = Addon:GetTheme() == "light" and 0 or 1
	local low, high = 0, 1
	local adjusted = { color[1], color[2], color[3], color[4] or 1 }
	for iteration = 1, 14 do
		local amount = (low + high) / 2
		for channel = 1, 3 do
			adjusted[channel] = color[channel] + (target - color[channel]) * amount
		end
		if Contrast(adjusted) >= 4.5 then high = amount else low = amount end
	end
	for channel = 1, 3 do
		adjusted[channel] = color[channel] + (target - color[channel]) * high
	end
	return adjusted
end

local function ApplyInlineText(fontString, text)
	if type(text) ~= "string" then return end
	local formatted = text:gsub("|c(%x%x)(%x%x)(%x%x)(%x%x)", function(alpha, red, green, blue)
		local color = W.ReadableTextColor({ tonumber(red, 16) / 255, tonumber(green, 16) / 255, tonumber(blue, 16) / 255 })
		-- Round toward higher contrast when encoding the adjusted color.
		local round = Addon:GetTheme() == "light" and math.floor or math.ceil
		return string.format("|c%s%02x%02x%02x", alpha, round(color[1] * 255), round(color[2] * 255), round(color[3] * 255))
	end)
	applyingText = true
	fontString:SetText(formatted)
	applyingText = false
end

local function ApplyFontShadow(fontString)
	if not fontString.GetShadowOffset or not fontString.SetShadowOffset
		or not fontString.GetShadowColor or not fontString.SetShadowColor then
		return
	end
	local shadow = fontShadows[fontString]
	if not shadow then
		local x, y = fontString:GetShadowOffset()
		shadow = { x = x, y = y, color = { fontString:GetShadowColor() } }
		fontShadows[fontString] = shadow
		-- Pooled rows can reassign their font object after creation.
		hooksecurefunc(fontString, "SetFontObject", function()
			ApplyFontShadow(fontString)
		end)
	end
	if Addon:GetTheme() == "light" then
		fontString:SetShadowOffset(0, 0)
		fontString:SetShadowColor(0, 0, 0, 0)
	else
		fontString:SetShadowOffset(shadow.x, shadow.y)
		fontString:SetShadowColor(unpack(shadow.color))
	end
end

local applyingColor = false
local function SetThemeColor(region, method, color)
	local bindings = themeBindings[region]
	if not bindings then
		bindings = {}
		themeBindings[region] = bindings
	end
	if not bindings[method] then
		-- Direct color changes (class colors, hover effects) release the old binding.
		hooksecurefunc(region, method, function(_, red, green, blue, alpha)
			if not applyingColor then
				if method == "SetTextColor" then
					-- Class colors and direct hover changes also need theme-aware contrast.
					SetThemeColor(region, method, { red, green, blue, alpha or 1 })
				else
					bindings[method].color = nil
				end
			end
		end)
		bindings[method] = {}
	end
	bindings[method].color = color
	local rendered = method == "SetTextColor" and W.ReadableTextColor(color) or color
	applyingColor = true
	region[method](region, rendered[1], rendered[2], rendered[3], rendered[4] or 1)
	applyingColor = false
end

function W.SetBackdropColor(frame, color)
	SetThemeColor(frame, "SetBackdropColor", color)
end

function W.SetTextureColor(texture, color)
	SetThemeColor(texture, "SetVertexColor", color)
end

function W.CreateFontString(parent, name, layer, template)
	local label = parent:CreateFontString(name, layer, template)
	W.SetFontColor(label, template and string.find(template, "Normal") and UI.GOLD or UI.TEXT_BODY)
	return label
end

function Addon:GetTheme()
	return self.db and self.db.theme == "light" and "light" or "dark"
end

function Addon:ApplyTheme()
	local palette = self:GetTheme() == "light" and lightPalette or darkPalette
	for key, color in pairs(palette) do
		for index = 1, 4 do
			UI[key][index] = color[index]
		end
	end
	for region, bindings in pairs(themeBindings) do
		for method, binding in pairs(bindings) do
			if binding.color then
				SetThemeColor(region, method, binding.color)
			end
		end
	end
	for fontString in pairs(fontShadows) do
		ApplyFontShadow(fontString)
	end
	for fontString, binding in pairs(inlineTextBindings) do
		ApplyInlineText(fontString, binding.text)
	end
end

function Addon:SetTheme(theme)
	if not self.db or (theme ~= "light" and theme ~= "dark") then
		return
	end
	self.db.theme = theme
	self:ApplyTheme()
	-- Refresh strings containing inline palette colors and the settings selection.
	if self.RefreshLocalizedUI then
		self:RefreshLocalizedUI()
	end
end


function W.SetFontColor(fontString, color)
	ApplyFontShadow(fontString)
	if fontString.GetObjectType and fontString:GetObjectType() == "FontString" and not inlineTextBindings[fontString] then
		local binding = { text = fontString:GetText() }
		inlineTextBindings[fontString] = binding
		hooksecurefunc(fontString, "SetText", function(_, text)
			if not applyingText then
				binding.text = text
				ApplyInlineText(fontString, text)
			end
		end)
		ApplyInlineText(fontString, binding.text)
	end
	SetThemeColor(fontString, "SetTextColor", color)
end

