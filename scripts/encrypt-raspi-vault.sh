#!/usr/bin/env sh
# Encrypt home-lab raspi ansible vault with age and write to dotfiles.
# Uses recipient from dotfiles/dot_config/chezmoi/chezmoi.toml.tmpl. Run from repo root.
#
# Usage:
#   ./scripts/encrypt-raspi-vault.sh
#   make encrypt-raspi-vault

set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(dirname "$0")}"
ROOT="${ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SOURCE_STATE="${ROOT}/dotfiles"
TMPL="$SOURCE_STATE/dot_config/chezmoi/chezmoi.toml.tmpl"
SRC="${RASPI_VAULT:-$HOME/github/womenlia/home-lab/raspi/ansible/group_vars/raspi/vault.yml}"
OUT="$SOURCE_STATE/github/womenlia/home-lab/raspi/ansible/group_vars/raspi/vault.yml.age"

recipient=$(grep '^recipient = ' "$TMPL" 2>/dev/null | sed 's/.*"\(age1[^"]*\)".*/\1/')
if [ -z "$recipient" ]; then
  echo "Error: could not read recipient from $TMPL" >&2
  exit 1
fi

if [ ! -f "$SRC" ]; then
  echo "Error: vault file not found: $SRC" >&2
  exit 1
fi

if ! command -v age >/dev/null 2>&1; then
  echo "Error: age not found. Install age (e.g. make install-age)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
age -e -r "$recipient" -o "$OUT" "$SRC"
echo "Encrypted $SRC -> $OUT"
