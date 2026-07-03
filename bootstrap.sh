#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode="dry-run"

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--dry-run|--apply]

Build an Ubuntu 24.04/WSL2 workstation matching this repository.
Dry-run is the default. --apply installs packages and tools, applies the
dotfiles, and synchronizes Neovim and Doom Emacs.
EOF
}

case "${1:---dry-run}" in
  --dry-run) ;;
  --apply) mode="apply" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ ! -r /etc/os-release ]]; then
  printf 'Unsupported system: /etc/os-release is missing\n' >&2
  exit 1
fi
. /etc/os-release
if [[ "$ID" != "ubuntu" || "${VERSION_ID%%.*}" -lt 24 ]]; then
  printf 'This bootstrap targets Ubuntu 24.04+; found %s %s.\n' "$ID" "$VERSION_ID" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) go_arch="amd64"; nvim_arch="x86_64" ;;
  aarch64|arm64) go_arch="arm64"; nvim_arch="arm64" ;;
  *) printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
esac

export PATH="$HOME/.local/bin:$HOME/go-installation/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.opencode/bin:$PATH"

step() { printf '\n==> %s\n' "$*"; }
skip() { printf '    skip: %s\n' "$*"; }

run() {
  printf '    +'
  printf ' %q' "$@"
  printf '\n'
  if [[ "$mode" == "apply" ]]; then
    "$@"
  fi
}

run_as_root() {
  if [[ $EUID -eq 0 ]]; then
    run "$@"
  else
    run sudo "$@"
  fi
}

remote_script() {
  local url="$1"; shift
  if [[ "$mode" == "dry-run" ]]; then
    printf '    + download %s; bash installer' "$url"
    if (( $# )); then
      printf ' %q' "$@"
    fi
    printf '\n'
    return
  fi
  local script
  script="$(mktemp /tmp/dotfiles-installer.XXXXXX)"
  curl -fsSL "$url" -o "$script"
  bash "$script" "$@"
  rm -f "$script"
}

clone_if_missing() {
  local url="$1" target="$2"
  if [[ -d "$target/.git" ]]; then
    skip "$target already cloned"
  else
    run git clone --depth 1 "$url" "$target"
  fi
}

github_archive_binaries() {
  local repository="$1" asset_regex="$2"; shift 2
  local binaries=("$@") binary
  local missing=0
  for binary in "${binaries[@]}"; do
    command -v "$binary" >/dev/null 2>&1 || missing=1
  done
  (( missing )) || { skip "${binaries[*]} already installed"; return; }

  if [[ "$mode" == "dry-run" ]]; then
    printf '    + install latest %s asset matching %s -> ~/.local/bin (%s)\n' \
      "$repository" "$asset_regex" "${binaries[*]}"
    return
  fi

  local work metadata asset url digest archive extract found
  work="$(mktemp -d /tmp/dotfiles-release.XXXXXX)"
  metadata="$work/release.json"
  curl -fsSL "https://api.github.com/repos/$repository/releases/latest" -o "$metadata"
  asset="$(jq -c --arg pattern "$asset_regex" '.assets[] | select(.name | test($pattern))' "$metadata" | head -n 1)"
  url="$(jq -r '.browser_download_url' <<<"$asset")"
  digest="$(jq -r '.digest // empty' <<<"$asset")"
  [[ -n "$url" && "$url" != "null" ]] || { printf 'No matching %s release asset.\n' "$repository" >&2; exit 1; }
  archive="$work/${url##*/}"
  extract="$work/extract"
  mkdir -p "$extract" "$HOME/.local/bin"
  curl -fL "$url" -o "$archive"
  if [[ "$digest" == sha256:* ]]; then
    printf '%s  %s\n' "${digest#sha256:}" "$archive" | sha256sum --check
  else
    printf '    warning: GitHub did not publish a digest for %s\n' "${url##*/}" >&2
  fi
  case "$archive" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$extract" ;;
    *.zip) unzip -q "$archive" -d "$extract" ;;
    *) printf 'Unsupported release archive: %s\n' "$archive" >&2; exit 1 ;;
  esac
  for binary in "${binaries[@]}"; do
    found="$(find "$extract" -type f -name "$binary" -print -quit)"
    [[ -n "$found" ]] || { printf 'Binary %s not found in %s.\n' "$binary" "$archive" >&2; exit 1; }
    install -m 0755 "$found" "$HOME/.local/bin/$binary"
  done
  rm -rf "$work"
}

