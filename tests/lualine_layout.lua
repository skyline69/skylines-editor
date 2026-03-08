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

local has_activity_component = false
local has_client_component = false
for _, component in ipairs(opts.sections.lualine_x) do
	if type(component) == "table" and component[1] == statusline.lsp_activity_status then
		has_activity_component = true
	elseif type(component) == "table" and component[1] == statusline.lsp_status then
		has_client_component = true
	end
end

assert(has_activity_component, "lualine_x should include the transient LSP activity component")
assert(has_client_component, "lualine_x should include the stable LSP client component")
