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

function W.T(key, ...)
	if Addon.T then
		return Addon:T(key, ...)
	end
	return tostring(key or "")
end

function W.ContentInnerWidth()
	return UI.CONTENT_WIDTH - (UI.PAD * 2)
end

-- Flat panel fill (no border edges); spacing comes from layout constants (PAD, gaps, COPY_PAD_*).
function W.ApplyPlainPanel(frame, color)
	color = color or UI.PANEL_BG
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true,
		tileSize = 16,
	})
	frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
	W.HidePanelBorder(frame)
end

function W.HidePanelBorder(frame)
	if not frame then
		return
	end
	if frame.rwBorderTop then
		frame.rwBorderTop:Hide()
		frame.rwBorderBottom:Hide()
		frame.rwBorderLeft:Hide()
		frame.rwBorderRight:Hide()
	end
end

function W.ApplyOuterBorder(frame, color, thickness)
	if not frame then
		return
	end
	color = color or UI.BORDER
	thickness = thickness or UI.BORDER_W or 1
	local alpha = color[4] or 1
	local function Edge(texture)
		if not texture then
			texture = frame:CreateTexture(nil, "OVERLAY")
			texture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		end
		texture:SetVertexColor(color[1], color[2], color[3], alpha)
		texture:Show()
		return texture
	end
	frame.rwBorderTop = Edge(frame.rwBorderTop)
	frame.rwBorderTop:ClearAllPoints()
	frame.rwBorderTop:SetHeight(thickness)
	frame.rwBorderTop:SetPoint("TOPLEFT", 0, 0)
	frame.rwBorderTop:SetPoint("TOPRIGHT", 0, 0)

	frame.rwBorderBottom = Edge(frame.rwBorderBottom)
	frame.rwBorderBottom:ClearAllPoints()
	frame.rwBorderBottom:SetHeight(thickness)
	frame.rwBorderBottom:SetPoint("BOTTOMLEFT", 0, 0)
	frame.rwBorderBottom:SetPoint("BOTTOMRIGHT", 0, 0)

	frame.rwBorderLeft = Edge(frame.rwBorderLeft)
	frame.rwBorderLeft:ClearAllPoints()
	frame.rwBorderLeft:SetWidth(thickness)
	frame.rwBorderLeft:SetPoint("TOPLEFT", 0, 0)
	frame.rwBorderLeft:SetPoint("BOTTOMLEFT", 0, 0)

	frame.rwBorderRight = Edge(frame.rwBorderRight)
	frame.rwBorderRight:ClearAllPoints()
	frame.rwBorderRight:SetWidth(thickness)
	frame.rwBorderRight:SetPoint("TOPRIGHT", 0, 0)
	frame.rwBorderRight:SetPoint("BOTTOMRIGHT", 0, 0)
end

function W.ApplyPanelBorderColor(frame)
	W.HidePanelBorder(frame)
end

-- Thin gold fill bar for long-running raid scan / export on the Raid roster page.
function W.CreateProgressBar(parent, height)
	height = height or UI.RAID_PROGRESS_H or 14
	local host = CreateFrame("Frame", nil, parent)
	host:SetHeight(height)

	local bg = host:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(host)
	bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	bg:SetVertexColor(0.05, 0.05, 0.08, 0.95)

	local bar = CreateFrame("StatusBar", nil, host)
	bar:SetPoint("TOPLEFT", 1, -1)
	bar:SetPoint("BOTTOMRIGHT", -1, 1)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	local fill = bar:GetStatusBarTexture()
	if fill then
		local gold = UI.GOLD_DIM or UI.GOLD or { 0.77, 0.63, 0.29 }
		fill:SetVertexColor(gold[1], gold[2], gold[3], 1)
	end
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	host.bar = bar

	function host:SetProgress(value, maxValue)
		maxValue = tonumber(maxValue) or 1
		if maxValue <= 0 then
			maxValue = 1
		end
		value = tonumber(value) or 0
		self.bar:SetMinMaxValues(0, maxValue)
		self.bar:SetValue(math.max(0, math.min(maxValue, value)))
	end

	return host
end

