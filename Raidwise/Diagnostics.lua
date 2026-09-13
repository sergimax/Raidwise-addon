local Addon = Raidwise
local LAYOUT_VERSION = 1

local function ErrorDetail(message)
	local trace = type(debugstack) == "function" and debugstack(2, 12, 0) or ""
	return tostring(message) .. "\n" .. trace
end

function Addon:RunDiagnostics()
	local lines = { "Raidwise diagnostics v1", "Addon: " .. tostring(self.version), "Lua: " .. tostring(_VERSION) }
	if type(GetBuildInfo) == "function" then
		local version, build = GetBuildInfo()
		lines[#lines + 1] = "Client: " .. tostring(version) .. " / " .. tostring(build)
	end
	lines[#lines + 1] = "Time: " .. (type(date) == "function" and date("%Y-%m-%d %H:%M:%S") or "unknown")
	lines[#lines + 1] = "Shell existed before test: " .. tostring(self.mainFrame ~= nil)
	local passed, failed, skipped = 0, 0, 0
	local function Check(name, callback)
		local ok, detail = xpcall(callback, ErrorDetail)
		if ok then passed = passed + 1 else failed = failed + 1 end
		lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name
		if not ok then lines[#lines + 1] = tostring(detail) end
	end
	if type(InCombatLockdown) == "function" and InCombatLockdown() then
		skipped = skipped + 1
		lines[#lines + 1] = "SKIP main window opening: leave combat and run again"
	else
		Check("main window opening", function()
			assert(type(self.ShowMainFrame) == "function", "ShowMainFrame module missing")
			self:ShowMainFrame()
			assert(self.mainFrame and self.mainFrame:IsShown(), "Main window did not become visible")
		end)
	end
	Check("gear rule self-tests", function()
		assert(type(self.GearCheckRulesSelfTest) == "function", "GearCheckSelfTest module missing")
		local results, count, total = self:GearCheckRulesSelfTest()
		for _, result in ipairs(results) do
			if not result.ok then lines[#lines + 1] = "FAIL rule: " .. tostring(result.name) end
		end
		lines[#lines + 1] = "Rules: " .. tostring(count) .. "/" .. tostring(total)
		assert(total > 0 and count == total, "Gear rule failures")
	end)
	lines[#lines + 1] = string.format("Summary: %d passed, %d failed, %d skipped", passed, failed, skipped)
	lines[#lines + 1] = "Run immediately after /reload to test fresh window construction."
	lines[#lines + 1] = "Scope: opening and gear rules; not every tab, profile interaction or live inspect timing."
	return table.concat(lines, "\n"), failed == 0 and skipped == 0
end

-- Independent of the main shell, theme and widget modules so UI failures remain copyable.
function Addon:ShowDiagnostics()
	local report, ok = self:RunDiagnostics()
	self.lastDiagnosticReport = report
	self:Print(ok and "Diagnostics PASS. Ctrl+A / Ctrl+C to copy." or "Diagnostics FAIL or SKIP. Copy the report for analysis.")
	local frame = self.diagnosticsFrame
	if not frame or frame.layoutVersion ~= LAYOUT_VERSION then
		if frame then frame:Hide() end
		frame = CreateFrame("Frame", nil, UIParent)
		frame.layoutVersion = LAYOUT_VERSION
		frame:SetSize(620, 420)
		frame:SetPoint("CENTER")
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:EnableMouse(true)
		frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", 20, -18)
		title:SetText("Raidwise diagnostics - Ctrl+A / Ctrl+C")
		local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -5, -5)
		close:SetScript("OnClick", function() frame:Hide() end)
		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 20, -48)
		scroll:SetPoint("BOTTOMRIGHT", -40, 20)
		local box = CreateFrame("EditBox", nil, scroll)
		box:SetMultiLine(true)
		box:SetAutoFocus(false)
		box:SetFontObject(ChatFontNormal)
		box:SetWidth(550)
		box:SetHeight(340)
		box:SetScript("OnEscapePressed", function() frame:Hide() end)
		frame:SetScript("OnHide", function() box:ClearFocus() end)
		scroll:SetScrollChild(box)
		frame.box = box
		self.diagnosticsFrame = frame
	end
	frame.box:SetText(report)
	frame:Show()
	frame.box:SetFocus()
	frame.box:HighlightText()
end
