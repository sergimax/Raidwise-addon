-- Active profile UI; the legacy CharacterProfile window is no longer loaded.
local Addon = Raidwise
local W = Addon.Widgets
local PROFILE_LAYOUT_VERSION = 40
local VERSION = PROFILE_LAYOUT_VERSION
local WIDTH, HEIGHT = 820, 540
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
	if not opinion then return Text("Снять мнение", "Clear opinion") end
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
	local labels = {saved=Text("Сохранено", "Saved"), dirty=Text("Сохранение…", "Saving…"),
		saving=Text("Сохранение…", "Saving…"), error=Text("Не удалось сохранить", "Save failed")}
	local reasons = {STALE_DRAFT=Text("Данные изменились. Перечитайте Профиль.", "Data changed. Reload the Profile."),
		AUTHOR_UNAVAILABLE=Text("Персонаж-автор пока недоступен.", "Your character is not available yet."),
		SELF_RATING=Text("Нельзя оценивать себя.", "You cannot rate yourself.")}
	frame.status:SetText((labels[editor.status] or "") .. (editor.error and (": " .. (reasons[editor.error]
		or Text("Проверьте изменения или перечитайте Профиль.", "Review changes or reload the Profile."))) or ""))
	frame.save.label:SetText(editor.status == "error" and Text("Повторить", "Retry") or Text("Сохранить", "Save"))
	if editor.dirty then frame.save:Show() else frame.save:Hide() end
	if editor.status == "error" then frame.reload:Show() else frame.reload:Hide() end
end

local function SelectTab(frame, id)
	frame.selectedProfileTab = id
	frame.eventMenu:Hide(); frame.actionsMenu:Hide()
	Refresh(frame)
end

local function Layout(frame)
	local expanded = frame.editingOpinion and Editable(frame)
	if expanded then frame.opinionEditor:Show() else frame.opinionEditor:Hide() end
	local top = expanded and 192 or 116
	frame.navigation:ClearAllPoints(); frame.navigation:SetPoint("TOPLEFT", 12, -top)
	for _, panel in pairs(frame.profilePanels) do
		panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", 12, -(top + 36))
		panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 48)
	end
	local height = HEIGHT - top - 84
	frame.eventList.scroll:SetHeight(height - 78)
	frame.meetingList.scroll:SetHeight(height - 100)
	frame.changeList.scroll:SetHeight(height - 78)
	frame.overviewList.scroll:SetHeight(math.min(186, height - 76))
	frame.notePanel:SetHeight(math.min(200, height - 104))
end

local eventGroups = {
	{ru="Организация", en="Organization", ids="organized_run disrupted_run prepared_for_run followed_instructions late_arrival no_arrival afk left_early rage_quit"},
	{ru="Договорённости и добыча", en="Agreements and loot", ids="fulfilled_agreement broke_agreement fair_loot unfair_loot loot_dispute changed_loot_rules scam"},
	{ru="Помощь и поведение", en="Help and behavior", ids="helped_player helped_with_gear explained_mechanics handled_role failed_mechanics toxic_behavior"},
}
local function RefreshChoices(frame)
	frame.add.label:SetText(frame.editingEvent and Text("Применить", "Apply") or Text("Добавить", "Add"))
	local query = (strlower or string.lower)(frame.eventSearch:GetText() or "")
	local offset, matches = 0, 0
	for _, group in ipairs(frame.eventGroups) do
		local count = 0
		for _, choice in ipairs(group.choices) do
			local info = frame.eventTypes[choice.typeIndex]
			if query == "" or (strlower or string.lower)(info.label):find(query, 1, true) then
				count = count + 1
			else choice:Hide() end
		end
		if count > 0 then
			group.label:SetText(Text(group.ru, group.en)); group.label:ClearAllPoints()
			group.label:SetPoint("TOPLEFT", 0, -offset); group.label:Show(); offset = offset + 24
			for _, choice in ipairs(group.choices) do
				local info = frame.eventTypes[choice.typeIndex]
				if query == "" or (strlower or string.lower)(info.label):find(query, 1, true) then
					choice.label:SetText(info.label); choice:ClearAllPoints(); choice:SetPoint("TOPLEFT", 0, -offset)
					SelectedButton(choice, choice.typeIndex == frame.typeIndex); choice:Show(); offset = offset + 28
				end
			end
		else group.label:Hide() end
		matches = matches + count
	end
	frame.choiceList.content:SetHeight(math.max(1, offset))
	frame.choiceList.scroll:SetVerticalScroll(0)
	frame.noChoices:SetText(matches == 0 and Text("Ничего не найдено", "No matching events") or "")
	frame.eventSelection:SetText(frame.typeIndex and frame.eventTypes[frame.typeIndex].label or Text("Выберите тип события", "Select an event type"))
	if frame.typeIndex then frame.add:Enable() else frame.add:Disable() end
