-- Gear Check: Phase 1 collection for target or self (no suitability rules).

local Addon = Raidwise

-- Slot order for collection / dump. Policy drives later evaluation skips.
local SLOT_DEFS = {
	{ key = "head", slotName = "HeadSlot", policy = "CHECKED" },
	{ key = "neck", slotName = "NeckSlot", policy = "CHECKED" },
	{ key = "shoulder", slotName = "ShoulderSlot", policy = "CHECKED" },
	{ key = "back", slotName = "BackSlot", policy = "CHECKED" },
	{ key = "chest", slotName = "ChestSlot", policy = "CHECKED" },
	{ key = "shirt", slotName = "ShirtSlot", policy = "IGNORED" },
	{ key = "tabard", slotName = "TabardSlot", policy = "IGNORED" },
	{ key = "wrist", slotName = "WristSlot", policy = "CHECKED" },
	{ key = "hands", slotName = "HandsSlot", policy = "CHECKED" },
	{ key = "waist", slotName = "WaistSlot", policy = "CHECKED" },
	{ key = "legs", slotName = "LegsSlot", policy = "CHECKED" },
	{ key = "feet", slotName = "FeetSlot", policy = "CHECKED" },
	{ key = "finger1", slotName = "Finger0Slot", policy = "CHECKED" },
	{ key = "finger2", slotName = "Finger1Slot", policy = "CHECKED" },
	{ key = "trinket1", slotName = "Trinket0Slot", policy = "PLANNED" },
	{ key = "trinket2", slotName = "Trinket1Slot", policy = "PLANNED" },
	{ key = "mainHand", slotName = "MainHandSlot", policy = "CHECKED" },
	{ key = "offHand", slotName = "SecondaryHandSlot", policy = "CHECKED" },
	{ key = "ranged", slotName = "RangedSlot", policy = "CHECKED" },
}

local scanToken = 0
local pendingUnit = nil
local pendingCallback = nil
local retryElapsed = 0
local retryBudget = 0
local lastReport = nil

local retryFrame = CreateFrame("Frame")
retryFrame:Hide()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("INSPECT_TALENT_READY")

local function ParseItemLinkParts(itemLink)
	if type(itemLink) ~= "string" or itemLink == "" then
		return nil
	end
	local itemId, enchantId, gem1, gem2, gem3, gem4 = itemLink:match(
		"item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)"
	)
	itemId = tonumber(itemId)
	if not itemId or itemId <= 0 then
		return nil
	end
	return {
		itemId = itemId,
		enchantId = tonumber(enchantId) or 0,
		gemIdsFromLink = {
			tonumber(gem1) or 0,
			tonumber(gem2) or 0,
			tonumber(gem3) or 0,
			tonumber(gem4) or 0,
		},
	}
end

local function CollectGemItemIds(itemLink, parsed)
	local gems = {}
	if type(GetItemGem) == "function" and itemLink then
		for index = 1, 4 do
			local _, gemLink = GetItemGem(itemLink, index)
			if gemLink then
				local gemId = tonumber(gemLink:match("item:(%d+)"))
				if gemId and gemId > 0 then
					gems[#gems + 1] = {
						socketIndex = index,
						itemId = gemId,
						link = gemLink,
					}
				end
			end
		end
	end
	if #gems == 0 and parsed and parsed.gemIdsFromLink then
		for index = 1, 4 do
			local gemId = parsed.gemIdsFromLink[index]
			if gemId and gemId > 0 then
				gems[#gems + 1] = {
					socketIndex = index,
					itemId = gemId,
					link = nil,
				}
			end
		end
	end
	return gems
end

local function IsMetaGemItem(gemItemId)
	if not gemItemId or gemItemId <= 0 then
		return false
	end
	local ok, itemSubType = pcall(function()
		local _, _, _, _, _, _, subClassName = GetItemInfo(gemItemId)
		return subClassName
	end)
	if not ok or type(itemSubType) ~= "string" then
		return false
	end
	-- Best-effort: subclass string is locale-dependent ("Meta" on enUS).
	return itemSubType:lower():find("meta", 1, true) ~= nil
end

local function IsRelicItem(itemId, equipLoc, itemSubType)
	if equipLoc == "INVTYPE_RELIC" then
		return true
	end
	if type(itemSubType) ~= "string" then
		return false
	end
	local lower = itemSubType:lower()
	return lower:find("idol", 1, true)
		or lower:find("libram", 1, true)
		or lower:find("totem", 1, true)
		or lower:find("sigil", 1, true)
		or lower:find("relic", 1, true)
