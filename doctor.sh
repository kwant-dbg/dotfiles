#!/usr/bin/env bash
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0
warnings=0

export PATH="$HOME/.local/bin:$HOME/go-installation/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/.opencode/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  nvm use default --silent >/dev/null 2>&1 || true
fi

ok() { printf 'ok    %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }

for command in zsh fish tmux nvim git rg fd fzf jq bat eza zoxide atuin oh-my-posh yazi \
  btop fastfetch micro ccsession stylua go node npm python3 pipx kubectl helm k9s glab \
  claude codex gemini opencode; do
  command -v "$command" >/dev/null 2>&1 && ok "$command: $(command -v "$command")" || fail "$command is missing"
done

for command in minikube velero aws kind code-review-graph bun emacs; do
  command -v "$command" >/dev/null 2>&1 && ok "$command: $(command -v "$command")" || warn "$command is missing"
done

while IFS=$'\t' read -r source target mode; do
  [[ -n "${source:-}" && "${source:0:1}" != "#" ]] || continue
  [[ -e "$HOME/$target" || -L "$HOME/$target" ]] || fail "missing configured target: ~/$target"
done < "$repo/manifest.tsv"

if command -v nvim >/dev/null 2>&1; then
  nvim --headless -i NONE '+lua print("ok    Neovim config loaded")' +qa || fail "Neovim config failed to load"
fi

if [[ -f "$HOME/.npmrc" ]] && grep -Eq '^[[:space:]]*(prefix|globalconfig)[[:space:]]*=' "$HOME/.npmrc"; then
  fail "~/.npmrc configures prefix/globalconfig, which is incompatible with nvm"
fi

printf '\nDoctor result: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
(( failures == 0 ))
