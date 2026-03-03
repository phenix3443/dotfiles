#!/usr/bin/env sh
# Decrypt KeePassXC database so keepassxc() template functions can read it.
# Runs before other targets (ASCII order: .claude < .config), so the DB exists when templates run.
set -e

SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-.}"
KEY="${HOME}/.config/chezmoi/age.txt"
SRC="${SOURCE_DIR}/dot_config/keepassxc/encrypted_private_chezmoi.kdbx.age"
OUT="${HOME}/.config/keepassxc/chezmoi.kdbx"

if [ ! -f "$SRC" ] || [ ! -f "$KEY" ]; then
  exit 0
fi

if ! command -v age >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
age --decrypt -i "$KEY" -o "$OUT" "$SRC"
