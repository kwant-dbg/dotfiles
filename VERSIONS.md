# Source workstation snapshot

Observed on Ubuntu 24.04 / WSL2 / x86_64 on 2026-07-01. The bootstrap installs current stable releases unless a major version is specified; these values are a comparison target, not a strict lockfile.

| Tool | Observed version |
|---|---|
| zsh | 5.9 |
| tmux | 3.4 |
| Neovim | 0.11.5 |
| Git | 2.43.0 |
| Go | 1.26.0 |
| Node.js / npm | 24.14.1 / 11.11.0 |
| Python / pipx | 3.12.3 / 1.4.3 |
| fzf | 0.73 development build |
| Atuin | 18.11.0 |
| Oh My Posh | 29.0.2 |
| kubectl | 1.31.0 |
| Helm | 3.13.2 |
| k9s | 0.32.4 |
| minikube | 1.37.0 |
| Velero | 1.13.0 |
| Claude Code | 2.1.196 |
| Codex CLI | 0.142.4 |
| OpenCode | 1.15.12 |
| code-review-graph | 2.3.3 |
| Doom Emacs | 3.0.0-pre |

The source machine did not currently expose `yazi`, `bun`, or Gemini on `PATH`, although the shell configuration expects them. The bootstrap installs all three.
