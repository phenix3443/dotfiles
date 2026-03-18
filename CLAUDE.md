# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository with integrated KeePassXC for secure credential management and age encryption for sensitive files. The source state lives in the `dotfiles/` subdirectory (configured via `.chezmoiroot`).

## Architecture

**Core Components:**
- **chezmoi templates** (`dotfiles/**/*.tmpl`): Template files that inject secrets from KeePassXC at apply time
- **KeePassXC integration**: Credentials stored in `~/.config/keepassxc/chezmoi.kdbx`, accessed via `keepassxc` template function
- **age encryption**: Sensitive files (KeePassXC database, kubeconfig, SSH configs) encrypted with age before committing
- **File watcher**: Universal auto-sync service monitoring all managed files (see `docs/watcher.md`)
- **Makefile system**: Modular makefiles in `make/*.mk` for installation, configuration, and management tasks

**Template System:**
- Templates use `{{ (keepassxc "EntryName").Password }}` to inject secrets from KeePassXC
- Entry names are case-sensitive and support hierarchical paths like `Internet/MyApp`
- Custom attributes accessed via `{{ keepassxcAttribute "EntryName" "AttributeName" }}`
- Age encryption configured in `dotfiles/dot_config/chezmoi/chezmoi.toml.tmpl`

**Security Model:**
- Secrets never committed in plaintext - only templates and age-encrypted files
- Pre-commit hooks (lefthook + gitleaks) scan for leaked credentials
- CI scanning via GitHub Actions (TruffleHog) for historical leaks

## Common Commands

**Installation & Setup:**
```bash
make install                    # Install all dependencies, setup hooks, bootstrap config
make setup-age-keys             # Generate age keypair
make bootstrap-chezmoi-config   # Bootstrap config on new machine
```

**chezmoi Operations:**
```bash
chezmoi apply                           # Apply all templates (prompts for KeePassXC password)
chezmoi apply ~/.config/app/config.json # Apply specific file
chezmoi diff                            # Preview changes before applying
chezmoi execute-template < file.tmpl    # Test template rendering without writing
```

**Per-app Sync & Apply:**
```bash
make sync-ssh / make apply-ssh          # SSH config
make sync-claude / make apply-claude    # Claude Code config
make sync-cursor / make apply-cursor    # Cursor config
make encrypt-kubeconfig                 # Kubernetes kubeconfig
```

**File Watcher (recommended):**
```bash
make install-chezmoi-watcher            # Install universal watcher for ALL managed files
make status-chezmoi-watcher             # Show watcher service status
make logs-chezmoi-watcher               # View watcher service logs
make uninstall-chezmoi-watcher          # Uninstall watcher service
```

**KeePassXC Entry Management:**
```bash
make keepassxc-entry add|show|edit|rm|ls|search
```

**Testing:**
```bash
make test                               # Run keepassxc-entry tests
```

## Development Workflow

**Adding New Managed Files:**
1. Create template in `dotfiles/` with appropriate chezmoi prefix (e.g., `dot_config/app/config.json.tmpl`)
2. Use `{{ (keepassxc "EntryName").Password }}` for secrets
3. Test with `chezmoi execute-template < dotfiles/path/to/file.tmpl`
4. Apply with `chezmoi apply`

**Managing Encrypted Files:**
- For KeePassXC database: `chezmoi add --encrypt ~/.config/keepassxc/chezmoi.kdbx`
- For kubeconfig: `make encrypt-kubeconfig`
- For SSH configs: `chezmoi add --encrypt ~/.ssh/config.d/*.sconf` (or use `make sync-ssh`)
- Encrypted files stored as `*.age` in source state

**New Machine Setup:**
1. Clone repository
2. Place age private key at `~/.config/chezmoi/age.txt`
3. Run `make bootstrap-chezmoi-config`
4. Run `chezmoi apply` (decrypts KeePassXC database, applies all configs)

## File Structure

```
dotfiles/                       # chezmoi source state (via .chezmoiroot)
  .chezmoiscripts/              # run_before / run_after hooks
  .chezmoitemplates/            # shared templates (Cursor configs)
  dot_claude/                   # Claude Code config
  dot_zshrc                     # ~/.zshrc
  dot_config/                   # ~/.config (chezmoi, keepassxc, zsh/conf.d)
  private_dot_ssh/              # SSH configs (encrypted .sconf, scripts)
  private_dot_kube/             # Kubernetes kubeconfig (encrypted)
  private_Library/              # macOS Library (Cursor on macOS)
  AppData/                      # Windows AppData (Cursor on Windows)

make/                           # modular Makefile components
  chezmoi.mk keepassxc.mk age.mk ssh.mk watcher.mk
  claude.mk cursor.mk zsh.mk
  lefthook.mk gitleaks.mk add-skill.mk common.mk

scripts/                        # installation and management scripts
  sync-ssh-config.sh            # SSH config sync (with encryption)
  sync-claude-config.sh         # Claude config sync (plain JSON copy)
  sync-cursor-config.sh         # Cursor config sync (preserves templates)
  watch-chezmoi-files.sh        # Universal file watcher
  install-chezmoi-watcher.sh    # Universal watcher service installer
  watch-ssh-config.sh           # SSH-specific file watcher
  install-ssh-watcher.sh        # SSH watcher service installer
  install-*.sh                  # Tool installation scripts
  encrypt-kubeconfig.sh         # Kubeconfig encryption

tests/                          # test scripts
docs/                           # detailed documentation
  ssh.md watcher.md claude.md cursor.md kubeconfig.md zsh.md
```

## Important Notes

- KeePassXC database password required for every `chezmoi apply`
- Entry names in templates must exactly match KeePassXC (case-sensitive)
- Age private key (`~/.config/chezmoi/age.txt`) must never be committed
- Generated files contain real secrets - managed by chezmoi, not for manual editing
- Use `git commit --no-verify` only for gitleaks false positives
