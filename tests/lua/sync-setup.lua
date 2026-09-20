Raidwise={db={history={}}}
now=2000000
function time() return now end
function GetRealmName() return "Realm" end
function UnitGUID(unit) return unit=="player" and "SELF" or "TARGET" end
function UnitName(unit) return unit=="player" and "Me" or "Friend" end
function UnitIsPlayer() return true end
function UnitIsUnit() return false end
function GetNumRaidMembers() return 2 end
function GetRaidRosterInfo(index) return index==1 and "Me" or "Friend" end
function IsInGuild() return true end
function GetNumGuildMembers() return 2 end
function GetGuildRosterInfo(index) return index==1 and "Me" or "Friend" end
function ChatFrame_AddMessageEventFilter() end
function Raidwise:T(key, ...) return key end
function Raidwise:Print() end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
sent={}
function SendAddonMessage(prefix,message,channel,target)
  assert(#prefix+#message+1<=255)
  sent[#sent+1]={prefix=prefix,message=message,channel=channel,target=target}
end