install_base_packages() {
  step "Ubuntu base packages"
  run_as_root apt-get update
  run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash zsh fish tmux git curl wget ca-certificates gnupg jq ripgrep fd-find fzf bat \
    btop neofetch micro \
    bc imagemagick file ffmpeg p7zip-full poppler-utils unzip xz-utils fontconfig \
    build-essential pkg-config python3 python3-pip python3-venv pipx emacs \
    shellcheck clang-format sqlite3 libsqlite3-dev kubectx glab

  run mkdir -p "$HOME/.local/bin"
  [[ -e "$HOME/.local/bin/bat" ]] || run ln -s /usr/bin/batcat "$HOME/.local/bin/bat"
  [[ -e "$HOME/.local/bin/fd" ]] || run ln -s /usr/bin/fdfind "$HOME/.local/bin/fd"
}

install_neovim() {
  step "Neovim stable binary"
  local current=""
  command -v nvim >/dev/null 2>&1 && current="$(nvim --version | awk 'NR==1 {sub(/^NVIM v/, ""); print $1}')"
  if [[ -n "$current" && "$(printf '%s\n' 0.11.0 "$current" | sort -V | head -n1)" == "0.11.0" ]]; then
    skip "Neovim $current satisfies >= 0.11"
    return
  fi
  local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz"
  local destination="$HOME/.local/opt/nvim-linux-${nvim_arch}"
  if [[ "$mode" == "dry-run" ]]; then
    printf '    + download %s; extract to %s; link ~/.local/bin/nvim\n' "$url" "$destination"
    return
  fi
  [[ ! -e "$destination" ]] || { printf '%s already exists; refusing to replace it.\n' "$destination" >&2; exit 1; }
  local work
  work="$(mktemp -d /tmp/dotfiles-nvim.XXXXXX)"
  local archive_name="nvim-linux-${nvim_arch}.tar.gz"
  curl -fL "$url" -o "$work/$archive_name"
  curl -fL "$url.sha256sum" -o "$work/$archive_name.sha256sum"
  (cd "$work" && sha256sum --check "$archive_name.sha256sum")
  mkdir -p "$HOME/.local/opt"
  tar -xzf "$work/$archive_name" -C "$HOME/.local/opt"
  ln -sfn "$destination/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$work"
}

install_go() {
  step "Go stable toolchain"
  local goroot="$HOME/go-installation/go"
  if [[ -x "$goroot/bin/go" ]]; then
    skip "$($goroot/bin/go version)"
    return
  fi
  if [[ "$mode" == "dry-run" ]]; then
    printf '    + download latest stable Go linux-%s with official SHA256; extract to %s\n' "$go_arch" "$goroot"
    return
  fi
  local work metadata version filename checksum
  work="$(mktemp -d /tmp/dotfiles-go.XXXXXX)"
  metadata="$work/releases.json"
  curl -fsSL 'https://go.dev/dl/?mode=json' -o "$metadata"
  version="$(jq -r '.[0].version' "$metadata")"
  filename="$(jq -r --arg arch "$go_arch" '.[0].files[] | select(.os=="linux" and .arch==$arch and .kind=="archive") | .filename' "$metadata")"
  checksum="$(jq -r --arg arch "$go_arch" '.[0].files[] | select(.os=="linux" and .arch==$arch and .kind=="archive") | .sha256' "$metadata")"
  [[ -n "$filename" && -n "$checksum" ]] || { printf 'Unable to resolve Go release metadata.\n' >&2; exit 1; }
  curl -fL "https://go.dev/dl/$filename" -o "$work/$filename"
  printf '%s  %s\n' "$checksum" "$work/$filename" | sha256sum --check
  mkdir -p "$HOME/go-installation"
  tar -xzf "$work/$filename" -C "$HOME/go-installation"
  rm -rf "$work"
  printf '    installed %s\n' "$version"
}

install_nvm_node() {
  step "nvm and Node.js 24"
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    if [[ "$mode" == "dry-run" ]]; then
      printf '    + clone latest nvm release to %s\n' "$NVM_DIR"
    else
      local nvm_tag
      nvm_tag="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name)"
      git clone --depth 1 --branch "$nvm_tag" https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    fi
  else
    skip "nvm already installed"
  fi
  if [[ "$mode" == "apply" ]]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
    nvm install 24
    nvm alias default 24
    npm install -g @openai/codex@latest @google/gemini-cli@latest \
      @amansingh-afk/milli@latest opencode-worktree@latest
  else
    printf '    + nvm install 24; npm install global Codex, Gemini, milli and opencode-worktree\n'
  fi
}

