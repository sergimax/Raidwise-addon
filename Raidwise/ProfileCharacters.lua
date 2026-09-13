-- Character associations UI. Changes save immediately; opinion drafts stay intact.
local Addon = Raidwise
local W = Addon.Widgets
local UI = Addon.UITheme
local ROW_HEIGHT = 28
local AttemptLink
local CurrentGuid

local function FinishAction(frame, ok, message)
	local member = frame.profileMember
	if member then frame.profileMember = Addon:HistoryProfileForMember(member) end
	Addon:RefreshProfileCharacters(frame)
	frame.charactersStatus:SetText(W.T(ok and "CHAR_LINK_SAVED" or (message or "CHAR_LINK_INVALID")))
	if Addon.RefreshLinkedProfileOpinion then Addon:RefreshLinkedProfileOpinion(frame) end
	if Addon.RefreshRatingViews then Addon:RefreshRatingViews() end
end

AttemptLink = function(frame, otherGuid, seed, chosenOpinion)
	local sourceGuid = CurrentGuid(frame)
	local ok, message = Addon:LinkPlayerCharacters(sourceGuid, otherGuid, seed, chosenOpinion)
	if not ok and message == "CHAR_LINK_CONFLICT" then
		frame.pendingCharacterLink = { sourceGuid = sourceGuid, otherGuid = otherGuid, seed = seed }
		frame.charactersStatus:SetText(W.T("CHAR_LINK_CONFLICT"))
		for index, entry in ipairs({ frame.profileMember, Addon:GetHistoryEntry(otherGuid) or seed }) do
			local opinion = Addon:GetPersonalRating(entry).opinion
			local button = frame.characterConflictButtons[index]
			button.label:SetText(W.T("CHAR_LINK_KEEP", Addon:RatingOpinionLabel(opinion)))
			button:SetScript("OnClick", function()
				local pending = frame.pendingCharacterLink
				if not pending or not frame.profileMember or frame.profileMember.guid ~= pending.sourceGuid then return end
				AttemptLink(frame, pending.otherGuid, pending.seed, opinion)
			end)
			button:Show()
		end
		frame.characterConflictCancel:Show()
		return
	end
	frame.pendingCharacterLink = nil
	if ok and frame.profileDraft then
		frame.profileDraft.draftOpinion = Addon:GetPersonalRating(frame.profileMember).opinion
	end
	FinishAction(frame, ok, message)
end

CurrentGuid = function(frame)
	local member = frame.profileMember
	if not member or not member.guid or member.guid == "" then return nil end
	Addon:EnsureHistoryEntryForGuid(member.guid, member)
	return member.guid
end

local function CreateList(parent, name, height)
	local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
	scroll:SetHeight(height)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetHeight(1)
	scroll:SetScrollChild(content)
	return scroll, content
end

