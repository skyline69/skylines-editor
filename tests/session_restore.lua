local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local bundles = require("user.bundles")

local function find_repo(specs, repo)
	for _, spec in ipairs(specs) do
		if spec == repo or spec[1] == repo then
			return spec
		end
	end
	return nil
end

local specs = bundles.resolve_plugins({ "core", "ui" }, {}, {})
local auto_session = assert(find_repo(specs, "rmagatti/auto-session"), "auto-session spec should exist")
local opts = auto_session.opts or {}

assert(opts.auto_save == true, "auto-session should save sessions on exit")
assert(opts.auto_restore == true, "auto-session should restore sessions on startup")
assert(opts.auto_restore_last_session == false, "auto-session should not restore an unrelated last session")
assert(opts.git_use_branch_name == false, "auto-session should keep one session per project directory")
assert(opts.cwd_change_handling == false, "auto-session should not swap sessions on cwd changes")
assert(opts.args_allow_single_directory == true, "auto-session should restore for a single directory launch")
assert(opts.args_allow_files_auto_save == false, "auto-session should not autosave when launched with explicit files")
assert(type(opts.bypass_save_filetypes) == "table", "auto-session should bypass dashboard-only filetypes")
assert(vim.tbl_contains(opts.bypass_save_filetypes, "alpha"), "auto-session should ignore alpha-only sessions")
assert(type(opts.close_filetypes_on_save) == "table", "auto-session should close transient windows before saving")
assert(vim.tbl_contains(opts.close_filetypes_on_save, "checkhealth"), "auto-session should close checkhealth before saving")

vim.cmd("source init.lua")
local expected_sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
assert(vim.o.sessionoptions == expected_sessionoptions, "sessionoptions should preserve tabs, folds, terminals, and local options")
