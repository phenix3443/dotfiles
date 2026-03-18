# Zsh (chezmoi)

## Layout

| Target | Source in repo |
|--------|----------------|
| `~/.zshrc` | [dotfiles/dot_zshrc](../dotfiles/dot_zshrc) |
| `~/.config/zsh/conf.d/*.zsh` | [dotfiles/dot_config/zsh/conf.d/](../dotfiles/dot_config/zsh/conf.d/) |

`dot_zshrc` loads every `*.zsh` in `conf.d` (zsh glob `(N)`), then sources **`~/.zshrc.local`** if present.

## Claude env (`claude.zsh`)

[claude.zsh.tmpl](../dotfiles/dot_config/zsh/conf.d/claude.zsh.tmpl) renders to `~/.config/zsh/conf.d/claude.zsh`:

- **ANTHROPIC_AUTH_TOKEN** from KeePassXC entry **`Claude Code`** (Password)
- **ANTHROPIC_BASE_URL** from the same entry (URL field)

Ensure the KeePassXC entry exists before `chezmoi apply`. Apply still runs `run_before` to unlock the database when other templates need it.

Do **not** copy plaintext `claude.zsh` from disk back into the repo; keep the `.tmpl` and KeePassXC as the source of truth for secrets.

Other non-secret snippets remain plain `.zsh` files in `conf.d/`.

## Commands

| Command | Description |
|---------|-------------|
| `make apply-zsh` | Apply `~/.zshrc` and `~/.config/zsh` (KeePassXC when templates run) |
| `make sync-zsh` | Copy `~/.zshrc` and `conf.d/*.zsh` into repo; **skips** `claude.zsh` (keep `claude.zsh.tmpl`) |

## New machine

1. Age key + KeePassXC DB as in main README.
2. Create KeePassXC entry **Claude Code** (Password = API token, URL = base URL).
3. `chezmoi apply` or `make apply-zsh`.

## Optional: other local-only exports

Use **`~/.zshrc.local`** for keys not stored in KeePassXC.

## Optional: sync from local to repo

`make sync-zsh` runs [sync-zsh-config.sh](../scripts/sync-zsh-config.sh). Edit `claude.zsh` behavior only via **`claude.zsh.tmpl`** and KeePassXC, not via sync.
