local M = {}

local function open_setup(opts)
	local profile = require("user.profile")
	require("user.setup_tui").open({
		profile = profile.load() or profile.default_minimal(),
		first_run = opts and opts.first_run or false,
	})
end

function M.setup()
	require("user.formatting").setup()

	vim.api.nvim_create_user_command("SkylineSetup", function()
		open_setup()
	end, { desc = "Open Skyline setup" })

	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			if vim.g.skyline_bootstrap_pending and #vim.api.nvim_list_uis() > 0 then
				vim.schedule(function()
					open_setup({ first_run = true })
				end)
			end
		end,
	})
end

return M
