# Runtime dependencies

`bootstrap.sh` installs the portable dependencies below. This document explains what remains external and why.

The dotfiles repository stores configuration, not third-party programs or generated package trees. Install the tools you use before applying the matching manifest entries.

## Core

- zsh, bash, Git, tmux, Neovim, jq, ripgrep, fd, fzf, curl, `bc`, `flock` (util-linux) and ImageMagick
- zoxide, Atuin, oh-my-posh, bat, eza and yazi for the interactive zsh setup
- `clip.exe` from WSL for tmux clipboard integration
- a Nerd Font for prompt, dashboard and status-line glyphs

## Development and operations

- Go, Node through nvm, npm, bun and Python
- kubectl, Helm, k9s, minikube, Velero and glab as needed
- `code-review-graph` installed through pipx for the Codex hooks and Windsurf/Copilot MCP entries
- Doom Emacs installed at `~/.config/emacs`; only the user config in `~/.config/doom` is tracked
- the optional local `~/dev/org-roam-ui.nvim` checkout; its Neovim spec disables itself when the checkout is absent

## Agent tools

- Claude Code, Codex, Gemini CLI and OpenCode
- `~/.local/bin/yum-litellm-key-helper`, the external compiled helper called by the tracked robust wrapper
- Claude plugins listed in `claude/plugins.txt`; plugin caches and absolute install paths are intentionally not copied
- Claude global MCP servers are recorded in `claude/mcp-servers.json`; add them through the CLI instead of replacing the stateful `~/.claude.json`

## Shell/plugin directories

Install `zsh-autosuggestions` and `zsh-syntax-highlighting` under `~/.zsh/plugins`. Third-party plugin source and tmux-resurrect are dependencies, not personal configuration, so they are not vendored here.
