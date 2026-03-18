# Dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理 dotfiles，通过 KeePassXC 注入敏感信息，age 加密后提交仓库。源状态位于 `dotfiles/`（通过 `.chezmoiroot` 配置）。

## 核心特性

- **安全管理敏感信息** -- API keys、tokens、密码存储在 KeePassXC 中，仅模板和加密文件入库
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
chezmoi add --encrypt ~/.config/keepassxc/chezmoi.kdbx  # 加密 KeePassXC 数据库
```

### 3. 应用配置

```bash
chezmoi apply                  # 应用所有配置（需输入 KeePassXC 数据库密码）
```

## 管理的配置

| 配置 | 说明 | 文档 |
|------|------|------|
| KeePassXC | 数据库（age 加密）和应用配置 | 见上文 |
| SSH | 模块化配置 + age 加密 + 自动同步 | [docs/ssh.md](docs/ssh.md) |
| Kubernetes | kubeconfig（age 加密） | [docs/kubeconfig.md](docs/kubeconfig.md) |
| Cursor | settings.json、keybindings.json | [docs/cursor.md](docs/cursor.md) |
| Claude Code | settings.json（KeePassXC 注入 token） | [docs/claude.md](docs/claude.md) |
| 文件监控 | 通用后台服务，自动同步所有管理的文件 | [docs/watcher.md](docs/watcher.md) |

## 命令速查

运行 `make help` 查看全部命令。

### 安装与设置

| 命令 | 说明 |
|------|------|
| `make install` | 安装所有依赖并配置 hooks |
| `make setup-age-keys` | 生成 age 密钥对 |
| `make bootstrap-chezmoi-config` | 新机器上引导 chezmoi 配置 |
| `make encrypt-kubeconfig` | 加密 kubeconfig |

### 配置应用与同步

| 命令 | 说明 |
|------|------|
| `chezmoi apply` | 应用所有配置 |
| `chezmoi diff` | 预览变更 |
| `make apply-ssh` | 仅应用 SSH 配置 |
| `make apply-claude` | 仅应用 Claude 配置 |
| `make apply-cursor` | 仅应用 Cursor 配置 |
| `make sync-ssh` | 同步本地 SSH 配置到仓库 |
| `make sync-claude` | 同步本地 Claude 配置到仓库 |
| `make sync-cursor` | 同步本地 Cursor 配置到仓库 |

### KeePassXC 管理

| 命令 | 说明 |
|------|------|
| `make keepassxc-entry add` | 添加条目 |
| `make keepassxc-entry show` | 查看条目 |
| `make keepassxc-entry edit` | 编辑条目 |
| `make keepassxc-entry rm` | 删除条目 |
| `make keepassxc-entry ls` | 列出所有条目 |
| `make keepassxc-entry search` | 搜索条目 |

### 文件监控

| 命令 | 说明 |
|------|------|
| `make install-chezmoi-watcher` | 安装通用监控服务（推荐） |
| `make status-chezmoi-watcher` | 查看服务状态 |
| `make logs-chezmoi-watcher` | 查看服务日志 |
| `make uninstall-chezmoi-watcher` | 卸载服务 |

## 模板与敏感信息

模板文件（`*.tmpl`）通过 `keepassxc` 函数从 KeePassXC 读取敏感信息。条目名区分大小写，子组使用完整路径（如 `Internet/MyApp`）。

```json
{
  "token": "{{ (keepassxc \"Claude Code\").Password }}",
  "url": "{{ (keepassxc \"Claude Code\").URL }}"
}
```

自定义属性使用 `{{ keepassxcAttribute "EntryName" "AttributeName" }}`。

## 安全机制

- **Pre-commit（gitleaks）** -- 提交前本地扫描，`make install` 已自动配置
- **CI（TruffleHog）** -- GitHub Actions 深度扫描，配置见 `.github/workflows/secret-scanning.yml`

**不提交到 git**：KeePassXC 明文数据库、age 私钥（`~/.config/chezmoi/age.txt`）、`chezmoi apply` 生成的含敏感信息的文件。

## 新机器部署

```bash
git clone <repo-url> ~/.local/share/chezmoi
# 将 age 私钥放到 ~/.config/chezmoi/age.txt
make bootstrap-chezmoi-config
chezmoi apply
```

## 注意事项

1. 需安装 `keepassxc-cli`，chezmoi 依赖其读取数据库
2. 模板中的条目名须与 KeePassXC 中完全一致（区分大小写）
3. 每次 `chezmoi apply` 会提示数据库密码
4. 生成的配置文件含真实敏感信息，由 chezmoi 管理，不宜手动修改
