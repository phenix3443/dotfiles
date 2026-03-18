# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository with integrated KeePassXC for secure credential management and age encryption for sensitive files. The source state lives in the `dotfiles/` subdirectory (configured via `.chezmoiroot`).

## Architecture

**Core Components:**
- **chezmoi templates** (`dotfiles/**/*.tmpl`): Template files that inject secrets from KeePassXC at apply time
- **KeePassXC integration**: Credentials stored in `~/.config/keepassxc/chezmoi.kdbx`, accessed via `keepassxc` template function
- **age encryption**: Sensitive files (KeePassXC database, kubeconfig, SSH configs) encrypted with age before committing
- **SSH config management**: Modular SSH configs with auto-sync watcher service (see `docs/ssh-watcher.md`)
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
make install INSTALL_BIN=~/bin  # Specify custom binary directory (default: ~/.local/bin)
```

**KeePassXC Entry Management:**
```bash
make keepassxc-entry add     # Add new entry (prompts for path, username, URL, password)
make keepassxc-entry show    # Show entry details
make keepassxc-entry edit    # Edit existing entry
make keepassxc-entry rm      # Remove entry
make keepassxc-entry ls      # List all entries
make keepassxc-entry search  # Search entries
```

**chezmoi Operations:**
```bash
chezmoi apply                           # Apply all templates (prompts for KeePassXC password)
chezmoi apply ~/.config/app/config.json # Apply specific file
chezmoi diff                            # Preview changes before applying
chezmoi execute-template < file.tmpl    # Test template rendering without writing
```

**Age Encryption Setup:**
```bash
make setup-age-keys        # Generate age keypair, update chezmoi.toml.tmpl recipient
make encrypt-kubeconfig    # Encrypt ~/.kube/config to dotfiles/private_dot_kube/config.age
```

**SSH Config Management:**
```bash
make sync-ssh              # Sync local SSH config to repository (manual)
make apply-ssh             # Apply SSH config from repository
make install-ssh-watcher   # Install SSH-specific watcher service
```

**Universal File Watcher (Recommended):**
```bash
make install-chezmoi-watcher   # Install universal watcher for ALL managed files
make status-chezmoi-watcher    # Show watcher service status
make logs-chezmoi-watcher      # View watcher service logs
make uninstall-chezmoi-watcher # Uninstall watcher service
```

The universal watcher automatically:
- Detects all chezmoi-managed files
- Watches directories: ~/.ssh, ~/.claude, ~/.config, Cursor configs, etc.
- Routes to specific sync scripts (SSH, Claude, Cursor) or uses generic `chezmoi add`
- Auto-detects and installs fswatch if needed

**Testing:**
```bash
make test  # Run keepassxc-entry tests
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

- `dotfiles/` - chezmoi source state (actual source root via `.chezmoiroot`)
  - `private_dot_ssh/` - SSH configs (encrypted .sconf files, scripts)
- `make/*.mk` - modular Makefile components (chezmoi, keepassxc, age, ssh, lefthook, gitleaks, add-skill, claude, cursor, common)
- `scripts/` - installation and management scripts
  - `sync-ssh-config.sh` - SSH config sync script
  - `watch-ssh-config.sh` - SSH config file watcher
  - `install-ssh-watcher.sh` - SSH watcher service installer
- `tests/` - test scripts for utilities
- `docs/` - documentation (ssh-watcher.md, kubeconfig.md, claude.md, cursor.md)
- `.gitleaks.toml` - gitleaks configuration for secret scanning
- `lefthook.yml` - git hooks configuration (pre-commit: gitleaks)

## Important Notes

- KeePassXC database password required for every `chezmoi apply`
- Entry names in templates must exactly match KeePassXC (case-sensitive)
- Age private key (`~/.config/chezmoi/age.txt`) must never be committed
- Generated files contain real secrets - managed by chezmoi, not for manual editing
- Use `git commit --no-verify` only for gitleaks false positives
