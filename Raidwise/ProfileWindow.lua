-- Active profile UI; the legacy CharacterProfile window is no longer loaded.
local Addon = Raidwise
local W = Addon.Widgets
local VERSION = 38
local WIDTH, HEIGHT = 680, 760
local Refresh
local words, translated = {}, setmetatable({}, {__mode="k"})
local function Text(ru, en)
	local value = Addon.db and Addon.db.locale == "ruRU" and ru or en
	words[value] = {ru, en}
	return value
end
local function Label(parent, x, y, width, text)
	local label = W.CreateFontString(parent, nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", x, y); label:SetWidth(width); label:SetJustifyH("LEFT"); label:SetText(text or "")
	if words[text] then translated[label] = words[text] end
	return label
end
local function Button(parent, x, y, width, text, action)
	local button = W.CreatePlainButton(parent, width, 24, text)
	button:SetPoint("TOPLEFT", x, y); button:SetScript("OnClick", action)
	if words[text] then translated[button.label] = words[text] end
	return button
end
local function SelectedButton(button, selected)
	button.selected = selected
	W.SetMenuButtonState(button, selected, false)
	button:SetScript("OnEnter", function(self) W.SetMenuButtonState(self, self.selected, true) end)
	button:SetScript("OnLeave", function(self) W.SetMenuButtonState(self, self.selected, false) end)
end
local function OpinionLabel(opinion)
	if not opinion then return Text("Сбросить", "Reset") end
	return W.IconMarkup(Addon:RatingOpinionIcon(opinion), 14) .. " "
		.. Addon:RatingWrapColor(Addon:RatingOpinionLabel(opinion), Addon:RatingOpinionColor(opinion))
end
local function Time(value) return Addon:FormatHistoryTime(value) or "—" end
local function Author(value) return value and Addon:LinkedCharacterName(value) or "—" end
local function Editable(frame) return Addon:CanEditCharacterProfile(frame.profileMember) end

local function Changed(frame)
	Addon:MarkProfileEditorChanged(frame.editor)
	Refresh(frame)
end

local function List(parent, name, x, y, width, height)
	local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", x, y); scroll:SetSize(width - 24, height)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(width - 28, 1); scroll:SetScrollChild(content)
	return {scroll=scroll, content=content, rows={}, width=width - 28}
end

local function Render(list, values, draw)
	for _, row in ipairs(list.rows) do row:Hide() end
	for index, value in ipairs(values) do
		local row = list.rows[index]
		if not row then
			row = CreateFrame("Frame", nil, list.content); row:SetSize(list.width, 62)
			row.label = Label(row, 0, 0, list.width, ""); row.label:SetHeight(38)
			list.rows[index] = row
		end
		row:SetPoint("TOPLEFT", 0, -(index - 1) * 62); row:Show(); draw(row, value)
	end
	list.content:SetHeight(math.max(1, #values * 62))
	list.scroll:SetVerticalScroll(math.min(list.scroll:GetVerticalScroll() or 0, math.max(0, #values * 62 - list.scroll:GetHeight())))
end

local function Slice(values, page)
	local result = {}
	for index = (page - 1) * 25 + 1, math.min(#values, page * 25) do result[#result + 1] = values[index] end
	return result
end

local function UpdateStatus(frame)
	local editor = frame.editor
	if not editor then return end
	local labels = {saved=Text("Сохранено", "Saved"), dirty=Text("Есть изменения", "Unsaved changes"),
		saving=Text("Сохранение", "Saving"), error=Text("Не удалось сохранить", "Save failed")}
	local reasons = {STALE_DRAFT=Text("Данные изменились. Перечитайте Профиль.", "Data changed. Reload the Profile."),
		AUTHOR_UNAVAILABLE=Text("Персонаж-автор пока недоступен.", "Your character is not available yet."),
		SELF_RATING=Text("Нельзя оценивать себя.", "You cannot rate yourself.")}
	frame.status:SetText((labels[editor.status] or "") .. (editor.error and (": " .. (reasons[editor.error]
		or Text("Проверьте изменения или перечитайте Профиль.", "Review changes or reload the Profile."))) or ""))
	if editor.dirty then frame.save:Enable() else frame.save:Disable() end
	if editor.status == "error" then frame.reload:Show() else frame.reload:Hide() end
end

Refresh = function(frame)
	if not frame.editor or not frame.profileMember then return end
	local draft = frame.editor.draft
	for label, pair in pairs(translated) do label:SetText(Addon.db.locale == "ruRU" and pair[1] or pair[2]) end
	frame.eventTypes = Addon:GetProfileEventCatalog()
	local record = Addon:GetPlayerRecord(draft.key)
	-- A live scan can resolve a name-only card while this window remains open.
	frame.profileMember.guid = draft.key
	frame.title:SetText(Text("Профиль: ", "Profile: ") .. Author(frame.profileMember))
	local identity = record.identity or frame.profileMember
	frame.guidLabel:SetText("GUID: " .. (identity.guid or draft.key))
	frame.details:SetText(W.CharacterIconMarkup(identity, 16) .. table.concat({identity.classLabel or identity.class or "", identity.guildName or "",
		identity.spec or "", identity.gearScore and ("GS: " .. identity.gearScore) or ""}, "  "))
	frame.author:SetText(Text("Автор мнения: ", "Opinion author: ") .. Author(record.profile and record.profile.author))
	local stats = Addon:GetCharacterMeetingStats(draft.key)
	frame.meetings:SetText(Text("Встречи этого персонажа: ", "This character's meetings: ") .. stats.count
		.. "  |  " .. Time(stats.firstMetAt) .. " — " .. Time(stats.lastMetAt))
	frame.selfHint:SetText(Editable(frame) and "" or Text("Самооценка запрещена. Заметка доступна.", "Self-rating is disabled. Private note is available."))
	for _, button in ipairs(frame.opinions) do
		button.label:SetText(OpinionLabel(button.opinion))
		SelectedButton(button, draft.opinion == button.opinion)
		if Editable(frame) then button:Enable() else button:Disable() end
	end
	for _, button in ipairs(frame.facts) do
		button.label:SetText(Addon:FactSummary({button.fact}))
		local selected = false
		for _, fact in ipairs(draft.facts) do if fact == button.fact then selected = true end end
		W.SetMenuButtonState(button, selected, false)
		if Editable(frame) then button:Enable() else button:Disable() end
	end
	if frame.notesBox:GetText() ~= draft.note then
		frame.updatingNote = true; frame.notesBox:SetText(draft.note); frame.updatingNote = false
	end
	for id, panel in pairs(frame.profilePanels) do
		SelectedButton(frame.profileTabs[id], id == frame.selectedProfileTab)
		if id == frame.selectedProfileTab then panel:Show() else panel:Hide() end
	end
	if frame.selectedProfileTab ~= "events" then frame.eventMenu:Hide() end
	if frame.selectedProfileTab == "characters" then Addon:RefreshProfileCharacters(frame) end
	local types = frame.eventTypes
	frame.typeButton.label:SetText(types[frame.typeIndex].label .. "  v")
	if Editable(frame) then frame.add:Enable() else frame.add:Disable() end
	local events = {}
	for _, event in ipairs(draft.events) do events[#events + 1] = event end
	table.sort(events, function(left, right) return left.eventAt > right.eventAt end)
	frame.eventPage = math.min(frame.eventPage, math.max(1, math.ceil(#events / 25)))
	local function EventLabel(eventType)
		for _, info in ipairs(types) do if info.id == eventType then return info.label end end
		return eventType
	end
	Render(frame.eventList, Slice(events, frame.eventPage), function(row, event)
		row.label:SetText(EventLabel(event.type) .. " | " .. Time(event.eventAt) .. " | " .. Author(event.author)
			.. "\n" .. (event.context.zoneName or "") .. " " .. (event.context.instanceName or ""))
		if not row.edit then
			row.edit = Button(row, 0, -38, 175, Text("Применить выбранный тип", "Apply selected type"), function() end)
			row.remove = Button(row, 183, -38, 90, Text("Удалить", "Remove"), function() end)
		end
		row.edit:SetScript("OnClick", function() event.type = types[frame.typeIndex].id; Changed(frame) end)
		row.remove:SetScript("OnClick", function()
			for index, value in ipairs(draft.events) do if value.id == event.id then table.remove(draft.events, index); break end end
			Changed(frame)
		end)
		if Editable(frame) then row.edit:Enable(); row.remove:Enable() else row.edit:Disable(); row.remove:Disable() end
	end)
	local meetings = Addon:GetCharacterEncounters(draft.key)
	table.sort(meetings, function(left, right) return left.lastSeenAt > right.lastSeenAt end)
	Render(frame.meetingList, Slice(meetings, frame.historyPage), function(row, meeting)
		local places = {}
		for _, place in ipairs(meeting.places) do places[#places + 1] = place.zoneName end
		row.label:SetText(Time(meeting.startedAt) .. " — " .. Time(meeting.lastSeenAt) .. "\n" .. table.concat(places, ", "))
	end)
	local changes = {}
	for index = #record.changes, 1, -1 do changes[#changes + 1] = record.changes[index] end
	Render(frame.changeList, Slice(changes, frame.historyPage), function(row, change)
		local detail = change.kind
		if change.kind == "opinion" then detail = Text("Мнение: ", "Opinion: ") .. (change.before and OpinionLabel(change.before) or "—") .. " → " .. (change.after and OpinionLabel(change.after) or "—") end
		if change.kind == "facts" then detail = Text("Факты: ", "Facts: ") .. table.concat(change.after or {}, ", ") end
		if change.kind == "events" then detail = Text("Изменены события", "Events changed") end
		if change.detail then detail = detail .. ": " .. (type(change.detail) == "table" and change.detail.name or change.detail) end
		row.label:SetText(Time(change.at) .. " | " .. Author(change.actor) .. "\n" .. detail)
	end)
	frame.eventPages:SetText(frame.eventPage .. " / " .. math.max(1, math.ceil(#events / 25)))
	frame.historyPages:SetText(frame.historyPage .. " / " .. math.max(1, math.ceil(math.max(#changes, #meetings) / 25)))
	frame.maxEventPage = math.max(1, math.ceil(#events / 25))
	frame.maxHistoryPage = math.max(1, math.ceil(math.max(#changes, #meetings) / 25))
	UpdateStatus(frame)
end

function Addon:RefreshRatingViews()
	if self.RefreshClassicOpinionMarkers then self:RefreshClassicOpinionMarkers() end
	if self.RefreshUnitOpinionTooltip then self:RefreshUnitOpinionTooltip() end
	if self.RefreshHistoryView then self:RefreshHistoryView() end
	local shell = self.mainFrame
	if shell and shell:IsShown() and shell.selectedTab == "raid" and self.RefreshRaidRosterView then self:RefreshRaidRosterView(false) end
end

function Addon:RefreshLinkedProfileOpinion(frame) Refresh(frame) end

local function Create()
	local frame = CreateFrame("Frame", "RaidwiseProfileV" .. VERSION, UIParent)
	frame:SetSize(WIDTH, HEIGHT); frame:SetPoint("CENTER"); frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true)
	frame.layoutVersion = VERSION; frame:Hide(); W.ApplyPlainPanel(frame); W.ApplyOuterBorder(frame)
	if UISpecialFrames then table.insert(UISpecialFrames, "RaidwiseProfileV" .. VERSION) end
	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 8, -8); titleBar:SetSize(WIDTH - 16, 26); W.AttachDragHandle(titleBar, frame)
	local close = Button(titleBar, WIDTH - 48, 0, 24, "X", function() frame:Hide() end)
	W.AttachLayoutVersionLabel(titleBar, VERSION, close)
	frame.title = Label(titleBar, 0, 0, 330, "")
	frame.guidLabel = Label(titleBar, 335, 0, 230, "")
	frame.details = Label(frame, 12, -40, WIDTH - 24, "")
	frame.author = Label(frame, 12, -62, WIDTH - 24, "")
	Label(frame, 12, -92, 65, Text("Мнение:", "Opinion:"))
	frame.opinions = {}
	for index, opinion in ipairs({"unset", "positive", "neutral", "negative"}) do
		local label = OpinionLabel(opinion ~= "unset" and opinion or nil)
		local button = Button(frame, 80 + (index - 1) * 147, -86, 139, label, function()
			frame.editor.draft.opinion = opinion ~= "unset" and opinion or nil; Changed(frame)
		end)
		button.opinion = opinion ~= "unset" and opinion or nil; frame.opinions[#frame.opinions + 1] = button
	end
	frame.facts = {}
	for index, fact in ipairs(Addon:FactCatalog()) do
		local button = Button(frame, 12 + (index - 1) * 163, -116, 155, Addon:FactSummary({fact.id}), function()
			local facts, found = frame.editor.draft.facts, false
			for position, value in ipairs(facts) do if value == fact.id then table.remove(facts, position); found = true; break end end
			if not found then facts[#facts + 1] = fact.id end; Changed(frame)
		end)
		button.fact = fact.id; frame.facts[#frame.facts + 1] = button
	end
	frame.meetings = Label(frame, 12, -146, WIDTH - 24, "")
	frame.selfHint = Label(frame, 12, -167, WIDTH - 24, "")
	frame.profilePanels, frame.profileTabs = {}, {}
	for index, tab in ipairs({{"events", Text("События", "Events")}, {"history", Text("История", "History")}, {"characters", Text("Персонажи", "Characters")}}) do
		local panel = CreateFrame("Frame", nil, frame); panel:SetPoint("TOPLEFT", 12, -223); panel:SetSize(WIDTH - 24, 305)
		frame.profilePanels[tab[1]] = panel
		frame.profileTabs[tab[1]] = Button(frame, 12 + (index - 1) * 218, -190, 210, tab[2], function() frame.selectedProfileTab = tab[1]; Refresh(frame) end)
	end
	local events = frame.profilePanels.events
	frame.typeIndex, frame.eventPage, frame.historyPage = 1, 1, 1
	frame.eventTypes = Addon:GetProfileEventCatalog()
	frame.typeButton = Button(events, 0, 0, 510, "", function()
		if frame.eventMenu:IsShown() then frame.eventMenu:Hide() else
			for index, button in ipairs(frame.eventChoices) do
				button.label:SetText(frame.eventTypes[index].label)
				SelectedButton(button, index == frame.typeIndex)
			end
			frame.eventMenu:Show()
		end
	end)
	-- A scrollable chooser selects any event directly instead of cycling 22 types.
	frame.eventMenu = CreateFrame("Frame", nil, events)
	frame.eventMenu:SetPoint("TOPLEFT", frame.typeButton, "BOTTOMLEFT", 0, -2)
	frame.eventMenu:SetSize(510, 272); frame.eventMenu:SetFrameLevel(100)
	frame.eventMenu:EnableMouse(true); W.ApplyPlainPanel(frame.eventMenu); W.ApplyOuterBorder(frame.eventMenu)
	local choices = List(frame.eventMenu, "RaidwiseProfileEventChoicesV" .. VERSION, 6, -6, 498, 260)
	choices.content:SetHeight(#frame.eventTypes * 26)
	frame.eventChoices = {}
	for index, info in ipairs(frame.eventTypes) do
		local choice = Button(choices.content, 0, -(index - 1) * 26, choices.width, info.label, function()
			frame.typeIndex = index; frame.eventMenu:Hide(); Refresh(frame)
		end)
		frame.eventChoices[index] = choice
	end
	frame.eventMenu:Hide()
	frame.add = Button(events, 520, 0, 130, Text("Добавить", "Add"), function()
		local id, err = Addon:AddPlayerRecordDraftEvent(frame.editor.draft, frame.eventTypes[frame.typeIndex].id)
		if id then Changed(frame) else frame.editor.status, frame.editor.error = "error", err; UpdateStatus(frame) end
	end)
	frame.eventList = List(events, "RaidwiseProfileEventsV" .. VERSION, 0, -32, WIDTH - 24, 235)
	frame.eventPages = Label(events, 120, -278, 120, "")
	Button(events, 0, -276, 50, "<", function() frame.eventPage = math.max(1, frame.eventPage - 1); Refresh(frame) end)
	Button(events, 56, -276, 50, ">", function() frame.eventPage = math.min(frame.maxEventPage, frame.eventPage + 1); Refresh(frame) end)
	local history = frame.profilePanels.history
	Label(history, 0, 0, 310, Text("Совместные встречи", "Shared meetings")); Label(history, 330, 0, 310, Text("Изменения Профиля", "Profile changes"))
	frame.meetingList = List(history, "RaidwiseProfileMeetingsV" .. VERSION, 0, -22, 320, 245)
	frame.changeList = List(history, "RaidwiseProfileChangesV" .. VERSION, 330, -22, 320, 245)
	frame.historyPages = Label(history, 120, -278, 120, "")
	Button(history, 0, -276, 50, "<", function() frame.historyPage = math.max(1, frame.historyPage - 1); Refresh(frame) end)
	Button(history, 56, -276, 50, ">", function() frame.historyPage = math.min(frame.maxHistoryPage, frame.historyPage + 1); Refresh(frame) end)
	Addon:CreateProfileCharactersPanel(frame, frame.profilePanels.characters, WIDTH - 24, VERSION)
	-- The helper creates the Characters panel itself; its parent remains the tab host.
	local notePanel = CreateFrame("Frame", nil, frame); notePanel:SetPoint("TOPLEFT", 12, -540); notePanel:SetSize(WIDTH - 24, 160)
	W.ApplyPlainPanel(notePanel, {0.12, 0.22, 0.32, 0.75})
	Label(notePanel, 8, -5, WIDTH - 44, Text("Заметка — только для себя, локальная", "Private note — local, only for you"))
	local box, host = W.CreateCopyBox(notePanel, "RaidwisePrivateNoteScrollV" .. VERSION, "RaidwisePrivateNoteV" .. VERSION)
	host:SetPoint("TOPLEFT", 6, -25); host:SetPoint("BOTTOMRIGHT", -6, 6)
	frame.notesBox = box
	box:SetScript("OnMouseUp", function() end)
	box:SetScript("OnTextChanged", function(self)
		W.FitCopyBoxToText(self)
		if not frame.updatingNote and frame.editor then frame.editor.draft.note = self:GetText(); Addon:MarkProfileEditorChanged(frame.editor); UpdateStatus(frame) end
	end)
	frame.status = Label(frame, 12, -710, 310, "")
	frame.save = Button(frame, 335, -710, 100, Text("Сохранить", "Save"), function() Addon:SaveProfileEditor(frame.editor); Refresh(frame) end)
	frame.reload = Button(frame, 440, -710, 100, Text("Перечитать", "Reload"), function() frame.editor = Addon:ReloadProfileEditor(frame.editor); Refresh(frame) end)
	Button(frame, 545, -710, 120, Text("Удалить данные", "Delete data"), function()
		local key = frame.profileMember and frame.profileMember.guid
		if not key then return end
		StaticPopupDialogs.RAIDWISE_PROFILE_DELETE = {text=Addon:T("DATABASE_DELETE_CONFIRM", Author(frame.profileMember)),
			button1=Text("Удалить", "Delete"), button2=Text("Отмена", "Cancel"), timeout=0, whileDead=true, hideOnEscape=true,
			OnAccept=function() Addon:DeleteCharacterDatabaseRecords({key}) end}
		StaticPopup_Show("RAIDWISE_PROFILE_DELETE")
	end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		if not frame.profileMember then return end
		local wasDirty = frame.editor.dirty; Addon:TickProfileEditor(frame.editor, elapsed)
		if wasDirty and not frame.editor.dirty then Refresh(frame) else UpdateStatus(frame) end
	end)
	frame:SetScript("OnHide", function()
		if frame.profileMember then
			local ok = Addon:CloseProfileEditor(frame.editor)
			if not ok and Addon.Print then
				Addon:Print(Text("Не удалось сохранить. Черновик останется в памяти до повторного открытия Профиля.",
					"Save failed. The draft stays in memory until you reopen the Profile."))
			end
		end
	end)
	return frame
end

function Addon:ShowRaidCharacterWindow(member)
	local frame = self.raidDetailFrame
	if frame and frame.profileMember then self:CloseProfileEditor(frame.editor) end
	local entry = self.UpsertHistoryMember and self:UpsertHistoryMember(member) or self:EnsureHistoryEntryForGuid(member.guid, member)
	if not entry then return end
	if not frame or frame.layoutVersion ~= VERSION then frame = Create(); self.raidDetailFrame = frame end
	frame.profileMember = self:HistoryProfileForMember(entry)
	frame.editor = self:OpenProfileEditor(entry.guid)
	frame.eventMenu:Hide()
	frame.selectedProfileTab, frame.eventPage, frame.historyPage = "events", 1, 1
	Refresh(frame); frame:Show()
end