install_rust_cli_tools() {
  step "Rust-based CLI tools"
  if [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
    remote_script https://sh.rustup.rs -y --profile minimal
  else
    skip "Rust toolchain already installed"
  fi
  if [[ "$mode" == "apply" ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    command -v eza >/dev/null 2>&1 || cargo install eza
    command -v zoxide >/dev/null 2>&1 || cargo install --locked zoxide
    command -v yazi >/dev/null 2>&1 || cargo install --force yazi-build
    command -v navi >/dev/null 2>&1 || cargo install --locked navi
    command -v stylua >/dev/null 2>&1 || cargo install stylua
  else
    printf '    + cargo install eza zoxide yazi-build navi stylua when missing\n'
  fi
}

install_shell_tools() {
  step "Shell and terminal tools"
  [[ -x "$HOME/.atuin/bin/atuin" ]] || remote_script https://setup.atuin.sh --non-interactive
  command -v oh-my-posh >/dev/null 2>&1 || remote_script https://ohmyposh.dev/install.sh -d "$HOME/.local/bin"
  [[ -x "$HOME/.bun/bin/bun" ]] || remote_script https://bun.com/install
  [[ -x "$HOME/.opencode/bin/opencode" ]] || remote_script https://opencode.ai/install

  if command -v fzf >/dev/null 2>&1 && \
     [[ "$(printf '%s\n' 0.53.0 "$(fzf --version | awk '{print $1}')" | sort -V | head -n1)" == "0.53.0" ]]; then
    skip "fzf satisfies >= 0.53"
  elif [[ "$mode" == "apply" ]]; then
    "$HOME/go-installation/go/bin/go" install github.com/junegunn/fzf@latest
  else
    printf '    + go install github.com/junegunn/fzf@latest\n'
  fi

  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/plugins/zsh-autosuggestions"
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/plugins/zsh-syntax-highlighting"
  clone_if_missing https://github.com/tmux-plugins/tmux-resurrect "$HOME/.tmux/plugins/tmux-resurrect"

  github_archive_binaries fastfetch-cli/fastfetch "^fastfetch-linux-${go_arch}\\.tar\\.gz$" fastfetch
  if ! command -v ccsession >/dev/null 2>&1; then
    if [[ "$mode" == "apply" ]]; then
      "$HOME/go-installation/go/bin/go" install github.com/sorafujitani/ccsession/cmd/ccsession@latest
    else
      printf '    + go install github.com/sorafujitani/ccsession/cmd/ccsession@latest\n'
    fi
  else
    skip "ccsession already installed"
  fi
}

install_python_tools() {
  step "pipx tools"
  run pipx ensurepath
  local package
  for package in code-review-graph grip tldr virtme-ng; do
    if pipx list --short 2>/dev/null | grep -q "^${package} "; then
      skip "$package already installed"
    else
      run pipx install "$package"
    fi
  done
}

install_kubernetes_tools() {
  step "Kubernetes and cloud CLI tools"
  if ! command -v kubectl >/dev/null 2>&1; then
    if [[ "$mode" == "dry-run" ]]; then
      printf '    + install latest kubectl linux/%s with official SHA256\n' "$go_arch"
    else
      local work version
      work="$(mktemp -d /tmp/dotfiles-kubectl.XXXXXX)"
      version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
      curl -fL "https://dl.k8s.io/release/$version/bin/linux/$go_arch/kubectl" -o "$work/kubectl"
      curl -fL "https://dl.k8s.io/release/$version/bin/linux/$go_arch/kubectl.sha256" -o "$work/kubectl.sha256"
      printf '%s  %s\n' "$(cat "$work/kubectl.sha256")" "$work/kubectl" | sha256sum --check
      install -m 0755 "$work/kubectl" "$HOME/.local/bin/kubectl"
      rm -rf "$work"
    fi
  else
    skip "kubectl already installed"
  fi

  command -v helm >/dev/null 2>&1 || remote_script https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  github_archive_binaries derailed/k9s "^k9s_Linux_${go_arch}\\.tar\\.gz$" k9s
  github_archive_binaries vmware-tanzu/velero "^velero-v.*-linux-${go_arch}\\.tar\\.gz$" velero

  if ! command -v minikube >/dev/null 2>&1; then
    if [[ "$mode" == "dry-run" ]]; then
      printf '    + install latest minikube linux-%s to ~/.local/bin\n' "$go_arch"
    else
      curl -fL "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${go_arch}" -o "$HOME/.local/bin/minikube"
      curl -fL "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${go_arch}.sha256" -o "$HOME/.local/bin/minikube.sha256"
      printf '%s  %s\n' "$(cat "$HOME/.local/bin/minikube.sha256")" "$HOME/.local/bin/minikube" | sha256sum --check
      rm -f "$HOME/.local/bin/minikube.sha256"
      chmod 0755 "$HOME/.local/bin/minikube"
    fi
  else
    skip "minikube already installed"
  fi

  if ! command -v kind >/dev/null 2>&1; then
    if [[ "$mode" == "apply" ]]; then
      "$HOME/go-installation/go/bin/go" install sigs.k8s.io/kind@latest
    else
      printf '    + go install sigs.k8s.io/kind@latest\n'
    fi
  else
    skip "kind already installed"
  fi

  if ! command -v aws >/dev/null 2>&1; then
    if [[ "$mode" == "dry-run" ]]; then
      printf '    + install AWS CLI v2 linux-%s under ~/.local/aws-cli\n' "$go_arch"
    else
      local work aws_arch
      aws_arch="$([[ "$go_arch" == amd64 ]] && printf x86_64 || printf aarch64)"
      work="$(mktemp -d /tmp/dotfiles-aws.XXXXXX)"
      curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o "$work/aws.zip"
      unzip -q "$work/aws.zip" -d "$work"
      "$work/aws/install" -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin"
      rm -rf "$work"
    fi
  else
    skip "AWS CLI already installed"
  fi
}

install_agent_tools() {
  step "Agent CLIs"
  command -v claude >/dev/null 2>&1 || remote_script https://claude.ai/install.sh
  [[ -x "$HOME/.opencode/bin/opencode" ]] || remote_script https://opencode.ai/install
  if command -v codex >/dev/null 2>&1; then skip "Codex already installed"; fi
  if command -v gemini >/dev/null 2>&1; then skip "Gemini already installed"; fi
}

install_font() {
  step "JetBrainsMono Nerd Font"
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  if find "$font_dir" -type f -name '*.ttf' -print -quit 2>/dev/null | grep -q .; then
    skip "JetBrainsMono Nerd Font already installed"
    return
  fi
  if [[ "$mode" == "dry-run" ]]; then
    printf '    + download latest nerd-fonts JetBrainsMono.zip; refresh font cache\n'
    return
  fi
  local work metadata asset url digest
  work="$(mktemp -d /tmp/dotfiles-font.XXXXXX)"
  metadata="$work/release.json"
  curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest -o "$metadata"
  asset="$(jq -c '.assets[] | select(.name=="JetBrainsMono.zip")' "$metadata")"
  url="$(jq -r '.browser_download_url' <<<"$asset")"
  digest="$(jq -r '.digest // empty' <<<"$asset")"
  [[ -n "$url" && "$url" != null ]] || { printf 'JetBrainsMono.zip release asset not found.\n' >&2; exit 1; }
  mkdir -p "$font_dir"
  curl -fL "$url" -o "$work/font.zip"
  if [[ "$digest" == sha256:* ]]; then
    printf '%s  %s\n' "${digest#sha256:}" "$work/font.zip" | sha256sum --check
  else
    printf '    warning: GitHub did not publish a JetBrainsMono.zip digest\n' >&2
  fi
  unzip -q "$work/font.zip" -d "$font_dir"
  fc-cache -f "$font_dir"
  rm -rf "$work"
}

install_editors_and_config() {
  step "Apply dotfiles"
  if [[ "$mode" == "apply" ]]; then
    "$repo/install.sh" --apply
  else
    "$repo/install.sh" --dry-run
  fi

  step "Editor frameworks and plugins"
  clone_if_missing https://github.com/doomemacs/core "$HOME/.config/emacs"
  clone_if_missing https://github.com/kwant-dbg/org-roam-ui.nvim.git "$HOME/dev/org-roam-ui.nvim"
  if [[ "$mode" == "apply" ]]; then
    nvim --headless '+Lazy! sync' +qa
    "$HOME/.config/emacs/bin/doom" install --force --no-config
  else
    printf '    + nvim --headless "+Lazy! sync" +qa\n'
    printf '    + ~/.config/emacs/bin/doom install --force --no-config\n'
  fi
}

main() {
  printf 'Bootstrap mode: %s\nTarget: %s %s (%s)\n' "$mode" "$NAME" "$VERSION_ID" "$(uname -m)"
  if ! grep -qi microsoft /proc/version 2>/dev/null; then
    printf 'WARNING: this is not WSL; tmux clip.exe and Windows integration need adaptation.\n' >&2
  fi
  if [[ -f "$HOME/.npmrc" ]] && grep -Eq '^[[:space:]]*(prefix|globalconfig)[[:space:]]*=' "$HOME/.npmrc"; then
    if [[ "$mode" == "apply" ]]; then
      printf 'Remove prefix/globalconfig from ~/.npmrc before bootstrap; nvm rejects those settings.\n' >&2
      exit 1
    fi
    printf 'WARNING: ~/.npmrc has prefix/globalconfig; remove it before --apply because nvm rejects it.\n' >&2
  fi
  install_base_packages
  install_neovim
  install_go
  install_nvm_node
  install_rust_cli_tools
  install_shell_tools
  install_python_tools
  install_kubernetes_tools
  install_agent_tools
  install_font
  install_editors_and_config

  step "Manual completion"
  printf 'See %s/POST_INSTALL.md for authentication, Docker Desktop, Teleport, kube contexts, and work-only setup.\n' "$repo"
  [[ "$mode" == "dry-run" ]] && printf 'No changes made. Run ./bootstrap.sh --apply when ready.\n'
}

main "$@"
