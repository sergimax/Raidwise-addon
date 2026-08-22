-- Shared UI helpers for Raidwise windows and pages.

local Addon = Raidwise

Addon.UITheme = {
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
	CD_HEADER_H = 52,
	CD_ROW_H = 34,
	CD_SPEC_ICON = 14,
	ROSTER_ICON = 18,
	PROFILE_ICON = 24,
	CD_SCROLLBAR_W = 16,
	CD_HSCROLL_H = 16,
	CD_ROW_A = { 0.18, 0.18, 0.18, 0.90 },
	CD_ROW_B = { 0.14, 0.14, 0.14, 0.90 },

	-- Raid roster tab
	RAID_BUFF_ICON = 18,
	RAID_BUFF_MAX = 8,
	RAID_BUFF_GAP = 2,
	ROSTER_STATS_H = 16,
	RAID_STATS_H = 32,

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
	TEXT_ALERT = { 0.90, 0.20, 0.20 },
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

function W.ApplyPlainPanel(frame, color)
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

function W.SetFontColor(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

function W.SetPlainButtonState(button, state)
	if state == "selected" then
		button:SetBackdropColor(UI.BTN_SELECTED[1], UI.BTN_SELECTED[2], UI.BTN_SELECTED[3], UI.BTN_SELECTED[4])
		W.SetFontColor(button.label, UI.GOLD)
	elseif state == "hover" then
		button:SetBackdropColor(UI.BTN_HOVER[1], UI.BTN_HOVER[2], UI.BTN_HOVER[3], UI.BTN_HOVER[4])
		W.SetFontColor(button.label, UI.TEXT_HOVER)
	elseif state == "disabled" then
		button:SetBackdropColor(UI.BTN_DISABLED[1], UI.BTN_DISABLED[2], UI.BTN_DISABLED[3], UI.BTN_DISABLED[4])
		W.SetFontColor(button.label, UI.TEXT_DISABLED)
	else
		button:SetBackdropColor(UI.BTN_IDLE[1], UI.BTN_IDLE[2], UI.BTN_IDLE[3], UI.BTN_IDLE[4])
		W.SetFontColor(button.label, UI.TEXT_IDLE)
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

W.COPY_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 },
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

function W.CreateCopyBox(parent, scrollName, boxName)
	local host = CreateFrame("Frame", nil, parent)

	local scrollBG = CreateFrame("Frame", nil, host)
	scrollBG:SetPoint("TOPLEFT", 0, 0)
	scrollBG:SetPoint("BOTTOMRIGHT", -UI.COPY_SCROLLBAR_W, 0)
	scrollBG:SetBackdrop(W.COPY_BACKDROP)
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
	return -math.floor((UI.CD_ROW_H - iconSize) / 2)
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

function W.RaidRosterTableTopOffset()
	return UI.CD_TOOLBAR_H + UI.CD_HINT_TO_TABLE + UI.RAID_STATS_H + UI.CD_HINT_TO_TABLE
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

function W.ShowMemberRatingTooltip(anchor, member)
	if not member then
		return
	end
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
	GameTooltip:Show()
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
