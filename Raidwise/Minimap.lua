local Addon = Raidwise
local grades = { S = 1, A = 2, B = 3, C = 4, D = 5 }

local function T(key, ...)
	return Addon:T("MINIMAP_" .. key, ...)
end

-- Only current members with complete scans participate in the readiness ranking.
function Addon:BuildMinimapRaidSummary()
	local members = {}
	for _, group in ipairs(self:BuildRaidGroups(false)) do
		for _, member in ipairs(group) do members[#members + 1] = member end
	end
	local summary = { members = members, unready = {}, scanned = 0, rated = 0 }
	summary.gs, summary.ilvl = self:AverageRosterStats(members)
	summary.consumables = self:SummarizeRaidConsumables(members)
	local reports = {}
	for _, entry in ipairs(self:ListGearCheckSavedReports()) do
		if not reports[entry.characterKey] then reports[entry.characterKey] = entry.report end
	end
	for _, entry in ipairs(self:GetLastGearCheckRaidResults() or {}) do
		local key = entry.member and entry.member.guid
		if key and key ~= "" then reports[key] = entry.report end
	end
	local total = 0
	for _, member in ipairs(members) do
		local rating = self:GetCommunityRating(member)
		if rating and not rating.isMock and tonumber(rating.positivePercent) then
			total = total + rating.positivePercent
			summary.rated = summary.rated + 1
		end
		local key = self:GearCheckCharacterKey({ character = member })
		local report = reports[key]
		local inspect = report and ((report.collection and report.collection.inspect) or report.inspect)
		local overall = report and report.overall or {}
		local gear, enchant = overall.gearGrade or overall.status, overall.enchantSocketGrade
		if inspect and inspect.complete and grades[gear] and grades[enchant] then
			summary.scanned = summary.scanned + 1
			if grades[gear] >= 4 or grades[enchant] >= 4 then
				summary.unready[#summary.unready + 1] = {
					name = member.name, gear = gear, enchant = enchant,
					severity = math.max(grades[gear], grades[enchant]),
					score = grades[gear] + grades[enchant],
				}
			end
		end
	end
	if summary.rated > 0 then summary.rating = math.floor(total / summary.rated + 0.5) end
	table.sort(summary.unready, function(a, b)
		if a.severity ~= b.severity then return a.severity > b.severity end
		if a.score ~= b.score then return a.score > b.score end
		return a.name < b.name
	end)
	return summary
end

local function Heading(text)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(text, 1, 0.82, 0)
end

local function Names(label, names)
	local visible = {}
	for i = 1, math.min(#names, 8) do visible[i] = names[i] end
	local text = #names == 0 and T("NONE") or table.concat(visible, ", ")
	if #names > 8 then text = text .. T("MORE", #names - 8) end
	GameTooltip:AddLine(label .. ": " .. text, 1, 1, 1, true)
end

function Addon:ShowMinimapTooltip(button)
	local summary = self:BuildMinimapRaidSummary()
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("Raidwise", 1, 0.49, 0.04)
	Heading(T("RAID", #summary.members))
	GameTooltip:AddDoubleLine(T("AVERAGES"), tostring(summary.ilvl or "—") .. " / " .. tostring(summary.gs or "—"), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(T("RATING"), summary.rating and (summary.rating .. "% (" .. summary.rated .. "/" .. #summary.members .. ")") or T("UNKNOWN"), 1, 1, 1, 1, 1, 1)
	Names(T("FLASKS"), summary.consumables.flaskMissing)
	Names(T("FOOD"), summary.consumables.foodMissing)
	local unknown, unknownNames = 0, {}
	for _, names in ipairs({ summary.consumables.flaskUnknown, summary.consumables.foodUnknown }) do
		for _, name in ipairs(names) do
			if not unknownNames[name] then
				unknownNames[name] = true
				unknown = unknown + 1
			end
		end
	end
	if unknown > 0 then GameTooltip:AddLine(T("BUFF_UNKNOWN", unknown), 0.65, 0.65, 0.65) end
	Heading(T("UNREADY", summary.scanned, #summary.members))
	for i = 1, math.min(5, #summary.unready) do
		local entry = summary.unready[i]
		GameTooltip:AddDoubleLine(entry.name, T("GRADES", entry.gear, entry.enchant), 1, 1, 1, 1, 0.4, 0.3)
	end
	if #summary.unready == 0 then GameTooltip:AddLine(T(summary.scanned == 0 and "NO_SCANS" or "NO_ISSUES"), 0.7, 0.7, 0.7) end
	Heading(T("COOLDOWNS"))
	local data, count = self:BuildCooldownTable(), 0
	for _, row in ipairs(data.rows) do
		if row.isRaid then
			for _, character in ipairs(data.characters) do
				local cell = row.cells[character.key]
				for _, entry in ipairs(cell and cell.tooltipEntries or {}) do
					count = count + 1
					if count <= 10 then GameTooltip:AddLine(character.displayName .. " — " .. row.name .. ": " .. entry.text, 1, 1, 1, true) end
				end
			end
		end
	end
	if count == 0 then GameTooltip:AddLine(T("NONE"), 0.7, 0.7, 0.7) end
	if count > 10 then GameTooltip:AddLine(T("MORE", count - 10), 0.7, 0.7, 0.7) end
	Heading(T("HINT"))
	GameTooltip:Show()
end

local function Position(button)
	local angle = math.rad(tonumber(Addon.db.minimapAngle) or 225)
	local x, y = math.cos(angle), math.sin(angle)
	if GetMinimapShape and GetMinimapShape() == "SQUARE" then
		local divisor = math.max(math.abs(x), math.abs(y))
		x, y = x / divisor, y / divisor
	end
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x * (Minimap:GetWidth() / 2 + 8), y * (Minimap:GetHeight() / 2 + 8))
end

function Addon:CreateMinimapButton()
	if self.minimapButton then return end
	local button = CreateFrame("Button", "RaidwiseMinimapButton", Minimap)
	self.minimapButton = button
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(20, 20)
	icon:SetPoint("TOPLEFT", 7, -5)
	icon:SetTexture("Interface\\Icons\\INV_Helmet_06")
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button:SetScript("OnClick", function(_, mouseButton)
		Addon:ShowMainFrame()
		Addon:SelectTab(mouseButton == "RightButton" and "cooldowns" or "raid")
	end)
	button:SetScript("OnEnter", function(self)
		if not self.dragging then Addon:ShowMinimapTooltip(self) end
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnDragStart", function(self)
		self.dragging = true
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStop", function(self) self.dragging = false end)
	button:SetScript("OnUpdate", function(self, elapsed)
		if self.dragging then
			local x, y = GetCursorPosition()
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			Addon.db.minimapAngle = math.deg(math.atan2(y / scale - my, x / scale - mx)) % 360
			Position(self)
		elseif GameTooltip:IsOwned(self) then
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed >= 1 then
				self.elapsed = 0
				Addon:ShowMinimapTooltip(self)
			end
		end
	end)
	Position(button)
end
