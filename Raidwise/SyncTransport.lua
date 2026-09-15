-- Wrath 3.3.5 SendAddonMessage transport. Offers broadcast; accepted data whispers.
local Addon = Raidwise
local PREFIX, CHUNK, TIMEOUT = "RaidwiseSync1", 180, 1800
local outgoing, uploads, incoming, cooldowns = nil, {}, nil, {}
local serial, elapsed, roundRobin = 0, 0, 0
Addon.syncOffers = {}

local function key(name)
	name = string.lower(name or "")
	if not name:find('-', 1, true) then name = name .. "-" .. string.lower(GetRealmName() or "") end
	return name:gsub('%s+', '')
end

local function validSender(sender)
	return type(sender) == "string" and #sender > 0 and #sender < 150 and not sender:find('[%c|]')
end

local function settings()
	Addon.db.sync = Addon.db.sync or {ignored={}}
	Addon.db.sync.ignored = Addon.db.sync.ignored or {}
	return Addon.db.sync
end

local function checksum(text)
	local first, second = 1, 0
	for index = 1, #text do first = (first + text:byte(index)) % 65521; second = (second + first) % 65521 end
	return string.format("%.0f", second * 65536 + first)
end

local function refresh(status)
	if status then Addon.syncStatus = status end
	if Addon.RefreshSyncView then Addon:RefreshSyncView() end
end

local function send(message, channel, target)
	if type(SendAddonMessage) ~= "function" then return false end
	-- Include prefix and separator in the legacy 255-byte budget.
	if #message + #PREFIX + 1 > 255 then return false end
	return pcall(SendAddonMessage, PREFIX, message, channel, target)
end

function Addon:SetSyncSenderIgnored(sender, ignored)
	if not self.db or not validSender(sender) then return false end
	settings().ignored[key(sender)] = ignored and true or nil
	for index = #self.syncOffers, 1, -1 do
		if key(self.syncOffers[index].sender) == key(sender) then table.remove(self.syncOffers, index) end
	end
	if incoming and key(incoming.sender) == key(sender) then incoming = nil end
	if self.syncReview and key(self.syncReview.sender) == key(sender) then self:CancelSyncImport() end
	refresh(); return true
end

function Addon:SetSyncRequestsDisabled(disabled)
	settings().disabled = disabled and true or false
	if disabled then self.syncOffers = {}; incoming = nil end
	refresh()
end

