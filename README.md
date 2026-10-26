# dotfiles

zsh (oh-my-zsh + autosuggestions), tmux, Neovim (LSP for TS/JS/React, Telescope) and herdr,
managed with [chezmoi](https://chezmoi.io). Works on macOS and Linux/WSL (Ubuntu).

## New machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply kenjinp
```

This installs chezmoi into `~/.local/bin`, clones this repo, asks one question
(is a Nerd Font your terminal font?), then:

1. installs packages (`run_onchange_before_10-install-packages.sh.tmpl`)
   - macOS: Homebrew, neovim, tmux, ripgrep, fd, node, JetBrainsMono Nerd Font
   - Linux: apt packages, Neovim 0.11+ in `~/.local/opt`, Node via nvm, zsh as login shell
2. writes the config files and clones oh-my-zsh and the tmux plugins (`.chezmoiexternal.toml`)
3. installs Neovim plugins at the versions in `lazy-lock.json`, highlighting parsers and
   language servers (`run_onchange_after_20-nvim-plugins.sh.tmpl`)

Open a new terminal afterwards. On macOS, set the terminal font to "JetBrainsMono Nerd Font".

## Everyday use

| Task | Command |
|---|---|
| Edit a config and apply it | `chezmoi edit --apply ~/.zshrc` |
| Copy a change made in place back into the repo | `chezmoi re-add` |
| See what would change | `chezmoi diff` |
| Commit and push | `chezmoi cd`, then `git add -A && git commit && git push` |
| Pull and apply on another machine | `chezmoi update` |
| Change the Nerd Font answer | set `nerdFont` in `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply` |

`~/.config/nvim/lazy-lock.json` is a symlink to `nvim-lazy-lock.json` in this repo, so
`:Lazy update` changes the repo directly: commit it to pin the new plugin versions everywhere.

## Layout

| Source | Target |
|---|---|
| `dot_zshrc` | `~/.zshrc` (machine-only settings go in untracked `~/.zshrc.local`) |
| `dot_tmux.conf.tmpl` | `~/.tmux.conf` (prefix `Ctrl-s`) |
| `dot_config/nvim/` | `~/.config/nvim/` (`lua/machine.lua` is rendered from `[data]` in `~/.config/chezmoi/chezmoi.toml`) |
| `dot_config/nvim/plugins/ascii-splash.nvim/` | local plugin: random Neovim logo from ascii.nvim on the start screen |
| `nvim-lazy-lock.json` | symlinked as `~/.config/nvim/lazy-lock.json` |
| `dot_config/herdr/config.toml` | `~/.config/herdr/config.toml` (prefix `Ctrl-s`) |
| `.chezmoiexternal.toml` | oh-my-zsh, zsh-autosuggestions, TPM and tmux plugins |
