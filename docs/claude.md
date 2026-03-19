# Claude Code 配置管理

本仓库在 **`dotfiles/dot_claude/`** 里用**普通文件**管理 Claude Code 配置（无模板、无 age 加密）。

- **`settings.json`**：权限、插件等（**不在此文件配置 API 网关**；可提交）
- **`skills_manifest.txt`**：用户级 skills 清单
- **`mcp_servers.json`**：与 `~/.claude.json` 中 `mcpServers` 同结构；由 chezmoi 写到 `~/.claude/mcp_servers.json`，apply 后 **`run_after_15-merge-claude-mcp.sh`** 只更新 `~/.claude.json` 的 `mcpServers`，其余键不动

**API 网关（`ANTHROPIC_BASE_URL`）与 token**：只在 **KeePassXC 条目「Claude Code」**（URL + Password）维护一处；终端里由 [30-claude.zsh.tmpl](../dotfiles/dot_config/zsh/conf.d/30-claude.zsh.tmpl) 生成 `30-claude.zsh`。详见 [zsh.md](zsh.md)。

若 **GUI 启动的 Claude Code** 读不到 zsh 环境，可在本机 **`~/.claude/settings.local.json`**（不进仓库）里按需写 `env`，不要写进仓库里的 `settings.json`。

不要在仓库的 `settings.json` 里写 Key；若本机 `~/.claude/settings.json` 里误写了 Key，`make sync-claude` 会把整文件拷回仓库，**提交前请检查 diff**。

**MCP 与安全**：`mcp_servers.json` 可能含 `env` / `headers` 中的 token。**提交前审阅 diff**，避免把密钥推进 git；优先用环境变量或由本机私有配置补全。若在 Claude UI 里新增/改了 MCP，需先 **`make sync-claude`** 再提交，否则下次 **`chezmoi apply` 会用仓库里的列表覆盖本机 `mcpServers`**。

## 命令

| 命令 | 说明 |
| ---- | ---- |
| `make apply-claude` | `chezmoi apply ~/.claude`，把仓库里的 `settings.json` 等写到本机 |
| `make sync-claude` | 拷回 `settings.json`、`skills_manifest.txt`；若存在 `~/.claude.json` 且已安装 `jq`，则把 `mcpServers` 写入 `mcp_servers.json` |
| `make check-sync` | 会对比 `~/.claude.json` 的 `mcpServers` 与仓库 `mcp_servers.json`（需 `jq` 且上述文件存在） |

## 修改流程

1. 改仓库里的 `dotfiles/dot_claude/settings.json`（及可选 `mcp_servers.json`）→ `chezmoi apply` 或 `make apply-claude`
2. 或在本机改 settings/skills/MCP 后 → `make sync-claude` → 审阅 diff → 提交（确认未包含密钥）

## Skills

apply 结束后 `run_after_10-install-claude-skills.sh` 会按 `skills_manifest.txt` 安装 skills。需已安装 `add-skill` 或可用 `npx`。随后 `run_after_15-merge-claude-mcp.sh` 将 `mcp_servers.json` 合并进 `~/.claude.json`（依赖 `jq`）。

## 参考

- 主 [README](../README.md)