function Addon:ShareSyncData(guid, channel)
	if outgoing or #uploads > 0 then return nil, "SYNC_BUSY" end
	local text, count = self:BuildSyncExport(guid)
	if not text then return nil, count end
	local allowed, target = {}, nil
	if channel == "WHISPER" then
		if not UnitIsPlayer("target") or UnitIsUnit("target", "player") then return nil, "SYNC_TARGET_REQUIRED" end
		local name, realm = UnitName("target")
		if not name then return nil, "SYNC_TARGET_REQUIRED" end
		target = realm and realm ~= "" and (name .. "-" .. realm) or name
		allowed[key(target)] = true
	elseif channel == "RAID" then
		if GetNumRaidMembers() == 0 then return nil, "SYNC_RAID_REQUIRED" end
		for index = 1, GetNumRaidMembers() do local name = GetRaidRosterInfo(index); if name then allowed[key(name)] = true end end
	elseif channel == "GUILD" then
		if not IsInGuild() then return nil, "SYNC_GUILD_REQUIRED" end
		for index = 1, GetNumGuildMembers() do local name = GetGuildRosterInfo(index); if name then allowed[key(name)] = true end end
	else return nil, "SYNC_INVALID" end
	serial = serial + 1
	local id = tostring(time()) .. "-" .. serial
	outgoing = {id=id, text=text, allowed=allowed, served={}, channel=channel, target=target, expires=time()+TIMEOUT}
	local ok = send("O|" .. id .. "|1|" .. #text .. "|" .. count .. "|" .. checksum(text), channel, target)
	if not ok then outgoing = nil; return nil, "SYNC_SEND_FAILED" end
	refresh(self:T("SYNC_OFFER_SENT")); return true
end

function Addon:CancelSyncSending()
	if outgoing then send("X|" .. outgoing.id, outgoing.channel, outgoing.target) end
	for _, upload in ipairs(uploads) do send("X|" .. upload.id, "WHISPER", upload.sender) end
	outgoing, uploads = nil, {}
	refresh(self:T("SYNC_CANCELLED"))
end

function Addon:AcceptSyncOffer()
	if incoming or self.syncReview then return nil, "SYNC_BUSY" end
	local offer = table.remove(self.syncOffers, 1)
	if not offer or offer.expires <= time() then return nil, "SYNC_EXPIRED" end
	incoming = offer; incoming.parts = {}; incoming.received = 0; incoming.bytes = 0
	if not send("A|" .. offer.id, "WHISPER", offer.sender) then incoming = nil; return nil, "SYNC_SEND_FAILED" end
	refresh(self:T("SYNC_RECEIVING")); return true
end

function Addon:RejectSyncOffer(ignore)
	local offer = table.remove(self.syncOffers, 1)
	if offer then
		send("X|" .. offer.id, "WHISPER", offer.sender)
		if ignore then self:SetSyncSenderIgnored(offer.sender, true) end
	end
	refresh()
end

function Addon:CancelSyncReceiving()
	if incoming then send("X|" .. incoming.id, "WHISPER", incoming.sender) end
	incoming = nil
	refresh(self:T("SYNC_CANCELLED"))
end

function Addon:OnSyncAddonMessage(prefix, message, channel, sender)
	if prefix ~= PREFIX or not self.db or not validSender(sender) or type(message) ~= "string" or #message > 240 then return end
	if channel ~= "WHISPER" and channel ~= "RAID" and channel ~= "GUILD" then return end
	local senderKey = key(sender)
	if senderKey == key(UnitName("player")) or settings().ignored[senderKey] then return end
	local kind, id = message:match('^([OADX])|([%d%-]+)|?')
	if not id or #id > 32 then return end
	if kind == "O" then
		if settings().disabled or incoming or self.syncReview or #self.syncOffers >= 5 then return end
		if cooldowns[senderKey] and cooldowns[senderKey] > time() then return end
		local offerId, version, bytes, count, hash = message:match('^O|([%d%-]+)|(%d+)|(%d+)|(%d+)|(%d+)$')
		bytes, count = tonumber(bytes), tonumber(count)
		if not offerId or version ~= "1" or not bytes or bytes < 1 or bytes > self.SYNC_MAX_BYTES or not count or count < 1 or count > 1000 then return end
		for _, offer in ipairs(self.syncOffers) do if key(offer.sender) == senderKey then return end end
		cooldowns[senderKey] = time() + 30
		self.syncOffers[#self.syncOffers + 1] = {sender=sender, id=id, size=bytes, count=count, hash=hash, expires=time()+TIMEOUT}
		if self.Print then self:Print(self:T("SYNC_REQUEST_FROM", sender, count)) end
		refresh()
	elseif kind == "A" and channel == "WHISPER" then
		if not outgoing or outgoing.id ~= id or outgoing.expires <= time() or not outgoing.allowed[senderKey] or outgoing.served[senderKey] then return end
		if #uploads >= 4 then send("X|" .. id, "WHISPER", sender); return end
		outgoing.served[senderKey] = true
		uploads[#uploads + 1] = {sender=sender, id=id, text=outgoing.text, index=1, expires=time()+TIMEOUT}
		refresh(self:T("SYNC_SENDING"))
	elseif kind == "D" and channel == "WHISPER" then
		if not incoming or incoming.id ~= id or key(incoming.sender) ~= senderKey or incoming.expires <= time() then return end
		local _, index, chunk = message:match('^D|([%d%-]+)|(%d+)|(.*)$')
		index = tonumber(index)
		local count = math.ceil(incoming.size / CHUNK)
		if not index or index < 1 or index > count or not chunk or #chunk < 1 or #chunk > CHUNK then return end
		if incoming.parts[index] then
			if incoming.parts[index] ~= chunk then incoming = nil; refresh(self:T("SYNC_INVALID")) end
			return
		end
		incoming.bytes = incoming.bytes + #chunk
		if incoming.bytes > incoming.size then incoming = nil; refresh(self:T("SYNC_INVALID")); return end
		incoming.parts[index] = chunk; incoming.received = incoming.received + 1
		if incoming.received == count then
			local transfer = incoming; incoming = nil
			local text = table.concat(transfer.parts)
			if #text ~= transfer.size or checksum(text) ~= transfer.hash then refresh(self:T("SYNC_INVALID")); return end
			local rows = self:ValidateSyncText(text)
			if not rows or #rows ~= transfer.count then refresh(self:T("SYNC_INVALID")); return end
			local review, err = self:StageSyncImport(text, sender, "user")
			refresh(self:T(review and "SYNC_READY" or err))
			if review and self.Print then self:Print(self:T("SYNC_READY")) end
		end
	elseif kind == "X" then
		if incoming and incoming.id == id and key(incoming.sender) == senderKey then incoming = nil; refresh(self:T("SYNC_CANCELLED")) end
		for index = #self.syncOffers, 1, -1 do
			local offer = self.syncOffers[index]
			if offer.id == id and key(offer.sender) == senderKey then table.remove(self.syncOffers, index); refresh() end
		end
		if channel == "WHISPER" and outgoing and outgoing.id == id and outgoing.allowed[senderKey] then
			if outgoing.channel == "WHISPER" then outgoing = nil end
			refresh(self:T("SYNC_CANCELLED"))
		end
		for index = #uploads, 1, -1 do if uploads[index].id == id and key(uploads[index].sender) == senderKey then table.remove(uploads, index) end end
	end
end

function Addon:UpdateSyncTransport(delta)
	elapsed = elapsed + delta
	if elapsed < 0.3 then return end
	elapsed = 0
	local now = time()
	if outgoing and outgoing.expires <= now then outgoing = nil end
	if incoming and incoming.expires <= now then incoming = nil; refresh(self:T("SYNC_EXPIRED")) end
	for index = #self.syncOffers, 1, -1 do if self.syncOffers[index].expires <= now then table.remove(self.syncOffers, index); refresh() end end
	for sender, expires in pairs(cooldowns) do if expires <= now then cooldowns[sender] = nil end end
	for index = #uploads, 1, -1 do if uploads[index].expires <= now then table.remove(uploads, index) end end
	if #uploads == 0 then return end
	roundRobin = roundRobin % #uploads + 1
	local upload = uploads[roundRobin]
	local chunk = upload.text:sub((upload.index - 1) * CHUNK + 1, upload.index * CHUNK)
	local ok = send("D|" .. upload.id .. "|" .. upload.index .. "|" .. chunk, "WHISPER", upload.sender)
	upload.index = upload.index + 1
	if not ok or (upload.index - 1) * CHUNK >= #upload.text then
		table.remove(uploads, roundRobin)
		refresh(self:T(ok and "SYNC_SENT" or "SYNC_SEND_FAILED"))
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(_, _, prefix, message, channel, sender) Addon:OnSyncAddonMessage(prefix, message, channel, sender) end)
frame:SetScript("OnUpdate", function(_, delta) if Addon.db then Addon:UpdateSyncTransport(delta) end end)
