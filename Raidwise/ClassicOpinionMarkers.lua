-- Personal opinion marks on the Wrath 3.3.5 friends, ignore, inbox and guild rows.
local Addon = Raidwise
local markedLabels = setmetatable({}, { __mode = "k" })
local guildHighlights = setmetatable({}, { __mode = "k" })
local installedHooks = {}
local eventFrame
local guildRefreshCount = 0

local function NameKey(value)
	return (strlower or string.lower)(tostring(value or ""))
end

local function RealmKey(value)
	return NameKey(value):gsub("%s+", "")
end

local function FindOpinion(sender)
	if type(sender) ~= "string" or sender == "" then return end
	local name, realm = sender:match("^([^%-]+)%-(.+)$")
	local currentRealm = RealmKey(GetRealmName())
	name, realm = NameKey(name or sender), realm and RealmKey(realm) or currentRealm
	local selected, selectedAt, selectedGuid
	for guid, entry in pairs(Addon.db and Addon.db.history or {}) do
		if type(entry) == "table" and NameKey(entry.name) == name then
			local entryRealm = RealmKey(entry.realm)
			if entryRealm == "" then entryRealm = currentRealm end
			if entryRealm == realm then
				local personal = Addon:GetPersonalRating(entry)
				local updatedAt = tonumber(personal.updatedAt) or 0
				if Addon:HasPersonalRatingData(personal) and (not selected or updatedAt > selectedAt
					or (updatedAt == selectedAt and tostring(guid) < selectedGuid)) then
					selected, selectedAt, selectedGuid = personal.opinion, updatedAt, tostring(guid)
				end
			end
		end
	end
	return selected
end

local function MarkLabel(label, sender)
	if not label then return end
	local text = label:GetText() or ""
	local previous = markedLabels[label]
	local original = previous and text == previous.marked and previous.original or text
	local opinion = FindOpinion(sender)
	if not opinion or original == "" then
		if previous and text == previous.marked then label:SetText(previous.original) end
		markedLabels[label] = nil
		return
	end
	local symbol = Addon:RatingWrapColor("[" .. Addon:RatingOpinionSymbol(opinion) .. "]",
		Addon:RatingOpinionColor(opinion))
	local marked = "|T" .. Addon:RatingOpinionIcon(opinion) .. ":14:14|t " .. symbol .. " " .. original
	markedLabels[label] = { original = original, marked = marked }
	if text ~= marked then label:SetText(marked) end
end

local function MarkGuildRow(row, sender)
	local opinion = FindOpinion(sender)
	local highlight = guildHighlights[row]
	if not opinion then
		if highlight then highlight:Hide() end
		return
	end
	if not highlight then
		-- Like the reputation reference, render above skinned row backgrounds.
		-- A mouse-disabled frame leaves guild selection and clicks with Blizzard.
		highlight = CreateFrame("Frame", nil, row)
		highlight:SetAllPoints(row)
		highlight:EnableMouse(false)
		highlight.texture = highlight:CreateTexture(nil, "ARTWORK")
		highlight.texture:SetAllPoints(highlight)
		highlight.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
		highlight.label = highlight:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		highlight.label:SetPoint("RIGHT", highlight, "RIGHT", -3, 0)
		guildHighlights[row] = highlight
	end
	highlight:SetFrameLevel(row:GetFrameLevel() + 1)
	local color = Addon:NativeOpinionColor(opinion)
	local background = Addon:NativeOpinionBackgroundColor(opinion)
	highlight.texture:SetVertexColor(background[1], background[2], background[3], 0.15)
	highlight.label:SetText("[" .. Addon:RatingOpinionSymbol(opinion) .. "]")
	highlight.label:SetTextColor(color[1], color[2], color[3])
	highlight:Show()
end

local function RefreshFriends()
	local scroll = FriendsFrameFriendsScrollFrame
	if not scroll or not GetFriendInfo then return end
	for index, row in ipairs(scroll.buttons or {}) do
		-- DynamicScrollFrame uses first/last buttons as blank spacing when scrolled.
		local spacer = (index == 1 and (scroll.topIndex or 1) > 1)
			or (index == scroll.usedButtons and (scroll.nextButtonOffset or 0) > 0)
		local sender
		if row:IsShown() and not spacer and row.buttonType == FRIENDS_BUTTON_TYPE_WOW and row.id then
			sender = GetFriendInfo(row.id)
		end
		MarkLabel(row.name, sender)
	end
end

local function RefreshIgnores()
	if not GetIgnoreName then return end
	for index = 1, (IGNORES_TO_DISPLAY or 19) do
		local row = _G["FriendsFrameIgnoreButton" .. index]
		if row then
			local sender
			if row:IsShown() and row.type == SQUELCH_TYPE_IGNORE and row.index then
				sender = GetIgnoreName(row.index)
			end
			MarkLabel(row.name, sender)
		end
	end
end

