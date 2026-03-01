#!/usr/bin/env sh
# Check KeePassXC database and Claude Code entry

set -e

DB_PATH="${KEEPASSXC_DB:-$HOME/.local/share/chezmoi.kdbx}"
ENTRY_NAME="Claude Code"

echo "Checking KeePassXC setup..."
echo "Database: $DB_PATH"
echo ""

if [ ! -f "$DB_PATH" ]; then
  echo "❌ Database not found: $DB_PATH"
  echo ""
  echo "To create it, run:"
  echo "  make keepassxc-entry add"
  exit 1
fi

echo "✓ Database exists"
echo ""
echo "Checking for '$ENTRY_NAME' entry..."
echo "(You will be prompted for database password)"
echo ""

if keepassxc-cli show "$DB_PATH" "$ENTRY_NAME" --quiet >/dev/null 2>&1; then
  echo "✓ Entry '$ENTRY_NAME' exists"
  echo ""
  echo "You can now run: chezmoi apply"
else
  echo "❌ Entry '$ENTRY_NAME' not found"
  echo ""
  echo "To create it, run:"
  echo "  make keepassxc-entry add"
  echo ""
  echo "Then enter:"
  echo "  Entry path: $ENTRY_NAME"
  echo "  URL: https://api.skyapi.org"
  echo "  Password: <your API key>"
  exit 1
fi