function W.SetFontColor(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

function W.ApplyFontSize(fontString, size)
	if not fontString or not size then
		return
	end
	local path, _, flags = fontString:GetFont()
	if not path then
		return
	end
	fontString:SetFont(path, size, flags or "")
end

function W.ColorText(color, text)
	if not text or text == "" then
		return ""
	end
	color = color or UI.TEXT_IDLE
	local red = math.floor((color[1] or 1) * 255 + 0.5)
	local green = math.floor((color[2] or 1) * 255 + 0.5)
	local blue = math.floor((color[3] or 1) * 255 + 0.5)
	return string.format("|cff%02x%02x%02x%s|r", red, green, blue, text)
end

function W.GearGradationColor(step)
	if not step or step == "" then
		return UI.GEAR_OK
	end
	local key = string.lower(tostring(step))
	if key == "s" then
		return UI.GEAR_S
	end
	if key == "d" or key == "bad" or key == "forbidden" then
		return UI.GEAR_BAD
	end
	if key == "c" or key == "replace" or key == "unwanted" then
		return UI.GEAR_REPLACE
	end
	if key == "a" or key == "good" or key == "preferred" then
		return UI.GEAR_GOOD
	end
	if key == "b" or key == "ok" or key == "acceptable" then
		return UI.GEAR_OK
	end
	return UI.GEAR_OK
end

function W.GearVerdictColor(verdict)
	return W.GearGradationColor(verdict)
end

function W.WrapGearGradation(label)
	return W.ColorText(W.GearGradationColor(label), label)
end

local GEAR_GRADATION_TOKENS = {
	"forbidden",
	"acceptable",
	"unwanted",
	"preferred",
	"S",
	"A",
	"B",
	"C",
	"D",
}

function W.ColorizeGearGradation(text)
	if not text or text == "" then
		return text
	end
	for index = 1, #GEAR_GRADATION_TOKENS do
		local token = GEAR_GRADATION_TOKENS[index]
		local colored = W.WrapGearGradation(token)
		text = text:gsub("(%f[%a])" .. token .. "(%f[%A])", colored)
	end
	return text
end

function W.FormatGearVerdictCountsLine(prefix, counts, suffix)
	counts = counts or {}
	local parts = {}
	if prefix and prefix ~= "" then
		parts[#parts + 1] = prefix
	end
	parts[#parts + 1] = W.WrapGearGradation("S") .. " " .. tostring(counts.s or 0)
	parts[#parts + 1] = " · "
	parts[#parts + 1] = W.WrapGearGradation("A") .. " " .. tostring(counts.a or 0)
	parts[#parts + 1] = " · "
	parts[#parts + 1] = W.WrapGearGradation("B") .. " " .. tostring(counts.b or 0)
	parts[#parts + 1] = " · "
	parts[#parts + 1] = W.WrapGearGradation("C") .. " " .. tostring(counts.c or 0)
	parts[#parts + 1] = " · "
	parts[#parts + 1] = W.WrapGearGradation("D") .. " " .. tostring(counts.d or 0)
	if suffix and suffix ~= "" then
		parts[#parts + 1] = suffix
	end
	return table.concat(parts)
end

function W.SetPlainButtonState(button, state)
	if state == "selected" then
		button:SetBackdropColor(UI.BTN_SELECTED[1], UI.BTN_SELECTED[2], UI.BTN_SELECTED[3], UI.BTN_SELECTED[4])
		if button.label then
			W.SetFontColor(button.label, UI.GOLD)
		end
	elseif state == "hover" then
		button:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		if button.label then
			W.SetFontColor(button.label, UI.TEXT_HOVER)
		end
	elseif state == "disabled" then
		button:SetBackdropColor(UI.BTN_DISABLED[1], UI.BTN_DISABLED[2], UI.BTN_DISABLED[3], UI.BTN_DISABLED[4])
		if button.label then
			W.SetFontColor(button.label, UI.TEXT_DISABLED)
		end
	else
		button:SetBackdropColor(UI.BTN_IDLE[1], UI.BTN_IDLE[2], UI.BTN_IDLE[3], UI.BTN_IDLE[4])
		if button.label then
			W.SetFontColor(button.label, UI.TEXT_IDLE)
		end
	end
end

function W.ActionButtonState(button, hovering)
	if not button:IsEnabled() then
		return "disabled"
	end
	if hovering then
		return "hover"
	end
	return "idle"
end

function W.CreatePlainButton(parent, width, height, label)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width, height)
	W.ApplyPlainPanel(button, UI.BTN_IDLE)

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 0)
	text:SetText(label)
	W.SetFontColor(text, UI.TEXT_IDLE)
	button.label = text

	button:SetScript("OnEnter", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, true))
	end)
	button:SetScript("OnLeave", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, false))
	end)
	button:SetScript("OnEnable", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, false))
	end)
	button:SetScript("OnDisable", function(self)
		W.SetPlainButtonState(self, "disabled")
	end)

	return button
end

-- Hover tip for plain buttons; keeps idle/hover/disabled styling. tipKey is looked up via W.T on enter.
function W.SetPlainButtonTooltip(button, tipKey)
	if not button then
		return
	end
	button.tooltipKey = tipKey
	button:SetScript("OnEnter", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, true))
		if self.tooltipKey then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(W.T(self.tooltipKey), nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, false))
		GameTooltip:Hide()
	end)
end

function W.SyncPlainIconButton(button)
	if not button or not button.icon then
		return
	end
	if button:IsEnabled() then
		button.icon:SetDesaturated(false)
		button.icon:SetVertexColor(1, 1, 1)
	else
		button.icon:SetDesaturated(true)
		button.icon:SetVertexColor(0.45, 0.45, 0.45)
	end
end

-- Square icon button; titleKey is the gold tooltip title, tipKey the body.
function W.CreatePlainIconButton(parent, size, iconPath, titleKey, tipKey)
	size = size or UI.CD_TOOLBAR_H
	local button = W.CreatePlainButton(parent, size, size, "")
	if button.label then
		button.label:Hide()
	end
	local inset = 6
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("CENTER", 0, 0)
	icon:SetSize(math.max(8, size - inset * 2), math.max(8, size - inset * 2))
	W.SetSpellIconTexture(icon, iconPath)
	button.icon = icon
	button.titleKey = titleKey
	button.tooltipKey = tipKey

	button:SetScript("OnEnter", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, true))
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.titleKey then
			GameTooltip:AddLine(W.T(self.titleKey), UI.GOLD[1], UI.GOLD[2], UI.GOLD[3])
		end
		if self.tooltipKey then
			GameTooltip:AddLine(W.T(self.tooltipKey), nil, nil, nil, true)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		W.SetPlainButtonState(self, W.ActionButtonState(self, false))
		GameTooltip:Hide()
	end)
	local onEnable = button:GetScript("OnEnable")
	button:SetScript("OnEnable", function(self)
		if onEnable then
			onEnable(self)
		end
		W.SyncPlainIconButton(self)
	end)
	local onDisable = button:GetScript("OnDisable")
	button:SetScript("OnDisable", function(self)
		if onDisable then
			onDisable(self)
		end
		W.SyncPlainIconButton(self)
	end)
	W.SyncPlainIconButton(button)
	return button
