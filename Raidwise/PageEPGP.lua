-- In-game EPGP roster and priority view.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme
Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 16
local PAGE_SIZE = 50
local EPGP_ROW_H = 28

local function FormatValue(value)
	if value == nil then return "—" end
	return tostring(value)
end

local function CurrentGroupNames(raidOnly)
	local names = {}
	local function Add(unit)
		if UnitExists and UnitExists(unit) and UnitName then
			local name, realm = UnitName(unit)
			if name then names[(name .. (realm and realm ~= "" and "-" .. realm or "")):lower()] = true; names[name:lower()] = true end
		end
	end
	local raidCount = (GetNumRaidMembers and GetNumRaidMembers()) or 0
	if raidCount > 0 then
		if raidOnly then
			for index = 1, raidCount do Add("raid" .. index) end
		else
			local _, _, playerSubgroup
			for index = 1, raidCount do
				local name, _, subgroup = GetRaidRosterInfo(index)
				if name == UnitName("player") then playerSubgroup = subgroup; break end
			end
			for index = 1, raidCount do
				local _, _, subgroup = GetRaidRosterInfo(index)
				if subgroup == playerSubgroup then Add("raid" .. index) end
			end
		end
	elseif not raidOnly then
		Add("player")
		local partyCount = (GetNumPartyMembers and GetNumPartyMembers()) or 0
		for index = 1, partyCount do Add("party" .. index) end
	end
	return names
end

