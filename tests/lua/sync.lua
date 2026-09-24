local addon=Raidwise
local entry=addon:EnsureHistoryEntryForGuid("A",{name="Тест",realm="Realm",class="MAGE"})
addon:SavePersonalRatingForGuid("A",nil,"positive",{"good_player"},{"raid_leader"})
addon:SaveProfileNotesForGuid("A",nil,"PRIVATE MEMO")
addon:EnsureHistoryEntryForGuid("encounter",{name="Encounter",realm="Realm"})
entry.metZone="PRIVATE MEETING"
entry.events={{type="same_party",eventAt=1},{type="late_arrival",eventAt=2,creatorId="SELF",context={zoneName="PRIVATE CONTEXT"}}}
local text,count=addon:BuildSyncExport()
assert(text and count==1)
assert(not text:find("PRIVATE",1,true) and not text:find("same_party",1,true))
local payload=addon:DecodeSyncJSON(text)
assert(payload.reportVersion==1 and payload.format=="RaidwiseProfiles")
assert(payload.characters[1].name=="Тест")
assert(#addon:ValidateSyncText(text)==1)
assert(not addon:ValidateSyncText(text:gsub('"reportVersion":1','"reportVersion":99')))
assert(not addon:DecodeSyncJSON('return os.execute("bad")'))
assert(not addon:DecodeSyncJSON('{"a":1,"a":2}'))
assert(not addon:DecodeSyncJSON(string.rep('[',30)..'0'..string.rep(']',30)))
assert(not addon:DecodeSyncJSON(string.rep(' ',262145)))
assert(not addon:DecodeSyncJSON('{"a":01}'))
assert(not addon:DecodeSyncJSON('{"a":1e999}'))
assert(not addon:DecodeSyncJSON('[1,]'))
assert(addon:DecodeSyncJSON('{"a":false}').a==false)
local escape=string.char(92)
assert(addon:DecodeSyncJSON('"'..escape..'u0410"')=="А")
assert(addon:DecodeSyncJSON('"'..escape..'ud83d'..escape..'ude00"')=="😀")
payload.characters[1].name="|Hplayer:bad"
assert(not addon:ValidateSyncText(addon:EncodeSyncJSON(payload)))

addon.db={history={}}
addon:EnsureHistoryEntryForGuid("A",{name="Alice",realm="Realm"})
addon:SavePersonalRatingForGuid("A",nil,"positive",{},{})
addon:EnsureHistoryEntryForGuid("B",{name="Bob",realm="Realm"})
addon:SavePersonalRatingForGuid("B",nil,"positive",{},{})
assert(addon:LinkPlayerCharacters("A","B"))
addon:SaveHistoryEventsForGuid("A",nil,{{id="remote-event",type="late_arrival",eventAt=10,context={}}})
text=assert(addon:BuildSyncExport())
addon.db={history={}}
assert(addon:StageSyncImport(text,"Friend-Realm","user"))
assert(not next(addon.db.history),"Staging changed the database")
assert(not addon:StageSyncImport(text,"Other","user"),"Review was replaced")
addon:CancelSyncImport(); assert(not next(addon.db.history))
assert(addon:StageSyncImport(text,"Friend-Realm","user"))
assert(addon:ApplySyncImport()==2)
assert(addon.db.history.A and addon.db.history.A.rating==nil and addon.db.history.A.events==nil)
local received=addon:GetReputationStore().exchangeProfilesBySource["user:friend-realm"]
assert(received and received.profilesByGuid.A and received.profilesByGuid.B)
assert(addon:GetReceivedProfileLinks("A","user:friend-realm")[1]=="B")
assert(not addon:CanEditCharacterProfile(addon.db.history.A))
assert(not addon:BuildSyncExport()) -- received data is never re-exported as local data
assert(addon:StageSyncImport(text,"JSON","website"))
assert(addon:ApplySyncImport()==2)
assert(addon:GetReputationStore().exchangeProfilesBySource["website:json"])
assert(received.profilesByGuid.A.opinion=="positive") -- a second sender cannot overwrite Friend's card
assert(addon:GetPersonalRating(addon.db.history.A).opinion=="positive") -- received card is readable
assert(#addon:GetHistoryEvents(addon.db.history.A)==1 and addon:GetHistoryEvents(addon.db.history.A)[1].type=="late_arrival")
local receivedA=received.profilesByGuid.A
addon:EnsureLocalProfile("A",addon.db.history.A).personal={opinion="negative",tags={},facts={},createdAt=1,updatedAt=1,creatorId="SELF"}
assert(addon:GetPersonalRating(addon.db.history.A).opinion=="negative") -- local wins for the same character
assert(receivedA.opinion=="positive" and addon:CanEditCharacterProfile(addon.db.history.A))
local forged=addon:DecodeSyncJSON(text); forged.globalKarma={revision=999}; forged.sender="Forged"
addon.db={history={}}
assert(addon:StageSyncImport(assert(addon:EncodeSyncJSON(forged)),"Actual-Realm","user"))
assert(addon:ApplySyncImport()==2)
assert(not addon:GetGlobalKarmaDataset() and addon:GetReputationStore().exchangeProfilesBySource["user:actual-realm"])

addon.db={history={}}
for _, channel in ipairs({"WHISPER","RAID","GUILD"}) do
  addon.db={history={}}
  addon:EnsureHistoryEntryForGuid("A",{name="Alice",realm="Realm"})
  addon:SavePersonalRatingForGuid("A",nil,"positive",{}, {})
  addon:CancelSyncSending(); sent={}
  assert(addon:ShareSyncData("A",channel))
  local offer=sent[1].message
  assert(sent[1].channel==channel and #sent==1,"Data sent before consent")
  local id=offer:match('^O|([^|]+)')
  addon:OnSyncAddonMessage("RaidwiseSync1","A|"..id,"WHISPER","Stranger")
  addon:UpdateSyncTransport(1); assert(#sent==1)
  addon:OnSyncAddonMessage("RaidwiseSync1","A|"..id,"WHISPER","Friend")
  assert(#sent==1,"Data sent without pacing")
  for index=1,30 do addon:UpdateSyncTransport(0.15) end
  assert(#sent>1 and sent[2].channel=="WHISPER" and sent[2].target=="Friend")
  local packets=sent
  sent={}; addon:CancelSyncSending(); addon.db={history={}}; sent={}
  now=now+31
  addon:OnSyncAddonMessage("RaidwiseSync1",offer,channel,"Friend")
  assert(#addon.syncOffers==1 and not addon.syncReview)
  addon:OnSyncAddonMessage("RaidwiseSync1",packets[2].message,"WHISPER","Friend")
  assert(not addon.syncReview,"Unsolicited data accepted")
  assert(addon:AcceptSyncOffer())
  for index=2,#packets do addon:OnSyncAddonMessage("RaidwiseSync1",packets[index].message,"WHISPER","Stranger") end
  assert(not addon.syncReview,"Wrong sender accepted")
  for index=#packets,2,-1 do addon:OnSyncAddonMessage("RaidwiseSync1",packets[index].message,"WHISPER","Friend") end
  assert(addon.syncReview and not next(addon.db.history))
  assert(addon:ApplySyncImport()==1)
end

addon.db={history={}}
local offer="O|123-1|1|100|1|123"
addon:SetSyncSenderIgnored("Friend",true)
assert(addon:IsSyncSenderIgnored("FRIEND-OtherRealm"))
assert(addon:GetIgnoredSyncCharacters("rie")[1]=="friend")
assert(#addon:GetIgnoredSyncCharacters("Realm")==0)
addon:OnSyncAddonMessage("RaidwiseSync1",offer,"WHISPER","Friend-Realm")
assert(#addon.syncOffers==0)
addon:OnSyncAddonMessage("RaidwiseSync1",offer,"WHISPER","Friend-OtherRealm")
assert(#addon.syncOffers==0)
addon:SetSyncSenderIgnored("Friend",false)
addon:SetSyncRequestsDisabled(true)
addon:OnSyncAddonMessage("RaidwiseSync1",offer,"WHISPER","Friend")
assert(#addon.syncOffers==0)
addon:SetSyncRequestsDisabled(false)
now=now+31
addon:OnSyncAddonMessage("RaidwiseSync1",offer:gsub('|1|100','|99|100'),"WHISPER","Friend")
assert(#addon.syncOffers==0)
addon:OnSyncAddonMessage("RaidwiseSync1",offer,"WHISPER","Friend")
assert(#addon.syncOffers==1)
addon:RejectSyncOffer(true); assert(#addon.syncOffers==0)
addon:SetSyncSenderIgnored("Friend",false); now=now+31
addon:OnSyncAddonMessage("RaidwiseSync1",offer,"WHISPER","Friend")
assert(addon:AcceptSyncOffer())
now=now+1801; addon:UpdateSyncTransport(1)
addon:OnSyncAddonMessage("RaidwiseSync1","D|123-1|1|bad","WHISPER","Friend")
assert(not addon.syncReview and not next(addon.db.history))

addon.db.sync={ignored={["friend-realm"]=true,["FRIEND-OtherRealm"]=true,zulu=true}}
assert(#addon:GetIgnoredSyncCharacters()==2 and addon:GetIgnoredSyncCharacters()[1]=="friend")
assert(addon:IsSyncSenderIgnored("Friend-NewRealm"))
addon:SetSyncSenderIgnored("Friend",false)
assert(not addon:IsSyncSenderIgnored("Friend-Realm") and #addon:GetIgnoredSyncCharacters()==1)
assert(not addon:SetSyncSenderIgnored("  ",true))
assert(not addon:SetSyncSenderIgnored("bad name",true))
