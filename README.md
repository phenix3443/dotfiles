# Dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理 dotfiles，敏感文件通过 age 加密后提交仓库。源状态位于 `dotfiles/`（通过 `.chezmoiroot` 配置）。

## 核心特性

- **安全管理敏感信息** -- 需入库的敏感文件通过 age 加密；应用自身配置保持各自管理方式
- **跨机器同步** -- 模板在多台机器间同步，敏感信息本地管理
- **自动化部署** -- 一键安装依赖、配置 hooks、应用配置
- **文件监控** -- 后台服务自动检测配置变化并同步到仓库

## 快速开始

### 1. 安装依赖

```bash
make install
```

自动检测包管理器，支持 Linux / macOS / Windows。可通过 `INSTALL_BIN=~/bin` 指定二进制目录（默认 `~/.local/bin`）。

### 2. 配置密钥

```bash
make setup-age-keys            # 生成 age 密钥对
chezmoi apply                  # 使 chezmoi.toml.tmpl 生效
```

### 3. 应用配置

```bash
chezmoi apply                  # 应用所有配置
```

## 管理的配置

| 配置 | 说明 | 文档 |
|------|------|------|
| SSH | 模块化配置 + age 加密 + 自动同步 | [docs/ssh.md](docs/ssh.md) |
| Kubernetes | kubeconfig（age 加密） | [docs/kubeconfig.md](docs/kubeconfig.md) |
| Cursor | settings.json、keybindings.json | [docs/cursor.md](docs/cursor.md) |
| Claude Code / Codex | `dot_claude/`、`dot_codex/`、gstack 安装流程 | [docs/claude.md](docs/claude.md) |
| Zsh | `dot_zshrc` + `conf.d/` | [docs/zsh.md](docs/zsh.md) |
| 文件监控 | 通用后台服务，自动同步所有管理的文件 | [docs/watcher.md](docs/watcher.md) |

## 命令速查

运行 `make help` 查看全部命令。

### 安装与设置

| 命令 | 说明 |
|------|------|
| `make install` | 安装所有依赖并配置 hooks |
| `make install-gstack` | 安装 gstack，并注册到 Claude Code 与 Codex |
| `make setup-age-keys` | 生成 age 密钥对 |
| `make bootstrap-chezmoi-config` | 新机器上引导 chezmoi 配置 |

### 配置应用与同步

| 命令 | 说明 |
|------|------|
| `chezmoi apply` | 应用所有配置 |
| `chezmoi diff` | 预览变更 |
| `make apply-ssh` | 仅应用 SSH 配置 |
| `make apply-claude` | 仅应用 Claude 配置（普通 settings.json） |
| `make apply-codex` | 仅应用 Codex 配置 |
| `make apply-zsh` | 仅应用 ~/.zshrc 与 ~/.config/zsh |
| `make apply-cursor` | 仅应用 Cursor 配置 |
| `make apply-kube` | 仅应用 ~/.kube/config（从 age 解密） |
| `make sync-ssh` | 同步本地 SSH 配置到仓库 |
| `make sync-claude` | 本机 Claude 配置原样写回仓库（提交前勿含密钥） |
| `make sync-codex` | 同步本机 Codex 配置到仓库 |
| `make sync-zsh` | 本机 zsh / conf.d 写回仓库（跳过已废弃的 `30-claude.zsh`） |
| `make sync-cursor` | 同步本地 Cursor 配置到仓库 |
| `make sync-kube` | 加密 ~/.kube/config 到仓库 |
| `make check-sync` | 中文提示：哪些配置与仓库不一致；未覆盖项见脚本末尾说明 |
| `make shellcheck` / `make lint` | 运行 shellcheck 检查所有脚本（与 CI 一致） |

### 文件监控

| 命令 | 说明 |
|------|------|
| `make install-chezmoi-watcher` | 安装通用监控服务（推荐） |
| `make status-chezmoi-watcher` | 查看服务状态 |
| `make logs-chezmoi-watcher` | 查看服务日志 |
| `make uninstall-chezmoi-watcher` | 卸载服务 |

## 模板与敏感信息

模板文件（`*.tmpl`）用于生成目标文件。需要保密的文件内容优先通过 age 加密后纳入仓库；工具私有的本机敏感配置应保留在各自的本地配置文件中。

## 安全机制

- **Pre-commit（gitleaks）** -- 提交前本地扫描，`make install` 已自动配置
- **CI（TruffleHog）** -- GitHub Actions 深度扫描，配置见 `.github/workflows/secret-scanning.yml`

**不提交到 git**：age 私钥（`~/.config/chezmoi/age.txt`）和 `chezmoi apply` 生成的本机敏感文件。

## 新机器部署

```bash
git clone <repo-url> ~/.local/share/chezmoi
# 将 age 私钥放到 ~/.config/chezmoi/age.txt
make bootstrap-chezmoi-config
chezmoi apply
```

## 注意事项

1. 需准备 age 私钥 `~/.config/chezmoi/age.txt` 以解密受管的加密文件
2. 生成的配置文件由 chezmoi 管理，不宜手动修改
