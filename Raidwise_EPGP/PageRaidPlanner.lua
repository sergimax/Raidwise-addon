-- Guild roster based raid composition planner.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme
Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 2
local ROW_HEIGHT = 28

local function GearScoreThreshold(value)
	local threshold = tonumber((tostring(value or ""):gsub(",", "."))) or 0
	if threshold > 0 and threshold < 100 then threshold = threshold * 1000 end
	return threshold
end
Addon.RaidPlannerGearScoreThreshold = GearScoreThreshold

local function CurrentRaidNames()
	local names = {}
	local count = type(GetNumRaidMembers) == "function" and GetNumRaidMembers() or 0
	for index = 1, count do
		local name = GetRaidRosterInfo(index)
		if name then names[name:lower()] = true end
	end
	return names
end

local function Refresh(page)
	local view = Addon.db.epgp and Addon.db.epgp.view
	local query = (page.search:GetText() or ""):lower()
	local minimum = GearScoreThreshold(page.minimum:GetText())
	local onlineOnly = page.onlineOnly:GetChecked()
	local raidNames = CurrentRaidNames()
	local members, visibleGroups = {}, {}
	local added = {}
	for index, member in ipairs(view and view.members or {}) do
		local groupIndex = member.mainIndex or member.rosterIndex or index
		local group = view.characterGroups and view.characterGroups[groupIndex]
		local groupOnline = member.online
		if group then
			for _, childIndex in ipairs(group.memberIndexes or {}) do
				if view.members[childIndex] and view.members[childIndex].online then groupOnline = true end
			end
		end
		local spec = member.publicNoteParsed and member.publicNoteParsed.specs and member.publicNoteParsed.specs[1]
		local score = spec and spec.gearScore
		local inGroup = visibleGroups[groupIndex]
		local matches = (not onlineOnly or groupOnline)
			and (minimum <= 0 or (score and score >= minimum))
			and (query == "" or tostring(member.name or ""):lower():find(query, 1, true))
		if matches then
			visibleGroups[groupIndex] = true
			if not added[index] then members[#members + 1] = member; added[index] = true end
		elseif inGroup then
			-- A prior character in the same main/alt group matched; keep the group together.
			if not added[index] then members[#members + 1] = member; added[index] = true end
		end
	end
	local selected = Addon.db.epgp.raidPlan or {}
	local limit = page.raidSize == 10 and 10 or 25
	local rows = math.min(#members, 120)
	page.content:SetHeight(math.max(1, rows) * ROW_HEIGHT)
	W.HidePoolFrom(page.rows, rows + 1)
	for rowIndex = 1, rows do
		local member = members[rowIndex]
		local row = page.rows[rowIndex]
		if not row then
			row = CreateFrame("Button", nil, page.content)
			W.ApplyPlainPanel(row, UI.CD_ROW_A)
			row.nameText = W.CreateFontString(row, nil, "OVERLAY", "GameFontNormalSmall")
			row.nameText:SetPoint("LEFT", 8, 0); row.nameText:SetWidth(220); row.nameText:SetJustifyH("LEFT")
			row.classText = W.CreateFontString(row, nil, "OVERLAY", "GameFontNormalSmall")
			row.classText:SetPoint("LEFT", row.nameText, "RIGHT", 4, 0); row.classText:SetWidth(100)
			row.scoreText = W.CreateFontString(row, nil, "OVERLAY", "GameFontNormalSmall")
			row.scoreText:SetPoint("LEFT", row.classText, "RIGHT", 4, 0); row.scoreText:SetWidth(90)
			row.onlineText = W.CreateFontString(row, nil, "OVERLAY", "GameFontNormalSmall")
			row.onlineText:SetPoint("LEFT", row.scoreText, "RIGHT", 4, 0); row.onlineText:SetWidth(70)
			row:SetScript("OnClick", function(clicked)
				local name = clicked.member and clicked.member.name
				if not name then return end
				local plan = Addon.db.epgp.raidPlan or {}
				Addon.db.epgp.raidPlan = plan
				if plan[name] then plan[name] = nil
				else
					local count = 0
					for _ in pairs(plan) do count = count + 1 end
					if count >= (page.raidSize == 10 and 10 or 25) then return end
					plan[name] = true
				end
				Refresh(page)
			end)
			page.rows[rowIndex] = row
		end
		row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(rowIndex - 1) * ROW_HEIGHT)
		row:SetSize(page.content:GetWidth(), ROW_HEIGHT); row:Show(); row.member = member
		local specs = member.publicNoteParsed and member.publicNoteParsed.specs or {}
		local score = specs[1] and specs[1].gearScore
		local isSelected = selected[member.name]
		local current = raidNames[tostring(member.name or ""):lower()]
		row:SetBackdropColor(current and 0.48 or (isSelected and 0.18 or 0.08), current and 0.26 or (isSelected and 0.35 or 0.08), current and 0.08 or (isSelected and 0.18 or 0.08), 0.9)
		row.nameText:SetText((isSelected and "[x] " or "[ ] ") .. tostring(member.name or ""))
		row.classText:SetText(tostring(member.class or ""))
		row.scoreText:SetText(score and tostring(score) or "—")
		row.onlineText:SetText(member.online and "Online" or "Offline")
	end
	local selectedCount = 0
	for _ in pairs(selected) do selectedCount = selectedCount + 1 end
	page.status:SetText(string.format("%d / %d selected · %d characters", selectedCount, limit, #members))
end

local function Create(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)
	page.raidSize = 10
	page.rows = {}
	local function Label(anchor, text, x)
		local label = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, -5)
		label:SetText(text)
		return label
	end
	local raidLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	raidLabel:SetPoint("TOPLEFT", 0, 0); raidLabel:SetText(W.T("PLANNER_RAID_SIZE"))
	local ten = W.CreatePlainButton(page, 60, UI.ACTION_BTN_H, "10")
	ten:SetPoint("TOPLEFT", raidLabel, "BOTTOMLEFT", 0, -5)
	local twentyFive = W.CreatePlainButton(page, 60, UI.ACTION_BTN_H, "25")
	twentyFive:SetPoint("LEFT", ten, "RIGHT", 4, 0)
	local search = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
	search:SetSize(140, 24); search:SetPoint("LEFT", twentyFive, "RIGHT", 24, 0); search:SetAutoFocus(false)
	local searchLabel = Label(search, W.T("PLANNER_SEARCH"))
	local minimum = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
	minimum:SetSize(70, 24); minimum:SetPoint("LEFT", search, "RIGHT", 18, 0); minimum:SetAutoFocus(false); minimum:SetNumeric(true)
	local minimumLabel = Label(minimum, W.T("PLANNER_MIN_GS"))
	local onlineOnly = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
	onlineOnly:SetPoint("LEFT", minimum, "RIGHT", 22, 0); onlineOnly:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE)
	local onlineLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	onlineLabel:SetPoint("LEFT", onlineOnly, "RIGHT", 2, 0); onlineLabel:SetText(W.T("PLANNER_ONLINE_ONLY"))
	local status = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	status:SetPoint("TOPLEFT", ten, "BOTTOMLEFT", 0, -17); status:SetPoint("RIGHT", page, "RIGHT", 0, 0); status:SetJustifyH("LEFT")
	local hint = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	hint:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -3); hint:SetPoint("RIGHT", page, "RIGHT", 0, 0); hint:SetJustifyH("LEFT")
	hint:SetText("Search · minimum GearScore · online players; orange rows are already in your raid")
	local host = CreateFrame("Frame", nil, page)
	host:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -5); host:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(host, UI.PANEL_BG)
	local scroll = CreateFrame("ScrollFrame", nil, host)
	scroll:SetPoint("TOPLEFT", 1, -1); scroll:SetPoint("BOTTOMRIGHT", -UI.CD_SCROLLBAR_W, 1)
	local content = CreateFrame("Frame", nil, scroll); content:SetSize(1, 1); scroll:SetScrollChild(content)
	page.search, page.minimum, page.onlineOnly = search, minimum, onlineOnly
	page.inputLabels = { raidLabel, searchLabel, minimumLabel, onlineLabel }
	page.status, page.content, page.scroll = status, content, scroll
	local function RefreshPage() Refresh(page) end
	search:SetScript("OnTextChanged", RefreshPage); minimum:SetScript("OnTextChanged", RefreshPage); onlineOnly:SetScript("OnClick", RefreshPage)
	ten:SetScript("OnClick", function() page.raidSize = 10; Refresh(page) end)
	twentyFive:SetScript("OnClick", function() page.raidSize = 25; Refresh(page) end)
	page:SetScript("OnShow", RefreshPage)
	page.layoutVersion = LAYOUT_VERSION
	Refresh(page)
	return page
end

Addon.Pages.RaidPlanner = { id = "raid-planner", LAYOUT_VERSION = LAYOUT_VERSION, Create = Create, Refresh = function(page) if page then Refresh(page) end end }

if Addon.MenuPages then
	table.insert(Addon.MenuPages, { id = "raid-planner", key = "RaidPlanner", labelKey = "TAB_RAID_PLANNER", icon = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider", group = "guild" })
end
