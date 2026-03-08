local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

package.loaded["user.keymaps"] = nil

local loaded_plugins = {}
package.loaded["lazy"] = {
	load = function(opts)
		loaded_plugins[#loaded_plugins + 1] = opts.plugins[1]
		if opts.plugins[1] == "telescope.nvim" then
			package.loaded["telescope.builtin"] = {
				find_files = function()
					_G.skyline_test_picker = "find_files"
				end,
			}
		elseif opts.plugins[1] == "nvim-tree.lua" then
			vim.api.nvim_create_user_command("NvimTreeToggle", function()
				_G.skyline_tree_opened = true
			end, {})
		end
	end,
}

require("user.keymaps")

local ff = vim.fn.maparg("<leader>ff", "n", false, true)
assert(type(ff.callback) == "function", "find files mapping should expose a callback")
ff.callback()
assert(loaded_plugins[1] == "telescope.nvim", "find files should load telescope on demand")
assert(_G.skyline_test_picker == "find_files", "find files should invoke telescope after loading")

local tree = vim.fn.maparg("<leader>t", "n", false, true)
assert(type(tree.callback) == "function", "tree mapping should expose a callback")
tree.callback()
assert(loaded_plugins[2] == "nvim-tree.lua", "tree mapping should load nvim-tree on demand")
assert(_G.skyline_tree_opened == true, "tree mapping should execute NvimTreeToggle after loading")

local diffview = vim.fn.maparg("<leader>dv", "n", false, true)
assert(diffview.rhs == "<cmd>DiffviewOpen<CR>", "diffview mapping should stay command-based so Lazy cmd stubs can load the plugin")

pcall(vim.api.nvim_del_user_command, "NvimTreeToggle")
