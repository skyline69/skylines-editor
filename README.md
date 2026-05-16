# Skyline's Editor (NeoVim Setup)

> Note: This is an old image. It looks better now.
![start-up-screen](https://github.com/skyline69/skylines-editor/assets/67526259/cac48334-002e-4634-ac9c-5e77a0eeb620)

## Features
![features](https://github.com/skyline69/skylines-editor/assets/67526259/0e01f9c7-7b53-4326-8d28-3723818629ed)
- ✅ Native LSP Built-in (<s>Very</s> Blazingly fast)
- ✅ Cool image on README
- ✅ 99.1% Pure Lua
- ✅ [Telescope](https://github.com/nvim-telescope/telescope.nvim) built-in
- ✅ [Nvim-Tree](https://github.com/nvim-tree/nvim-tree.lua) built-in
- ✅ [Neovide](https://neovide.dev/) compatible

## Demo (old)
[![asciicast](https://asciinema.org/a/636243.svg)](https://asciinema.org/a/636243)

## Prequisites
- [NeoVim](https://neovim.io/)
- Native `vim.pack` on Neovim 0.12+, with [Lazy](https://github.com/folke/lazy.nvim) used as the fallback package manager on older versions
- A [NerdFont](https://www.nerdfonts.com/)
- <s>Motivation to install everything</s> Installs everything itself!

## Plugin Manager
Skyline ships its own compatibility layer (`lua/user/plugin_manager.lua`):
- Native `vim.pack` is used on Neovim 0.12+. Lockfile: `nvim-pack-lock.json` (tracked).
- Lazy.nvim is used as a fallback for older Neovim. Lockfile: `lazy-lock.json` (gitignored).
- Force the fallback with `SKYLINE_PLUGIN_MANAGER=lazy nvim`.

Useful commands:
- `:SkylineSetup` — pick bundles, languages, QoL plugins.
- `:SkylinePackStatus` — show per-plugin load status and any errors.
- `:checkhealth skyline` — verify profile, manager, treesitter CLI, mason tooling.
