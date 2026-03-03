#!/usr/bin/env sh
# Encrypt ~/.kube/config with age and write to private_dot_kube/config.age.
# Uses recipient from dot_config/chezmoi/chezmoi.toml.tmpl. Run from repo root.
#
# Usage:
#   ./scripts/encrypt-kubeconfig.sh
#   make encrypt-kubeconfig

set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(dirname "$0")}"
ROOT="${ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TMPL="$ROOT/dot_config/chezmoi/chezmoi.toml.tmpl"
SRC="${KUBECONFIG:-$HOME/.kube/config}"
OUT="$ROOT/private_dot_kube/config.age"

recipient=$(grep '^recipient = ' "$TMPL" 2>/dev/null | sed 's/.*"\(age1[^"]*\)".*/\1/')
if [ -z "$recipient" ]; then
  echo "Error: could not read recipient from $TMPL" >&2
  exit 1
fi

if [ ! -f "$SRC" ]; then
  echo "Error: kubeconfig not found: $SRC" >&2
  exit 1
fi

if ! command -v age >/dev/null 2>&1; then
  echo "Error: age not found. Install age (e.g. make install-age)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
age -e -r "$recipient" -o "$OUT" "$SRC"
echo "Encrypted $SRC -> $OUT"
