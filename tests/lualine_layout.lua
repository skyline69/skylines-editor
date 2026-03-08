local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local statusline = require("user.statusline")

local opts = statusline.opts()

assert(opts.options.globalstatus == true, "lualine should use a global statusline")
assert(opts.options.section_separators.left == "", "lualine should keep a flat section style")
assert(opts.options.section_separators.right == "", "lualine should keep a flat section style")
assert(vim.tbl_contains(opts.options.disabled_filetypes.statusline, "alpha"), "alpha should not render lualine")
assert(opts.options.theme.normal.c.bg == "#151b24", "lualine should use a dedicated Carbonfox-style panel background")
assert(opts.options.theme.normal.x.bg == "#151b24", "right-side statusline sections should share the panel background")
assert(opts.options.theme.inactive.c.bg == "#151b24", "inactive statuslines should keep the same panel background")

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/apps/api/src", "p")
vim.fn.writefile({ "console.log('x')" }, root .. "/package.json")
vim.fn.writefile({ "export const x = 1" }, root .. "/apps/api/src/example.ts")

local old_cwd = vim.uv.cwd()
vim.cmd.cd(root)

local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(bufnr, root .. "/apps/api/src/example.ts")

local root_name = statusline.project_root(bufnr)
local file_path = statusline.file_path(bufnr)

assert(root_name == vim.fs.basename(root), "project_root should show the project directory name")
assert(file_path == "apps/api/src/example.ts", "file_path should be relative to the detected project root")

vim.cmd.cd(old_cwd)

assert(statusline.lsp_activity_status() == "", "lsp_activity_status should be empty when noice progress is unavailable")

package.loaded["noice.lsp.progress"] = {
	_progress = {
		["rust-analyzer:1"] = {
			opts = {
				progress = {
					kind = "report",
					title = "Building CrateGraph",
				},
			},
		},
	},
}

assert(statusline.lsp_activity_status() == "lsp...", "lsp_activity_status should collapse active progress into a minimal marker")

package.loaded["noice.lsp.progress"] = {
	_progress = {
		["rust-analyzer:1"] = {
			opts = {
				progress = {
					kind = "end",
					title = "Building CrateGraph",
				},
			},
		},
	},
}

local notifications = {}
local original_notify = vim.notify
local original_get_client_by_id = vim.lsp.get_client_by_id

vim.notify = function(msg, level, opts)
	notifications[#notifications + 1] = {
		msg = msg,
		level = level,
		opts = opts,
	}
end

assert(statusline.lsp_activity_status() == "", "lsp_activity_status should hide completed progress")
assert(#notifications == 1, "completed progress should emit a completion notification")
assert(notifications[1].msg == "LSP ready", "completed progress without a resolved client should fall back to a generic message")

notifications = {}

vim.lsp.get_client_by_id = function(id)
	if id == 7 then
		return { name = "rust_analyzer" }
	end
	return nil
end

package.loaded["noice.lsp.progress"] = {
	_progress = {
		["rust-analyzer:2"] = {
			opts = {
				progress = {
					id = "rust-analyzer:2",
					client_id = 7,
					kind = "report",
					title = "Indexing",
				},
			},
		},
	},
}

assert(statusline.lsp_activity_status() == "lsp...", "active progress should still render the transient status")
assert(#notifications == 0, "active progress should not emit a completion notification")

package.loaded["noice.lsp.progress"] = {
	_progress = {
		["rust-analyzer:2"] = {
			opts = {
				progress = {
					id = "rust-analyzer:2",
					client_id = 7,
					kind = "end",
					title = "Indexing",
				},
			},
		},
	},
}

assert(statusline.lsp_activity_status() == "", "completed progress should disappear from the transient status")
assert(#notifications == 1, "completed progress should emit one completion notification")
assert(notifications[1].msg == "rust_analyzer ready", "completion notification should stay compact and client-focused")

assert(statusline.lsp_activity_status() == "", "re-rendering completed progress should stay hidden")
assert(#notifications == 1, "completed progress should not emit duplicate notifications")

vim.notify = original_notify
vim.lsp.get_client_by_id = original_get_client_by_id

local has_activity_component = false
for _, component in ipairs(opts.sections.lualine_x) do
	if type(component) == "table" and component[1] == statusline.lsp_activity_status then
		has_activity_component = true
		break
	end
end

assert(has_activity_component, "lualine_x should include the transient LSP activity component")
