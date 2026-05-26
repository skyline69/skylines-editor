local M = {}

local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"
local lockfile = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"

local function read_lock()
	local raw = vim.fn.readfile(lockfile)
	if #raw == 0 then
		return {}
	end
	local ok, data = pcall(vim.json.decode, table.concat(raw, "\n"))
	return ok and data.plugins or {}
end

local function write_lock(plugins)
	local sorted = {}
	for name in pairs(plugins) do
		sorted[#sorted + 1] = name
	end
	table.sort(sorted)

	local entries = {}
	for _, name in ipairs(sorted) do
		local p = plugins[name]
		local fields = { ('    "rev": %s'):format(vim.json.encode(p.rev)) }
		fields[#fields + 1] = ('    "src": %s'):format(vim.json.encode(p.src))
		if p.version then
			fields[#fields + 1] = ('    "version": %s'):format(vim.json.encode(p.version))
		end
		entries[#entries + 1] = ("    %s: {\n%s\n    }"):format(vim.json.encode(name), table.concat(fields, ",\n"))
	end

	local json = '{\n  "plugins": {\n' .. table.concat(entries, ",\n") .. "\n  }\n}\n"
	vim.fn.writefile(vim.split(json, "\n", { plain = true }), lockfile)
end

local function git(plugin_dir, args)
	local cmd = vim.list_extend({ "git", "-C", plugin_dir }, args)
	local result = vim.system(cmd):wait()
	return vim.trim(result.stdout or ""), result.code
end

local function check_and_pull(name, lock_entry)
	local dir = pack_dir .. "/" .. name
	local old_rev = git(dir, { "rev-parse", "HEAD" })

	if lock_entry and lock_entry.version then
		local tags_raw = git(dir, { "tag", "--list", "--sort=-v:refname" })
		if tags_raw ~= "" then
			local range_ok, range = pcall(vim.version.range, lock_entry.version)
			if range_ok and range then
				for tag in tags_raw:gmatch("[^\n]+") do
					local ver_ok, ver = pcall(vim.version.parse, tag)
					if ver_ok and ver and range:has(ver) then
						git(dir, { "checkout", "--quiet", tag })
						local new_rev = git(dir, { "rev-parse", "HEAD" })
						if new_rev ~= old_rev then
							return { old = old_rev, new = new_rev, tag = tag }
						end
						return nil
					end
				end
			end
		end
		return nil
	end

	local new_rev = git(dir, { "rev-parse", "origin/HEAD" })
	if new_rev == "" then
		local branch = git(dir, { "symbolic-ref", "--short", "HEAD" })
		if branch == "" then
			branch = "main"
		end
		new_rev = git(dir, { "rev-parse", "origin/" .. branch })
	end

	if new_rev == old_rev or new_rev == "" then
		return nil
	end

	local _, merge_code = git(dir, { "merge", "--ff-only", new_rev })
	if merge_code ~= 0 then
		return nil, "merge failed"
	end

	return { old = old_rev, new = new_rev }
end

function M.update(state, callback)
	local lock = read_lock()
	local names = state.registry:names()
	local total = #names
	local completed = 0
	local results = {}

	if total == 0 then
		if callback then
			callback({})
		end
		return
	end

	for _, name in ipairs(names) do
		local dir = pack_dir .. "/" .. name
		local stat = (vim.uv or vim.loop).fs_stat(dir)
		if not stat then
			results[name] = { error = "not installed" }
			completed = completed + 1
			if completed == total then
				vim.schedule(function()
					if callback then
						callback(results)
					end
				end)
			end
		else
			vim.system({ "git", "-C", dir, "fetch", "--quiet", "origin" }, {}, function(fetch_result)
				vim.schedule(function()
					local update_info, err
					if fetch_result.code ~= 0 then
						err = "fetch failed"
					else
						update_info, err = check_and_pull(name, lock[name])
					end
					results[name] = { updated = update_info, error = err }

					if update_info and lock[name] then
						lock[name].rev = update_info.new
					end

					completed = completed + 1
					if completed == total then
						local updated_names = {}
						for n, r in pairs(results) do
							if r.updated then
								updated_names[#updated_names + 1] = n
							end
						end

						if #updated_names > 0 then
							write_lock(lock)
							for _, n in ipairs(updated_names) do
								local spec = state.registry:get(n)
								if spec and spec.build then
									local build_dir = pack_dir .. "/" .. n
									local build = spec.build
									if type(build) == "function" then
										pcall(build, spec)
									elseif type(build) == "string" and build:sub(1, 1) ~= ":" then
										local args = vim.split(build, "%s+", { trimempty = true })
										if #args > 0 then
											vim.system(args, { cwd = build_dir }):wait()
										end
									end
								end
							end
						end

						if callback then
							callback(results)
						end
					end
				end)
			end)
		end
	end
end

local ns = vim.api.nvim_create_namespace("SkylinePackUpdate")

function M.open_results(results)
	local names = {}
	for name in pairs(results) do
		names[#names + 1] = name
	end
	table.sort(names)

	local updated, failed, uptodate = 0, 0, 0
	for _, r in pairs(results) do
		if r.error then
			failed = failed + 1
		elseif r.updated then
			updated = updated + 1
		else
			uptodate = uptodate + 1
		end
	end

	local lines = {
		("Skyline Pack Update — %d updated, %d up-to-date, %d failed"):format(updated, uptodate, failed),
		"",
	}
	local highlights = {}

	for _, name in ipairs(names) do
		local r = results[name]
		local line_idx = #lines
		if r.error then
			lines[#lines + 1] = ("✗  %-30s  %s"):format(name, r.error)
			highlights[#highlights + 1] = { line_idx, "DiagnosticError" }
		elseif r.updated then
			local detail = r.updated.old:sub(1, 7) .. " → " .. r.updated.new:sub(1, 7)
			if r.updated.tag then
				detail = detail .. " (" .. r.updated.tag .. ")"
			end
			lines[#lines + 1] = ("✓  %-30s  %s"):format(name, detail)
			highlights[#highlights + 1] = { line_idx, "DiagnosticOk" }
		else
			lines[#lines + 1] = ("·  %-30s  up-to-date"):format(name)
			highlights[#highlights + 1] = { line_idx, "Comment" }
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, ns, hl[2], hl[1], 0, -1)
	end
	vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	local height = math.min(#lines + 2, 30)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - 80) / 2),
		width = 80,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " SkylinePackUpdate ",
		footer = " q to close ",
		footer_pos = "right",
	})
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

function M.register_command(state)
	vim.api.nvim_create_user_command("SkylinePackUpdate", function()
		vim.notify("Updating plugins…", vim.log.levels.INFO, { title = "Skyline Pack" })
		M.update(state, function(results)
			M.open_results(results)
		end)
	end, {
		desc = "Fetch and update all Skyline-managed plugins",
	})
end

return M
