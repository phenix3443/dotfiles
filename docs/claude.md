# Claude Code 配置管理

本仓库在 **`dotfiles/dot_claude/`** 里用**普通文件**管理 Claude Code 配置（无模板、无 age 加密）。

- **`settings.json`**：权限、插件、`ANTHROPIC_BASE_URL` 等（可直接提交）
- **`skills_manifest.txt`**：用户级 skills 清单

**API Key**：放在 **`~/.zshrc`**（或其它 shell 配置）里导出，例如：

```bash
export ANTHROPIC_API_KEY="sk-..."
# or: export ANTHROPIC_AUTH_TOKEN="..."
```

不要在仓库的 `settings.json` 里写 Key；若本机 `~/.claude/settings.json` 里误写了 Key，`make sync-claude` 会把整文件拷回仓库，**提交前请检查 diff**。

## 命令

| 命令 | 说明 |
| ---- | ---- |
| `make apply-claude` | `chezmoi apply ~/.claude`，把仓库里的 `settings.json` 等写到本机 |
| `make sync-claude` | 把本机 `~/.claude/settings.json`、`skills_manifest.txt` **原样**拷回 `dotfiles/dot_claude/` |

## 修改流程

1. 改仓库里的 `dotfiles/dot_claude/settings.json` → `make apply-claude`
2. 或在本机改完后 → `make sync-claude` → 审阅 diff → 提交（确认未包含密钥）

## Skills

apply 结束后 `run_after_10-install-claude-skills.sh` 会按 `skills_manifest.txt` 安装 skills。需已安装 `add-skill` 或可用 `npx`。

## 参考

- 主 [README](../README.md)
