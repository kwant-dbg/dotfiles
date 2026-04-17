# ~/.zshrc

# Interactive check
[[ $- != *i* ]] && return

# ─────────────────────────────────────────────────────────────
# Environment & Path
# ─────────────────────────────────────────────────────────────
eval "$(zoxide init zsh --cmd cd)"

export PATH="$HOME/.local/bin:$HOME/.opencode/bin:/snap/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"

# Go installation
export GOROOT="$HOME/go-installation/go"
export PATH="$GOROOT/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

export EDITOR="nvim"
export VISUAL="nvim"
export BAT_PAGER=""
export BAT_THEME="base16"

# Machine-specific secrets (AWS, API keys, etc.) go in ~/.zshrc.local — not tracked in git
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Tmux persistent socket directory
export TMUX_TMPDIR="$HOME/.tmux/tmp"

# ─────────────────────────────────────────────────────────────
# Shell Options
# ─────────────────────────────────────────────────────────────
unsetopt BEEP HIST_BEEP LIST_BEEP
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# ─────────────────────────────────────────────────────────────
# Plugins & Completion
# ─────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

source $HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# ─────────────────────────────────────────────────────────────
# Aliases
# ─────────────────────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias cat='bat --paging=never'
alias grep='grep --color=auto'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias k='kubectl'
alias kubeon='export K8S_ACTIVE=1'
alias kubeoff='unset K8S_ACTIVE'

# ─────────────────────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────────────────────
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

function nvm() {
    unset -f nvm node npm npx gemini codex > /dev/null 2>&1;
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}
function node() { nvm >/dev/null; command node "$@"; }
function npm()  { nvm >/dev/null; command npm "$@"; }
function gemini() { nvm >/dev/null; command gemini "$@"; }
function npx()  { nvm >/dev/null; command npx "$@"; }

# ─────────────────────────────────────────────────────────────
# Prompt & External Tools
# ─────────────────────────────────────────────────────────────
eval "$(oh-my-posh init zsh --config ~/.poshthemes/trip-custom.omp.json)"

. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# Key Bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^U' backward-kill-line
bindkey '^K' kill-line
bindkey '^W' backward-kill-word

# ─────────────────────────────────────────────────────────────
# Terminal Tab Title
# ─────────────────────────────────────────────────────────────
function _set_tab_title() {
    local title="${1:-zsh}"
    printf '\e]0;%s\a' "$title"
}
function preexec() { _set_tab_title "${1%% *}"; }
function precmd()  { _set_tab_title "zsh"; }

export DOOMDIR="$HOME/.config/doom"
export EMACSDIR="$HOME/.config/emacs"

# Wayland (set if not auto-configured by your compositor)
# export WAYLAND_DISPLAY=wayland-1
# export XDG_RUNTIME_DIR=/run/user/$(id -u)
