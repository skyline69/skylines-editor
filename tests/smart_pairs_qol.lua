local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local qol = require("user.qol")

local resolved = qol.resolve({ "autoclose" }, {})
local spec = resolved.specs[1]

assert(spec ~= nil, "autoclose QoL should resolve a plugin spec")
assert(spec[1] == "windwp/nvim-autopairs", "autoclose QoL should use nvim-autopairs")
assert(type(spec.opts) == "table", "smart pairs should configure nvim-autopairs explicitly")
assert(spec.opts.check_ts == true, "smart pairs should enable treesitter-aware checks")
assert(spec.opts.enable_check_bracket_line == false, "smart pairs should allow Enter between braces on the same line")
assert(spec.opts.fast_wrap == nil or spec.opts.fast_wrap == {}, "smart pairs migration should stay focused and avoid broad fast-wrap behavior")
