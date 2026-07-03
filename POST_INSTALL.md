# Post-install checklist

The bootstrap deliberately does not transfer authentication, private keys, cluster contexts, browser state or organization credentials.

1. Set zsh as the login shell: `chsh -s "$(command -v zsh)"`, then open a new terminal.
2. Configure Windows Terminal to use a JetBrainsMono Nerd Font. Enable Docker Desktop’s WSL integration; `docker` and `clip.exe` come from Windows rather than this script.
   Install or sign into VS Code/Windsurf, Copilot and Sqlectron separately if those desktop configurations are wanted.
3. Authenticate GitHub/GitLab and agent CLIs: `glab auth login`, `codex login`, `gemini`, `claude`, and OpenCode’s `/connect` flow.
4. Restore AWS/Azure access through your organization’s approved process. Add Kubernetes contexts separately and always verify `kubectl config current-context` before writes.
5. Install a Teleport `tsh` version compatible with the organization proxy, then authenticate. Teleport is intentionally not auto-upgraded because client/server compatibility is organization-specific.
6. Build or obtain `~/.local/bin/yum-litellm-key-helper` from the private `gitlab.com/yumbrands/yumdev/platform-engineering/yum-litellm-key-helper` source. The tracked robust wrapper calls this binary but does not contain credentials.
7. Reinstall Claude plugins listed in `claude/plugins.txt` and add the global MCP servers recorded in `claude/mcp-servers.json`. Project MCP entries containing auth headers were not copied.
8. Sign into Atuin only if history sync is wanted. Its encryption key, auth session and history database were deliberately excluded.
9. Clone or restore work repositories and the separate `~/notes/roam` knowledge base. Codex trust entries and editor shortcuts do not clone project data.
10. Run `./doctor.sh`, then check `nvim` with `:checkhealth` and Doom with `~/.config/emacs/bin/doom doctor`.
