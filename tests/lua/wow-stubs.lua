Raidwise = {}
function Raidwise:T(key) return key end
strlower = string.lower
function CreateFrame()
    return setmetatable({}, {__index = function() return function() end end})
end