end

local function ItemInfoBundle(itemId, itemLink)
	local name, link, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture
	local ok = pcall(function()
		name, link, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture = GetItemInfo(itemLink or itemId)
	end)
	if not ok or not name then
		ok = pcall(function()
			name, link, quality, itemLevel, _, itemType, itemSubType, _, equipLoc, texture = GetItemInfo(itemId)
		end)
	end
	if type(itemLink) == "string" and (not name or name == "") then
		name = itemLink:match("%[(.-)%]")
	end
	return {
		name = name,
		link = link or itemLink,
		quality = tonumber(quality),
		itemLevel = tonumber(itemLevel),
		itemType = itemType,
		itemSubType = itemSubType,
		equipLoc = equipLoc,
		texture = texture,
		infoKnown = name ~= nil and name ~= "",
	}
end

local function CollectSlot(unit, def)
	local slotId = GetInventorySlotInfo(def.slotName)
	local entry = {
		key = def.key,
		slotName = def.slotName,
		slotId = slotId,
		policy = def.policy,
		policyNote = nil,
		empty = true,
		item = nil,
	}

	if def.policy == "PLANNED" then
		entry.policyNote = "planned"
	elseif def.policy == "IGNORED" then
		entry.policyNote = "ignored"
	end

	if not slotId or not unit then
		return entry
	end

	local itemLink = GetInventoryItemLink(unit, slotId)
	if not itemLink then
		local itemId = GetInventoryItemID and GetInventoryItemID(unit, slotId)
		if itemId and itemId > 0 then
			-- Link not ready yet (common right after NotifyInspect).
			entry.empty = false
			entry.item = {
				itemId = itemId,
				link = nil,
				enchantId = 0,
				gems = {},
				metaGemId = nil,
				infoKnown = false,
				pendingLink = true,
			}
		end
		return entry
	end

	local parsed = ParseItemLinkParts(itemLink)
	if not parsed then
		return entry
	end

	local info = ItemInfoBundle(parsed.itemId, itemLink)
	local gems = CollectGemItemIds(itemLink, parsed)
	local metaGemId = nil
	for index = 1, #gems do
		local gem = gems[index]
		if IsMetaGemItem(gem.itemId) then
			metaGemId = gem.itemId
			gem.isMeta = true
			break
		end
	end

	local policy = def.policy
	local policyNote = entry.policyNote
	if policy == "CHECKED" and IsRelicItem(parsed.itemId, info.equipLoc, info.itemSubType) then
		policy = "IGNORED"
		policyNote = "relic"
	end

	entry.empty = false
	entry.policy = policy
	entry.policyNote = policyNote
	entry.item = {
		itemId = parsed.itemId,
		link = itemLink,
		enchantId = parsed.enchantId,
		gems = gems,
		metaGemId = metaGemId,
		name = info.name,
		quality = info.quality,
		itemLevel = info.itemLevel,
		itemType = info.itemType,
		itemSubType = info.itemSubType,
		equipLoc = info.equipLoc,
		texture = info.texture,
		infoKnown = info.infoKnown,
		pendingLink = false,
	}
	return entry
end

local function CollectClassSpec(unit)
	local className, classFile = UnitClass(unit)
	local specName, specIcon, specTab = "", "", 0
	local specKnown = false

	if UnitIsUnit(unit, "player") and Addon.CollectPrimarySpec then
		specName, specIcon, specTab = Addon:CollectPrimarySpec()
	else
		local isInspect = true
		local talentGroup = 1
		if type(GetActiveTalentGroup) == "function" then
			talentGroup = GetActiveTalentGroup(isInspect) or 1
		end
		local tabCount = 3
		if type(GetNumTalentTabs) == "function" then
			tabCount = GetNumTalentTabs(isInspect) or 3
		end
		local bestPoints = -1
		for tab = 1, tabCount do
			local name, icon, pointsSpent = GetTalentTabInfo(tab, isInspect, nil, talentGroup)
			pointsSpent = tonumber(pointsSpent) or 0
			if pointsSpent > bestPoints then
				bestPoints = pointsSpent
				specName = name or ""
				specIcon = icon or ""
				specTab = tab
			end
		end
	end

	if (specName and specName ~= "") or (specTab and specTab > 0) then
		specKnown = true
	end

	return {
		className = className,
		classFile = classFile,
		specName = specName or "",
		specIcon = specIcon or "",
		specTab = tonumber(specTab) or 0,
		specKnown = specKnown,
	}
