#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DOTFILES_DIR/manifest.tsv"
MODE="dry-run"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run|--apply]

  --dry-run  Show the links and backups that would be created (default).
  --apply    Back up existing targets, then create the links.
EOF
}

case "${1:---dry-run}" in
  --dry-run) ;;
  --apply) MODE="apply" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ ! -f "$MANIFEST" ]]; then
  printf 'Missing manifest: %s\n' "$MANIFEST" >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backups/$timestamp"
changes=0

render_template() {
  local src="$1" dst="$2" escaped_home
  escaped_home="${HOME//&/\\&}"
  escaped_home="${escaped_home//#/\\#}"
  sed "s#/home/trip#${escaped_home}#g" "$src" > "$dst"
}

while IFS=$'\t' read -r source target mode; do
  [[ -n "${source:-}" && "${source:0:1}" != "#" ]] || continue
  mode="${mode:-link}"

  src="$DOTFILES_DIR/$source"
  dst="$HOME/$target"

  if [[ ! -e "$src" ]]; then
    printf 'ERROR missing source: %s\n' "$src" >&2
    exit 1
  fi

  if [[ "$mode" == "link" && -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    printf 'ok      %s\n' "$dst"
    continue
  fi

  if [[ "$mode" == "copy" && -f "$dst" ]] && cmp -s "$src" "$dst"; then
    printf 'ok      %s\n' "$dst"
    continue
  fi

  if [[ "$mode" == "template" && -f "$dst" ]] && render_template "$src" /dev/stdout | cmp -s - "$dst"; then
    printf 'ok      %s\n' "$dst"
    continue
  fi

  changes=$((changes + 1))
  if [[ "$MODE" == "dry-run" ]]; then
    if [[ -e "$dst" || -L "$dst" ]]; then
      printf 'backup  %s -> %s/%s\n' "$dst" "$backup_root" "$target"
    fi
    printf '%-7s %s <- %s\n' "$mode" "$dst" "$src"
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup="$backup_root/$target"
    mkdir -p "$(dirname "$backup")"
    mv "$dst" "$backup"
    printf 'backed  %s -> %s\n' "$dst" "$backup"
  fi
  if [[ "$mode" == "copy" ]]; then
    cp -a "$src" "$dst"
    printf 'copied  %s <- %s\n' "$dst" "$src"
  elif [[ "$mode" == "template" ]]; then
    render_template "$src" "$dst"
    printf 'rendered %s <- %s\n' "$dst" "$src"
  else
    ln -s "$src" "$dst"
    printf 'linked  %s -> %s\n' "$dst" "$src"
  fi
done < "$MANIFEST"

if [[ "$MODE" == "dry-run" ]]; then
  printf '\nDry run only: %d change(s). Run ./install.sh --apply to install.\n' "$changes"
else
  mkdir -p "$HOME/.tmux/tmp"
  chmod 700 "$HOME/.tmux/tmp"
  printf '\nInstalled %d change(s). Backups: %s\n' "$changes" "$backup_root"
fi