end

W.COPY_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true,
}

function W.ChatFontLineHeight()
	local _, fontSize = ChatFontNormal:GetFont()
	fontSize = tonumber(fontSize) or 14
	return fontSize + 2
end

function W.FitCopyBoxToText(box)
	local text = box:GetText() or ""
	local width = box:GetWidth()
	local insets = 8
	local lineHeight = box.rwLineHeight
	if not lineHeight or lineHeight <= 0 then
		lineHeight = W.ChatFontLineHeight()
	end

	if text == "" then
		box:SetHeight(UI.COPY_MIN_H)
		return
	end

	-- Huge raid dumps: FontString measure freezes the client; estimate from newlines.
	if #text > 40000 then
		local lines = 1
		for _ in text:gmatch("\n") do
			lines = lines + 1
		end
		box:SetHeight(math.max(UI.COPY_MIN_H, lines * lineHeight + insets))
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

-- REFACTOR candidate: ScrollFrame + EditBox + cursor/scroll sync + auto-height fitting.
function W.CreateCopyBox(parent, scrollName, boxName)
	local host = CreateFrame("Frame", nil, parent)

	local scrollBG = CreateFrame("Frame", nil, host)
	scrollBG:SetPoint("TOPLEFT", 0, 0)
	scrollBG:SetPoint("BOTTOMRIGHT", -UI.COPY_SCROLLBAR_W, 0)
	scrollBG:SetBackdrop(W.COPY_BACKDROP)
	scrollBG:SetBackdropColor(0, 0, 0, 1)

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
	-- Raid dumps can be very large; default EditBox letter caps truncate mid-report.
	if exportBox.SetMaxLetters then
		exportBox:SetMaxLetters(0)
	end
	scroll:SetScrollChild(exportBox)

	scroll:SetScript("OnSizeChanged", function(self, width)
		exportBox:SetWidth(width)
		W.FitCopyBoxToText(exportBox)
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
		W.FitCopyBoxToText(box)
	end)

	return exportBox, host
