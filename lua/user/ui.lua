local M = {}

function M.notify_opts()
	return {
		fps = 60,
		render = "wrapped-compact",
		stages = "fade_in_slide_out",
		timeout = 2500,
		top_down = true,
	}
end

function M.setup_notify(opts)
	local notify = require("notify")
	notify.setup(opts)
	vim.notify = notify
end

function M.noice_opts()
	return {
		lsp = {
			progress = { enabled = true },
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
		},
		routes = {
			{
				filter = { event = "lsp", kind = "progress" },
				opts = { skip = true },
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			lsp_doc_border = true,
		},
	}
end

return M
