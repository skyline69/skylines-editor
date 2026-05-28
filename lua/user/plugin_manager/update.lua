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

local function git_async(dir, args, cb)
	local cmd = vim.list_extend({ "git", "-C", dir }, args)
	vim.system(cmd, { text = true }, function(result)
		cb(vim.trim(result.stdout or ""), result.code)
	end)
end

-- Branch-tracked plugins: fetch only the default-branch tip (no other heads,
-- no tags), then fast-forward to FETCH_HEAD. Halves the network payload versus
-- a full `git fetch origin`.
local function update_branch(dir, done)
	git_async(dir, { "fetch", "--quiet", "--no-tags", "origin", "HEAD" }, function(_, code)
		if code ~= 0 then
			return done({ error = "fetch failed" })
		end
		git_async(dir, { "rev-parse", "HEAD", "FETCH_HEAD" }, function(out, rc)
			local old_rev, new_rev = out:match("^(%S+)%s+(%S+)")
			if rc ~= 0 or not old_rev or not new_rev then
				return done({ error = "rev-parse failed" })
			end
			if old_rev == new_rev then
				return done({})
			end
			git_async(dir, { "merge", "--ff-only", new_rev }, function(_, mc)
				if mc ~= 0 then
					return done({ error = "merge failed" })
				end
				done({ updated = { old = old_rev, new = new_rev } })
			end)
		end)
	end)
end

-- Version-pinned plugins resolve a tag inside the semver range, so fetch tags
-- only (skip head transfer) and check out the best match.
local function update_versioned(dir, version, done)
	git_async(
		dir,
		{ "fetch", "--quiet", "--no-write-fetch-head", "origin", "refs/tags/*:refs/tags/*" },
		function(_, code)
			if code ~= 0 then
				return done({ error = "fetch failed" })
			end
			git_async(dir, { "rev-parse", "HEAD" }, function(old_rev, rc)
				if rc ~= 0 then
					return done({ error = "rev-parse failed" })
				end
				git_async(dir, { "tag", "--list", "--sort=-v:refname" }, function(tags_raw, tc)
					if tc ~= 0 or tags_raw == "" then
						return done({})
					end
					local range_ok, range = pcall(vim.version.range, version)
					if not (range_ok and range) then
						return done({})
					end
					local match_tag
					for tag in tags_raw:gmatch("[^\n]+") do
						local ver_ok, ver = pcall(vim.version.parse, tag)
						if ver_ok and ver and range:has(ver) then
							match_tag = tag
							break
						end
					end
					if not match_tag then
						return done({})
					end
					git_async(dir, { "checkout", "--quiet", match_tag }, function(_, cc)
						if cc ~= 0 then
							return done({ error = "checkout failed" })
						end
						git_async(dir, { "rev-parse", "HEAD" }, function(new_rev, nc)
							if nc ~= 0 then
								return done({ error = "rev-parse failed" })
							end
							if new_rev ~= old_rev then
								done({ updated = { old = old_rev, new = new_rev, tag = match_tag } })
							else
								done({})
							end
						end)
					end)
				end)
			end)
		end
	)
end

local function process_plugin(name, lock_entry, done)
	local dir = pack_dir .. "/" .. name
	if not (vim.uv or vim.loop).fs_stat(dir) then
		-- Defer so the dispatch loop always sees uniform async completion.
		return vim.schedule(function()
			done({ error = "not installed" })
		end)
	end
	if lock_entry and lock_entry.version then
		update_versioned(dir, lock_entry.version, done)
	else
		update_branch(dir, done)
	end
end

local function run_builds(state, updated_names)
	for _, name in ipairs(updated_names) do
		local spec = state.registry:get(name)
		if spec and spec.build then
			local build = spec.build
			if type(build) == "function" then
				pcall(build, spec)
			elseif type(build) == "string" and build:sub(1, 1) ~= ":" then
				local args = vim.split(build, "%s+", { trimempty = true })
				if #args > 0 then
					vim.system(args, { cwd = pack_dir .. "/" .. name }):wait()
				end
			end
		end
	end
end

local MAX_CONCURRENT = 16

function M.update(state, callback)
	local lock = read_lock()
	local names = state.registry:names()
	local total = #names
	local results = {}

	if total == 0 then
		if callback then
			callback({})
		end
		return
	end

	local completed = 0
	local next_idx = 0
	local running = 0

	local function finish()
		local updated_names = {}
		for name, r in pairs(results) do
			if r.updated then
				updated_names[#updated_names + 1] = name
			end
		end
		if #updated_names > 0 then
			write_lock(lock)
			run_builds(state, updated_names)
		end
		if callback then
			callback(results)
		end
	end

	local pump
	local function on_done(name, result)
		results[name] = result
		if result.updated and lock[name] then
			lock[name].rev = result.updated.new
		end
		running = running - 1
		completed = completed + 1
		if completed == total then
			vim.schedule(finish)
		else
			pump()
		end
	end

	pump = function()
		while running < MAX_CONCURRENT and next_idx < total do
			next_idx = next_idx + 1
			local name = names[next_idx]
			running = running + 1
			process_plugin(name, lock[name], function(result)
				on_done(name, result)
			end)
		end
	end

	pump()
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
	local line_count = #lines
	local function win_config()
		local width = math.min(80, vim.o.columns - 4)
		local height = math.min(line_count + 2, 30, vim.o.lines - 4)
		return {
			relative = "editor",
			row = math.floor((vim.o.lines - height) / 2),
			col = math.floor((vim.o.columns - width) / 2),
			width = width,
			height = height,
			style = "minimal",
			border = "rounded",
			title = " SkylinePackUpdate ",
			footer = " q to close ",
			footer_pos = "right",
		}
	end

	local win = vim.api.nvim_open_win(buf, true, win_config())

	local resize_group = vim.api.nvim_create_augroup("SkylinePackUpdateResize", { clear = true })
	vim.api.nvim_create_autocmd("VimResized", {
		group = resize_group,
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_config(win, win_config())
			else
				vim.api.nvim_del_augroup_by_id(resize_group)
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = resize_group,
		buffer = buf,
		callback = function()
			vim.api.nvim_del_augroup_by_id(resize_group)
		end,
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
