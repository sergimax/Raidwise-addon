-- Final report preparation shared by previews and transport.
local Addon = Raidwise
local CHAT_MAX_BYTES = 255

local function AtomicEnd(message, index)
	-- Keep complete links (including an optional color wrapper) together.
	local tail = string.sub(message, index)
	local link = tail:match("^(|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r)")
		or tail:match("^(|H.-|h.-|h)")
	if link then return index + #link - 1 end
	local escape = tail:match("^(|c%x%x%x%x%x%x%x%x)") or tail:match("^(|r)")
	if escape then return index + #escape - 1 end
	local byte = string.byte(message, index)
	local size = byte >= 240 and 4 or byte >= 224 and 3 or byte >= 192 and 2 or 1
	return index + size - 1
end

function Addon:PrepareReportMessage(message)
	if type(message) ~= "string" then return "" end
	local chatType = self.ResolveReportChatType and self:ResolveReportChatType()
	if not chatType or #message <= CHAT_MAX_BYTES then return message end
	local index, last = 1, 0
	while index <= #message do
		local finish = AtomicEnd(message, index)
		if finish > CHAT_MAX_BYTES - 5 then break end
		last = finish
		index = finish + 1
	end
	local result = string.sub(message, 1, last)
	-- Reserve a reset only when truncation leaves a color open.
	local colorOpen = false
	for escape in result:gmatch("|([cr])") do colorOpen = escape == "c" end
	return result .. (colorOpen and "|r" or "") .. "..."
end
