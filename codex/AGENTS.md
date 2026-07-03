# Global Configuration

## Environment
Ubuntu 24.04 LTS on WSL2 | zsh | Neovim (LazyVim) at `~/.config/nvim/`

## Skills
Use skills from `~/.Codex/skills/` for domain-specific questions:
- `nvim.md` — Neovim/LazyVim
- `kubectl.md` — Kubernetes operations

## Kubernetes Safety
- Never auto-execute `kubectl apply` — dry-run first, confirm
- Always check cluster context before any write operations
- Use `-o wide` by default
