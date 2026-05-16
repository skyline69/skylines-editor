-----------------------------------------------------------------------
--  Resolve active bundle profile before loading plugins
-----------------------------------------------------------------------
local profile = require("user.profile").ensure()
vim.g.skyline_active_bundles = profile.features
vim.g.skyline_active_languages = profile.languages
vim.g.skyline_active_qol = profile.qol

local specs = require("user.bundles").resolve_plugins(profile.features, profile.languages, profile.qol)
require("user.plugin_manager").setup(specs)