end

local function CountFilledCheckedSlots(slots)
	local filled = 0
	local checked = 0
	for index = 1, #slots do
		local slot = slots[index]
		if slot.policy == "CHECKED" then
			checked = checked + 1
			if not slot.empty and slot.item and slot.item.itemId then
				filled = filled + 1
			end
		end
	end
	return filled, checked
end

function Addon:ResolveGearCheckUnit()
	if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
		return "target"
	end
	return "player"
end

function Addon:GetLastGearCheckReport()
	return lastReport
end

function Addon:CollectGearCheck(unit)
	unit = unit or self:ResolveGearCheckUnit()
	if not unit or not UnitExists(unit) then
		return nil
	end

	local name, realm = UnitName(unit)
	local identity = CollectClassSpec(unit)
	local slots = {}
	for index = 1, #SLOT_DEFS do
		slots[#slots + 1] = CollectSlot(unit, SLOT_DEFS[index])
	end

	local filled, checked = CountFilledCheckedSlots(slots)
	local report = {
		phase = 1,
		collectedAt = time(),
		unit = unit,
		isSelf = UnitIsUnit(unit, "player") and true or false,
		name = name,
		realm = realm,
		guid = UnitGUID(unit),
		className = identity.className,
		classFile = identity.classFile,
		specName = identity.specName,
		specIcon = identity.specIcon,
		specTab = identity.specTab,
		specKnown = identity.specKnown,
		slots = slots,
		stats = {
			checkedSlots = checked,
			filledCheckedSlots = filled,
		},
		inspect = {
			needed = not UnitIsUnit(unit, "player"),
			canInspect = false,
			notified = false,
			complete = UnitIsUnit(unit, "player") and true or false,
		},
	}

	if report.inspect.needed then
		if type(CanInspect) == "function" then
			report.inspect.canInspect = CanInspect(unit) and true or false
		end
		if report.inspect.canInspect and type(CheckInteractDistance) == "function" then
			if not CheckInteractDistance(unit, 4) then
				report.inspect.canInspect = false
				report.inspect.tooFar = true
			end
		end
	end

	lastReport = report
	return report
end

function Addon:FormatGearCheckPhase1Dump(report)
	if not report then
		return "No Gear Check data."
	end

	local lines = {}
	lines[#lines + 1] = "Raidwise Gear Check — Phase 1 snapshot (collection only; no rules)"
	lines[#lines + 1] = "Surface-level evaluation comes in later phases. Rules are being maintained."
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format(
		"Unit: %s (%s)%s",
		tostring(report.unit),
		tostring(report.name or "?"),
		report.isSelf and " [self]" or ""
	)
	if report.realm and report.realm ~= "" then
		lines[#lines + 1] = "Realm: " .. tostring(report.realm)
	end
	lines[#lines + 1] = string.format(
		"Class: %s (%s)",
		tostring(report.className or "?"),
		tostring(report.classFile or "?")
	)
	if report.specKnown then
		lines[#lines + 1] = string.format(
			"Spec: %s (tab %d)",
			tostring(report.specName ~= "" and report.specName or "?"),
			tonumber(report.specTab) or 0
		)
	else
		lines[#lines + 1] = "Spec: unknown (class-only rules will apply later)"
	end
	lines[#lines + 1] = string.format(
		"Checked slots filled: %d / %d",
		report.stats.filledCheckedSlots or 0,
		report.stats.checkedSlots or 0
	)
	if report.inspect then
		if report.inspect.tooFar then
			lines[#lines + 1] = "Inspect: too far"
		elseif report.inspect.needed and not report.inspect.canInspect then
			lines[#lines + 1] = "Inspect: not available"
		elseif report.inspect.needed and not report.inspect.complete then
			lines[#lines + 1] = "Inspect: pending / incomplete"
		elseif report.inspect.needed then
			lines[#lines + 1] = "Inspect: ok"
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Slots:"

	for index = 1, #report.slots do
		local slot = report.slots[index]
		local policy = slot.policy or "?"
		local note = slot.policyNote and (" / " .. slot.policyNote) or ""
		if slot.empty or not slot.item then
			lines[#lines + 1] = string.format(
				"  [%s%s] %s — empty",
				policy,
				note,
				slot.slotName
			)
		else
			local item = slot.item
			local name = item.name or (item.pendingLink and "(link pending)" or "unknown")
			local ilvl = item.itemLevel and tostring(item.itemLevel) or "-"
			lines[#lines + 1] = string.format(
				"  [%s%s] %s — id=%s  ilvl=%s  %s",
				policy,
				note,
				slot.slotName,
				tostring(item.itemId),
				ilvl,
				name
			)
			if item.itemType or item.itemSubType then
				lines[#lines + 1] = string.format(
					"      type=%s / %s  equipLoc=%s",
					tostring(item.itemType or "-"),
					tostring(item.itemSubType or "-"),
					tostring(item.equipLoc or "-")
				)
			end
			lines[#lines + 1] = string.format("      enchantId=%s", tostring(item.enchantId or 0))
			if item.gems and #item.gems > 0 then
				local gemParts = {}
				for g = 1, #item.gems do
					local gem = item.gems[g]
					gemParts[#gemParts + 1] = string.format(
						"#%d=%s%s",
						gem.socketIndex or g,
						tostring(gem.itemId),
						gem.isMeta and " (meta)" or ""
					)
				end
				lines[#lines + 1] = "      gems: " .. table.concat(gemParts, ", ")
			else
				lines[#lines + 1] = "      gems: (none detected)"
			end
			if item.metaGemId then
				lines[#lines + 1] = "      metaGemId=" .. tostring(item.metaGemId)
			end
			if item.infoKnown == false then
				lines[#lines + 1] = "      note: item info incomplete (not-checkable later if still unknown)"
			end
		end
	end

	return table.concat(lines, "\n")
end

local function FinishScan(report, status)
	if report then
		report.scanStatus = status
	end
	lastReport = report
	local callback = pendingCallback
	pendingCallback = nil
	pendingUnit = nil
	retryFrame:Hide()
	retryElapsed = 0
	retryBudget = 0
	if callback then
		callback(report, status)
	end
end

local function TryCollectPending(forceComplete)
	if not pendingUnit then
		return
	end
	local report = Addon:CollectGearCheck(pendingUnit)
	if not report then
		FinishScan(nil, "missing")
		return
	end
	if report.isSelf then
		FinishScan(report, "ok")
		return
	end
	local filled = report.stats.filledCheckedSlots or 0
	if filled > 0 and (report.specKnown or forceComplete) then
		report.inspect.complete = true
		FinishScan(report, "ok")
		return
	end
	if forceComplete then
		report.inspect.complete = filled > 0
		FinishScan(report, filled > 0 and "ok" or "empty")
	end
end

retryFrame:SetScript("OnUpdate", function(_, elapsed)
	if not pendingUnit then
		retryFrame:Hide()
		return
	end
	retryElapsed = retryElapsed + elapsed
	retryBudget = retryBudget - elapsed
	if retryElapsed >= 0.25 then
		retryElapsed = 0
		TryCollectPending(false)
		if not pendingUnit then
			return
		end
	end
	if retryBudget <= 0 then
		TryCollectPending(true)
		if pendingUnit then
			local report = Addon:CollectGearCheck(pendingUnit)
			if report then
				report.inspect.complete = false
				report.inspect.timedOut = true
			end
			FinishScan(report, "timeout")
		end
	end
end)

eventFrame:SetScript("OnEvent", function(_, event)
	if event ~= "INSPECT_TALENT_READY" then
		return
	end
	if pendingUnit then
		TryCollectPending(true)
	end
end)

function Addon:StartGearCheckScan(callback)
	pendingCallback = callback
	scanToken = scanToken + 1
	local unit = self:ResolveGearCheckUnit()
	local report = self:CollectGearCheck(unit)
	if not report then
		FinishScan(nil, "missing")
		return
	end

	if report.isSelf then
		FinishScan(report, "ok")
		return
	end

	if not report.inspect.canInspect then
		FinishScan(report, report.inspect.tooFar and "too_far" or "cannot_inspect")
		return
	end

	pendingUnit = unit
	retryElapsed = 0
	retryBudget = 2.5
	if type(NotifyInspect) == "function" then
		local ok = pcall(NotifyInspect, unit)
		report.inspect.notified = ok and true or false
	end
	-- Immediate second pass (inventory sometimes available right away).
	TryCollectPending(false)
	if pendingUnit then
		retryFrame:Show()
	end
end
