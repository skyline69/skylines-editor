---@class SkylineStatusline
local M = {}
local lsp_ui = require("user.lsp_ui")
local project = require("user.project")
local statusline_colors = require("user.statusline_colors")

local resolve_colors = statusline_colors.resolve

---@class SkylineStatuslineOpts
---@field options table
---@field sections table
---@field inactive_sections table

local mode_names = {
	n = "NORMAL",
	no = "OP",
	nov = "OP",
	noV = "OP",
	["no\22"] = "OP",
	niI = "NORMAL",
	niR = "NORMAL",
	niV = "NORMAL",
	nt = "NORMAL",
	v = "VISUAL",
	vs = "VISUAL",
	V = "V-LINE",
	Vs = "V-LINE",
	["\22"] = "V-BLOCK",
	["\22s"] = "V-BLOCK",
	s = "SELECT",
	S = "S-LINE",
	["\19"] = "S-BLOCK",
	i = "INSERT",
	ic = "INSERT",
	ix = "INSERT",
	R = "REPLACE",
	Rc = "REPLACE",
	Rx = "REPLACE",
	Rv = "V-REPLACE",
	c = "COMMAND",
	cv = "COMMAND",
	ce = "COMMAND",
	r = "PROMPT",
	rm = "MORE",
	["r?"] = "CONFIRM",
	["!"] = "SHELL",
	t = "TERMINAL",
}

local function current_buf(bufnr)
	return bufnr or vim.api.nvim_get_current_buf()
end

M.project_root_path = project.root_for_buf
M.project_root = project.root_name
M.file_path = project.relative_path

function M.mode_label()
	return (" %s "):format(mode_names[vim.fn.mode()] or "NORMAL")
end

function M.file_context()
	local bufnr = current_buf()
	local path = M.file_path(bufnr)
	local marks = {}

	if vim.bo[bufnr].modified then
		table.insert(marks, "+")
	end
	if vim.bo[bufnr].readonly then
		table.insert(marks, "ro")
	end

	if #marks == 0 then
		return path
	end

	return ("%s [%s]"):format(path, table.concat(marks, ","))
end

function M.package_status()
	if vim.bo.filetype ~= "json" or vim.fn.expand("%:t") ~= "package.json" then
		return ""
	end

	local ok, package_info = pcall(require, "package-info")
	if not ok or type(package_info.get_status) ~= "function" then
		return ""
	end

	local status = package_info.get_status()
	if status == nil then
		return ""
	end

	return status
end

function M.formatter_status()
	local ok, formatting = pcall(require, "user.formatting")
	if not ok then
		return ""
	end

	local resolved = formatting.resolve(current_buf())
	if not resolved then
		return ""
	end

	if resolved.project_formatter then
		return "fmt:" .. resolved.project_formatter
	end
	if resolved.formatters and resolved.formatters[1] then
		return "fmt:" .. resolved.formatters[1]
	end

	return ""
end

function M.lsp_status()
	local bufnr = current_buf()
	if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "" then
		return ""
	end

	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		return "lsp:…"
	end

	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end

	return "lsp:" .. table.concat(names, ",")
end

function M.lsp_activity_status()
	return lsp_ui.activity_status()
end

local function mode_palette(c, accent)
	return {
		a = { fg = c.bg, bg = accent, gui = "bold" },
		b = { fg = c.fg, bg = c.panel_alt },
		c = { fg = c.fg, bg = c.panel },
		x = { fg = c.muted, bg = c.panel },
		y = { fg = c.fg, bg = c.panel_alt },
		z = { fg = c.bg, bg = c.cyan, gui = "bold" },
	}
end

local function build_theme(c)
	local inactive_section = { fg = c.muted, bg = c.panel }
	return {
		normal = mode_palette(c, c.blue),
		insert = mode_palette(c, c.green),
		visual = mode_palette(c, c.purple),
		replace = mode_palette(c, c.orange),
		command = mode_palette(c, c.yellow),
		inactive = {
			a = inactive_section,
			b = inactive_section,
			c = inactive_section,
			x = inactive_section,
			y = inactive_section,
			z = inactive_section,
		},
	}
end

local function lualine_options(c)
	return {
		theme = build_theme(c),
		globalstatus = true,
		component_separators = { left = "·", right = "·" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "alpha" },
			winbar = { "alpha", "NvimTree" },
		},
		always_divide_middle = true,
	}
end

local function active_sections(c)
	return {
		lualine_a = {
			{ M.mode_label, padding = 0 },
		},
		lualine_b = {
			{ M.project_root, icon = "󰉋", color = { fg = c.blue, bg = c.panel_alt, gui = "bold" } },
			{ "branch", icon = "󰘬", color = { fg = c.purple, bg = c.panel_alt } },
			{
				"diff",
				colored = true,
				diff_color = {
					added = { fg = c.green },
					modified = { fg = c.yellow },
					removed = { fg = c.red },
				},
				symbols = { added = "+", modified = "~", removed = "-" },
			},
		},
		lualine_c = {
			{ M.file_context, color = { fg = c.fg, bg = c.panel } },
		},
		lualine_x = {
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
				sections = { "error", "warn", "info", "hint" },
				colored = true,
				update_in_insert = false,
			},
			{ M.formatter_status, color = { fg = c.orange } },
			{ M.lsp_activity_status, color = { fg = c.yellow } },
			{ M.lsp_status, color = { fg = c.cyan } },
			{ M.package_status, color = { fg = c.green } },
			{ "filetype", colored = true, icon_only = false },
		},
		lualine_y = {
			{ "progress", color = { fg = c.muted } },
		},
		lualine_z = {
			{ "location" },
		},
	}
end

local function inactive_sections(c)
	return {
		lualine_a = {},
		lualine_b = {
			{ M.project_root, icon = "󰉋", color = { fg = c.muted } },
		},
		lualine_c = {
			{ M.file_context, color = { fg = c.muted } },
		},
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	}
end

---@return table
function M.theme()
	return build_theme(resolve_colors())
end

---@return SkylineStatuslineOpts
function M.opts()
	local c = resolve_colors()
	return {
		options = lualine_options(c),
		sections = active_sections(c),
		inactive_sections = inactive_sections(c),
	}
end

function M.attach_colorscheme_refresh()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("SkylineStatuslineRefresh", { clear = true }),
		callback = function()
			local ok, lualine = pcall(require, "lualine")
			if ok and type(lualine.setup) == "function" then
				lualine.setup(M.opts())
			end
		end,
	})
end

return M
