#!/usr/bin/env sh
# Install gstack once and register its skills for Claude Code and Codex.
# https://github.com/garrytan/gstack

set -e

GSTACK_REPO_URL="https://github.com/garrytan/gstack.git"
GSTACK_ROOT="${HOME}/.gstack/repos/gstack"
GSTACK_PARENT="$(dirname "$GSTACK_ROOT")"

need_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "需要命令 $1，但当前未安装。" >&2
    exit 1
  fi
}

update_repo() {
  if [ ! -d "$GSTACK_ROOT/.git" ]; then
    mkdir -p "$GSTACK_PARENT"
    echo "Cloning gstack into $GSTACK_ROOT..."
    git clone --single-branch --depth 1 "$GSTACK_REPO_URL" "$GSTACK_ROOT"
    return 0
  fi

  if [ -n "$(git -C "$GSTACK_ROOT" status --porcelain 2>/dev/null)" ]; then
    echo "gstack repo has local changes; skipping update: $GSTACK_ROOT"
    return 0
  fi

  echo "Updating gstack in $GSTACK_ROOT..."
  current_branch="$(git -C "$GSTACK_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [ -n "$current_branch" ] && [ "$current_branch" != "main" ]; then
    git -C "$GSTACK_ROOT" checkout main
  fi
  git -C "$GSTACK_ROOT" pull --ff-only origin main
}

run_setup() {
  host="$1"

  echo "Registering gstack for $host..."
  (
    cd "$GSTACK_ROOT"
    ./setup --host "$host" --no-prefix --quiet
  )
}

verify_path() {
  path="$1"
  label="$2"

  if [ -e "$path" ]; then
    echo "$label ready: $path"
    return 0
  fi

  echo "$label install verification failed: $path not found" >&2
  return 1
}

need_command git
need_command bun
need_command claude
need_command codex

update_repo
run_setup claude
run_setup codex

verify_path "${HOME}/.claude/skills/gstack" "Claude gstack"
verify_path "${HOME}/.codex/skills/gstack" "Codex gstack"

echo "gstack installed successfully for Claude Code and Codex."
