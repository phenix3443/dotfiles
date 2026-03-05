# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository with integrated KeePassXC for secure credential management and age encryption for sensitive files. The source state lives in the `dotfiles/` subdirectory (configured via `.chezmoiroot`).

## Architecture

**Core Components:**
- **chezmoi templates** (`dotfiles/**/*.tmpl`): Template files that inject secrets from KeePassXC at apply time
- **KeePassXC integration**: Credentials stored in `~/.config/keepassxc/chezmoi.kdbx`, accessed via `keepassxc` template function
- **age encryption**: Sensitive files (KeePassXC database, kubeconfig) encrypted with age before committing
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
- Encrypted files stored as `*.age` in source state

**New Machine Setup:**
1. Clone repository
2. Place age private key at `~/.config/chezmoi/age.txt`
3. Run `make bootstrap-chezmoi-config`
4. Run `chezmoi apply` (decrypts KeePassXC database, applies all configs)

## File Structure

- `dotfiles/` - chezmoi source state (actual source root via `.chezmoiroot`)
- `make/*.mk` - modular Makefile components (chezmoi, keepassxc, age, lefthook, gitleaks, add-skill, claude, common)
- `scripts/` - installation and management scripts
- `tests/` - test scripts for utilities
- `.gitleaks.toml` - gitleaks configuration for secret scanning
- `lefthook.yml` - git hooks configuration (pre-commit: gitleaks)

## Important Notes

- KeePassXC database password required for every `chezmoi apply`
- Entry names in templates must exactly match KeePassXC (case-sensitive)
- Age private key (`~/.config/chezmoi/age.txt`) must never be committed
- Generated files contain real secrets - managed by chezmoi, not for manual editing
- Use `git commit --no-verify` only for gitleaks false positives
