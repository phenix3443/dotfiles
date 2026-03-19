# Zsh (chezmoi)

## Layout

| Target | Source in repo |
|--------|----------------|
| `~/.zshrc` | [dotfiles/dot_zshrc](../dotfiles/dot_zshrc) |
| `~/.config/zsh/conf.d/*.zsh` | [dotfiles/dot_config/zsh/conf.d/](../dotfiles/dot_config/zsh/conf.d/) |

`dot_zshrc` loads every `*.zsh` in `conf.d` (zsh glob `(N)`), then sources **`~/.zshrc.local`** if present.

### conf.d files (loaded in alphabetical order)

**数字前缀控制加载顺序**，确保依赖关系正确：

| File | Purpose | Why this order? |
|------|---------|-----------------|
| `00-compinit.zsh` | fpath setup and compinit initialization | 必须最先：其他插件依赖补全系统 |
| `06-zsh-autosuggestions.zsh` | Load zsh-autosuggestions plugin (requires Homebrew) | compinit 之后 |
| `10-asdf-path.zsh` | asdf version manager fpath and PATH setup | 在插件之后设置环境变量 |
| `20-local-bin-path.zsh` | ~/.local/bin path setup | 最后修改 PATH |
| `30-claude.zsh` | Claude Code API credentials (generated from 30-claude.zsh.tmpl) | 无依赖，环境变量设置 |
| `99-zsh-syntax-highlighting.zsh` | Load zsh-syntax-highlighting plugin (requires Homebrew) | **必须最后**：官方要求在所有插件之后加载 |

## Claude env (`30-claude.zsh`)

[30-claude.zsh.tmpl](../dotfiles/dot_config/zsh/conf.d/30-claude.zsh.tmpl) renders to `~/.config/zsh/conf.d/30-claude.zsh`:

- **ANTHROPIC_AUTH_TOKEN** from KeePassXC entry **`Claude Code`** (Password)
- **ANTHROPIC_BASE_URL** from the same entry (URL field)

Ensure the KeePassXC entry exists before `chezmoi apply`. Apply still runs `run_before` to unlock the database when other templates need it.

Do **not** copy plaintext `30-claude.zsh` from disk back into the repo; keep the `.tmpl` and KeePassXC as the source of truth for secrets.

Other non-secret snippets remain plain `.zsh` files in `conf.d/`.

## Commands

| Command | Description |
|---------|-------------|
| `make install-zsh-plugins` | Ensure Homebrew and zsh plugins (syntax-highlighting, autosuggestions) are installed |
| `make apply-zsh` | Ensure plugins installed, then apply `~/.zshrc` and `~/.config/zsh` (KeePassXC when templates run) |
| `make sync-zsh` | Copy `~/.zshrc` and `conf.d/*.zsh` into repo; **skips** `30-claude.zsh` (keep `30-claude.zsh.tmpl`) |

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

`make sync-zsh` runs [sync-zsh-config.sh](../scripts/sync-zsh-config.sh). Edit `30-claude.zsh` behavior only via **`30-claude.zsh.tmpl`** and KeePassXC, not via sync.
