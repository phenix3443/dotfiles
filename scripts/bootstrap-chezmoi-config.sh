#!/usr/bin/env sh
# Bootstrap ~/.config/chezmoi/chezmoi.toml before first chezmoi apply:
# writes encryption, [age], and [keepassxc] so apply does not error with
# "encryption not configured" or "keepassxc.database not set".
# Run once before first chezmoi apply, or as part of: make install

set -e

CONFIG_DIR="${HOME}/.config/chezmoi"
CONFIG_FILE="${CONFIG_DIR}/chezmoi.toml"
KEY_PATH="${HOME}/.config/chezmoi/age.txt"
DB_PATH="${HOME}/.config/keepassxc/chezmoi.kdbx"
RECIPIENT="age1ysazs0jjmru5hshy9zwap03rpf8qsqg44wmpqx8ux06qqg32kudsmtmpm8"

mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_FILE" ] && grep -q 'encryption' "$CONFIG_FILE" 2>/dev/null; then
  exit 0
fi

cat > "$CONFIG_FILE" << EOF
encryption = "age"
[age]
identity = "$KEY_PATH"
recipient = "$RECIPIENT"

[keepassxc]
database = "$DB_PATH"
EOF

echo "Bootstrap config written to $CONFIG_FILE (encryption + age + keepassxc)"
