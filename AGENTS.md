# Repository Guidelines

## Project Structure & Module Organization
This repository is a small Neovim configuration written in Lua. `init.lua` is the entrypoint and loads modules from `lua/user/`. Keep behavior split by concern: `options.lua` for editor settings, `keymaps.lua` for mappings, `autocmds.lua` for events, `plugins.lua` for lazy.nvim plugin specs, and focused modules such as `lsp.lua`, `colors.lua`, and `alpha.lua` for feature-specific setup.

## Build, Test, and Development Commands
Use headless Neovim commands to validate changes without starting a UI:

- `nvim --headless "+Lazy! sync" +qa`: install or update plugins declared in `lua/user/plugins.lua`.
- `nvim --headless "+checkhealth" +qa`: run Neovim health checks after changing plugins, LSP, or external tools.
- `nvim --headless "+qa"`: verify the config starts cleanly.
- `stylua init.lua lua/user`: format Lua files before finishing a change.

If a change affects a plugin feature, also open Neovim normally and exercise that path manually.

## Coding Style & Naming Conventions
Match the existing Lua style: tabs for indentation, concise comments, and small modules with one clear purpose. Use lowercase filenames under `lua/user/` and prefer descriptive names such as `colors.lua` or `autocmds.lua`. Keep plugin-specific setup near the owning module; avoid turning `plugins.lua` into a large block of inline config unless the setup is trivial.

## Testing Guidelines
There is no formal automated test suite in this repo. Agents should treat startup validation as the baseline: run headless launch, `:checkhealth`, and any command needed to load the changed feature. For LSP or formatter changes, confirm required tools are installed through Mason or documented as external dependencies.

## Commit & Pull Request Guidelines
Recent history favors short, direct subjects, often conventional-style, for example `fix: neovim config warning`, `Update lsp config`, and `Add autosession`. Keep commits narrowly scoped. Pull requests should explain the user-facing effect, list any new dependencies, and include screenshots or terminal output when the change alters UI, startup, or health status.

## Agent-Specific Instructions
Prefer minimal diffs and preserve unrelated user edits. Do not reorder plugin specs or rewrite formatting without need. When adding tooling, note whether it is managed by Mason, by `make`, or requires a system package.