end
local function OpenEventPicker(frame, event)
	if not Editable(frame) then return end
	frame.editingEvent = event
	frame.typeIndex = nil
	if event then
		for index, info in ipairs(frame.eventTypes) do if info.id == event.type then frame.typeIndex = index end end
	end
	frame.eventSearch:SetText(""); RefreshChoices(frame)
	frame.eventMenu:Show()
end

Refresh = function(frame)
	if not frame.editor or not frame.profileMember then return end
	local draft = frame.editor.draft
	for label, pair in pairs(translated) do label:SetText(Addon.db.locale == "ruRU" and pair[1] or pair[2]) end
	frame.eventTypes = Addon:GetProfileEventCatalog()
	local record = Addon:GetPlayerRecordProfile(draft.key)
	frame.profileMember.guid = draft.key
	frame.title:SetText(Author(frame.profileMember))
	local identity = record.identity or frame.profileMember
	frame.guidLabel:SetText("GUID: " .. (identity.guid or draft.key))
	frame.details:SetText(W.CharacterIconMarkup(identity, 16) .. table.concat({identity.classLabel or identity.class or "", identity.guildName or "",
		identity.spec or "", identity.gearScore and ("GS: " .. identity.gearScore) or ""}, "  "))
	frame.opinionSummary:SetText((draft.opinion and OpinionLabel(draft.opinion) or Text("Мнение не задано", "Opinion not set"))
		.. (#draft.facts > 0 and ("  /  " .. Addon:FactSummary(draft.facts)) or ""))
	local profile = record.profile
	frame.author:SetText(Text("Автор мнения: ", "Opinion author: ") .. Author(profile and profile.author)
		.. "  /  " .. Time(profile and profile.updatedAt))
	local editable = Editable(frame)
	frame.selfHint:SetText(editable and "" or Text("Это ваш персонаж — оценка недоступна", "This is your character — rating is unavailable"))
	if editable then frame.author:Show(); frame.editOpinion:Show(); frame.typeButton:Show(); frame.overviewAdd:Show() else
		frame.author:Hide()
		frame.editOpinion:Hide(); frame.typeButton:Hide(); frame.overviewAdd:Hide(); frame.eventMenu:Hide()
	end
	for _, button in ipairs(frame.opinions) do
		button.label:SetText(OpinionLabel(button.opinion)); SelectedButton(button, draft.opinion == button.opinion)
		if editable then button:Enable() else button:Disable() end
	end
	for _, button in ipairs(frame.facts) do
		button.label:SetText(Addon:FactSummary({button.fact}))
		local selected = false
		for _, fact in ipairs(draft.facts) do if fact == button.fact then selected = true end end
		SelectedButton(button, selected)
		if editable then button:Enable() else button:Disable() end
	end
	if frame.notesBox:GetText() ~= draft.note then
		frame.updatingNote = true; frame.notesBox:SetText(draft.note); frame.updatingNote = false
	end
	for id, panel in pairs(frame.profilePanels) do
		if frame.profileTabs[id] then SelectedButton(frame.profileTabs[id], id == frame.selectedProfileTab) end
		if id == frame.selectedProfileTab then panel:Show() else panel:Hide() end
	end
	if frame.selectedProfileTab == "history" then frame.journalBack:Show() else frame.journalBack:Hide() end
	if frame.selectedProfileTab == "overview" then frame.toNote:Hide() else frame.toNote:Show() end
	Layout(frame)
	if frame.selectedProfileTab == "characters" then Addon:RefreshProfileCharacters(frame) end
	local events = {}
	for _, event in ipairs(draft.events) do events[#events + 1] = event end
	table.sort(events, function(left, right)
		if left.eventAt ~= right.eventAt then return left.eventAt > right.eventAt end
		return tostring(left.id) > tostring(right.id)
	end)
	local function EventLabel(eventType)
		for _, info in ipairs(frame.eventTypes) do if info.id == eventType then return info.label end end
		return eventType
	end
	local function DrawEvent(row, event)
		local context = event.context or {}
		row.label:SetText(EventLabel(event.type) .. " | " .. Time(event.eventAt) .. " | " .. Author(event.author)
			.. "\n" .. (context.zoneName or "") .. " " .. (context.instanceName or ""))
		row:EnableMouse(true)
		row:SetScript("OnEnter", function()
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:AddLine(EventLabel(event.type), 1, 1, 1, true)
			GameTooltip:AddLine(Time(event.eventAt) .. " | " .. Author(event.author), 0.8, 0.8, 0.8, true)
			GameTooltip:AddLine((context.zoneName or "") .. " " .. (context.instanceName or ""), 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function() GameTooltip:Hide() end)
		if not row.edit then
			row.edit = Button(row, 0, -38, 125, Text("Изменить тип", "Change type"), function() end)
			row.remove = Button(row, 133, -38, 90, Text("Удалить", "Remove"), function() end)
		end
		row.edit:SetScript("OnClick", function() OpenEventPicker(frame, event) end)
		row.remove:SetScript("OnClick", function()
			for index, value in ipairs(draft.events) do if value.id == event.id then table.remove(draft.events, index); break end end
			Changed(frame)
		end)
		if editable then row.edit:Show(); row.remove:Show() else row.edit:Hide(); row.remove:Hide() end
	end
	frame.maxEventPage = math.max(1, math.ceil(#events / 25))
	frame.eventPage = math.min(frame.eventPage, frame.maxEventPage)
	if frame.selectedProfileTab == "events" then Render(frame.eventList, Slice(events, frame.eventPage), DrawEvent) end
	local recent = {}
	for index = 1, math.min(3, #events) do recent[index] = events[index] end
	if frame.selectedProfileTab == "overview" then
		Render(frame.overviewList, recent, DrawEvent)
		local recentHeight = #recent > 0 and math.min(#recent * 62, frame.overviewList.scroll:GetHeight()) or 30
		frame.overviewList.scroll:SetHeight(recentHeight)
		if #recent > 0 then frame.overviewList.scroll:Show() else frame.overviewList.scroll:Hide() end
		frame.allEvents:ClearAllPoints(); frame.allEvents:SetPoint("TOPLEFT", 0, -(40 + recentHeight + 8))
	end
	local empty = #events == 0 and Text("Событий пока нет", "No events yet") or ""
	frame.eventsEmpty:SetText(empty); frame.overviewEmpty:SetText(empty)
	local stats = Addon:GetCharacterMeetingStats(draft.key)
	local observerName, observerRealm = UnitName("player")
	frame.meetings:SetText(Text("Встречи персонажа ", "Meetings as ") .. (observerName or "—") .. (observerRealm and (" — " .. observerRealm) or "")
		.. ": " .. stats.count .. "\n" .. Time(stats.firstMetAt) .. " — " .. Time(stats.lastMetAt))
	frame.meetingSummary:SetText(Text("Совместных встреч: ", "Shared meetings: ") .. stats.count .. "\n"
		.. Text("Последняя: ", "Last: ") .. Time(stats.lastMetAt))
	local links = Addon:GetLinkedCharacters(draft.key)
	local names = {}
	for _, link in ipairs(links) do
		if link.guid ~= draft.key then
			local label = Author(link.entry)
			local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[link.entry.class]
			if color then label = Addon:RatingWrapColor(label, {color.r, color.g, color.b}) end
			names[#names + 1] = label
		end
	end
	frame.linkSummary:SetText(#names > 0 and table.concat(names, ", ") or Text("Связанных персонажей нет", "No linked characters"))
	if frame.selectedProfileTab == "meetings" then
		local meetings = Addon:GetCharacterEncounters(draft.key)
		table.sort(meetings, function(left, right) return left.lastSeenAt > right.lastSeenAt end)
		frame.maxMeetingPage = math.max(1, math.ceil(#meetings / 25))
		frame.meetingPage = math.min(frame.meetingPage, frame.maxMeetingPage)
		Render(frame.meetingList, Slice(meetings, frame.meetingPage), function(row, meeting)
			local places = {}
			for _, place in ipairs(meeting.places) do places[#places + 1] = place.zoneName end
			row.label:SetText(Time(meeting.startedAt) .. " — " .. Time(meeting.lastSeenAt) .. "\n" .. table.concat(places, ", "))
		end)
		frame.meetingsEmpty:SetText(#meetings == 0 and Text("Подробных записей встреч нет", "No detailed meeting records") or "")
	end
	if frame.selectedProfileTab == "history" then
		frame.maxHistoryPage = math.max(1, math.ceil(Addon:GetPlayerRecordChangeCount(draft.key) / 25))
		frame.historyPage = math.min(frame.historyPage, frame.maxHistoryPage)
		local changes = Addon:GetPlayerRecordChangePage(draft.key, frame.historyPage)
		Render(frame.changeList, changes, function(row, change)
			local detail = change.kind
			if change.kind == "opinion" then detail = Text("Мнение: ", "Opinion: ") .. (change.before and OpinionLabel(change.before) or "—") .. " → " .. (change.after and OpinionLabel(change.after) or "—") end
			if change.kind == "facts" then detail = Text("Роли: ", "Roles: ") .. Addon:FactSummary(change.after or {}) end
			if change.kind == "events" then detail = Text("Изменены события", "Events changed") end
			if change.detail then detail = detail .. ": " .. (type(change.detail) == "table" and change.detail.name or change.detail) end
			row.label:SetText(Time(change.at) .. " | " .. Author(change.actor) .. "\n" .. detail)
		end)
		frame.changesEmpty:SetText(#changes == 0 and Text("Изменений пока нет", "No changes yet") or "")
	end
	frame.eventPages:SetText(frame.eventPage .. " / " .. frame.maxEventPage)
	frame.meetingPages:SetText(frame.meetingPage .. " / " .. (frame.maxMeetingPage or 1))
	frame.historyPages:SetText(frame.historyPage .. " / " .. (frame.maxHistoryPage or 1))
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
	UISpecialFrames[#UISpecialFrames + 1] = frame:GetName()
	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 12, -10); titleBar:SetSize(WIDTH - 24, 26); W.AttachDragHandle(titleBar, frame)
	local close = Button(titleBar, WIDTH - 48, 0, 24, "X", function() frame:Hide() end)
	W.AttachLayoutVersionLabel(titleBar, VERSION, close)
	frame.title = Label(titleBar, 0, 0, 490, ""); frame.title:SetHeight(24)
	frame.details = Label(frame, 12, -36, WIDTH - 24, ""); frame.details:SetHeight(20)
	frame.opinionSummary = Label(frame, 12, -58, 664, ""); frame.opinionSummary:SetHeight(30)
	frame.author = Label(frame, 12, -88, 664, ""); frame.author:SetHeight(20)
	frame.selfHint = Label(frame, 12, -88, 664, "")
	frame.editOpinion = Button(frame, 690, -58, 118, Text("Изменить", "Edit"), function()
		frame.editingOpinion = not frame.editingOpinion; Refresh(frame)
	end)
	frame.opinionEditor = CreateFrame("Frame", nil, frame)
	frame.opinionEditor:SetPoint("TOPLEFT", 12, -122); frame.opinionEditor:SetSize(796, 64)
	frame.opinions, frame.facts = {}, {}
	for index, opinion in ipairs({"unset", "positive", "neutral", "negative"}) do
		local button = Button(frame.opinionEditor, (index - 1) * 172, 0, 164, "", function()
			if not Editable(frame) then return end
			frame.editor.draft.opinion = opinion ~= "unset" and opinion or nil; Changed(frame)
		end)
		button.opinion = opinion ~= "unset" and opinion or nil; frame.opinions[#frame.opinions + 1] = button
	end
	for index, fact in ipairs(Addon:FactCatalog()) do
		local button = Button(frame.opinionEditor, (index - 1) * 172, -30, 164, "", function()
			if not Editable(frame) then return end
			local facts, found = frame.editor.draft.facts, false
			for position, value in ipairs(facts) do if value == fact.id then table.remove(facts, position); found = true; break end end
			if not found then facts[#facts + 1] = fact.id end; Changed(frame)
		end)
		button.fact = fact.id; frame.facts[#frame.facts + 1] = button
	end
	Button(frame.opinionEditor, 688, -30, 108, Text("Готово", "Done"), function() frame.editingOpinion = false; Refresh(frame) end)
	frame.profilePanels, frame.profileTabs = {}, {}
	frame.navigation = CreateFrame("Frame", nil, frame); frame.navigation:SetSize(796, 28)
	for index, tab in ipairs({{"overview", Text("Обзор", "Overview")}, {"events", Text("События", "Events")},
		{"meetings", Text("Встречи", "Meetings")}, {"characters", Text("Персонажи", "Characters")}}) do
		frame.profileTabs[tab[1]] = Button(frame.navigation, (index - 1) * 138, 0, 130, tab[2], function() SelectTab(frame, tab[1]) end)
	end
	for _, id in ipairs({"overview", "events", "meetings", "characters", "history"}) do
		frame.profilePanels[id] = CreateFrame("Frame", nil, frame)
	end
	frame.journalButton = Button(frame.navigation, 572, 0, 224, Text("Журнал изменений", "Change journal"), function()
		if frame.selectedProfileTab ~= "history" then frame.beforeJournal = frame.selectedProfileTab end
		SelectTab(frame, "history")
	end)
	frame.eventPage, frame.meetingPage, frame.historyPage = 1, 1, 1
	frame.eventTypes = Addon:GetProfileEventCatalog()
	local function Pager(panel, pageKey, maxKey)
		local previous = Button(panel, 0, 0, 44, "<", function() frame[pageKey] = math.max(1, frame[pageKey] - 1); Refresh(frame) end)
		previous:ClearAllPoints(); previous:SetPoint("BOTTOMLEFT", 0, 0)
		local nextButton = Button(panel, 52, 0, 44, ">", function() frame[pageKey] = math.min(frame[maxKey] or 1, frame[pageKey] + 1); Refresh(frame) end)
		nextButton:ClearAllPoints(); nextButton:SetPoint("BOTTOMLEFT", 52, 0)
		local label = Label(panel, 0, 0, 120, ""); label:ClearAllPoints(); label:SetPoint("BOTTOMLEFT", 110, 6)
		return label
	end
	local overview = frame.profilePanels.overview
	Label(overview, 0, 0, 270, Text("Последние события", "Recent events"))
	frame.overviewAdd = Button(overview, 280, 0, 180, Text("Добавить событие", "Add event"), function() OpenEventPicker(frame) end)
	frame.overviewList = List(overview, "RaidwiseProfileRecentV" .. VERSION, 0, -40, 460, 186)
	frame.overviewEmpty = Label(overview, 0, -42, 436, "")
	frame.allEvents = Button(overview, 0, -78, 160, Text("Все события", "All events"), function() SelectTab(frame, "events") end)
	frame.notePanel = CreateFrame("Frame", nil, overview)
	frame.notePanel:SetPoint("TOPLEFT", 476, 0); frame.notePanel:SetWidth(320)
	W.ApplyPlainPanel(frame.notePanel, {0.12, 0.22, 0.32, 0.75})
	Label(frame.notePanel, 8, -8, 304, Text("Заметка — только для себя", "Private note — only for you"))
	local box, host = W.CreateCopyBox(frame.notePanel, "RaidwisePrivateNoteScrollV" .. VERSION, "RaidwisePrivateNoteV" .. VERSION)
	host:SetPoint("TOPLEFT", 6, -32); host:SetPoint("BOTTOMRIGHT", -6, 6); frame.notesBox = box
	box:SetScript("OnMouseUp", function() end)
	box:SetScript("OnTextChanged", function(self)
		W.FitCopyBoxToText(self)
		if not frame.updatingNote and frame.editor then frame.editor.draft.note = self:GetText(); Addon:MarkProfileEditorChanged(frame.editor); UpdateStatus(frame) end
	end)
	frame.meetingSummary = Label(overview, 476, 0, 248, ""); frame.meetingSummary:ClearAllPoints()
	frame.meetingSummary:SetPoint("TOPLEFT", frame.notePanel, "BOTTOMLEFT", 0, -10); frame.meetingSummary:SetHeight(38)
	local meetingLink = Button(overview, 0, 0, 60, Text("Все", "All"), function() SelectTab(frame, "meetings") end)
	meetingLink:ClearAllPoints(); meetingLink:SetPoint("TOPRIGHT", frame.notePanel, "BOTTOMRIGHT", 0, -10)
	frame.linkSummary = Label(overview, 0, 0, 238, ""); frame.linkSummary:ClearAllPoints()
	frame.linkSummary:SetPoint("TOPLEFT", frame.notePanel, "BOTTOMLEFT", 0, -56); frame.linkSummary:SetHeight(36)
	local linksLink = Button(overview, 0, 0, 70, Text("Связи", "Links"), function() SelectTab(frame, "characters") end)
	linksLink:ClearAllPoints(); linksLink:SetPoint("TOPRIGHT", frame.notePanel, "BOTTOMRIGHT", 0, -56)
	local events = frame.profilePanels.events
	frame.typeButton = Button(events, 0, 0, 200, Text("Добавить событие", "Add event"), function() OpenEventPicker(frame) end)
	frame.eventList = List(events, "RaidwiseProfileEventsV" .. VERSION, 0, -40, 796, 260)
	frame.eventsEmpty = Label(events, 0, -42, 740, "")
	frame.eventPages = Pager(events, "eventPage", "maxEventPage")
	local meetings = frame.profilePanels.meetings
	frame.meetings = Label(meetings, 0, 0, 796, ""); frame.meetings:SetHeight(40)
	frame.meetingList = List(meetings, "RaidwiseProfileMeetingsV" .. VERSION, 0, -60, 796, 240)
	frame.meetingsEmpty = Label(meetings, 0, -62, 740, "")
	frame.meetingPages = Pager(meetings, "meetingPage", "maxMeetingPage")
	local history = frame.profilePanels.history
	frame.journalBack = Button(history, 0, 0, 150, Text("Назад", "Back"), function() SelectTab(frame, frame.beforeJournal or "overview") end)
	frame.changeList = List(history, "RaidwiseProfileChangesV" .. VERSION, 0, -40, 796, 260)
	frame.changesEmpty = Label(history, 0, -42, 740, "")
	frame.historyPages = Pager(history, "historyPage", "maxHistoryPage")
	Addon:CreateProfileCharactersPanel(frame, frame.profilePanels.characters, 796, VERSION)
	-- A modal chooser keeps selecting a type separate from committing an event.
	frame.eventMenu = CreateFrame("Frame", nil, frame)
	frame.eventMenu:SetSize(620, 480); frame.eventMenu:SetPoint("CENTER"); frame.eventMenu:SetFrameLevel(frame:GetFrameLevel() + 20)
	frame.eventMenu:EnableMouse(true); W.ApplyPlainPanel(frame.eventMenu); W.ApplyOuterBorder(frame.eventMenu)
	Label(frame.eventMenu, 12, -12, 570, Text("Тип события — поиск и категории", "Event type — search and categories"))
	local search, searchHost = W.CreateTextInput(frame.eventMenu, 590)
	searchHost:SetPoint("TOPLEFT", 12, -38); frame.eventSearch = search
	frame.choiceList = List(frame.eventMenu, "RaidwiseProfileEventChoicesV" .. VERSION, 12, -76, 596, 300)
	frame.eventChoices, frame.eventGroups = {}, {}
	for _, info in ipairs(eventGroups) do
		local group = {ru=info.ru, en=info.en, label=Label(frame.choiceList.content, 0, 0, 550, ""), choices={}}
		for id in info.ids:gmatch("%S+") do
			for index, entry in ipairs(frame.eventTypes) do if entry.id == id then
				local choice = Button(frame.choiceList.content, 0, 0, frame.choiceList.width, entry.label, function()
					frame.typeIndex = index; RefreshChoices(frame)
				end)
				choice.typeIndex = index; frame.eventChoices[index] = choice; group.choices[#group.choices + 1] = choice
			end end
		end
		frame.eventGroups[#frame.eventGroups + 1] = group
	end
	frame.noChoices = Label(frame.eventMenu, 12, -80, 550, "")
	frame.eventSelection = Label(frame.eventMenu, 12, -390, 590, ""); frame.eventSelection:SetHeight(36)
	search:SetScript("OnTextChanged", function() RefreshChoices(frame) end)
	frame.add = Button(frame.eventMenu, 12, -440, 180, Text("Добавить", "Add"), function()
		if not Editable(frame) or not frame.typeIndex then return end
		local eventType = frame.eventTypes[frame.typeIndex].id
		if frame.editingEvent then
			frame.editingEvent.type = eventType; frame.eventMenu:Hide(); Changed(frame)
		else
			local id, err = Addon:AddPlayerRecordDraftEvent(frame.editor.draft, eventType)
			if id then frame.eventMenu:Hide(); frame.eventPage = 1; Changed(frame)
			else frame.editor.status, frame.editor.error = "error", err; UpdateStatus(frame) end
		end
	end)
	Button(frame.eventMenu, 430, -440, 178, Text("Отмена", "Cancel"), function() frame.eventMenu:Hide() end)
	frame.eventMenu:Hide()
	frame.actionsMenu = CreateFrame("Frame", nil, frame)
	frame.actionsMenu:SetSize(340, 104); frame.actionsMenu:SetPoint("TOPRIGHT", -12, -38)
	frame.actionsMenu:SetFrameLevel(frame:GetFrameLevel() + 10); frame.actionsMenu:EnableMouse(true)
	W.ApplyPlainPanel(frame.actionsMenu); W.ApplyOuterBorder(frame.actionsMenu)
	frame.guidLabel = Label(frame.actionsMenu, 8, -8, 324, "")
	frame.deleteData = Button(frame.actionsMenu, 8, -40, 200, Text("Удалить данные", "Delete data"), function()
		local key = frame.profileMember and frame.profileMember.guid
		if not key then return end
		StaticPopupDialogs.RAIDWISE_PROFILE_DELETE = {text=Addon:T("DATABASE_DELETE_CONFIRM", Author(frame.profileMember)),
			button1=Text("Удалить", "Delete"), button2=Text("Отмена", "Cancel"), timeout=0, whileDead=true, hideOnEscape=true,
			OnAccept=function() Addon:DeleteCharacterDatabaseRecords({key}) end}
		frame.actionsMenu:Hide(); StaticPopup_Show("RAIDWISE_PROFILE_DELETE")
	end)
	Button(frame.actionsMenu, 222, -40, 108, Text("Закрыть", "Close"), function() frame.actionsMenu:Hide() end)
	frame.actionsMenu:Hide()
	Button(titleBar, 560, 0, 110, Text("Действия", "Actions"), function()
		if frame.actionsMenu:IsShown() then frame.actionsMenu:Hide() else frame.actionsMenu:Show() end
	end)
	frame.status = Label(frame, 12, -508, 430, "")
	frame.save = Button(frame, 456, -504, 110, "", function() Addon:SaveProfileEditor(frame.editor); Refresh(frame) end)
	frame.reload = Button(frame, 574, -504, 110, Text("Перечитать", "Reload"), function()
		frame.eventMenu:Hide(); frame.editor = Addon:ReloadProfileEditor(frame.editor); Refresh(frame)
	end)
	frame.toNote = Button(frame, 692, -504, 116, Text("К заметке", "To note"), function()
		SelectTab(frame, "overview"); frame.notesBox:SetFocus()
	end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		if not frame.profileMember then return end
		local wasDirty = frame.editor.dirty; Addon:TickProfileEditor(frame.editor, elapsed)
		if wasDirty and not frame.editor.dirty then Refresh(frame) else UpdateStatus(frame) end
	end)
	frame:SetScript("OnHide", function()
		frame.eventMenu:Hide(); frame.actionsMenu:Hide()
		if frame.profileMember then
			local ok = Addon:CloseProfileEditor(frame.editor)
			if not ok and Addon.Print then Addon:Print(Text("Не удалось сохранить. Черновик останется в памяти до повторного открытия Профиля.",
				"Save failed. The draft stays in memory until you reopen the Profile.")) end
		end
	end)
	return frame
end

function Addon:ShowRaidCharacterWindow(member)
	local frame = self.raidDetailFrame
	if frame and frame.profileMember then self:CloseProfileEditor(frame.editor) end
	local entry = self.UpsertHistoryMember and self:UpsertHistoryMember(member) or self:EnsureHistoryEntryForGuid(member.guid, member)
	if not entry then return end
	if not frame or frame.layoutVersion ~= VERSION then
		if frame then frame:Hide() end
		frame = Create(); self.raidDetailFrame = frame
	end
	frame.profileMember = self:HistoryProfileForMember(entry)
	frame.editor = self:OpenProfileEditor(entry.guid)
	if not frame.editor then frame:Hide(); return end
	frame.eventMenu:Hide(); frame.actionsMenu:Hide(); frame.editingOpinion = false; frame.beforeJournal = nil
	frame.selectedProfileTab, frame.eventPage, frame.meetingPage, frame.historyPage = "overview", 1, 1, 1
	if frame.characterSearchPanel then frame.characterSearchPanel:Hide() end
	Refresh(frame); frame:Show()
end
