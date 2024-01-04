require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff" },
		javascript = { "prettier" },
		rust = { "rustfmt --edition 2021" },
		c = { "clangd" },
		cpp = { "clangd" },
		sql = { "sleek" },
	},
	formatters = {
		sleek = {
			command = "sleek",
			args = { "$FILENAME" },
			stdin = false,
		},
		-- other formatters
	},
	--
})

vim.api.nvim_create_user_command("Format", function(args)
	local range = nil
	if args.count ~= -1 then
		local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
		range = {
			start = { args.line1, 0 },
			["end"] = { args.line2, end_line:len() },
		}
	end
	require("conform").format({ async = true, lsp_fallback = true, range = range })
end, { range = true })

