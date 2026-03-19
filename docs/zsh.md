# Zsh (chezmoi)

## Layout

| Target | Source in repo |
|--------|----------------|
| `~/.zshrc` | [dotfiles/dot_zshrc](../dotfiles/dot_zshrc) |
| `~/.config/zsh/conf.d/*.zsh` | [dotfiles/dot_config/zsh/conf.d/](../dotfiles/dot_config/zsh/conf.d/) |

`dot_zshrc` loads every `*.zsh` in `conf.d` (zsh glob `(N)`), then sources **`~/.zshrc.local`** if present.

### conf.d files (loaded in alphabetical order)

| File | Purpose |
|------|---------|
| `00-compinit.zsh` | fpath setup and compinit initialization |
| `05-zsh-syntax-highlighting.zsh` | Load zsh-syntax-highlighting plugin (requires Homebrew) |
| `06-zsh-autosuggestions.zsh` | Load zsh-autosuggestions plugin (requires Homebrew) |
| `10-asdf-path.zsh` | asdf version manager path setup |
| `20-local-bin-path.zsh` | ~/.local/bin path setup |
| `claude.zsh` | Claude Code API credentials (generated from claude.zsh.tmpl) |

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
| `make install-zsh-plugins` | Ensure Homebrew and zsh plugins (syntax-highlighting, autosuggestions) are installed |
| `make apply-zsh` | Ensure plugins installed, then apply `~/.zshrc` and `~/.config/zsh` (KeePassXC when templates run) |
| `make sync-zsh` | Copy `~/.zshrc` and `conf.d/*.zsh` into repo; **skips** `claude.zsh` (keep `claude.zsh.tmpl`) |

**Note**: `make apply-zsh` automatically runs `ensure-zsh-plugins.sh` first, which will:
- Install Homebrew if missing (macOS only)
- Install `zsh-syntax-highlighting` and `zsh-autosuggestions` via Homebrew
- On Linux, requires Homebrew to be pre-installed

## New machine

1. Age key + KeePassXC DB as in main README.
2. Create KeePassXC entry **Claude Code** (Password = API token, URL = base URL).
3. `make install` (includes `install-zsh-plugins`) or `make apply-zsh` (auto-installs plugins if missing).

## Optional: other local-only exports

Use **`~/.zshrc.local`** for keys not stored in KeePassXC.

## Optional: sync from local to repo

`make sync-zsh` runs [sync-zsh-config.sh](../scripts/sync-zsh-config.sh). Edit `claude.zsh` behavior only via **`claude.zsh.tmpl`** and KeePassXC, not via sync.
