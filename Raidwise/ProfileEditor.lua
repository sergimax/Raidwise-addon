-- One save controller for the profile window; failed drafts survive closing.
local Addon = Raidwise
local pending = {}

function Addon:OpenProfileEditor(key)
	for savedKey, editor in pairs(pending) do
		if editor.draft.key == key then
			pending[savedKey] = nil
			pending[key] = editor
			return editor
		end
	end
	local draft, err = self:CreatePlayerRecordDraft(key)
	if not draft then return nil, err end
	local editor = {draft=draft, dirty=false, elapsed=0, status="saved"}
	pending[key] = editor
	return editor
end

function Addon:MarkProfileEditorChanged(editor)
	editor.dirty, editor.elapsed, editor.status, editor.error = true, 0, "dirty", nil
end

function Addon:SaveProfileEditor(editor)
	if not editor or not editor.dirty then return true end
	editor.status = "saving"
	local ok, err = self:CommitPlayerRecordDraft(editor.draft)
	if not ok then
		editor.status, editor.error = "error", err
		return nil, err
	end
	editor.dirty, editor.elapsed, editor.status, editor.error = false, 0, "saved", nil
	if self.RefreshRatingViews then self:RefreshRatingViews() end
	return true
end

function Addon:TickProfileEditor(editor, elapsed)
	if not editor or not editor.dirty or editor.status == "error" then return end
	editor.elapsed = editor.elapsed + elapsed
	if editor.elapsed >= 1 then return self:SaveProfileEditor(editor) end
end

function Addon:CloseProfileEditor(editor)
	if not editor then return true end
	local ok, err = self:SaveProfileEditor(editor)
	if ok then
		for key, saved in pairs(pending) do if saved == editor then pending[key] = nil end end
	end
	return ok, err
end

function Addon:DiscardProfileEdits(key)
	for savedKey, editor in pairs(pending) do
		if editor.draft.key == key then
			editor.dirty, editor.status = false, "discarded"
			pending[savedKey] = nil
		end
	end
end

function Addon:ReloadProfileEditor(editor)
	local key = editor.draft.key
	self:DiscardProfileEdits(key)
	return self:OpenProfileEditor(key)
end
