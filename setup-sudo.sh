#!/usr/bin/env bash
# setup-sudo.sh — Run once in your terminal (needs sudo)
set -euo pipefail

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   kwant-dbg dotfiles — sudo setup               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── 1. pacman packages ────────────────────────────────────────
echo "==> [1/7] Installing pacman packages..."
sudo pacman -S --needed --noconfirm \
    zsh zoxide tmux neovim bat eza yazi fzf fd ripgrep jq atuin \
    kitty ghostty wl-clipboard cliphist brightnessctl \
    hyprland hypridle hyprlock hyprpaper waybar wofi grim slurp \
    playerctl networkmanager nm-connection-editor dunst \
    git curl wget

# ── 2. yay (AUR helper) ──────────────────────────────────────
echo ""
echo "==> [2/7] Checking yay..."
if ! command -v yay &>/dev/null; then
    echo "  Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    rm -rf /tmp/yay-install
    echo "  ✓ yay installed"
else
    echo "  ✓ yay already installed"
fi

# ── 3. AUR packages ──────────────────────────────────────────
echo ""
echo "==> [3/7] Installing AUR packages..."
yay -S --needed --noconfirm oh-my-posh-bin ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

# ── 4. Font cache ─────────────────────────────────────────────
echo ""
echo "==> [4/7] Refreshing font cache..."
fc-cache -fv

# ── 5. nvm ─────────────────────────────────────────────────────
echo ""
echo "==> [5/7] Checking nvm..."
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "  Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    echo "  ✓ nvm installed"
else
    echo "  ✓ nvm already installed"
fi

# ── 6. bun ─────────────────────────────────────────────────────
echo ""
echo "==> [6/7] Checking bun..."
if ! command -v bun &>/dev/null && [[ ! -f "$HOME/.bun/bin/bun" ]]; then
    echo "  Installing bun..."
    curl -fsSL https://bun.sh/install | bash
    echo "  ✓ bun installed"
else
    echo "  ✓ bun already installed"
fi

# ── 7. Default shell → zsh ────────────────────────────────────
echo ""
echo "==> Checking default shell..."
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo "  Changing default shell to zsh..."
    chsh -s "$ZSH_PATH"
    echo "  ✓ Default shell set to $ZSH_PATH"
else
    echo "  ✓ zsh already default shell"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅  All done!                                  ║"
echo "║                                                  ║"
echo "║   Next steps:                                    ║"
echo "║   1. Open a new terminal (or run: exec zsh)      ║"
echo "║   2. Open nvim — LazyVim will auto-install       ║"
echo "║   3. Add secrets to ~/.zshrc.local               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
