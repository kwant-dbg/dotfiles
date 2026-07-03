# dotfiles

Personal configuration snapshot for Ubuntu 24.04 on WSL2, zsh, tmux, Neovim/LazyVim, CLI tools, and coding agents.

The snapshot is audited in [`INVENTORY.md`](INVENTORY.md). The source machine’s versions are recorded in [`VERSIONS.md`](VERSIONS.md).

## Recreate the workstation

For a fresh Ubuntu 24.04/WSL2 machine:

```bash
git clone https://github.com/kwant-dbg/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh              # full dry-run
./bootstrap.sh --apply      # install tools, apply config, sync editors
./doctor.sh                 # verify the resulting environment
```

The bootstrap installs the base packages, current stable Neovim and Go, nvm with Node 24, Rust CLI tools, shell integrations, Kubernetes/cloud utilities, agent CLIs, fonts, LazyVim plugins and Doom Emacs. Authentication and organization-specific setup remain in [`POST_INSTALL.md`](POST_INSTALL.md).

## Install

The installer creates symlinks for normal configuration, copies credential-capable files, and renders path-sensitive templates for the target `$HOME`. It does not install packages, use `sudo`, or access the network.

```bash
git clone https://github.com/kwant-dbg/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh                 # dry-run (default)
./install.sh --apply         # back up targets, then link
```

Backups are written below `~/.local/state/dotfiles-backups/<timestamp>/`. Review `manifest.tsv` to add or remove components before applying.

Docker config, Helm repositories and Sqlectron servers use `copy` mode. Their applications may later add credentials, so they must not point back into this repository.

Codex, Claude, Gemini, k9s, Windsurf and Copilot files containing `/home/trip` use `template` mode. Installation rewrites that prefix to the target machine’s actual home directory.

## Included

- Shell: zsh, bash, profile and prompt themes
- Terminal/editor: tmux, Neovim/LazyVim, Doom config, VS Code settings
- CLI tools: Atuin, bat, btop, fastfetch, Helm, k9s, micro and neofetch; tealdeer configuration is preserved
- Agent tools: portable Claude, Codex, Gemini, and OpenCode configuration
- Shared and Claude-specific agent skills, with the shared skill lockfile
- Git/SSH: identities, global ignore rules, and host aliases (never private keys)

Some checked-in settings contain internal work endpoints. Review them before installing on a non-work machine.

## Deliberately excluded

Credentials, keys, auth sessions, command/chat history, databases, logs, caches, package trees, editor backups, Kubernetes/cloud contexts, and runtime state are not tracked. In particular, this repository does not include `.ssh`, `.aws`, `.azure`, `.kube`, `.git-credentials`, `.netrc`, Docker auth, Boot.dev auth, agent auth files, or Atuin history/session data.

Keep secrets in untracked local files such as `~/.zshrc.local`. The tracked `zshrc` sources that file when present.

Run `./check.sh` after changing the snapshot. It validates the manifest, shell/JSON syntax, symlinks, ignored files, and common credential signatures.
