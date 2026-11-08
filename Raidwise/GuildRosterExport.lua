-- Raw guild roster JSON export for staged EPGP workflows.

local Addon = Raidwise
local SCHEMA_VERSION = 1

local function JsonString(value)
	if value == nil then return "null" end
	return '"' .. Addon.EscapeJsonString(value) .. '"'
end

local function JsonNumber(value)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return "null"
	end
	return tostring(value)
end

function Addon:FormatGuildRosterSnapshot(snapshot)
	if type(snapshot) ~= "table" or type(snapshot.members) ~= "table"
		or type(snapshot.memberCountReported) ~= "number" then
		return nil, "Invalid guild roster snapshot"
	end
	local members = {}
	local officerNotesAvailable = snapshot.officerNotesStatus == "available"
	local levelFilter = snapshot.levelFilter
	for index = 1, #snapshot.members do
		local member = snapshot.members[index]
		if type(member) == "table" and member.name
			and (levelFilter == nil or member.level == levelFilter) then
			members[#members + 1] = "{"
				.. '"name":' .. JsonString(member.name)
				.. ',"rank":' .. JsonString(member.rank)
				.. ',"rankIndex":' .. JsonNumber(member.rankIndex)
				.. (levelFilter == 80 and "" or ',"level":' .. JsonNumber(member.level))
				.. ',"class":' .. JsonString(member.class)
				.. ',"classFileName":' .. JsonString(member.classFileName)
				.. ',"publicNote":' .. JsonString(member.publicNote)
				.. ',"officerNote":' .. (officerNotesAvailable and JsonString(member.officerNote) or "null")
				.. ',"officerNoteStatus":' .. JsonString(officerNotesAvailable and "available" or "unavailable")
				.. ',"online":' .. (member.online and "true" or "false")
				.. ',"status":' .. JsonString(member.status)
				.. "}"
		end
	end
	local complete = #members == snapshot.memberCountReported
	local output = '{"format":"RaidwiseGuildRoster","schemaVersion":' .. SCHEMA_VERSION
		.. ',"scannedAt":' .. JsonNumber(snapshot.scannedAt)
		.. ',"levelFilter":' .. JsonNumber(levelFilter)
		.. ',"memberCountReported":' .. JsonNumber(snapshot.memberCountReported)
		.. ',"memberCountMatchingFilter":' .. #members
		.. ',"memberCountExported":' .. #members
		.. ',"complete":' .. (complete and "true" or "false")
		.. ',"officerNotesStatus":' .. JsonString(officerNotesAvailable and "available" or "unavailable")
		.. ',"members":[' .. table.concat(members, ",") .. "]}"
	return output, complete and nil or "Some roster entries had no name"
end

function Addon:CollectGuildRosterSnapshot()
	if type(GetNumGuildMembers) ~= "function" or type(GetGuildRosterInfo) ~= "function" then
		return nil, "Guild roster API unavailable"
	end
	local count = GetNumGuildMembers()
	if type(count) ~= "number" or count < 0 then return nil, "Guild roster unavailable" end
	local snapshot = { memberCountReported = count, members = {}, scannedAt = type(time) == "function" and time() or nil }
	local canReadOfficerNotes = type(CanEditOfficerNote) ~= "function" or CanEditOfficerNote()
	snapshot.officerNotesStatus = canReadOfficerNotes and "available" or "unavailable"
	for index = 1, count do
		local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName = GetGuildRosterInfo(index)
		if name then
			snapshot.members[#snapshot.members + 1] = {
				name = name, rank = rank, rankIndex = rankIndex, level = level, class = class,
				classFileName = classFileName, zone = zone, publicNote = note,
				officerNote = officerNote, online = online, status = status,
			}
		end
	end
	return snapshot
end

function Addon:FormatGuildRosterExport(levelFilter)
	local snapshot, err = self:CollectGuildRosterSnapshot()
	if not snapshot then return nil, err end
	snapshot.levelFilter = levelFilter
	return self:FormatGuildRosterSnapshot(snapshot)
end

function Addon:ShowGuildRosterExport()
	if not (IsInGuild and IsInGuild()) then
		self:Print("You must be in a guild to export the guild roster.")
		return
	end
	if type(GuildRoster) == "function" then
		self.guildRosterExportPending = true
		GuildRoster()
		self:Print("Guild roster refresh requested; export will open when the roster updates.")
		return
	end
	self:CompleteGuildRosterExport()
end

function Addon:ShowFullGuildRosterExport()
	if not (IsInGuild and IsInGuild()) then
		self:Print("You must be in a guild to export the guild roster.")
		return
	end
	if type(SetGuildRosterShowOffline) ~= "function" then
		self:Print("This client does not support showing offline guild members through the roster API.")
		return
	end
	self.guildRosterExportLevelFilter = nil
	self.guildRosterExportIncludeOffline = true
	self.guildRosterExportPreviousOffline = type(GetGuildRosterShowOffline) == "function" and GetGuildRosterShowOffline() or nil
	SetGuildRosterShowOffline(true)
	self.guildRosterExportPending = true
	if type(GuildRoster) == "function" then GuildRoster() end
	self:Print("Refreshing the full guild roster, including offline members...")
end

function Addon:ShowLevel80GuildRosterExport()
	if not (IsInGuild and IsInGuild()) then
		self:Print("You must be in a guild to export the guild roster.")
		return
	end
	if type(SetGuildRosterShowOffline) ~= "function" then
		self:Print("This client does not support showing offline guild members through the roster API.")
		return
	end
	self.guildRosterExportLevelFilter = 80
	self.guildRosterExportIncludeOffline = true
	self.guildRosterExportPreviousOffline = type(GetGuildRosterShowOffline) == "function" and GetGuildRosterShowOffline() or nil
	SetGuildRosterShowOffline(true)
	self.guildRosterExportPending = true
	if type(GuildRoster) == "function" then GuildRoster() end
	self:Print("Refreshing the full guild roster; export will include level 80 characters only...")
end

function Addon:CompleteGuildRosterExport()
	if not self.guildRosterExportPending and IsInGuild and not IsInGuild() then return end
	self.guildRosterExportPending = nil
	local levelFilter = self.guildRosterExportLevelFilter
	self.guildRosterExportLevelFilter = nil
	local text, err = self:FormatGuildRosterExport(levelFilter)
	if self.guildRosterExportIncludeOffline then
		self.guildRosterExportIncludeOffline = nil
		local previousOffline = self.guildRosterExportPreviousOffline
		self.guildRosterExportPreviousOffline = nil
		if previousOffline ~= nil and previousOffline ~= true and type(SetGuildRosterShowOffline) == "function" then
			SetGuildRosterShowOffline(previousOffline)
		end
	end
	if not text then self:Print(err); return end
	local frame = self.guildRosterExportFrame
	if not frame then
		frame = CreateFrame("Frame", "RaidwiseGuildRosterExportFrame", UIParent)
		frame:SetWidth(620); frame:SetHeight(440); frame:SetPoint("CENTER")
		frame:SetFrameStrata("DIALOG"); frame:EnableMouse(true); frame:SetMovable(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", function(window) window:StartMoving() end)
		frame:SetScript("OnDragStop", function(window) window:StopMovingOrSizing() end)
		local bg = frame:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(frame); bg:SetTexture(0, 0, 0, 0.95)
		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", 0, -12); title:SetText("Guild roster JSON — Ctrl+C to copy")
		local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -4, -4)
		local scroll = CreateFrame("ScrollFrame", "RaidwiseGuildRosterExportScroll", frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 16, -40); scroll:SetPoint("BOTTOMRIGHT", -34, 16)
		local edit = CreateFrame("EditBox", nil, scroll)
		edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal)
		edit:SetWidth(560); edit:SetScript("OnEscapePressed", function() frame:Hide() end)
		scroll:SetScrollChild(edit); frame.editBox = edit; self.guildRosterExportFrame = frame
	end
	frame.editBox:SetText(text); frame:Show(); frame.editBox:SetFocus(); frame.editBox:HighlightText()
	self:Print(err or "Guild roster JSON is ready. Click the text and press Ctrl+C.")
end
