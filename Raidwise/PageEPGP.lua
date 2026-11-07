-- In-game EPGP roster and priority view.

local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme
Addon.Pages = Addon.Pages or {}

local LAYOUT_VERSION = 3
local PAGE_SIZE = 20

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

local function BuildReport(snapshot, query, pageNumber, groupOnly, raidOnly)
	if not snapshot then return "No guild roster snapshot. Click Refresh guild roster." end
	pageNumber = math.max(1, tonumber(pageNumber) or 1)
	local groupNames = (groupOnly or raidOnly) and CurrentGroupNames(raidOnly) or nil
	local filtered = {}
	query = (query or ""):lower()
	for _, member in ipairs(snapshot.members or {}) do
		local specs = member.publicNoteParsed and member.publicNoteParsed.specs or {}
		local searchable = (tostring(member.name or "") .. " " .. tostring(member.publicNote or "") .. " " .. tostring(specs[1] and specs[1].label or "")):lower()
		local inGroup = not groupNames or groupNames[tostring(member.name or ""):lower()]
		if inGroup and (query == "" or searchable:find(query, 1, true)) then filtered[#filtered + 1] = member end
	end
	local pageCount = math.max(1, math.ceil(#filtered / PAGE_SIZE))
	pageNumber = math.min(pageNumber, pageCount)
	local lines = {
		"Members: " .. tostring(snapshot.memberCountExported or #snapshot.members)
			.. " / " .. tostring(snapshot.memberCountReported or #snapshot.members)
			.. "    Snapshot: " .. FormatValue(snapshot.scannedAt)
		.. "    Complete: " .. tostring(snapshot.complete ~= false)
		.. "    Officer notes: " .. tostring(snapshot.officerNotesStatus or "unknown"),
		"Minimum GP: " .. tostring(snapshot.epgpSettings.minimumGP)
			.. "    BIS minimum EP: " .. tostring(snapshot.epgpSettings.bisMinimumEP),
		"Character | Main | EP | GP | Effective GP | PR | BIS | Status | Main spec / GS / DPS",
	}
	lines[#lines + 1] = string.format("Matches: %d    Page: %d / %d    Page size: %d", #filtered, pageNumber, pageCount, PAGE_SIZE)
	for rowIndex = (pageNumber - 1) * PAGE_SIZE + 1, math.min(pageNumber * PAGE_SIZE, #filtered) do
		local member = filtered[rowIndex]
		local specs = member.publicNoteParsed and member.publicNoteParsed.specs or {}
		local mainSpec = specs[1] and specs[1].label or ""
		local mainGs = specs[1] and FormatValue(specs[1].gearScore) or "—"
		local mainDps = specs[1] and FormatValue(specs[1].dps) or "—"
		if member then
			local bis = member.bisEligibilityStatus == "available"
				and (member.bisEligible and "eligible" or "ineligible") or member.bisEligibilityStatus
			local mainName = member.mainIndex and snapshot.members[member.mainIndex].name or member.name
			lines[#lines + 1] = table.concat({
				tostring(member.name or "?"), tostring(mainName or "?"), FormatValue(member.ep),
				FormatValue(member.gp), FormatValue(member.effectiveGP),
				member.pr and string.format("%.4f", member.pr) or FormatValue(member.prStatus),
				bis, tostring(member.linkStatus or member.publicNoteParsed.status),
				table.concat({ mainSpec, mainGs, mainDps }, " / "),
			}, " | ")
		end
	end
	return table.concat(lines, "\n"), pageNumber, pageCount, #filtered
end

local function RefreshReport(page)
	local text, pageNumber, pageCount, count = BuildReport(Addon.db.epgp.view, page.search:GetText(), page.pageNumber, page.groupOnly:GetChecked(), page.raidOnly:GetChecked())
	page.pageNumber = pageNumber or 1
	page.report:SetText(text)
	page.pageLabel:SetText(string.format("Page %d / %d (%d)", page.pageNumber, pageCount or 1, count or 0))
	if page.previous then
		if page.pageNumber > 1 then page.previous:Enable() else page.previous:Disable() end
	end
	if page.next then
		if page.pageNumber < (pageCount or 1) then page.next:Enable() else page.next:Disable() end
	end
end

local function ApplySettings(page)
	local settings = Addon.db.epgp
	local minimumGP = tonumber(page.minimumGP:GetText())
	local bisMinimumEP = tonumber(page.bisMinimumEP:GetText())
	if not minimumGP or minimumGP < 0 or not bisMinimumEP or bisMinimumEP < 0 then
		page.status:SetText("Settings must be non-negative numbers.")
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
		page.report:SetText(BuildReport(self.db.epgp.view, page.search:GetText()))
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
	local groupOnly = CreateFrame("CheckButton", "RaidwiseEPGPGroupOnlyV3", page, "UICheckButtonTemplate")
	groupOnly:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE); groupOnly:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -4)
	local groupText = _G[groupOnly:GetName() .. "Text"]; if groupText then groupText:SetText(W.T("EPGP_FILTER_GROUP")) end
	local raidOnly = CreateFrame("CheckButton", "RaidwiseEPGPRaidOnlyV3", page, "UICheckButtonTemplate")
	raidOnly:SetSize(UI.CHECK_SIZE, UI.CHECK_SIZE); raidOnly:SetPoint("LEFT", groupOnly, "RIGHT", 115, 0)
	local raidText = _G[raidOnly:GetName() .. "Text"]; if raidText then raidText:SetText(W.T("EPGP_FILTER_RAID")) end
	groupOnly:SetScript("OnClick", function() if groupOnly:GetChecked() then raidOnly:SetChecked(false) end; page.pageNumber = 1; RefreshReport(page) end)
	raidOnly:SetScript("OnClick", function() if raidOnly:GetChecked() then groupOnly:SetChecked(false) end; page.pageNumber = 1; RefreshReport(page) end)
	local previous = W.CreatePlainButton(page, 90, UI.ACTION_BTN_H, W.T("EPGP_PREVIOUS"))
	previous:SetPoint("LEFT", raidOnly, "RIGHT", 115, 0)
	local nextPage = W.CreatePlainButton(page, 90, UI.ACTION_BTN_H, W.T("EPGP_NEXT"))
	nextPage:SetPoint("LEFT", previous, "RIGHT", 5, 0)
	local pageLabel = W.CreateFontString(page, nil, "OVERLAY", "GameFontNormalSmall")
	pageLabel:SetPoint("LEFT", nextPage, "RIGHT", 8, 0)
	previous:SetScript("OnClick", function() page.pageNumber = math.max(1, page.pageNumber - 1); RefreshReport(page) end)
	nextPage:SetScript("OnClick", function() page.pageNumber = page.pageNumber + 1; RefreshReport(page) end)
	local progress = W.CreateProgressBar(page, 12)
	progress:SetPoint("TOPLEFT", groupOnly, "BOTTOMLEFT", 0, -5)
	progress:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	progress:SetProgress(0, 1)
	local report, host = W.CreateCopyBox(page, "RaidwiseEPGPRosterScrollV1", "RaidwiseEPGPRosterBoxV1")
	host:SetPoint("TOPLEFT", progress, "BOTTOMLEFT", 0, -7); host:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	if report.SetMaxLetters then report:SetMaxLetters(0) end
	page.minimumGP, page.bisMinimumEP, page.status, page.search, page.report, page.progress = minimumGP, bisMinimumEP, status, search, report, progress
	page.groupOnly, page.raidOnly, page.previous, page.next, page.pageLabel, page.pageNumber = groupOnly, raidOnly, previous, nextPage, pageLabel, 1
	minimumGP:SetText(tostring(Addon.db.epgp.minimumGP or 500))
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
