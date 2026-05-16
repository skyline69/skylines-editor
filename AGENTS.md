# Repository Guidelines

## Project Structure & Module Organization
This repository is a small Neovim configuration written in Lua. `init.lua` is the entrypoint and loads modules from `lua/user/`. Keep behavior split by concern: `options.lua` for editor settings, `keymaps.lua` for mappings, `autocmds.lua` for events, `plugins.lua` for plugin-manager startup, `bundles.lua` and `qol.lua` for plugin specs, and focused modules such as `lsp.lua`, `colors.lua`, and `alpha.lua` for feature-specific setup. Healthcheck lives under `lua/skyline/health.lua` and is invoked with `:checkhealth skyline`.

## Plugin Manager
`lua/user/plugin_manager.lua` provides a compatibility layer that:

- Uses native `vim.pack` on Neovim 0.12+ (lockfile: `nvim-pack-lock.json`).
- Falls back to lazy.nvim on older Neovim (lockfile: `lazy-lock.json`, gitignored).
- Force the fallback with `SKYLINE_PLUGIN_MANAGER=lazy nvim`.

Specs accept lazy.nvim-style fields: `event`, `cmd`, `ft`, `keys`, `lazy`, `priority`, `dependencies`, `opts`, `config`, `build`, `main`. Plugins whose Lua module name differs from their repo name should declare it explicitly with `main = "module_name"` in the spec.

Use `:SkylinePackStatus` to see per-plugin load status and captured errors.

## Build, Test, and Development Commands
Use headless Neovim commands to validate changes without starting a UI:

- `nvim --headless "+lua if vim.pack then vim.pack.update(nil, { force = true }) else vim.cmd('Lazy! sync') end" +qa`: install or update plugins declared in the active bundle profile.
- `nvim --headless "+checkhealth skyline" +qa`: verify profile, manager, treesitter CLI, and mason tooling.
- `nvim --headless "+checkhealth" +qa`: run all Neovim health checks after changing plugins, LSP, or external tools.
- `nvim --headless "+qa"`: verify the config starts cleanly.
- `for t in tests/*.lua; do nvim --headless -l "$t"; done`: run the headless test suite.
- `stylua init.lua lua/user lua/skyline tests`: format Lua files before finishing a change.

If a change affects a plugin feature, also open Neovim normally and exercise that path manually.

## Coding Style & Naming Conventions
Match the existing Lua style: tabs for indentation, concise comments, and small modules with one clear purpose. Use lowercase filenames under `lua/user/` and prefer descriptive names such as `colors.lua` or `autocmds.lua`. Keep plugin-specific setup near the owning module; avoid turning `plugins.lua` into a large block of inline config unless the setup is trivial.

## Testing Guidelines
Tests live under `tests/` and run via `nvim --headless -l <test>`. Add a test next to the closest existing one when changing public behavior in `user/plugin_manager.lua`, `user/statusline.lua`, `user/languages.lua`, `user/profile.lua`, or related setup. For LSP or formatter changes, confirm required tools are installed through Mason or documented as external dependencies.

## Commit & Pull Request Guidelines
Recent history favors short, direct subjects, often conventional-style, for example `fix: neovim config warning`, `Update lsp config`, and `Add autosession`. Keep commits narrowly scoped. Pull requests should explain the user-facing effect, list any new dependencies, and include screenshots or terminal output when the change alters UI, startup, or health status.

## Agent-Specific Instructions
Prefer minimal diffs and preserve unrelated user edits. Do not reorder plugin specs or rewrite formatting without need. When adding tooling, note whether it is managed by Mason, by `make`, or requires a system package.
