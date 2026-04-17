# dotfiles

Personal dotfiles for zsh + Neovim (LazyVim) + tmux setup.
Targets **Arch Linux (Hyprland/Wayland)** — also works on WSL Ubuntu with minor tweaks.

## Quick Install

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The script will:
- Symlink all configs into place (backs up existing files as `.bak`)
- Install packages via `pacman` + `yay` (Arch) or `apt` (WSL)
- Clone zsh plugins, tmux-resurrect
- Install nvm, bun, atuin

## What's Included

| File/Dir | Destination | Notes |
|---|---|---|
| `zshrc` | `~/.zshrc` | zsh config, aliases, plugins |
| `tmux.conf` | `~/.tmux.conf` | Wayland clipboard (`wl-copy`) |
| `gitconfig` | `~/.gitconfig` | Personal git identity |
| `nvim/` | `~/.config/nvim/` | LazyVim config + locked plugins |
| `poshthemes/` | `~/.poshthemes/` | oh-my-posh prompt theme |

## Secrets / Machine-Specific Config

Put machine-specific env vars in `~/.zshrc.local` — this file is **not tracked in git**:

```bash
# ~/.zshrc.local
export MY_API_KEY="..."
```

## WSL Notes

`tmux.conf` uses `wl-copy` (Wayland). On WSL, change it to `clip.exe`:
```
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"
```

## Stack

- **Shell**: zsh + oh-my-posh + zsh-autosuggestions + zsh-syntax-highlighting + atuin + zoxide
- **Editor**: Neovim (LazyVim) with telescope, lualine, noice, org-roam
- **Terminal**: Kitty + tmux (mellow dark theme)
- **CLI tools**: bat, eza, yazi, fzf, ripgrep, fd