end

function W.CreateLineCopyBox(parent, boxName)
	local host = CreateFrame("Frame", nil, parent)
	host:SetHeight(UI.URL_BOX_H)
	host:SetBackdrop(W.COPY_BACKDROP)
	host:SetBackdropColor(0, 0, 0, 1)

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
	end)

	return box, host
end

function W.SetMenuButtonState(button, selected, hovering)
	if selected then
		W.SetPlainButtonState(button, "selected")
	elseif hovering then
		W.SetPlainButtonState(button, "hover")
	else
		W.SetPlainButtonState(button, "idle")
	end
end

function W.AttachDragHandle(handle, target)
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		target:StartMoving()
	end)
	handle:SetScript("OnDragStop", function()
		target:StopMovingOrSizing()
	end)
end

local ICON_TEX_INSET = 0.07
local ICON_TEX_MAX = 1 - ICON_TEX_INSET

function W.ClassColor(classToken)
	local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
	if color then
		return color.r, color.g, color.b
	end
	return UI.TEXT_IDLE[1], UI.TEXT_IDLE[2], UI.TEXT_IDLE[3]
end

function W.SetSpellIconTexture(texture, iconPath)
	if not texture or not iconPath or iconPath == "" then
		return
	end
	texture:SetTexture(iconPath)
	texture:SetTexCoord(ICON_TEX_INSET, ICON_TEX_MAX, ICON_TEX_INSET, ICON_TEX_MAX)
end

-- Inline icon for FontString / GameTooltip lines (|T…|t). Crops the default border like SetSpellIconTexture.
function W.IconMarkup(iconPath, size)
	if not iconPath or iconPath == "" then
		return ""
	end
	size = size or 14
	local left = math.floor(64 * ICON_TEX_INSET + 0.5)
	local right = 64 - left
	return string.format("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t", iconPath, size, size, left, right, left, right)
end

function W.SetSpecOrClassIcon(texture, specIcon, classToken)
	if specIcon and specIcon ~= "" then
		W.SetSpellIconTexture(texture, specIcon)
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

function W.TableIconInset(columnWidth, iconSize)
	return math.floor((columnWidth - iconSize) / 2)
end

function W.TableIconTopOffset(iconSize)
	local inset = 1
	local innerH = UI.CD_ROW_H - (inset * 2)
	return -(inset + math.floor((innerH - iconSize) / 2))
end

function W.CreateBuffIconHost(parent)
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

function W.FillRaidBuffIcons(hosts, buffs)
	buffs = buffs or {}
	for buffIndex = 1, UI.RAID_BUFF_MAX do
		local host = hosts[buffIndex]
		local buff = buffs[buffIndex]
		if host and buff and buff.icon then
			W.SetSpellIconTexture(host.icon, buff.icon)
			host.buffName = buff.name or ""
			host:Show()
		elseif host then
			host.icon:SetTexture(nil)
			host.buffName = nil
			host:Hide()
		end
	end
end

function W.CreatePartyBuffStatusHost(parent)
	local host = CreateFrame("Frame", nil, parent)
	host:SetSize(UI.PARTY_BUFF_ICON, UI.PARTY_BUFF_ICON)
	host.icon = host:CreateTexture(nil, "ARTWORK")
	host.icon:SetAllPoints(host)
	host:EnableMouse(true)
	host:SetScript("OnEnter", function(self)
		if not self.buffName or self.buffName == "" then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.buffName, 1, 1, 1)
		if self.present then
			local providerText = table.concat(self.providers or {}, ", ")
			GameTooltip:AddLine(W.T("RAID_PARTY_BUFF_PRESENT", providerText), 0.2, 1, 0.2)
		else
			GameTooltip:AddLine(W.T("RAID_PARTY_BUFF_MISSING"), 1, 0.3, 0.3)
		end
		GameTooltip:Show()
	end)
	host:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return host
