#!/bin/sh
# Backup files that chezmoi apply will modify
BACKUP_DIR="$HOME/.local/share/chezmoi-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# shellcheck disable=SC2120
status_targets() {
    if [ -z "${CHEZMOI_ARGS:-}" ]; then
        return 1
    fi

    # CHEZMOI_ARGS keeps the original invocation, including any target paths.
    # shellcheck disable=SC2086
    eval "set -- $CHEZMOI_ARGS"

    seen_apply=0
    found_target=1
    while [ "$#" -gt 0 ]; do
        if [ "$seen_apply" -eq 0 ]; then
            if [ "$1" = "apply" ]; then
                seen_apply=1
            fi
            shift
            continue
        fi

        case "$1" in
            -*)
                ;;
            *)
                found_target=0
                printf '%s\n' "$1"
                ;;
        esac
        shift
    done

    return "$found_target"
}

# shellcheck disable=SC2119
if TARGETS="$(status_targets)"; then
    STATUS_ARGS=$TARGETS
else
    STATUS_ARGS=
fi

# shellcheck disable=SC2086
chezmoi status $STATUS_ARGS 2>/dev/null | while read -r flags path; do
    case "$flags" in
        *M*) ;;  # modified
        *) continue ;;
    esac
    src="$HOME/$path"
    [ -f "$src" ] || continue
    dest="$BACKUP_DIR/$path"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
done

echo "Backup saved to $BACKUP_DIR"
