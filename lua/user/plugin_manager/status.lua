local M = {}

function M.rows(state)
	local rows = {}
	for _, name in ipairs(state.registry:names()) do
		local kind = "pending"
		if state.errors[name] then
			kind = "error"
		elseif state.loaded[name] then
			kind = "loaded"
		end
		rows[#rows + 1] = {
			name = name,
			state = kind,
			errors = state.errors[name] or {},
		}
	end
	return rows
end

function M.open_buffer(state)
	local rows = M.rows(state)
	local lines = { ("Skyline Pack (%s) — %d plugins"):format(vim.g.skyline_plugin_manager or "?", #rows), "" }
	local icon = { loaded = "✓", pending = "·", error = "✗" }
	for _, row in ipairs(rows) do
		lines[#lines + 1] = ("%s  %-30s  %s"):format(icon[row.state] or "?", row.name, row.state)
		for _, message in ipairs(row.errors) do
			for _, errline in ipairs(vim.split(message, "\n", { plain = true })) do
				lines[#lines + 1] = "      " .. errline
			end
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - math.min(#lines + 2, 30)) / 2),
		col = math.floor((vim.o.columns - 80) / 2),
		width = 80,
		height = math.min(#lines + 2, 30),
		style = "minimal",
		border = "rounded",
		title = " SkylinePackStatus ",
	})
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
end

function M.register_command(state)
	vim.api.nvim_create_user_command("SkylinePackStatus", function()
		M.open_buffer(state)
	end, {
		desc = "Show Skyline plugin load status and errors",
	})
end

return M
