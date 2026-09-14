-- Personal opinion marks on the Wrath 3.3.5 friends, ignore and inbox rows.
local Addon = Raidwise
local markedLabels = setmetatable({}, { __mode = "k" })
local installedHooks = {}
local eventFrame

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

function Addon:RefreshClassicOpinionMarkers()
	RefreshFriends()
	RefreshIgnores()
	RefreshInbox()
end

local function InstallHooks()
	if not hooksecurefunc then return end
	local callbacks = {
		FriendsList_Update = RefreshFriends,
		IgnoreList_Update = RefreshIgnores,
		InboxFrame_Update = RefreshInbox,
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
		eventFrame:SetScript("OnEvent", function()
			InstallHooks()
			Addon:RefreshClassicOpinionMarkers()
		end)
	end
	self:RefreshClassicOpinionMarkers()
end
