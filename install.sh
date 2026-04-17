#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=""

# ── Detect OS ────────────────────────────────────────────────
if [[ -f /etc/arch-release ]]; then
    OS="arch"
elif grep -qi microsoft /proc/version 2>/dev/null; then
    OS="wsl"
else
    echo "Unsupported OS. This script targets Arch Linux or WSL Ubuntu."
    exit 1
fi

echo "Detected OS: $OS"

# ── Helper ───────────────────────────────────────────────────
symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "  Backing up existing $dst → $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sf "$src" "$dst"
    echo "  Linked $dst"
}

# ── Symlink dotfiles ─────────────────────────────────────────
echo ""
echo "==> Linking dotfiles..."
symlink "$DOTFILES_DIR/zshrc"              "$HOME/.zshrc"
symlink "$DOTFILES_DIR/tmux.conf"          "$HOME/.tmux.conf"
symlink "$DOTFILES_DIR/gitconfig"          "$HOME/.gitconfig"
symlink "$DOTFILES_DIR/nvim"               "$HOME/.config/nvim"
symlink "$DOTFILES_DIR/poshthemes"         "$HOME/.poshthemes"

# ── Arch: install packages ───────────────────────────────────
if [[ "$OS" == "arch" ]]; then
    echo ""
    echo "==> Installing packages (pacman)..."
    sudo pacman -S --needed --noconfirm \
        zsh zoxide atuin bat eza yazi fzf ripgrep fd \
        tmux neovim kitty wl-clipboard git curl wget

    # AUR helper (yay)
    if ! command -v yay &>/dev/null; then
        echo "==> Installing yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay-install
        (cd /tmp/yay-install && makepkg -si --noconfirm)
        rm -rf /tmp/yay-install
    fi

    echo "==> Installing AUR packages..."
    yay -S --needed --noconfirm oh-my-posh-bin ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

    echo "==> Refreshing font cache..."
    fc-cache -fv

    echo "==> Installing Kubernetes tools..."
    sudo pacman -S --needed --noconfirm kubectl helm
    yay -S --needed --noconfirm k9s

    # Set zsh as default shell
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        echo "==> Setting zsh as default shell..."
        chsh -s "$(which zsh)"
    fi
fi

# ── WSL: install packages ────────────────────────────────────
if [[ "$OS" == "wsl" ]]; then
    echo ""
    echo "==> Installing packages (apt)..."
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        zsh tmux neovim git curl wget fzf ripgrep fd-find bat

    # Arch-only tools installed via other means on WSL:
    # eza, yazi, zoxide, atuin, oh-my-posh — install manually if needed
    echo "  Note: eza, yazi, zoxide, atuin, oh-my-posh need manual install on WSL."
fi

# ── Zsh plugins ──────────────────────────────────────────────
echo ""
echo "==> Installing zsh plugins..."
mkdir -p "$HOME/.zsh/plugins"

if [[ ! -d "$HOME/.zsh/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "$HOME/.zsh/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$HOME/.zsh/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        "$HOME/.zsh/plugins/zsh-syntax-highlighting"
fi

# ── tmux-resurrect plugin ────────────────────────────────────
echo ""
echo "==> Installing tmux-resurrect..."
mkdir -p "$HOME/.tmux/plugins"
if [[ ! -d "$HOME/.tmux/plugins/tmux-resurrect" ]]; then
    git clone --depth=1 https://github.com/tmux-plugins/tmux-resurrect \
        "$HOME/.tmux/plugins/tmux-resurrect"
fi

# ── nvm ──────────────────────────────────────────────────────
if [[ ! -d "$HOME/.nvm" ]]; then
    echo ""
    echo "==> Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# ── bun ──────────────────────────────────────────────────────
if ! command -v bun &>/dev/null; then
    echo ""
    echo "==> Installing bun..."
    curl -fsSL https://bun.sh/install | bash
fi

# ── atuin ────────────────────────────────────────────────────
if ! command -v atuin &>/dev/null; then
    echo ""
    echo "==> Installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# ── .zshrc.local reminder ────────────────────────────────────
if [[ ! -f "$HOME/.zshrc.local" ]]; then
    echo ""
    echo "==> Creating ~/.zshrc.local template for machine-specific secrets..."
    cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-specific env vars — NOT committed to git
# Add API keys, tokens, AWS profiles, etc. here
EOF
    echo "  Edit ~/.zshrc.local to add your secrets."
fi

echo ""
echo "==> Done! Open a new shell or run: exec zsh"
echo ""
echo "Remaining manual steps:"
echo "  1. Set up SSH keys: ssh-keygen -t ed25519 -C 'your@email.com'"
echo "  2. Add secrets to ~/.zshrc.local"
echo "  3. Add kubectl contexts from your clusters"
echo "  4. Install Claude Code: npm install -g @anthropic-ai/claude-code"
echo "  5. Open nvim — LazyVim will auto-install plugins on first launch"
