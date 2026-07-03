# Configuration inventory

Audited against `/home/trip` on 2026-07-01. “Exhaustive” here means every discovered user configuration namespace is classified as tracked, reference-only, generated/runtime state, credential-bearing, or empty. It does not mean copying caches, databases, histories or secrets into Git.

Environment reproduction is handled by `bootstrap.sh`; configuration installation is handled by `install.sh`; post-install verification is handled by `doctor.sh`.

## Tracked and installable

- Root: bash/profile, zsh, tmux, Git identities/ignore, GTK 2, clang-format, SSH aliases and Docker credential-store selection
- XDG: Atuin, bat, btop, ccsession, ccstatusline, Doom, Envman loader, fastfetch, fish, Git ignore, GTK 3/4, Helm repositories, k9s, MIME defaults, micro, neofetch, Neovim/LazyVim, OpenCode, Sqlectron, tealdeer, VS Code settings and GLab aliases
- Agents: shared `~/.agents` skills/lockfile; Claude settings, bindings, status line, native/shared skills and Claude-only `.agents` skills; Codex config/hooks/rules; Gemini instructions/settings; OpenCode configs
- IDE agents: Windsurf and Copilot MCP definitions plus the custom Windsurf review workflow
- Local scripts: `codex`, `dev`, `img` and the robust LiteLLM key-helper wrapper
- Assets: prompt themes, bat theme and fastfetch image

## Reference-only

- Claude plugin identifiers are in `claude/plugins.txt`; plugin caches contain absolute paths and are reinstalled instead of copied
- Claude global MCP definitions are in `claude/mcp-servers.json`; `~/.claude.json` is stateful and may contain sensitive project MCP headers
- Runtime requirements are in `DEPENDENCIES.md`

## Excluded because they hold credentials or private material

- `~/.aws`, `~/.azure`, `~/.kube`, `~/.tsh`, SSH private keys, `.netrc`, `.git-credentials` and GLab host authentication
- `.bootdev.yaml`, Docker auth beyond the safe credential-store selector, Claude/Codex/Gemini authentication, LiteLLM cached keys and agent project MCP headers
- Atuin encryption/session data and any application token, cookie, certificate or private key

## Excluded generated or runtime state

- Shell/editor histories, completion dumps, Vim info, logs, telemetry, caches, backups, sessions, transcripts, memories and SQLite databases
- `~/.config/emacs` (Doom installation/packages), `node_modules`, NVM/npm/bun stores, downloaded binaries, zsh/tmux third-party plugin source and OpenCode/Codex/Claude plugin caches
- Micro backups/history, Sqlectron databases/cache, dconf and pulse state, update-notifier files, receipts and version-check files

## Empty namespaces observed

`cagent`, `htop`, `kitty`, `nnn`, `procps` and `tmux` currently contain no portable configuration to copy.

## XDG namespace accounting

| Namespace | Disposition |
|---|---|
| `.config` | Accounted for namespace-by-namespace in the XDG table above |
| `.git` | Empty/incomplete home directory metadata; `/home/trip` is not a Git worktree |
| `Code`, `Sqlectron`, `atuin`, `bat`, `btop` | Tracked configuration; Atuin receipt/session data excluded |
| `cagent`, `htop`, `kitty`, `nnn`, `procps`, `tmux` | Empty |
| `ccsession`, `ccstatusline`, `doom`, `fastfetch`, `fish`, `git` | Tracked |
| `envman` | Loader tracked; mutable environment/alias files remain local so secrets cannot enter Git |
| `glab-cli` | Aliases tracked; host config excluded because it embeds an access token |
| `gtk-3.0`, `gtk-4.0`, `helm`, `k9s`, `micro`, `mimeapps.list`, `neofetch`, `nvim`, `tealdeer` | Tracked |
| `opencode` | User config and plugin source tracked; packages, account files and notifier state excluded |
| `emacs` | Generated Doom installation/package tree; user config is tracked under `doom` |
| `configstore`, `go`, `gopls`, `nextjs-nodejs`, `temporalio`, `wslu` | Update, telemetry, generated cluster/version or WSL runtime state |
| `dconf` | Binary settings database; `dconf` CLI is unavailable in this WSL environment, so no portable text export exists |
| `pulse` | Runtime cookie/state |
| `sqlectron` | Electron cache, local/session storage and crash state; the portable empty server list is tracked from `Sqlectron` |
| `google-chrome` | Symlink to the Windows Chrome profile; browser profile/state is not a dotfile |

## Root-file accounting

Tracked root configuration includes `.bashrc`, `.bash_logout`, `.profile`, `.zshrc`, `.tmux.conf`, `.gitconfig`, `.gitconfig-yumbrands`, `.gitignore_global`, `.clang-format` and `.gtkrc-2.0`. SSH aliases and Docker’s safe credential-store selector are also tracked from their directories. The live `.npmrc` prefix was deliberately removed because it is incompatible with nvm; the bootstrap uses nvm’s default global package location.

Excluded root files are histories (`.bash_history`, `.zsh_history`, `.lesshst`, `.viminfo`), generated state (`.zcompdump`, `.wget-hsts`, marker files), backups, `.claude.json` state, `.bootdev.yaml`, `.git-credentials` and `.netrc`. The root `cert-manager-tls-migration.md` is a project document rather than user configuration.

## Non-XDG hidden-directory accounting

| Namespace | Disposition |
|---|---|
| `.agents`, `.claude`, `.codex`, `.gemini`, `.opencode` | Portable configuration tracked; auth, sessions, histories, caches, databases and generated state excluded |
| `.codeium` / Windsurf | MCP config and custom workflow tracked; protobuf state, conversations, codemaps, identities and onboarding state excluded |
| `.copilot` | MCP config tracked |
| `.poshthemes`, `.ssh`, `.docker` | Safe configuration tracked; keys and credentials excluded |
| `.atuin`, `.bun`, `.cargo`, `.nvm`, `.npm`, `.npm-global`, `.tmux`, `.zsh` | Installed programs, package stores or third-party plugin source; configuration dependencies documented separately |
| `.antigravity-server`, `.vscode-server`, `.windsurf-server`, `.zed_server`, `.vscode-remote-containers` | Downloaded editor/server programs, extensions, logs and runtime state |
| `.aws`, `.azure`, `.kube`, `.minikube`, `.pki`, `.tsh` | Credentials, certificates, cluster profiles or private state |
| `.cache`, `.local` | Mixed cache/data/install tree; only the four audited human-authored scripts from `.local/bin` are tracked |
| `.devbox` | Generated Nix environment/cache and shell history; no source `devbox.json` exists here |
| `.code-review-graph` | Empty |
| `.codeium` remainder, `.gitlab`, `.redhat` | IDs, protobuf/editor state, telemetry or selected-model state |
| `.dotnet`, `.grip`, `.landscape`, `.tldr`, `.temporalio` | Certificate revocation cache, rendered CSS cache, logs, search cache or downloaded binary |
| `.vim`, `.w3m` | Netrw history and browser cookie respectively; neither is portable configuration |

## Safety rule

Never turn credential-bearing files into symlinks to this repository. Authenticate tools after installation and keep machine-local secrets in untracked files such as `~/.zshrc.local`.

Credential-capable but currently safe Docker, Helm and Sqlectron files are installed as copies rather than symlinks, preventing future application writes from leaking credentials into the repository.
