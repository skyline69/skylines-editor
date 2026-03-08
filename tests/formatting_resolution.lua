local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local uv = vim.uv or vim.loop

local function mkdirp(path)
	assert(vim.fn.mkdir(path, "p") == 1 or vim.fn.isdirectory(path) == 1)
end

local function write(path, lines)
	mkdirp(vim.fn.fnamemodify(path, ":h"))
	local fd = assert(io.open(path, "w"))
	fd:write(table.concat(lines, "\n"))
	fd:write("\n")
	fd:close()
end

local function chmod_x(path)
	assert(uv.fs_chmod(path, 493)) -- 0755
end

local function make_buffer(filename, filetype)
	local bufnr = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(bufnr, filename)
	vim.bo[bufnr].filetype = filetype
	return bufnr
end

local root = vim.fn.tempname()
mkdirp(root)

local formatting = require("user.formatting")

local biome_root = root .. "/biome"
write(biome_root .. "/biome.json", { "{}", })
write(biome_root .. "/node_modules/.bin/biome", { "#!/bin/sh", "exit 0" })
chmod_x(biome_root .. "/node_modules/.bin/biome")
local biome_file = biome_root .. "/src/app.ts"
write(biome_file, { "const x = 1;" })

local biome_buf = make_buffer(biome_file, "typescript")
local biome_info = formatting.resolve(biome_buf)
assert(biome_info.source == "project", "biome project should use project formatter")
assert(biome_info.project_formatter == "biome", "biome config should select biome")
assert(vim.deep_equal(biome_info.formatters, { "skyline_biome" }), "biome project should resolve the custom local biome formatter")

local prettier_root = root .. "/prettier-missing"
write(prettier_root .. "/.prettierrc", { "{}", })
local prettier_file = prettier_root .. "/src/app.ts"
write(prettier_file, { "const x = 1;" })

local prettier_buf = make_buffer(prettier_file, "typescript")
local prettier_info = formatting.resolve(prettier_buf)
assert(prettier_info.source == "project-missing", "missing project formatter should fail loudly")
assert(prettier_info.project_formatter == "prettier", "prettier config should be detected")
assert(vim.deep_equal(prettier_info.formatters, {}), "missing project formatter should not silently fall back")
assert(prettier_info.lsp_format == "never", "missing project formatter should not fall back to LSP")

local lua_root = root .. "/lua-fallback"
local lua_file = lua_root .. "/init.lua"
write(lua_file, { "local x=1" })
local lua_buf = make_buffer(lua_file, "lua")
local lua_info = formatting.resolve(lua_buf)
assert(lua_info.source == "fallback", "lua without project formatter should use fallback formatters")
assert(vim.deep_equal(lua_info.formatters, { "stylua" }), "lua fallback should keep stylua")

local text_root = root .. "/text"
local text_file = text_root .. "/README.txt"
write(text_file, { "hello" })
local text_buf = make_buffer(text_file, "text")
local text_info = formatting.resolve(text_buf)
assert(text_info.source == "lsp-fallback", "unknown filetypes should fall back to LSP formatting")
assert(vim.deep_equal(text_info.formatters, {}), "unknown filetypes should not have direct formatters")
assert(text_info.lsp_format == "fallback", "unknown filetypes should use LSP as last fallback")

formatting.setup()
assert(vim.fn.exists(":SkylineFormatInfo") == 2, "SkylineFormatInfo command should be registered")

pcall(vim.api.nvim_del_user_command, "SkylineFormatInfo")
package.loaded["user.setup"] = nil
require("user.setup").setup()
assert(vim.fn.exists(":SkylineFormatInfo") == 2, "SkylineFormatInfo should be available through normal startup setup")
