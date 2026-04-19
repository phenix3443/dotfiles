# Claude Code 配置管理

本仓库在 **`dotfiles/dot_claude/`** 管理 Claude Code 配置，并在 **`dotfiles/dot_codex/`** 管理 Codex 的用户级配置。

## 管理的文件

| 文件 | 说明 |
| ---- | ---- |
| `settings.json.tmpl` | `env`、权限、hooks、插件（chezmoi 模板；若路径含 `$HOME` 会写成 `{{ .chezmoi.homeDir }}`）|
| `CLAUDE.md` | 全局 AI 行为规则 |
| `RTK.md` | RTK 用法说明（被 `CLAUDE.md` 通过 `@RTK.md` 引用）|
| `hooks/` | PreToolUse / PostToolUse 脚本（`rtk-rewrite.sh`、`fix-to-code-reminder.sh`）|
| `skills_manifest.txt` | 用户级 skills 清单 |
| `mcp_servers.json` | 与 `~/.claude.json` 中 `mcpServers` 同结构；apply 后 `run_after_15-merge-claude-mcp.sh` 合并到 `~/.claude.json` |
| `settings/mcp.json` | Claude Code 的 `~/.claude/settings/mcp.json` |

## 敏感与覆盖

- **`env` 与 `make sync-claude`**：`settings.json` 会**整份**写入 `settings.json.tmpl`（含 `env`）。**提交前审阅 diff**，勿把真实 API Key 推进公开仓库；需要机内覆盖时仍可用 **`~/.claude/settings.local.json`**
- **`mcp_servers.json`**：可能含 token，**提交前审阅 diff**

## RTK（Rust Token Killer）

RTK 是一个 CLI 代理，对常见开发命令的 LLM token 消耗减少 60-90%。

- **安装**：`make install-rtk`（brew / install.sh / cargo）
- **chezmoi apply** 时：`run_after_05-install-rtk.sh` 会自动安装 rtk 二进制
- hooks 和 `RTK.md` 由 chezmoi 直接管理，无需额外 `rtk init -g`

## gstack

gstack 通过一份共享源码同时注册到 Claude Code 和 Codex。

- **安装**：`make install-gstack`
- **源码目录**：`~/.gstack/repos/gstack`
- **注册结果**：Claude 使用 `~/.claude/skills/gstack`，Codex 使用 `~/.codex/skills/gstack`
- **安装参数**：仓库脚本会执行官方 `./setup --host claude --no-prefix --quiet` 与 `./setup --host codex --no-prefix --quiet`

## 命令

| 命令 | 说明 |
| ---- | ---- |
| `make install-claude` | 安装 Claude Code CLI |
| `make install-rtk` | 安装 RTK 二进制 |
| `make install-gstack` | 安装 gstack 并注册到 Claude Code / Codex |
| `make sync-claude` | 拷回 settings（模板化）、skills、hooks、md、MCP 到仓库 |
| `make apply-claude` | `chezmoi apply ~/.claude`，应用所有配置到本机 |
| `make sync-codex` | 拷回 `~/.codex/config.toml` 到仓库模板 |
| `make apply-codex` | `chezmoi apply ~/.codex`，应用 Codex 配置到本机 |
| `make check-sync` | 对比 `~/.claude.json` 的 `mcpServers` 与仓库 `mcp_servers.json` |

## 修改流程

1. 改仓库里的模板/配置 → `chezmoi apply` 或 `make apply-claude`
2. 或在本机改 settings/hooks/skills/MCP 后 → `make sync-claude` → 审阅 diff → 提交

## chezmoi apply 自动流程

1. `run_after_05-install-rtk.sh` — 安装 RTK 二进制（若不存在）
2. `run_after_10-install-claude-skills.sh` — 按 `skills_manifest.txt` 安装 skills
3. `run_after_15-merge-claude-mcp.sh` — 将 `mcp_servers.json` 合并进 `~/.claude.json`

## 参考

- 主 [README](../README.md)
