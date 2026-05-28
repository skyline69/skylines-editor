local M = {}

local profile = require("user.profile").ensure()
local selected = require("user.languages").resolve(profile.languages)

-- language id -> (filetype -> linter names)
local catalog = {
	go = {
		go = { "golangcilint" },
	},
}

-- filetype -> linter names, limited to the active profile's languages
local function active_linters_by_ft()
	local out = {}
	for _, id in ipairs(selected.languages) do
		local by_ft = catalog[id]
		if by_ft then
			for ft, linters in pairs(by_ft) do
				out[ft] = vim.list_extend(out[ft] or {}, vim.deepcopy(linters))
			end
		end
	end
	return out
end

local linters_by_ft = active_linters_by_ft()

local function linter_executable(lint, name)
	local linter = lint.linters[name]
	if type(linter) == "function" then
		linter = linter()
	end
	local cmd = linter and linter.cmd
	if type(cmd) == "function" then
		cmd = cmd()
	end
	return type(cmd) == "string" and vim.fn.executable(cmd) == 1
end

-- golangci-lint analyses whole packages and is slow, so only run linters whose
-- binary actually resolves; a half-installed mason tree should stay quiet.
local function available_linters(lint, ft)
	local names = linters_by_ft[ft]
	if not names then
		return {}
	end
	local out = {}
	for _, name in ipairs(names) do
		if linter_executable(lint, name) then
			out[#out + 1] = name
		end
	end
	return out
end

function M.lint()
	local ok, lint = pcall(require, "lint")
	if not ok then
		return
	end
	local ft = vim.bo[vim.api.nvim_get_current_buf()].filetype
	local names = available_linters(lint, ft)
	if #names == 0 then
		return
	end
	-- golangci-lint exits non-zero (e.g. 7 = ErrorWasLogged) even when it emits
	-- valid JSON results, which nvim-lint would otherwise surface as a spurious
	-- error notification on every run. The diagnostics still parse from stdout.
	if lint.linters.golangcilint then
		lint.linters.golangcilint.ignore_exitcode = true
	end
	lint.try_lint(names)
end

function M.setup()
	local ok, lint = pcall(require, "lint")
	if not ok then
		return
	end

	for ft, names in pairs(linters_by_ft) do
		lint.linters_by_ft[ft] = names
	end

	if next(linters_by_ft) then
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			group = vim.api.nvim_create_augroup("SkylineLint", { clear = true }),
			callback = function()
				M.lint()
			end,
		})
	end

	if vim.fn.exists(":SkylineLintInfo") == 0 then
		vim.api.nvim_create_user_command("SkylineLintInfo", function()
			local has_lint, lint_mod = pcall(require, "lint")
			local ft = vim.bo[vim.api.nvim_get_current_buf()].filetype
			local configured = linters_by_ft[ft] or {}
			local avail = has_lint and available_linters(lint_mod, ft) or {}
			local lines = {
				("filetype: %s"):format(ft ~= "" and ft or "none"),
				("configured: %s"):format(#configured > 0 and table.concat(configured, ", ") or "none"),
				("available: %s"):format(#avail > 0 and table.concat(avail, ", ") or "none"),
			}
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Skyline Lint Info" })
		end, { desc = "Show active linters for the current buffer" })
	end
end

return M