end

function W.FillPartyBuffStatusIcons(hosts, coverage)
	coverage = coverage or {}
	for buffIndex = 1, UI.PARTY_BUFF_MAX do
		local host = hosts[buffIndex]
		local entry = coverage[buffIndex]
		if host and entry and entry.icon then
			W.SetSpellIconTexture(host.icon, entry.icon)
			host.buffName = entry.name or ""
			host.present = entry.present and true or false
			host.providers = entry.providers or {}
			if host.present then
				host.icon:SetDesaturated(false)
				host.icon:SetVertexColor(1, 1, 1)
			else
				host.icon:SetDesaturated(true)
				host.icon:SetVertexColor(UI.TEXT_ALERT[1], UI.TEXT_ALERT[2], UI.TEXT_ALERT[3])
			end
			host:Show()
		elseif host then
			host.icon:SetTexture(nil)
			host.buffName = nil
			host.present = nil
			host.providers = nil
			host:Hide()
		end
	end
end

function W.CreateConsumableStatusHost(parent)
	local host = CreateFrame("Frame", nil, parent)
	host:SetSize(UI.PARTY_BUFF_ICON, UI.PARTY_BUFF_ICON)
	host.icon = host:CreateTexture(nil, "ARTWORK")
	host.icon:SetAllPoints(host)
	host:EnableMouse(true)
	host:SetScript("OnEnter", function(self)
		if not self.kindLabel or self.kindLabel == "" then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.kindLabel, 1, 1, 1)
		if self.unknown then
			GameTooltip:AddLine(W.T(self.reasonKey or "RAID_CONSUMABLE_OUT_OF_RANGE"), 0.70, 0.70, 0.70)
		elseif self.present then
			local detail = self.detail
			if self.elixirPair then
				detail = W.T("RAID_CONSUMABLE_ELIXIRS")
			end
			if not detail or detail == "" then
				detail = W.T("RAID_PARTY_BUFF_PRESENT", self.kindLabel)
			end
			GameTooltip:AddLine(detail, 0.2, 1, 0.2)
		else
			GameTooltip:AddLine(W.T("RAID_PARTY_BUFF_MISSING"), 1, 0.3, 0.3)
		end
		GameTooltip:Show()
	end)
	host:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	host:Hide()
	return host
end

function W.FillConsumableStatusIcon(host, status, kindLabelKey)
	if not host then
		return
	end
	if not status then
		host:Hide()
		return
	end
	host.kindLabel = W.T(kindLabelKey)
	host.present = status.present and true or false
	host.unknown = status.unknown and true or false
	host.elixirPair = status.elixirPair and true or false
	host.detail = status.name or ""
	host.reasonKey = status.reasonKey
	if status.icon then
		W.SetSpellIconTexture(host.icon, status.icon)
	end
	if host.unknown then
		host.icon:SetDesaturated(true)
		host.icon:SetVertexColor(0.55, 0.55, 0.55)
	elseif host.present then
		host.icon:SetDesaturated(false)
		host.icon:SetVertexColor(1, 1, 1)
	else
		host.icon:SetDesaturated(true)
		host.icon:SetVertexColor(UI.TEXT_ALERT[1], UI.TEXT_ALERT[2], UI.TEXT_ALERT[3])
	end
	host:Show()
end

function W.HidePoolFrom(pool, startIndex)
	for index = startIndex, #pool do
		pool[index]:Hide()
	end
end

function W.CreateCooldownScrollBar(parent, orientation)
	local bar = CreateFrame("Slider", nil, parent)
	bar:SetOrientation(orientation)
	if orientation == "VERTICAL" then
		bar:SetWidth(UI.CD_SCROLLBAR_W)
	else
		bar:SetHeight(UI.CD_HSCROLL_H)
	end
	W.ApplyPlainPanel(bar, UI.BTN_IDLE)
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

-- REFACTOR candidate: shared H/V scrollbar visibility for table pages.
function W.LayoutTableScrollBars(page)
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

function W.CooldownTableTopOffset()
	return UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE
end

function W.RosterTableTopOffset()
	return UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE + UI.ROSTER_STATS_H + UI.CD_HINT_TO_TABLE
