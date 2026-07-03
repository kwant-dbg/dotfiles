#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$repo/manifest.tsv"
errors=0

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  errors=$((errors + 1))
}

declare -A sources targets
while IFS=$'\t' read -r source target mode; do
  [[ -n "${source:-}" && "${source:0:1}" != "#" ]] || continue
  mode="${mode:-link}"
  [[ -n "${target:-}" ]] || { fail "missing target for $source"; continue; }
  [[ "$mode" == "link" || "$mode" == "copy" || "$mode" == "template" ]] || fail "invalid mode for $source: $mode"
  [[ -e "$repo/$source" || -L "$repo/$source" ]] || fail "missing source: $source"
  [[ -z "${sources[$source]:-}" ]] || fail "duplicate source: $source"
  [[ -z "${targets[$target]:-}" ]] || fail "duplicate target: $target"
  sources[$source]=1
  targets[$target]=1
done < "$manifest"

bash -n "$repo/install.sh" || fail "install.sh syntax"
bash -n "$repo/bootstrap.sh" || fail "bootstrap.sh syntax"
bash -n "$repo/doctor.sh" || fail "doctor.sh syntax"
bash -n "$repo/bin/codex" || fail "bin/codex syntax"
bash -n "$repo/bin/img" || fail "bin/img syntax"
bash -n "$repo/bin/yum-litellm-key-helper-robust" || fail "LiteLLM wrapper syntax"
zsh -n "$repo/zshrc" || fail "zshrc syntax"
zsh -n "$repo/bin/dev" || fail "bin/dev syntax"
git -C "$repo" diff --check || fail "Git whitespace errors"

if command -v jq >/dev/null; then
  while IFS= read -r file; do
    jq -e . "$file" >/dev/null || fail "invalid JSON: ${file#$repo/}"
  done < <(find "$repo" -path "$repo/.git" -prune -o -type f -name '*.json' -print | sort)
fi

if command -v python3 >/dev/null; then
  while IFS= read -r file; do
    python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$file" \
      || fail "invalid TOML: ${file#$repo/}"
  done < <(find "$repo" -path "$repo/.git" -prune -o -type f -name '*.toml' -print | sort)
fi

while IFS= read -r link; do
  resolved="$(readlink -f "$link" || true)"
  [[ -n "$resolved" && "$resolved" == "$repo"/* ]] || fail "external or dangling symlink: ${link#$repo/}"
done < <(find "$repo" -path "$repo/.git" -prune -o -type l -print)

ignored="$(find "$repo" -path "$repo/.git" -prune -o -type f -print | git -C "$repo" check-ignore --stdin || true)"
[[ -z "$ignored" ]] || fail "snapshot files ignored by Git: $ignored"

if rg -l --hidden -g '!.git/**' -g '!check.sh' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'gh[pousr]_[A-Za-z0-9_]{20,}' \
  -e 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' \
  -e 'access_token:[[:space:]]*[^[:space:]]+' \
  -e 'refresh_token:[[:space:]]*[^[:space:]]+' "$repo"; then
  fail "high-signal credential pattern detected"
fi

(( errors == 0 )) || exit 1
printf 'dotfiles check passed (%s manifest entries)\n' "$(awk -F '\t' 'NF && $1 !~ /^#/ {n++} END {print n}' "$manifest")"
