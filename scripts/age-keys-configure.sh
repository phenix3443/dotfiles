#!/usr/bin/env sh
# 配置 chezmoi 使用 age：
# - 生成（或复用）age 私钥到 ~/.config/chezmoi/age.txt
# - 计算对应公钥
# - 更新 dotfiles/dot_config/chezmoi/chezmoi.toml.tmpl 中 [age] 的 recipient
#
# 用法（在 dotfiles 仓库根目录）:
#   ./scripts/age-keys-configure.sh           # 默认使用 ~/.config/chezmoi/age.txt（不存在则生成）
#   ./scripts/age-keys-configure.sh age.txt  # 使用指定私钥文件，并复制到 ~/.config/chezmoi/age.txt

set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(dirname "$0")}"
ROOT="${ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SOURCE_STATE="${ROOT}/dotfiles"
TMPL="$SOURCE_STATE/dot_config/chezmoi/chezmoi.toml.tmpl"
KEY_DIR="${HOME}/.config/chezmoi"
KEY_FILE="$KEY_DIR/age.txt"

usage() {
  cat <<EOF
Usage: $(basename "$0") [PRIVATE_KEY_FILE]

Configure chezmoi age encryption:
  - Ensure private key at $KEY_FILE
  - Derive public key with age-keygen -y
  - Update recipient in $TMPL

If PRIVATE_KEY_FILE is given, it will be copied to $KEY_FILE first.
EOF
}

error() {
  echo "Error: $*" >&2
  exit 1
}

ensure_prereqs() {
  if [ ! -f "$TMPL" ]; then
    error "Template not found: $TMPL (run from dotfiles repo root)"
  fi

  if ! command -v age-keygen >/dev/null 2>&1; then
    error "age-keygen not found. Install age first (e.g. make install-age)"
  fi

  mkdir -p "$KEY_DIR"
}

derive_public_key() {
  ARG_KEY="${1:-}"

  if [ -n "$ARG_KEY" ]; then
    # 从命令行提供的私钥文件生成/更新配置
    if [ ! -f "$ARG_KEY" ]; then
      error "Private key file not found: $ARG_KEY"
    fi
    echo "Using private key from: $ARG_KEY"
    cp "$ARG_KEY" "$KEY_FILE"
    chmod 600 "$KEY_FILE" 2>/dev/null || true
    PUBLIC_KEY=$(age-keygen -y "$KEY_FILE")
  else
    if [ -f "$KEY_FILE" ]; then
      echo "Using existing key: $KEY_FILE"
      PUBLIC_KEY=$(age-keygen -y "$KEY_FILE")
    else
      echo "Generating new age key at: $KEY_FILE"
      # age-keygen 将私钥写入文件，公钥打印到 stderr
      OUTPUT=$(age-keygen -o "$KEY_FILE" 2>&1)
      PUBLIC_KEY=$(echo "$OUTPUT" | sed -n 's/.*Public key: *//p')
      if [ -z "$PUBLIC_KEY" ]; then
        error "Failed to get public key from age-keygen output"
      fi
      echo "Public key: $PUBLIC_KEY"
    fi
  fi
}

update_template() {
  # 替换模板中的 recipient 占位符或已有公钥
  if grep -q 'recipient = "age1' "$TMPL"; then
    # 使用 | 作为 sed 分隔符，避免公钥中的字符干扰
    sed -i.bak "s|recipient = \"age1[^\"]*\"|recipient = \"$PUBLIC_KEY\"|" "$TMPL"
    rm -f "${TMPL}.bak"
    echo "Updated recipient in $TMPL"
  else
    echo "Warning: No recipient line found in $TMPL to update."
    echo "Add this to [age] section: recipient = \"$PUBLIC_KEY\""
  fi
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

ensure_prereqs
derive_public_key "${1:-}"
update_template

echo ""
echo "Done. Private key: $KEY_FILE (do not commit)"
echo "Public key has been set in dotfiles/dot_config/chezmoi/chezmoi.toml.tmpl"
