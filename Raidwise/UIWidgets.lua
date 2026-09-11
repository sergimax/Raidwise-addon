-- Generic UI controls and layout helpers.
local Addon = Raidwise
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
	W.SetBackdropColor(frame, color)
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
	local function Edge(texture)
		if not texture then
			texture = frame:CreateTexture(nil, "OVERLAY")
			texture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		end
		W.SetTextureColor(texture, color)
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
	W.SetTextureColor(bg, UI.INPUT_BG)

	local bar = CreateFrame("StatusBar", nil, host)
	bar:SetPoint("TOPLEFT", 1, -1)
	bar:SetPoint("BOTTOMRIGHT", -1, 1)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	local fill = bar:GetStatusBarTexture()
	if fill then
		local gold = UI.GOLD_DIM or UI.GOLD or { 0.77, 0.63, 0.29 }
		W.SetTextureColor(fill, gold)
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

function W.SetPlainButtonState(button, state)
	if state == "selected" then
		W.SetBackdropColor(button, UI.BTN_SELECTED)
		if button.label then
			W.SetFontColor(button.label, UI.GOLD)
		end
	elseif state == "hover" then
		W.SetBackdropColor(button, UI.BTN_HOVER)
		if button.label then
			W.SetFontColor(button.label, UI.TEXT_HOVER)
		end
	elseif state == "disabled" then
		W.SetBackdropColor(button, UI.BTN_DISABLED)
		if button.label then
			W.SetFontColor(button.label, UI.TEXT_DISABLED)
		end
	else
		W.SetBackdropColor(button, UI.BTN_IDLE)
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

	local text = W.CreateFontString(button, nil, "OVERLAY", "GameFontNormalSmall")
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
			probe = W.CreateFontString(box, nil, "ARTWORK")
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
	W.SetBackdropColor(scrollBG, UI.INPUT_BG)

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
	W.SetFontColor(exportBox, UI.TEXT_BODY)
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
	W.SetBackdropColor(host, UI.INPUT_BG)

	local box = CreateFrame("EditBox", boxName, host)
	box:SetPoint("TOPLEFT", 8, -4)
	box:SetPoint("BOTTOMRIGHT", -8, 4)
	box:SetFontObject(ChatFontNormal)
	W.SetFontColor(box, UI.TEXT_BODY)
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

function W.AttachLayoutVersionLabel(titleBarOrParent, version, anchorRightOf)
	local label = W.CreateFontString(titleBarOrParent, nil, "OVERLAY", "GameFontNormalSmall")
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
