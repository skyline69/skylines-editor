local M = {}

local group = vim.api.nvim_create_augroup("skyline-indent", { clear = true })

local function has_editorconfig(bufnr)
	local ok, editorconfig = pcall(function()
		return vim.b[bufnr].editorconfig
	end)
	return ok
		and type(editorconfig) == "table"
		and (editorconfig.indent_style ~= nil or editorconfig.indent_size ~= nil or editorconfig.tab_width ~= nil)
end

local function maybe_apply_guess_indent(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	if has_editorconfig(bufnr) then
		vim.b[bufnr].skyline_indent_source = nil
		return
	end

	local before = {
		expandtab = vim.bo[bufnr].expandtab,
		tabstop = vim.bo[bufnr].tabstop,
		shiftwidth = vim.bo[bufnr].shiftwidth,
		softtabstop = vim.bo[bufnr].softtabstop,
	}

	require("guess-indent").set_from_buffer(bufnr, true, true)

	local changed = before.expandtab ~= vim.bo[bufnr].expandtab
		or before.tabstop ~= vim.bo[bufnr].tabstop
		or before.shiftwidth ~= vim.bo[bufnr].shiftwidth
		or before.softtabstop ~= vim.bo[bufnr].softtabstop

	vim.b[bufnr].skyline_indent_source = changed and "guess-indent" or nil
end

function M.inspect(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local source = "defaults"
	if has_editorconfig(bufnr) then
		source = "editorconfig"
	elseif vim.b[bufnr].skyline_indent_source then
		source = vim.b[bufnr].skyline_indent_source
	end

	return {
		source = source,
		filetype = vim.bo[bufnr].filetype,
		expandtab = vim.bo[bufnr].expandtab,
		tabstop = vim.bo[bufnr].tabstop,
		shiftwidth = vim.bo[bufnr].shiftwidth,
		softtabstop = vim.bo[bufnr].softtabstop,
		indentexpr = vim.bo[bufnr].indentexpr,
		editorconfig = has_editorconfig(bufnr) and vim.b[bufnr].editorconfig or nil,
	}
end

function M.setup()
	if vim.fn.exists(":SkylineIndentInfo") == 0 then
		vim.api.nvim_create_user_command("SkylineIndentInfo", function()
			local info = M.inspect(0)
			local lines = {
				("source: %s"):format(info.source),
				("filetype: %s"):format(info.filetype ~= "" and info.filetype or "none"),
				("expandtab: %s"):format(tostring(info.expandtab)),
				("tabstop: %s"):format(info.tabstop),
				("shiftwidth: %s"):format(info.shiftwidth),
				("softtabstop: %s"):format(info.softtabstop),
				("indentexpr: %s"):format(info.indentexpr ~= "" and info.indentexpr or "none"),
			}
			if info.editorconfig then
				lines[#lines + 1] = "editorconfig: " .. vim.inspect(info.editorconfig)
			end
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Skyline Indent Info" })
		end, { desc = "Show active indentation settings for the current buffer" })
	end

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		callback = function(args)
			maybe_apply_guess_indent(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufNewFile", {
		group = group,
		callback = function(args)
			if has_editorconfig(args.buf) then
				return
			end
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = group,
				buffer = args.buf,
				once = true,
				callback = function(write_args)
					maybe_apply_guess_indent(write_args.buf)
				end,
			})
		end,
	})
end

return M
