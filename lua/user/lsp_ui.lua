local M = {}

local completed_progress = {}

local function progress_module()
	local ok, progress = pcall(require, "noice.lsp.progress")
	if not ok or type(progress._progress) ~= "table" then
		return nil
	end

	return progress
end

local function ready_message(state)
	local client_name = state.client

	if not client_name and state.client_id then
		local client = vim.lsp.get_client_by_id(state.client_id)
		client_name = client and client.name or nil
	end

	return (client_name or "LSP") .. " ready"
end

local function sync_completion_notifications(progress_items)
	local present = {}

	for id, message in pairs(progress_items) do
		local state = message and message.opts and message.opts.progress
		local progress_id = type(state) == "table" and (state.id or id) or id
		present[progress_id] = true

		if type(state) == "table" and state.kind == "end" and not completed_progress[progress_id] then
			completed_progress[progress_id] = true
			vim.notify(ready_message(state), vim.log.levels.INFO, { title = "LSP" })
		elseif type(state) == "table" and state.kind ~= "end" then
			completed_progress[progress_id] = nil
		end
	end

	for progress_id in pairs(completed_progress) do
		if not present[progress_id] then
			completed_progress[progress_id] = nil
		end
	end
end

function M.activity_status()
	local progress = progress_module()
	if not progress then
		return ""
	end

	sync_completion_notifications(progress._progress)

	for _, message in pairs(progress._progress) do
		local state = message and message.opts and message.opts.progress
		if type(state) == "table" and state.kind ~= "end" then
			return "lsp..."
		end
	end

	return ""
end

return M
