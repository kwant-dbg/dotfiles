# ~/.zshrc

# Interactive check
[[ $- != *i* ]] && return

# ─────────────────────────────────────────────────────────────
# Environment & Path
# ─────────────────────────────────────────────────────────────
# Consolidated paths for efficiency

eval "$(zoxide init zsh --cmd cd)"

export PATH="$HOME/.local/bin:/home/trip/.opencode/bin:/snap/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"

# Go installation
export GOROOT="$HOME/go-installation/go"
export PATH="$GOROOT/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"  # For installed Go tools

export EDITOR="nvim"
export VISUAL="nvim"
export BAT_PAGER=""             # Force bat/cat to stay inline globally
export BAT_THEME="trip-catppuccin"
export EZA_COLORS="di=38;2;245;194;231:ex=38;2;148;226;213:ln=38;2;180;190;254:or=38;2;243;139;168:*.go=38;2;148;226;213:*.lua=38;2;137;180;250:*.md=38;2;180;190;254:*.json=38;2;250;179;135:*.yaml=38;2;203;166;247:*.yml=38;2;203;166;247:*.toml=38;2;245;194;231:*.sh=38;2;148;226;213:*.Dockerfile=38;2;116;199;236:Dockerfile=38;2;116;199;236"

# Claude Code via Yum LiteLLM
export ANTHROPIC_BASE_URL="https://litellm.shd.yumconnect.dev"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="haiku (bedrock)"
export ANTHROPIC_DEFAULT_SONNET_MODEL="sonnet (bedrock)"
export ANTHROPIC_DEFAULT_OPUS_MODEL="opus (bedrock)"
export CLAUDE_CODE_USE_BEDROCK="0"
export CLAUDE_CODE_API_KEY_HELPER_TTL_MS="21600000"
unset ANTHROPIC_MODEL

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

# Load plugins with silent error handling
source $HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# ─────────────────────────────────────────────────────────────
# Aliases
# ─────────────────────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias cat='bat --paging=never --style=grid,header'   # Keeps file separators without line numbers
alias grep='grep --color=auto'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias k='kubectl'
alias kon='export K8S_ACTIVE=1'
alias koff='unset K8S_ACTIVE'
alias n='nvim'
alias cc='claude'
alias oc='opencode'

# ─────────────────────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────────────────────
# Yazi with directory change on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# NVM Lazy Loader: Speeds up shell startup by loading Node only when needed
function nvm() {
    unset -f nvm node npm npx gemini codex > /dev/null 2>&1;
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}
function node() { nvm >/dev/null; command node "$@"; }
function npm() { nvm >/dev/null; command npm "$@"; }
function gemini() { nvm >/dev/null; command gemini "$@"; }
function npx() { nvm >/dev/null; command npx "$@"; }


# ─────────────────────────────────────────────────────────────
# Prompt & External Tools
# ─────────────────────────────────────────────────────────────
eval "$(oh-my-posh init zsh --config ~/.poshthemes/catppuccin_mocha.omp.json)"

# Atuin - Better Shell History
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
# Terminal Tab Title (enables icon swap in Windsurf for 'claude' tabs)
# ─────────────────────────────────────────────────────────────
function _set_tab_title() {
    local title="${1:-zsh}"
    # VSCode / Windsurf integrated terminal
    printf '\e]0;%s\a' "$title"
}

function preexec() {
    # Extract just the command name (first word), strip args
    _set_tab_title "${1%% *}"
}

function precmd() {
    _set_tab_title "zsh"
}
export DOOMDIR="$HOME/.config/doom"
export EMACSDIR="$HOME/.config/emacs"
export DISPLAY=:0
export PATH="$HOME/.npm-global/bin:$PATH"
export AWS_CLI_AUTO_PROMPT=on-partial

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

  export PATH="${PATH}:/home/trip/.cargo/bin"