local function RefreshInbox()
	local count = GetInboxNumItems and GetInboxNumItems() or 0
	local perPage = INBOXITEMS_TO_DISPLAY or 7
	local offset = ((InboxFrame and InboxFrame.pageNum or 1) - 1) * perPage
	for index = 1, perPage do
		local row = _G["MailItem" .. index]
		if row then
			local sender
			if InboxFrame and InboxFrame:IsShown() and row:IsShown() and offset + index <= count and GetInboxHeaderInfo then
				local _, _, name = GetInboxHeaderInfo(offset + index)
				sender = name
			end
			MarkLabel(_G["MailItem" .. index .. "Sender"], sender)
		end
	end
end

local function RefreshGuild()
	if not GetGuildRosterInfo then return end
	guildRefreshCount = guildRefreshCount + 1
	-- Player-status and guild-status modes have separate pools of native rows.
	for _, prefix in ipairs({ "GuildFrameButton", "GuildFrameGuildStatusButton" }) do
		for index = 1, (GUILDMEMBERS_TO_DISPLAY or 13) do
			local row = _G[prefix .. index]
			if row then
				local sender
				if row:IsShown() and row.guildIndex then
					sender = GetGuildRosterInfo(row.guildIndex)
				end
				-- Keep native name text untouched: ElvUI constrains its width.
				MarkLabel(_G[prefix .. index .. "Name"], nil)
				MarkGuildRow(row, sender)
			end
		end
	end
end

function Addon:GetClassicOpinionDiagnostics()
	local records, opinions, localOpinions = 0, 0, 0
	local realm = RealmKey(GetRealmName())
	for _, entry in pairs(self.db and self.db.history or {}) do
		if type(entry) == "table" then
			records = records + 1
			if self:HasPersonalRatingData(self:GetPersonalRating(entry)) then
				opinions = opinions + 1
				local savedRealm = RealmKey(entry.realm)
				if savedRealm == "" or savedRealm == realm then localOpinions = localOpinions + 1 end
			end
		end
	end
	local lines = {
		"Native markers revision: 3; initialized=" .. tostring(eventFrame ~= nil)
			.. "; ElvUI=" .. tostring(ElvUI ~= nil),
		"Guild hook=" .. tostring(installedHooks.GuildStatus_Update == true)
			.. "; refreshes=" .. guildRefreshCount,
		string.format("History records=%d; saved opinions=%d; current realm opinions=%d", records, opinions, localOpinions),
	}
	for _, prefix in ipairs({ "GuildFrameButton", "GuildFrameGuildStatusButton" }) do
		local rows, visible, identities, matches, shown = 0, 0, 0, 0, 0
		for index = 1, (GUILDMEMBERS_TO_DISPLAY or 13) do
			local row = _G[prefix .. index]
			if row then
				rows = rows + 1
				if row:IsShown() then
					visible = visible + 1
					local sender = GetGuildRosterInfo and row.guildIndex and GetGuildRosterInfo(row.guildIndex)
					if sender then identities = identities + 1 end
					if FindOpinion(sender) then matches = matches + 1 end
					local overlay = guildHighlights[row]
					if overlay and overlay:IsShown() then shown = shown + 1 end
				end
			end
		end
		lines[#lines + 1] = string.format("%s: rows=%d visible=%d identities=%d matches=%d overlays=%d", prefix, rows, visible, identities, matches, shown)
	end
	return table.concat(lines, "\n")
end

function Addon:RefreshClassicOpinionMarkers()
	RefreshFriends()
	RefreshIgnores()
	RefreshInbox()
	RefreshGuild()
end

-- One-shot refresh runs after Blizzard and skin hooks, including mode switches.
local function QueueGuildRefresh()
	if not eventFrame then return end
	eventFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil)
		RefreshGuild()
	end)
end

local function InstallHooks()
	if not hooksecurefunc then return end
	local callbacks = {
		FriendsList_Update = RefreshFriends,
		IgnoreList_Update = RefreshIgnores,
		InboxFrame_Update = RefreshInbox,
		GuildStatus_Update = function()
			RefreshGuild()
			QueueGuildRefresh()
		end,
		FauxScrollFrame_Update = function(scroll)
			if scroll == GuildListScrollFrame then QueueGuildRefresh() end
		end,
		DynamicScrollFrame_Update = function(scroll)
			if scroll == FriendsFrameFriendsScrollFrame then RefreshFriends() end
		end,
	}
	for name, callback in pairs(callbacks) do
		if not installedHooks[name] and type(_G[name]) == "function" then
			hooksecurefunc(name, callback)
			installedHooks[name] = true
		end
	end
end

function Addon:InitializeClassicOpinionMarkers()
	InstallHooks()
	if not eventFrame then
		eventFrame = CreateFrame("Frame")
		eventFrame:RegisterEvent("ADDON_LOADED")
		eventFrame:RegisterEvent("PLAYER_LOGIN")
		eventFrame:RegisterEvent("MAIL_CLOSED")
		eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
		eventFrame:SetScript("OnEvent", function()
			InstallHooks()
			Addon:RefreshClassicOpinionMarkers()
			QueueGuildRefresh()
		end)
	end
	self:RefreshClassicOpinionMarkers()
end