local function GetFilteredMembers(snapshot, query, groupOnly, raidOnly, includeLinked)
	if not snapshot then return {} end
	local groupNames = (groupOnly or raidOnly) and CurrentGroupNames(raidOnly) or nil
	local filtered, matched, selectedGroups = {}, {}, {}
	query = (query or ""):lower()
	for index, member in ipairs(snapshot.members or {}) do
		local specs = member.publicNoteParsed and member.publicNoteParsed.specs or {}
		local searchable = (tostring(member.name or "") .. " " .. tostring(member.publicNote or "") .. " " .. tostring(specs[1] and specs[1].label or "")):lower()
		local inGroup = not groupNames or groupNames[tostring(member.name or ""):lower()]
		if inGroup then
			if query == "" or searchable:find(query, 1, true) then
				matched[#matched + 1] = member
				selectedGroups[member.mainIndex or index] = true
			end
		end
	end
	if query ~= "" then
		for index, member in ipairs(snapshot.members) do
			local isMain = member.mainIndex == index
			local nameMatches = tostring(member.name or ""):lower():find(query, 1, true)
			if isMain and nameMatches then selectedGroups[index] = true end
		end
	end
	if (includeLinked and groupNames) or query ~= "" then
		local included = {}
		for _, member in ipairs(matched) do
			local index = member.rosterIndex
			if index then included[index] = true; filtered[#filtered + 1] = member end
		end
		for index, member in ipairs(snapshot.members) do
			if selectedGroups[member.mainIndex or index] and not included[index] then
				filtered[#filtered + 1] = member
				included[index] = true
			end
		end
	else
		filtered = matched
	end
	return filtered
end

local function SortValue(member, columnIndex, snapshot)
	local main = member.mainIndex and snapshot.members[member.mainIndex] or member
	local specs = member.publicNoteParsed and member.publicNoteParsed.specs or {}
	local spec = specs[1] or {}
	if columnIndex == 1 then
		local index = member.rosterIndex
		return member.mainIndex and member.mainIndex ~= index and "t" or "m"
	end
	if columnIndex == 2 then return tostring(member.name or ""):lower() end
	if columnIndex == 3 then return member.ep end
	if columnIndex == 4 then return member.effectiveGP end
	if columnIndex == 5 then return member.pr end
	if columnIndex == 6 then return tostring(member.publicNote or ""):lower() end
end

local function RefreshReport(page)
	local snapshot = Addon.db.epgp.view
	local filtered = GetFilteredMembers(snapshot, page.search:GetText(), page.groupOnly:GetChecked(), page.raidOnly:GetChecked(), page.includeLinked:GetChecked())
	if snapshot then
		local sortColumn, descending = page.sortColumn or 2, page.sortDescending
		table.sort(filtered, function(left, right)
			local leftMainIndex = left.mainIndex or left.rosterIndex
			local rightMainIndex = right.mainIndex or right.rosterIndex
			if leftMainIndex == rightMainIndex then
				local leftIsMain, rightIsMain = leftMainIndex == left.rosterIndex, rightMainIndex == right.rosterIndex
				if leftIsMain ~= rightIsMain then return leftIsMain end
				return tostring(left.name or ""):lower() < tostring(right.name or ""):lower()
			end
			local leftRoot = snapshot.members[leftMainIndex] or left
			local rightRoot = snapshot.members[rightMainIndex] or right
			local leftValue, rightValue = SortValue(leftRoot, sortColumn, snapshot), SortValue(rightRoot, sortColumn, snapshot)
			if leftValue == rightValue then return tostring(leftRoot.name or ""):lower() < tostring(rightRoot.name or ""):lower() end
			if leftValue == nil then return false end
			if rightValue == nil then return true end
			if descending then return leftValue > rightValue end
			return leftValue < rightValue
		end)
	end
	if snapshot and not page.groupOnly:GetChecked() and not page.raidOnly:GetChecked() then
		local visibleMembers, collapsed = {}, page.collapsedGroups or {}
		local collapsedRoots = {}
		for _, member in ipairs(filtered) do
			local rootIndex = member.mainIndex or member.rosterIndex
			local isAlt = member.mainIndex and member.mainIndex ~= member.rosterIndex
			if not (isAlt and collapsed[rootIndex]) then visibleMembers[#visibleMembers + 1] = member end
			if not isAlt and collapsed[rootIndex] then collapsedRoots[rootIndex] = true end
		end
		filtered = visibleMembers
		page.collapsedRoots = collapsedRoots
	end
	local pageCount = math.max(1, math.ceil(#filtered / PAGE_SIZE))
	page.pageNumber = math.min(math.max(page.pageNumber or 1, 1), pageCount)
	local first = (page.pageNumber - 1) * PAGE_SIZE + 1
	local visible = math.min(PAGE_SIZE, math.max(0, #filtered - first + 1))
	local columns = page.columns
	local tableWidth = 0
	for _, column in ipairs(columns) do tableWidth = tableWidth + column.width end
	local contentHeight = UI.CD_HEADER_H + math.max(visible, 1) * EPGP_ROW_H
	page.tableContent:SetSize(tableWidth, contentHeight)
	page.tableHeader:SetWidth(tableWidth)
	page.pageLabel:SetText(string.format("Page %d / %d (%d)", page.pageNumber, pageCount, #filtered))
	if page.previous then if page.pageNumber > 1 then page.previous:Enable() else page.previous:Disable() end end
	if page.next then if page.pageNumber < pageCount then page.next:Enable() else page.next:Disable() end end
	W.HidePoolFrom(page.rowFrames, visible + 1)
	for rowIndex = 1, visible do
		local member = filtered[first + rowIndex - 1]
		local row = page.rowFrames[rowIndex]
		if not row then
			row = CreateFrame("Button", nil, page.tableContent)
			W.ApplyPlainPanel(row, UI.CD_ROW_A)
			row:RegisterForClicks("LeftButtonUp")
			row:SetScript("OnClick", function(clickedRow)
				local clickedMember = clickedRow.member
				if not clickedMember or page.groupOnly:GetChecked() or page.raidOnly:GetChecked() then return end
				local rootIndex = clickedMember.mainIndex or clickedMember.rosterIndex
				if clickedMember.rosterIndex ~= rootIndex then return end
				local hasAlts = false
				for _, candidate in ipairs((Addon.db.epgp.view and Addon.db.epgp.view.members) or {}) do
					if candidate.mainIndex == rootIndex and candidate.rosterIndex ~= rootIndex then hasAlts = true; break end
				end
				if hasAlts then
					page.collapsedGroups = page.collapsedGroups or {}
					page.collapsedGroups[rootIndex] = not page.collapsedGroups[rootIndex]
					RefreshReport(page)
				end
			end)
			row.cells = {}
			local x = 0
			for columnIndex, column in ipairs(columns) do
				local cell = W.CreateFontString(row, nil, "OVERLAY", "GameFontNormalSmall")
				cell:SetPoint("TOPLEFT", x + 4, -4); cell:SetWidth(column.width - 8); cell:SetHeight(EPGP_ROW_H - 6)
				cell:SetJustifyH("LEFT"); cell:SetJustifyV("TOP")
				row.cells[columnIndex] = cell
				x = x + column.width
			end
			page.rowFrames[rowIndex] = row
		end
		row:ClearAllPoints(); row:SetPoint("TOPLEFT", page.tableContent, "TOPLEFT", 0, -(UI.CD_HEADER_H + (rowIndex - 1) * EPGP_ROW_H))
		row:SetSize(tableWidth, EPGP_ROW_H); row:Show()
		row.member = member
		local specs = member.publicNoteParsed and member.publicNoteParsed.specs or {}
		local mainSpec = specs[1] or {}
		local mainMember = member.mainIndex and snapshot.members[member.mainIndex] or member
		local rollStatus = member.bisEligibilityStatus == "available" and (member.bisEligible and "V" or "X") or "?"
		local isAlt = member.mainIndex and member.mainIndex ~= member.rosterIndex
		local memberType = isAlt and "T" or (member.mainIndex == member.rosterIndex and "M" or "?")
		local typeLabel = isAlt and "Альт" or (memberType == "M" and "Мейн" or "?")
		local linkStatus = member.linkStatus or (member.publicNoteParsed and member.publicNoteParsed.status)
		if linkStatus and linkStatus ~= "main" and linkStatus ~= "linked" then
			local statusLabel = linkStatus == "invalid" and "Ошибка" or (linkStatus == "invalid-chain" and "Ссылка" or linkStatus)
			typeLabel = typeLabel .. " " .. statusLabel
		end
		local rootIndex = member.mainIndex or member.rosterIndex
		local hasAlts = false
		for _, candidate in ipairs(snapshot.members) do
			if candidate.mainIndex == rootIndex and candidate.rosterIndex ~= rootIndex then hasAlts = true; break end
		end
		local gpValue = member.gp == nil and "?" or tostring(member.gp)
		if member.effectiveGP and member.gp ~= nil and member.effectiveGP ~= member.gp then
			gpValue = gpValue .. " (+" .. tostring(member.effectiveGP - member.gp) .. ")"
		elseif member.gp == nil and member.effectiveGP then
			gpValue = "? (+" .. tostring(member.effectiveGP) .. ")"
		end
		local values = {
			typeLabel, member.name or "?", FormatValue(member.ep) .. " " .. rollStatus, gpValue,
			member.pr and string.format("%.3f", member.pr) or FormatValue(member.prStatus),
			tostring(member.publicNote or ""),
		}
		for columnIndex, cell in ipairs(row.cells) do
			cell:SetText(tostring(values[columnIndex] or ""))
			if columnIndex == 3 or columnIndex == 4 then cell:SetJustifyH("RIGHT") end
			if columnIndex <= 2 and not isAlt then
				cell:SetFontObject(GameFontNormal)
			elseif columnIndex <= 2 then
				cell:SetFontObject(GameFontNormalSmall)
			end
			if columnIndex == 1 then
				if memberType == "M" then cell:SetTextColor(0.25, 0.9, 1) elseif memberType == "T" then cell:SetTextColor(1, 0.8, 0.2) else cell:SetTextColor(1, 0.35, 0.35) end
			elseif columnIndex == 2 then
				local classToken = member.classFileName or member.class
				local collapsed = page.collapsedGroups and page.collapsedGroups[rootIndex]
				local prefix = isAlt and "   ↳ " or (hasAlts and ((page.collapsedRoots and page.collapsedRoots[rootIndex]) and "+ " or "− ") or "")
				cell:SetText(prefix .. W.CharacterIconMarkup({class=classToken}, 24) .. tostring(member.name or "?"))
				cell:SetTextColor(W.ClassColor(classToken))
			elseif columnIndex == 3 and member.bisEligibilityStatus == "available" then
				if member.bisEligible then cell:SetTextColor(0.25, 1, 0.25) else cell:SetTextColor(1, 0.3, 0.3) end
			elseif columnIndex == 4 then
				cell:SetTextColor(1, 0.3, 0.3)
			else
				W.SetFontColor(cell, UI.TEXT_IDLE)
			end
		end
		if not isAlt then
			W.SetBackdropColor(row, UI.CD_CURRENT_CHARACTER)
		else
			W.SetBackdropColor(row, rowIndex % 2 == 0 and UI.CD_ROW_B or UI.CD_ROW_A)
		end
	end
	W.LayoutTableScrollBars(page)
	page.snapshotLabel:SetText(snapshot and ("Members " .. tostring(snapshot.memberCountReported or #snapshot.members)
		.. " | " .. tostring(snapshot.officerNotesStatus or "unknown")) or "No roster snapshot")
end

local function ApplySettings(page)
	local settings = Addon.db.epgp
	local minimumGP = tonumber(page.minimumGP:GetText())
	local bisMinimumEP = tonumber(page.bisMinimumEP:GetText())
	if not minimumGP or minimumGP < 0 or not bisMinimumEP or bisMinimumEP < 0 then
		page.status:SetText("GP base and BIS EP threshold must be non-negative numbers.")
		return false
	end
	settings.minimumGP, settings.bisMinimumEP = minimumGP, bisMinimumEP
	if Addon.db.epgp.snapshot then
		local resolved = Addon.GuildRosterLinks.Resolve(Addon.GuildRosterParser.ParseGuildRosterSnapshot(Addon.db.epgp.snapshot))
		Addon.db.epgp.view = Addon.GuildEPGP.Calculate(resolved, settings)
	end
	RefreshReport(page)
	page.status:SetText("EPGP settings saved.")
	return true
end

function Addon:RefreshEPGPRoster()
	local snapshot, err = self:CollectGuildRosterSnapshot()
	if not snapshot then
		local page = self.mainFrame and self.mainFrame.epgpPage
		if page then page.status:SetText(err or "Roster unavailable.") end
		return
	end
	self.db.epgp.snapshot = snapshot
	local parsed = self.GuildRosterParser.ParseGuildRosterSnapshot(snapshot)
	local resolved = self.GuildRosterLinks.Resolve(parsed)
	self.db.epgp.view = self.GuildEPGP.Calculate(resolved, self.db.epgp)
	local page = self.mainFrame and self.mainFrame.epgpPage
	if page then
		RefreshReport(page)
		page.status:SetText("Roster parsed. Review ambiguous and unresolved rows before relying on PR.")
	end
end

function Addon:StartEPGPRosterCollection()
	if self.epgpCollectFrame then return end
	if type(GetNumGuildMembers) ~= "function" or type(GetGuildRosterInfo) ~= "function" then
		self:FinishEPGPRosterCollection(nil, "Guild roster API unavailable")
		return
	end
	local count = GetNumGuildMembers()
	if type(count) ~= "number" or count < 0 then
		self:FinishEPGPRosterCollection(nil, "Guild roster unavailable")
		return
	end
	local snapshot = {
		memberCountReported = count,
		members = {},
		scannedAt = type(time) == "function" and time() or nil,
		officerNotesStatus = (type(CanEditOfficerNote) ~= "function" or CanEditOfficerNote()) and "available" or "unavailable",
	}
	local frame = CreateFrame("Frame")
	self.epgpCollectFrame = frame
	local index, elapsed = 1, 0
	frame:SetScript("OnUpdate", function(collector, delta)
		elapsed = elapsed + delta
		if elapsed < 0.03 then return end
		elapsed = 0
		local stopAt = math.min(count, index + 9)
		while index <= stopAt do
			local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName = GetGuildRosterInfo(index)
			if name then
				snapshot.members[#snapshot.members + 1] = {
					name = name, rank = rank, rankIndex = rankIndex, level = level, class = class,
					classFileName = classFileName, zone = zone, publicNote = note,
					officerNote = officerNote, online = online, status = status,
				}
			end
			index = index + 1
		end
		local page = self.mainFrame and self.mainFrame.epgpPage
		if page and page.progress then
			page.progress:SetProgress(index - 1, math.max(count, 1))
			page.status:SetText("Collecting guild members: " .. tostring(math.min(index - 1, count)) .. " / " .. tostring(count))
		end
		if index > count then
			collector:SetScript("OnUpdate", nil)
			self.epgpCollectFrame = nil
			self:FinishEPGPRosterCollection(snapshot)
		end
	end)
end

function Addon:FinishEPGPRosterCollection(snapshot, err)
	local page = self.mainFrame and self.mainFrame.epgpPage
	if not snapshot then
		if page then page.status:SetText(err or "Roster collection failed."); page.progress:SetProgress(0, 1) end
		local previousOffline = self.epgpPreviousOffline
		self.epgpPreviousOffline = nil
		if previousOffline ~= nil and previousOffline ~= true and type(SetGuildRosterShowOffline) == "function" then
			SetGuildRosterShowOffline(previousOffline)
		end
		return
	end
	if page then
		page.status:SetText("Processing notes, character links, and EPGP...")
		page.progress:SetProgress(0.85, 1)
	end
	self.db.epgp.snapshot = snapshot
	local parsed = self.GuildRosterParser.ParseGuildRosterSnapshot(snapshot)
	local resolved = self.GuildRosterLinks.Resolve(parsed)
	self.db.epgp.view = self.GuildEPGP.Calculate(resolved, self.db.epgp)
	if page then
		RefreshReport(page)
		page.status:SetText("Complete: " .. tostring(#snapshot.members) .. " of " .. tostring(snapshot.memberCountReported) .. " members processed (notes, links, PR ready).")
		page.progress:SetProgress(1, 1)
	end
	local previousOffline = self.epgpPreviousOffline
	self.epgpPreviousOffline = nil
	if previousOffline ~= nil and previousOffline ~= true and type(SetGuildRosterShowOffline) == "function" then
		SetGuildRosterShowOffline(previousOffline)
	end
end

local function CreateEPGPPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints(parent)
	local refresh = W.CreatePlainButton(page, 190, UI.ACTION_BTN_H, W.T("EPGP_REFRESH"))
	refresh:SetPoint("TOPLEFT", 0, 0)
	refresh:SetScript("OnClick", function()
		if type(SetGuildRosterShowOffline) == "function" then
			Addon.epgpPreviousOffline = type(GetGuildRosterShowOffline) == "function" and GetGuildRosterShowOffline() or nil
			SetGuildRosterShowOffline(true)
		end
		Addon.epgpRefreshPending = true
		if type(GuildRoster) == "function" then GuildRoster() end
		page.status:SetText("Requesting full guild roster...")
		page.progress:SetProgress(0, 1)
	end)
	local search = CreateFrame("EditBox", "RaidwiseEPGPSearchV1", page, "InputBoxTemplate")
	search:SetSize(170, 24); search:SetPoint("LEFT", refresh, "RIGHT", 14, 0); search:SetAutoFocus(false)
	search:SetScript("OnTextChanged", function()
		page.pageNumber = 1
		RefreshReport(page)
	end)
	local minimumLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	minimumLabel:SetPoint("TOPLEFT", refresh, "BOTTOMLEFT", 0, -12); minimumLabel:SetText(W.T("EPGP_MIN_GP"))
	local minimumGP = CreateFrame("EditBox", "RaidwiseEPGPMinimumGPV1", page, "InputBoxTemplate")
	minimumGP:SetSize(70, 24); minimumGP:SetPoint("LEFT", minimumLabel, "RIGHT", 8, 0); minimumGP:SetAutoFocus(false)
	minimumGP:SetNumeric(true)
	local bisLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	bisLabel:SetPoint("LEFT", minimumGP, "RIGHT", 18, 0); bisLabel:SetText(W.T("EPGP_BIS_EP"))
	local bisMinimumEP = CreateFrame("EditBox", "RaidwiseEPGPBisEPV1", page, "InputBoxTemplate")
	bisMinimumEP:SetSize(70, 24); bisMinimumEP:SetPoint("LEFT", bisLabel, "RIGHT", 8, 0); bisMinimumEP:SetAutoFocus(false)
	bisMinimumEP:SetNumeric(true)
	local apply = W.CreatePlainButton(page, 110, UI.ACTION_BTN_H, W.T("BTN_SAVE"))
	apply:SetPoint("LEFT", bisMinimumEP, "RIGHT", 14, 0)
	local status = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	status:SetPoint("TOPLEFT", minimumLabel, "BOTTOMLEFT", 0, -10); status:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	status:SetJustifyH("LEFT")
	local groupOnly = CreateFrame("CheckButton", "RaidwiseEPGPGroupOnlyV8", page, "UICheckButtonTemplate")
	groupOnly:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE); groupOnly:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -4)
	local groupText = _G[groupOnly:GetName() .. "Text"]; if groupText then groupText:SetText(W.T("EPGP_FILTER_GROUP")) end
	local raidOnly = CreateFrame("CheckButton", "RaidwiseEPGPRaidOnlyV8", page, "UICheckButtonTemplate")
	raidOnly:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE); raidOnly:SetPoint("LEFT", groupOnly, "RIGHT", 115, 0)
	local raidText = _G[raidOnly:GetName() .. "Text"]; if raidText then raidText:SetText(W.T("EPGP_FILTER_RAID")) end
	groupOnly:SetScript("OnClick", function()
		if groupOnly:GetChecked() then
			raidOnly:SetChecked(false)
			includeLinked:SetChecked(false)
		end
		page.pageNumber = 1
		RefreshReport(page)
	end)
	raidOnly:SetScript("OnClick", function()
		if raidOnly:GetChecked() then
			groupOnly:SetChecked(false)
			includeLinked:SetChecked(false)
		end
		page.pageNumber = 1
		RefreshReport(page)
	end)
	local includeLinked = CreateFrame("CheckButton", "RaidwiseEPGPLinkedGroupV8", page, "UICheckButtonTemplate")
	includeLinked:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE); includeLinked:SetPoint("LEFT", raidOnly, "RIGHT", 135, 0)
	local linkedText = _G[includeLinked:GetName() .. "Text"]; if linkedText then linkedText:SetText(W.T("EPGP_INCLUDE_LINKED")) end
	includeLinked:SetScript("OnClick", function() page.pageNumber = 1; RefreshReport(page) end)
	local previous = W.CreatePlainButton(page, 90, UI.ACTION_BTN_H, W.T("EPGP_PREVIOUS"))
	previous:SetPoint("TOPLEFT", groupOnly, "BOTTOMLEFT", 0, -2)
	local nextPage = W.CreatePlainButton(page, 90, UI.ACTION_BTN_H, W.T("EPGP_NEXT"))
	nextPage:SetPoint("LEFT", previous, "RIGHT", 5, 0)
	local pageLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	pageLabel:SetPoint("LEFT", nextPage, "RIGHT", 8, 0)
	previous:SetScript("OnClick", function() page.pageNumber = math.max(1, page.pageNumber - 1); RefreshReport(page) end)
	nextPage:SetScript("OnClick", function() page.pageNumber = page.pageNumber + 1; RefreshReport(page) end)
	local progress = W.CreateProgressBar(page, 12)
	progress:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5)
	progress:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	progress:SetProgress(0, 1)
	local snapshotLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	snapshotLabel:SetPoint("TOPLEFT", progress, "BOTTOMLEFT", 0, -5); snapshotLabel:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	snapshotLabel:SetJustifyH("LEFT")
	local tableHost = CreateFrame("Frame", nil, page)
	tableHost:SetPoint("TOPLEFT", snapshotLabel, "BOTTOMLEFT", 0, -5); tableHost:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	W.ApplyPlainPanel(tableHost, UI.PANEL_BG)
	local tableScroll = CreateFrame("ScrollFrame", "RaidwiseEPGPRosterScrollV3", tableHost)
	tableScroll:SetPoint("TOPLEFT", 1, -1); tableScroll:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), UI.CD_HSCROLL_H + 2)
	tableScroll:EnableMouseWheel(true)
	local tableContent = CreateFrame("Frame", nil, tableScroll); tableContent:SetSize(1, 1); tableScroll:SetScrollChild(tableContent)
	local columns = {
		{key=W.T("EPGP_COL_TYPE"), width=105}, {key=W.T("EPGP_COL_CHARACTER"), width=150}, {key=W.T("EPGP_COL_EP_ROLL"), width=105},
		{key=W.T("EPGP_COL_GP_BASE"), width=100}, {key=W.T("EPGP_COL_PR"), width=65}, {key=W.T("EPGP_COL_NOTE"), width=240},
	}
	local tableHeader = CreateFrame("Frame", nil, tableContent); tableHeader:SetPoint("TOPLEFT", 0, 0); tableHeader:SetHeight(UI.CD_HEADER_H)
	W.ApplyPlainPanel(tableHeader, UI.TITLE_BG)
	local columnX = 0
	local headerButtons = {}
	for columnIndex, column in ipairs(columns) do
		local sortIndex = columnIndex
		local button = CreateFrame("Button", nil, tableHeader)
		button:SetPoint("TOPLEFT", columnX, 0); button:SetWidth(column.width); button:SetHeight(UI.CD_HEADER_H)
		local label = W.CreateFontString(button, nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", 4, -8); label:SetWidth(column.width - 8)
		if columnIndex == 3 or columnIndex == 4 then label:SetJustifyH("RIGHT") end
		label:SetText(column.key); W.SetFontColor(label, UI.GOLD)
		button:SetScript("OnClick", function()
			if page.sortColumn == sortIndex then
				page.sortDescending = not page.sortDescending
			else
				page.sortColumn, page.sortDescending = sortIndex, false
			end
			page.pageNumber = 1
			RefreshReport(page)
		end)
		headerButtons[columnIndex] = button
		columnX = columnX + column.width
	end
	local verticalBar = W.CreateCooldownScrollBar(tableHost, "VERTICAL")
	verticalBar:SetPoint("TOPRIGHT", -1, -1); verticalBar:SetPoint("BOTTOMRIGHT", -1, UI.CD_HSCROLL_H + 2)
	verticalBar:SetScript("OnValueChanged", function(bar) tableScroll:SetVerticalScroll(bar:GetValue() or 0) end)
	local horizontalBar = W.CreateCooldownScrollBar(tableHost, "HORIZONTAL")
	horizontalBar:SetPoint("BOTTOMLEFT", 1, 1); horizontalBar:SetPoint("BOTTOMRIGHT", -(UI.CD_SCROLLBAR_W + 2), 1)
	horizontalBar:SetScript("OnValueChanged", function(bar) tableScroll:SetHorizontalScroll(bar:GetValue() or 0) end)
	tableScroll:SetScript("OnMouseWheel", function(scroll, delta)
		local maxValue = math.max(0, (tableContent:GetHeight() or 0) - (scroll:GetHeight() or 0))
		local value = math.max(0, math.min(maxValue, (scroll:GetVerticalScroll() or 0) - delta * EPGP_ROW_H))
		scroll:SetVerticalScroll(value); verticalBar:SetValue(value)
	end)
	tableScroll:SetScript("OnSizeChanged", function()
		W.LayoutTableScrollBars({tableHost=tableHost, scroll=tableScroll, tableContent=tableContent, vBar=verticalBar, hBar=horizontalBar})
	end)
	page.minimumGP, page.bisMinimumEP, page.status, page.search, page.progress = minimumGP, bisMinimumEP, status, search, progress
	page.groupOnly, page.raidOnly, page.previous, page.next, page.pageLabel, page.pageNumber = groupOnly, raidOnly, previous, nextPage, pageLabel, 1
	page.includeLinked = includeLinked
	page.snapshotLabel, page.tableContent, page.tableHeader, page.rowFrames, page.columns = snapshotLabel, tableContent, tableHeader, {}, columns
	page.headerButtons = headerButtons
	page.scroll, page.vBar, page.hBar, page.tableHost = tableScroll, verticalBar, horizontalBar, tableHost
	minimumGP:SetText(tostring(Addon.db.epgp.minimumGP == nil and 500 or Addon.db.epgp.minimumGP))
	bisMinimumEP:SetText(tostring(Addon.db.epgp.bisMinimumEP or 4000))
	apply:SetScript("OnClick", function() ApplySettings(page) end)
	page.layoutVersion = LAYOUT_VERSION
	RefreshReport(page)
	return page
end

Addon.Pages.EPGP = {
	id = "epgp",
	LAYOUT_VERSION = LAYOUT_VERSION,
	Create = CreateEPGPPage,
	Refresh = function(page) if page then RefreshReport(page) end end,
}
