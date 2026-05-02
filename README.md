# dotfiles

Personal Linux dotfiles centered on a Hyprland desktop, `zsh`, `tmux`, and Neovim.

## Included

| Path | Destination |
|---|---|
| `zshrc` | `~/.zshrc` |
| `tmux.conf` | `~/.tmux.conf` |
| `gitconfig` | `~/.gitconfig` |
| `nvim/` | `~/.config/nvim/` |
| `hypr/` | `~/.config/hypr/` |
| `waybar/` | `~/.config/waybar/` |
| `kitty/` | `~/.config/kitty/` |
| `atuin/` | `~/.config/atuin/` |
| `poshthemes/` | `~/.poshthemes/` |

## Quick install

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:

- symlink tracked configs into `$HOME`
- back up replaced real files with a timestamped `.bak.<timestamp>` suffix
- install core packages on Arch or WSL
- clone shell and tmux plugins
- install `nvm`, `bun`, and `atuin` if missing

## Arch desktop coverage

The Arch path now includes packages needed for the tracked desktop config:

- Hyprland, Hypridle, Hyprlock, Hyprpaper
- Waybar, Wofi, Dunst
- Kitty, tmux, Neovim
- clipboard, screenshot, audio, brightness, and network helpers

## Machine-local overrides

Keep secrets and machine-specific values in `~/.zshrc.local`:

```bash
export MY_API_KEY="..."
export WAYBAR_WEATHER_LAT="31.6138"
export WAYBAR_WEATHER_LON="76.3579"
export WAYBAR_WEATHER_LABEL="Bangana, Himachal Pradesh"
```

`waybar/weather.sh` reads those weather variables if you want a different location.

## Wallpaper note

The Hyprland config expects an optional wallpaper at:

```bash
~/.config/hypr/wallpaper.jpg
```

If it is missing, startup continues without wallpaper assignment.

## WSL note

The repo still links shell, tmux, git, Neovim, Kitty, and Atuin on WSL, but the Hyprland and Waybar pieces are Linux desktop specific.