end

function W.RaidRosterMiniTableHeight()
	local row1 = UI.CD_TOOLBAR_H
	local row2 = UI.RAID_SUMMARY_BAND_H or 20
	local gap = UI.RAID_HEADER_ROW_GAP or 4
	return row1 + gap + row2
end

function W.RaidRosterHeaderHeight()
	local blockGap = UI.RAID_DESC_BLOCK_GAP or 4
	return W.RaidRosterMiniTableHeight()
		+ blockGap
		+ UI.RAID_PROGRESS_STATUS_H
		+ UI.RAID_PROGRESS_STATUS_GAP
		+ UI.RAID_PROGRESS_H
end

function W.RaidRosterTableTopOffset()
	-- Compact header (chips + stats + icon toolbar, then status row) + scan status + progress bar.
	return W.RaidRosterHeaderHeight() + UI.CD_HINT_TO_TABLE
end

function W.FormatGuildDisplay(guildName, guildRank)
	if not guildName or guildName == "" then
		return "-"
	end
	if guildRank and guildRank ~= "" then
		return guildName .. " (" .. guildRank .. ")"
	end
	return guildName
end

function W.RatingOpinion(member)
	if Addon.GetPersonalRating then
		local rating = Addon:GetPersonalRating(member)
		return rating.opinion, rating.tags
	end
	return "neutral", {}
end

function W.RatingOpinionText(member)
	local opinion = W.RatingOpinion(member)
	if Addon.RatingOpinionLabel then
		return Addon:RatingOpinionLabel(opinion)
	end
	return tostring(opinion or "")
end

function W.RatingOpinionSymbol(member)
	local opinion = W.RatingOpinion(member)
	if Addon.RatingOpinionSymbol then
		return Addon:RatingOpinionSymbol(opinion)
	end
	return "="
end

function W.RatingOpinionIcon(member)
	local opinion = W.RatingOpinion(member)
	if Addon.RatingOpinionIcon then
		return Addon:RatingOpinionIcon(opinion)
	end
	return nil
end

function W.RatingOpinionColor(member)
	local opinion = W.RatingOpinion(member)
	if Addon.RatingOpinionColor then
		return Addon:RatingOpinionColor(opinion)
	end
	return UI.TEXT_IDLE
end

function W.FormatOpinionLine(member)
	return W.T("RATING_PROFILE_OPINION", W.RatingOpinionText(member))
end

function W.FormatTagLine(member)
	local _, tags = W.RatingOpinion(member)
	if Addon.RatingTagColoredSummary then
		return Addon:RatingTagColoredSummary(tags, 3)
	end
	return ""
end

function W.ShowMemberRatingTooltip(anchor, member, opts)
	if not member then
		return
	end
	opts = type(opts) == "table" and opts or nil
	GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
	local opinionText = W.RatingOpinionText(member)
	if Addon.RatingWrapColor and Addon.RatingOpinionColor then
		opinionText = Addon:RatingWrapColor(opinionText, Addon:RatingOpinionColor(W.RatingOpinion(member)))
	end
	GameTooltip:AddLine(W.T("COL_OPINION") .. ": " .. opinionText)
	local tags = W.FormatTagLine(member)
	if tags ~= "" then
		GameTooltip:AddLine(W.T("COL_TAGS") .. ": " .. tags, 0.8, 0.8, 0.8, true)
	end
	if Addon.GetCommunityRating then
		local community = Addon:GetCommunityRating(member)
		local percent = community and tonumber(community.positivePercent)
		if percent then
			GameTooltip:AddLine(W.T("TOOLTIP_COMMUNITY_POSITIVE", percent), 0.8, 0.8, 0.8)
			if Addon.RatingTagColoredSummary and community.tags then
				local communityTags = Addon:RatingTagColoredSummary(community.tags, 3)
				if communityTags ~= "" then
					GameTooltip:AddLine(communityTags, 0.75, 0.75, 0.75, true)
				end
			end
		end
	end
	local guildText = W.FormatGuildDisplay(member.guildName, member.guildRank)
	if guildText and guildText ~= "-" then
		GameTooltip:AddLine(W.T("COL_GUILD") .. ": " .. guildText, 0.8, 0.8, 0.8, true)
	end
	if opts and opts.gearCheck then
		W.AppendGearCheckRaidTooltip(opts.gearEntry)
	end
	if opts and type(opts.raidBuffs) == "table" and #opts.raidBuffs > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(W.T("COL_BUFFS"), UI.GOLD[1], UI.GOLD[2], UI.GOLD[3])
		for buffIndex = 1, #opts.raidBuffs do
			local buff = opts.raidBuffs[buffIndex]
			local buffName = buff and buff.name
			if buffName and buffName ~= "" then
				local icon = W.IconMarkup(buff.icon, 14)
				if icon ~= "" then
					GameTooltip:AddLine(icon .. " " .. buffName, 1, 1, 1)
				else
					GameTooltip:AddLine(buffName, 1, 1, 1)
				end
			end
		end
	end
	GameTooltip:Show()