local function CreateCharacterRow(parent, candidate)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT)
	row.name = W.CreateFontString(row, nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", 0, 0)
	row.name:SetJustifyH("LEFT")
	row.buttons = {}
	local keys = candidate and { "CHAR_LINK_ADD" } or { "CHAR_ROLE_MAIN", "CHAR_LINK_REMOVE" }
	local previous
	for index = #keys, 1, -1 do
		local key = keys[index]
		local button = W.CreatePlainButton(row, 70, 22, W.T(key))
		if previous then button:SetPoint("RIGHT", previous, "LEFT", -3, 0)
		else button:SetPoint("RIGHT", row, "RIGHT", 0, 0) end
		row.buttons[key] = button
		previous = button
	end
	row.name:SetPoint("RIGHT", previous, "LEFT", -6, 0)
	return row
end

local function FillRows(frame, content, rows, characters, candidate)
	for _, row in ipairs(rows) do row:Hide() end
	local guid = frame.profileMember and frame.profileMember.guid
	for index, character in ipairs(characters) do
		local entry = candidate and character or character.entry
		local row = rows[index]
		if not row then row = CreateCharacterRow(content, candidate); rows[index] = row end
		row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
		row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
		local label = Addon:LinkedCharacterName(entry)
		if not candidate then label = label .. " (" .. W.T("CHAR_ROLE_" .. string.upper(character.role)) .. ")" end
		row.name:SetText(label)
		local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
		W.SetFontColor(row.name, color and { color.r, color.g, color.b } or UI.TEXT_IDLE)
		row:SetScript("OnEnter", function()
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:AddLine(Addon:LinkedCharacterName(entry))
			GameTooltip:AddLine(entry.guid or "", 0.7, 0.7, 0.7)
			if not candidate then GameTooltip:AddLine(W.T("CHAR_ROLE_" .. string.upper(character.role))) end
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function() GameTooltip:Hide() end)
		row:EnableMouse(true)
		if candidate then
			local button = row.buttons.CHAR_LINK_ADD
			button.label:SetText(W.T("CHAR_LINK_ADD"))
			button:SetScript("OnClick", function()
				AttemptLink(frame, entry.guid)
			end)
		else
			for _, role in ipairs({ "main" }) do
				local button = row.buttons["CHAR_ROLE_" .. string.upper(role)]
				button.label:SetText(W.T("CHAR_ROLE_" .. string.upper(role)))
				W.SetMenuButtonState(button, character.role == role, false)
				button:SetScript("OnClick", function()
					FinishAction(frame, Addon:SetLinkedCharacterRole(CurrentGuid(frame), entry.guid, role))
				end)
			end
			local remove = row.buttons.CHAR_LINK_REMOVE
			remove.label:SetText(W.T("CHAR_LINK_REMOVE"))
			if #characters > 1 and character.role ~= "main" then remove:Enable() else remove:Disable() end
			remove:SetScript("OnClick", function()
				FinishAction(frame, Addon:UnlinkPlayerCharacter(guid, entry.guid))
			end)
		end
		row:Show()
	end
	content:SetHeight(math.max(1, #characters * ROW_HEIGHT))
end

function Addon:RefreshProfileCharacters(frame)
	if not frame or not frame.charactersContent then return end
	local guid = frame.profileMember and frame.profileMember.guid
	frame.charactersHint:SetText(W.T("CHAR_LINK_HINT"))
	frame.charactersSearchLabel:SetText(W.T("CHAR_LINK_SEARCH"))
	frame.charactersTarget.label:SetText(W.T("CHAR_LINK_TARGET"))
	frame.characterConflictCancel.label:SetText(W.T("CHAR_LINK_CANCEL"))
	frame.charactersStatus:SetText("")
	frame.pendingCharacterLink = nil
	for _, button in ipairs(frame.characterConflictButtons) do button:Hide() end
	frame.characterConflictCancel:Hide()
	local linked = self:GetLinkedCharacters(guid)
	if #linked == 0 and guid and guid ~= "" then
		linked = { { guid = guid, entry = frame.profileMember, role = "main" } }
	end
	FillRows(frame, frame.charactersContent, frame.characterRows, linked, false)
	FillRows(frame, frame.characterCandidatesContent, frame.characterCandidateRows,
		guid and guid ~= "" and self:GetCharacterLinkCandidates(guid, frame.charactersSearch:GetText()) or {}, true)
	if guid and guid ~= "" then frame.charactersTarget:Enable() else frame.charactersTarget:Disable() end
end

function Addon:CreateProfileCharactersPanel(frame, parent, width, layoutVersion)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints(parent)
	panel:Hide()
	frame.profilePanels.characters = panel
	local hint = W.CreateFontString(panel, nil, "OVERLAY", "GameFontNormalSmall")
	hint:SetPoint("TOPLEFT", 0, 0)
	hint:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	hint:SetHeight(30)
	hint:SetJustifyH("LEFT")
	frame.charactersHint = hint
	local linkedScroll, linkedContent = CreateList(panel, "RaidwiseLinkedCharactersV" .. layoutVersion, 84)
	linkedScroll:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -4)
	linkedScroll:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
	linkedContent:SetWidth(width - 28)
	frame.charactersContent, frame.characterRows = linkedContent, {}
	local searchLabel = W.CreateFontString(panel, nil, "OVERLAY", "GameFontNormalSmall")
	searchLabel:SetPoint("TOPLEFT", linkedScroll, "BOTTOMLEFT", 0, -10)
	frame.charactersSearchLabel = searchLabel
	local target = W.CreatePlainButton(panel, 120, 24, "")
	local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	search:SetAutoFocus(false)
	search:SetHeight(24)
	search:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 6, -4)
	search:SetPoint("RIGHT", target, "LEFT", -8, 0)
	target:ClearAllPoints()
	target:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	target:SetPoint("TOP", searchLabel, "BOTTOM", 0, -4)
	search:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
	search:SetScript("OnTextChanged", function() Addon:RefreshProfileCharacters(frame) end)
	frame.charactersSearch, frame.charactersTarget = search, target
	target:SetScript("OnClick", function()
		if not UnitExists("target") or not UnitIsPlayer("target") then
			FinishAction(frame, false, "CHAR_LINK_TARGET_MISSING"); return
		end
		local guid = UnitGUID("target")
		local name, realm = UnitName("target")
		local classLabel, class = UnitClass("target")
		AttemptLink(frame, guid, {
			guid = guid, name = name, realm = realm or GetRealmName(), class = class, classLabel = classLabel,
		})
	end)
	local status = W.CreateFontString(panel, nil, "OVERLAY", "GameFontNormalSmall")
	status:SetPoint("BOTTOMLEFT", 0, 0)
	status:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	status:SetHeight(58)
	status:SetJustifyH("LEFT")
	status:SetJustifyV("TOP")
	frame.charactersStatus = status
	frame.characterConflictButtons = {}
	for index = 1, 2 do
		local button = W.CreatePlainButton(panel, 155, 24, "")
		button:SetPoint("BOTTOMLEFT", (index - 1) * 159, 0)
		button:Hide()
		frame.characterConflictButtons[index] = button
	end
	local cancel = W.CreatePlainButton(panel, 110, 24, W.T("CHAR_LINK_CANCEL"))
	cancel:SetPoint("BOTTOMRIGHT", 0, 0)
	cancel:SetScript("OnClick", function() Addon:RefreshProfileCharacters(frame) end)
	cancel:Hide()
	frame.characterConflictCancel = cancel
	local candidatesScroll, candidatesContent = CreateList(panel, "RaidwiseCharacterCandidatesV" .. layoutVersion, 1)
	candidatesScroll:SetPoint("TOPLEFT", search, "BOTTOMLEFT", -6, -6)
	candidatesScroll:SetPoint("BOTTOMRIGHT", status, "TOPRIGHT", -24, 4)
	candidatesContent:SetWidth(width - 28)
	frame.characterCandidatesContent, frame.characterCandidateRows = candidatesContent, {}
end
