#!/usr/bin/env sh
# KeePassXC entry CRUD: add, show, edit, rm, ls, search

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

DEFAULT_DB="${KEEPASSXC_DB:-$HOME/.local/share/chezmoi.kdbx}"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

expand_tilde() {
  case "$1" in
    "~")   echo "$HOME" ;;
    "~/"*) echo "$HOME/${1#"~/"}" ;;
    *)     echo "$1" ;;
  esac
}

prompt() {
  printf "%s [%s]: " "$1" "$2" >&2
  if [ -t 0 ]; then
    read -r reply </dev/tty
  else
    read -r reply
  fi
  echo "${reply:-$2}"
}

prompt_required() {
  while true; do
    printf "%s: " "$1" >&2
    if [ -t 0 ]; then
      read -r reply </dev/tty
    else
      read -r reply
    fi
    if [ -n "$reply" ]; then
      echo "$reply"
      return
    fi
  done
}

get_db_path() {
  db_path=$(expand_tilde "$(prompt "KeePassXC database path" "$DEFAULT_DB")")
}

require_keepassxc_cli() {
  if ! command -v keepassxc-cli >/dev/null 2>&1; then
    echo "Error: keepassxc-cli not found. Run: make install-keepassxc-cli"
    exit 1
  fi
}

require_db_exists() {
  if [ ! -f "$db_path" ]; then
    echo "Error: Database not found: $db_path"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Commands
# -----------------------------------------------------------------------------

cmd_add() {
  get_db_path
  entry_path=$(prompt_required "Entry path (e.g. Claude Code or Internet/MyService)")
  username=$(prompt "Username" "")
  url=$(prompt "URL" "")
  notes=$(prompt "Notes" "")

  echo "" >&2
  echo "Adding entry: $entry_path" >&2
  [ -n "$username" ] && echo "  Username: $username" >&2
  [ -n "$url" ] && echo "  URL:      $url" >&2
  [ -n "$notes" ] && echo "  Notes:    $notes" >&2
  echo "" >&2

  if [ ! -f "$db_path" ]; then
    echo "Database does not exist. Creating..." >&2
    db_dir=$(dirname "$db_path")
    if [ ! -d "$db_dir" ]; then
      if ! mkdir -p "$db_dir" 2>/dev/null; then
        echo "Error: Cannot create directory: $db_dir" >&2
        echo "Check the path or use default: $DEFAULT_DB" >&2
        exit 1
      fi
    fi
    keepassxc-cli db-create "$db_path" -p
    echo "" >&2
  fi

  echo "You will be prompted for database password, entry password, and confirmation." >&2
  keepassxc-cli add "$db_path" "$entry_path" -p \
    ${username:+-u "$username"} \
    ${url:+--url "$url"} \
    ${notes:+--notes "$notes"}

  echo ""
  echo "Done."
}

cmd_show() {
  get_db_path
  require_db_exists
  entry_path=$(prompt_required "Entry path")

  echo "" >&2
  keepassxc-cli show "$db_path" "$entry_path"
}

cmd_edit() {
  get_db_path
  require_db_exists
  entry_path=$(prompt_required "Entry path")

  echo "" >&2
  echo "Leave blank to keep current value." >&2
  title=$(prompt "Title" "")
  username=$(prompt "Username" "")
  url=$(prompt "URL" "")
  notes=$(prompt "Notes" "")
  printf "Change password? [y/N]: " >&2
  if [ -t 0 ]; then
    read -r change_pass </dev/tty
  else
    read -r change_pass
  fi

  if [ -z "$title$username$url$notes" ] && [ "$change_pass" != "y" ] && [ "$change_pass" != "Y" ]; then
    echo "No changes specified." >&2
    exit 0
  fi

  echo "" >&2
  if [ "$change_pass" = "y" ] || [ "$change_pass" = "Y" ]; then
    echo "You will be prompted for database password and new entry password." >&2
    keepassxc-cli edit "$db_path" "$entry_path" -p \
      ${title:+-t "$title"} \
      ${username:+-u "$username"} \
      ${url:+--url "$url"} \
      ${notes:+--notes "$notes"}
  else
    echo "You will be prompted for database password." >&2
    keepassxc-cli edit "$db_path" "$entry_path" \
      ${title:+-t "$title"} \
      ${username:+-u "$username"} \
      ${url:+--url "$url"} \
      ${notes:+--notes "$notes"}
  fi

  echo ""
  echo "Done."
}

cmd_rm() {
  get_db_path
  require_db_exists
  entry_path=$(prompt_required "Entry path")

  echo "" >&2
  printf "Remove entry '%s'? [y/N]: " "$entry_path" >&2
  if [ -t 0 ]; then
    read -r confirm </dev/tty
  else
    read -r confirm
  fi
  case "$confirm" in
    [yY]|[yY][eE][sS])
      keepassxc-cli rm "$db_path" "$entry_path"
      echo "Done."
      ;;
    *)
      echo "Cancelled."
      ;;
  esac
}

cmd_ls() {
  get_db_path
  require_db_exists
  group=$(prompt "Group (empty for root)" "/")
  group=${group:-/}

  echo "" >&2
  keepassxc-cli ls "$db_path" "$group" -R -f
}

cmd_search() {
  get_db_path
  require_db_exists
  term=$(prompt_required "Search term")

  echo "" >&2
  keepassxc-cli search "$db_path" "$term"
}

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

show_help() {
  echo "Usage: $(basename "$0") <command> [OPTIONS]"
  echo ""
  echo "KeePassXC entry CRUD (add, show, edit, rm, ls, search)."
  echo ""
  echo "Commands:"
  echo "  add     Create a new entry"
  echo "  show    Display an entry"
  echo "  edit    Modify an entry"
  echo "  rm      Remove an entry"
  echo "  ls      List entries (optionally in a group)"
  echo "  search  Find entries by term"
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help"
  echo ""
  echo "Environment:"
  echo "  KEEPASSXC_DB  Default database path (default: ~/.local/share/chezmoi.kdbx)"
}

# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------

case "${1:-}" in
  -h|--help|"") show_help; exit 0 ;;
esac

require_keepassxc_cli

case "$1" in
  add)    cmd_add ;;
  show)   cmd_show ;;
  edit)   cmd_edit ;;
  rm)     cmd_rm ;;
  ls)     cmd_ls ;;
  search) cmd_search ;;
  *)
    echo "Error: Unknown command '$1'"
    echo ""
    show_help
    exit 1
    ;;
esac