end

local TOOLTIP_DETAIL_MAX = 6

function W.AppendGearCheckRaidTooltip(gearEntry)
	if not Addon.BuildGearCheckCategoryTooltipLines then
		return
	end

	local report = gearEntry and gearEntry.report
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(W.T("GEAR_CHECK_RAID_TIP_HEADER"), 1, 0.82, 0)

	if not report then
		local statusLabel = Addon.GetGearCheckRaidEntryStatusLabel
			and Addon:GetGearCheckRaidEntryStatusLabel(gearEntry)
			or W.T("GEAR_CHECK_RAID_NOT_SCANNED")
		GameTooltip:AddLine(statusLabel, 0.7, 0.7, 0.7, true)
		GameTooltip:AddLine(W.T("GEAR_CHECK_RAID_CLICK_HINT"), 0.6, 0.6, 0.6, true)
		return
	end

	local sections = {
		{ key = "gear", labelKey = "GEAR_CHECK_RAID_TIP_GEAR" },
		{ key = "enchantSocket", labelKey = "GEAR_CHECK_RAID_TIP_ENCHANT" },
	}

	for sectionIndex = 1, #sections do
		local section = sections[sectionIndex]
		local block = Addon:BuildGearCheckCategoryTooltipLines(report, section.key, TOOLTIP_DETAIL_MAX)
		local gradeColor = W.GearVerdictColor(block.grade)
		GameTooltip:AddLine(
			W.T(section.labelKey, W.WrapGearGradation(block.grade)),
			gradeColor[1],
			gradeColor[2],
			gradeColor[3]
		)
		for lineIndex = 1, #block.lines do
			local line = block.lines[lineIndex]
			local color = UI.TEXT_IDLE
			if line.severity == "hard" then
				color = UI.GEAR_BAD
			elseif line.severity == "soft" then
				color = UI.GEAR_REPLACE
			elseif line.severity == "clean" then
				color = UI.GEAR_GOOD
			else
				color = { 0.8, 0.8, 0.8 }
			end
			local indent = (line.kind == "bullet") and "    " or "  "
			GameTooltip:AddLine(indent .. line.text, color[1], color[2], color[3], true)
		end
		if block.hidden and block.hidden > 0 then
			GameTooltip:AddLine(W.T("GEAR_CHECK_RAID_TIP_MORE", block.hidden), 0.6, 0.6, 0.6, true)
		end
	end

	GameTooltip:AddLine(W.T("GEAR_CHECK_RAID_CLICK_HINT"), 0.6, 0.6, 0.6, true)
end

function W.AttachLayoutVersionLabel(titleBarOrParent, version, anchorRightOf)
	local label = titleBarOrParent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetJustifyH("RIGHT")
	label:SetText("v" .. tostring(version))
	W.SetFontColor(label, UI.TEXT_DISABLED)

	if anchorRightOf then
		label:SetPoint("RIGHT", anchorRightOf, "LEFT", -8, 0)
	else
		label:SetPoint("RIGHT", -(UI.CLOSE_SIZE + 8), 0)
	end

	titleBarOrParent.layoutVersionText = label
	return label
end

function W.DetachFrameChildren(frame)
	if not frame or not frame.GetChildren then
		return
	end
	local children = { frame:GetChildren() }
	for index = 1, #children do
		local child = children[index]
		child:Hide()
		if child.EnableMouse then
			child:EnableMouse(false)
		end
		if child.EnableMouseWheel then
			child:EnableMouseWheel(false)
		end
		child:SetParent(nil)
	end
end
