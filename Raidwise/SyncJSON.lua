-- Bounded JSON codec for interchange. Never executes imported text.
local Addon = Raidwise
local MAX_BYTES, MAX_DEPTH, MAX_NODES = 262144, 16, 40000
local arrayMT = {}
local null = {}

function Addon:SyncJSONArray(values)
	return setmetatable(values or {}, arrayMT)
end

function Addon:EncodeSyncJSON(value)
	local function quote(text)
		return '"' .. text:gsub('[%z\1-\31\\"]', function(char)
			if char == '"' or char == '\\' then return '\\' .. char end
			return string.format('\\u%04x', char:byte())
		end) .. '"'
	end
	local function encode(item, depth)
		assert(depth <= MAX_DEPTH, "JSON depth")
		if item == null then return "null" end
		if type(item) == "string" then return quote(item) end
		if type(item) == "boolean" then return tostring(item) end
		if type(item) == "number" then
			assert(item == item and math.abs(item) < math.huge, "JSON number")
			return tostring(item)
		end
		assert(type(item) == "table", "JSON type")
		local parts = {}
		if getmetatable(item) == arrayMT then
			for index = 1, #item do parts[index] = encode(item[index], depth + 1) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local keys = {}
		for key in pairs(item) do assert(type(key) == "string", "JSON key"); keys[#keys + 1] = key end
		table.sort(keys)
		for _, key in ipairs(keys) do parts[#parts + 1] = quote(key) .. ":" .. encode(item[key], depth + 1) end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	local ok, result = pcall(encode, value, 0)
	if not ok or #result > MAX_BYTES then return nil, "SYNC_INVALID" end
	return result
end

function Addon:DecodeSyncJSON(text)
	if type(text) ~= "string" or #text > MAX_BYTES then return nil, "SYNC_INVALID" end
	local index, nodes = 1, 0
	local function skip() local _, last = text:find("^[ \t\r\n]*", index); index = (last or index - 1) + 1 end
	local function utf8(code)
		if code < 128 then return string.char(code) end
		if code < 2048 then return string.char(192 + math.floor(code / 64), 128 + code % 64) end
		if code < 65536 then return string.char(224 + math.floor(code / 4096), 128 + math.floor(code / 64) % 64, 128 + code % 64) end
		return string.char(240 + math.floor(code / 262144), 128 + math.floor(code / 4096) % 64, 128 + math.floor(code / 64) % 64, 128 + code % 64)
	end
	local function hex()
		local digits = text:sub(index, index + 3)
		assert(digits:match('^%x%x%x%x$'), "Unicode escape")
		index = index + 4
		return tonumber(digits, 16)
	end
	local function stringValue()
		assert(text:sub(index, index) == '"', "JSON string")
		index = index + 1
		local parts = {}
		while index <= #text do
			local char = text:sub(index, index); index = index + 1
			if char == '"' then return table.concat(parts) end
			if char == '\\' then
				local escape = text:sub(index, index); index = index + 1
				local escapes = { ['"']='"', ['\\']='\\', ['/']='/', b='\b', f='\f', n='\n', r='\r', t='\t' }
				if escape == 'u' then
					local code = hex()
					if code >= 55296 and code <= 56319 then
						assert(text:sub(index, index + 1) == '\\u', "Surrogate pair")
						index = index + 2
						local low = hex(); assert(low >= 56320 and low <= 57343, "Surrogate pair")
						code = 65536 + (code - 55296) * 1024 + low - 56320
					else assert(code < 56320 or code > 57343, "Surrogate") end
					char = utf8(code)
				else char = escapes[escape]; assert(char, "JSON escape") end
			else assert(char:byte() >= 32, "JSON control") end
			parts[#parts + 1] = char
		end
		error("Unclosed JSON string")
	end
	local parse
	parse = function(depth)
		nodes = nodes + 1; assert(nodes <= MAX_NODES and depth <= MAX_DEPTH, "JSON limits")
		skip(); local char = text:sub(index, index)
		if char == '"' then return stringValue() end
		if char == '{' or char == '[' then
			local array = char == '['
			local result = array and Addon:SyncJSONArray() or {}
			local close = array and ']' or '}'
			index = index + 1; skip()
			if text:sub(index, index) == close then index = index + 1; return result end
			while true do
				skip(); local key = #result + 1
				if not array then
					key = stringValue(); assert(result[key] == nil, "Duplicate key"); skip()
					assert(text:sub(index, index) == ':', "JSON colon"); index = index + 1
				end
				result[key] = parse(depth + 1); skip()
				local separator = text:sub(index, index); index = index + 1
				if separator == close then return result end
				assert(separator == ',', "JSON separator")
			end
		end
		for literal, value in pairs({ ['true']=true, ['false']=false, ['null']=null }) do
			if text:sub(index, index + #literal - 1) == literal then index = index + #literal; return value end
		end
		local token = text:match('^%-?%d+%.?%d*[eE]?[+-]?%d*', index)
		assert(token and not token:match('^%-?0%d') and not token:match('%.[^%d]') and not token:match('%.$'), "JSON number")
		local number = tonumber(token); assert(number and number == number and math.abs(number) < math.huge, "JSON number")
		index = index + #token; return number
	end
	local ok, result = pcall(function() local value = parse(0); skip(); assert(index > #text, "Trailing JSON"); return value end)
	if not ok then return nil, "SYNC_INVALID" end
	return result
end

function Addon:IsSyncJSONArray(value)
	return type(value) == "table" and getmetatable(value) == arrayMT
end
