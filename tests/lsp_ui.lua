local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local lsp_ui = require("user.lsp_ui")

assert(lsp_ui.activity_status() == "", "activity_status should be empty when noice progress is unavailable")

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

assert(lsp_ui.activity_status() == "lsp...", "activity_status should collapse active progress into a minimal marker")

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

assert(lsp_ui.activity_status() == "", "completed progress should disappear from the transient status")
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

assert(lsp_ui.activity_status() == "lsp...", "active progress should not emit a completion notification")
assert(#notifications == 0, "active progress should not notify")

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

assert(lsp_ui.activity_status() == "", "completed progress should stay hidden")
assert(#notifications == 1, "completed progress should emit one notification")
assert(notifications[1].msg == "rust_analyzer ready", "completion notification should stay compact and client-focused")

assert(lsp_ui.activity_status() == "", "re-rendering completed progress should stay hidden")
assert(#notifications == 1, "completed progress should not emit duplicate notifications")

vim.notify = original_notify
vim.lsp.get_client_by_id = original_get_client_by_id
