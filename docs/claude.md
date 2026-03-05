# Claude Code 配置管理

本仓库通过 chezmoi 管理 Claude Code（Claude 开发者工具）的用户配置，敏感信息从 KeePassXC 注入，不提交明文。

## 配置位置

Claude Code 用户配置存放在：

| 平台   | 路径           |
|--------|----------------|
| 通用   | `~/.claude/`   |

本仓库管理的文件与目录：

- `settings.json`：环境变量、权限等（由模板 `settings.json.tmpl` 生成）
- `skills_manifest.txt`：用户级 skills 安装清单，apply 时由 run_after 脚本按清单安装到 `~/.claude/skills/`（见下方「Skills 配置」与「安装社区 Skills」）
- `skills/`：仅占位（`.gitkeep`）；实际 skill 内容不放入仓库，由清单 + add-skill 在 apply 时安装

## 模板与敏感信息

源文件为 `dotfiles/dot_claude/settings.json.tmpl`，通过 `keepassxc` 模板函数从 KeePassXC 读取敏感信息：

- **ANTHROPIC_AUTH_TOKEN**：来自 KeePassXC 条目 `Claude Code` 的 **Password** 字段
- **ANTHROPIC_BASE_URL**：来自 KeePassXC 条目 `Claude Code` 的 **URL** 字段

因此需在 KeePassXC 中预先创建名为 **Claude Code** 的条目（区分大小写），并填写 Password 与 URL。可使用：

```bash
make keepassxc-entry add    # 添加时条目路径填 Claude Code
make keepassxc-entry show   # 查看
make keepassxc-entry edit   # 编辑
```

apply 前会由 `run_before_00-decrypt-keepassxc.sh` 解密 KeePassXC 数据库，保证模板执行时能读取到该条目。

## 当前模板内容说明

- **env**：注入 `ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_BASE_URL`，以及 `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`（按需保留或修改）
- **permissions**：`allow`/`deny` 控制 Claude Code 的权限，可按需在模板中调整

生成后的 `~/.claude/settings.json` 含真实 token，由 chezmoi 管理，不宜长期手动改；修改请编辑仓库中的 `settings.json.tmpl` 后执行 `chezmoi apply`。

## Skills 配置

用户级 skills 存放在 `~/.claude/skills/`，Claude Code 会在所有项目中自动发现并可用（项目内 `.claude/skills/` 优先级更高）。

本仓库采用**轻量管理**：不把完整 skill 文档放进仓库，而是维护一份安装清单 `skills_manifest.txt`，在 `chezmoi apply` 结束时由 run_after 脚本根据清单调用 `add-skill` 从网络安装到 `~/.claude/skills/`。清单格式与已列 skills 见下方「安装社区 Skills」。

每个 skill 对应一个子目录，且必须包含 `SKILL.md`，例如：

```text
~/.claude/skills/
  my-skill/
    SKILL.md           # 必选，技能定义与说明
    examples/          # 可选
    templates/         # 可选
```

增删 skill 时：编辑 `dotfiles/dot_claude/skills_manifest.txt`（每行一条 `owner/repo [--skill name]`），执行 `chezmoi apply` 即可；run_after 会按清单重新安装。`add-skill` CLI 由 `make install` 安装到 `INSTALL_BIN`。

## 安装社区 Skills

### 轻量管理方式

仓库只保存 `dotfiles/dot_claude/skills_manifest.txt` 与 run_after 脚本 `dotfiles/.chezmoiscripts/run_after_10-install-claude-skills.sh`。执行 `chezmoi apply` 时，清单会应用到 `~/.claude/skills_manifest.txt`，apply 结束后 run_after 脚本读取该清单，逐行调用 `add-skill <args> -g -y` 将 skills 安装到 `~/.claude/skills/`。无需在仓库中保存完整 skill 文档。若本机未安装 `add-skill` 或 Node，脚本会输出错误并退出（exit 非零），不会静默跳过。

### 清单格式

每行一条：`owner/repo [--skill name]`，与 `add-skill` 参数一致。空行与 `#` 开头行会被忽略。增删 skill 时编辑清单并执行 `chezmoi apply` 即可。

### add-skill 的安装

`add-skill` 由 `make install` 安装到 `INSTALL_BIN`（见主 README）。新机器上先执行 `make install`，再执行 `chezmoi apply`，即可自动按清单安装用户级 skills。

### 已列 skills 与来源

| Skill | 来源仓库 | 清单行示例 |
| ----- | -------- | ---------- |
| skills-discovery（find-skills） | Kamalnrf/claude-plugins | `Kamalnrf/claude-plugins --skill skills-discovery` |
| Frontend-design | anthropics/claude-code | `anthropics/claude-code --skill frontend-design` |
| Skill-creator | anthropics/skills | `anthropics/skills --skill skill-creator` |
| Planning-with-files | OthmanAdi/planning-with-files | `OthmanAdi/planning-with-files` |
| Superpowers | obra/superpowers-skills | `obra/superpowers-skills` |
| NotebookLM | PleasePrompto/notebooklm-skill | `PleasePrompto/notebooklm-skill` |
| Best Minds | 待用户提供来源后补充 | — |

## 纳入 chezmoi（新机器或新配置）

若本机尚未把 Claude 配置交给 chezmoi 管理，可先确保 KeePassXC 与 age 已按主 README 配置好，然后：

```bash
mkdir -p ~/.claude
# 若已有本地 settings.json 想纳入为源（通常用模板即可，不必 add）
chezmoi add ~/.claude/settings.json
```

用户级 skills 由清单在 apply 时自动安装，无需执行 `chezmoi add ~/.claude/skills`。

若希望完全由模板生成，只需保证 `dotfiles/dot_claude/settings.json.tmpl` 存在且 KeePassXC 中有 `Claude Code` 条目，执行：

```bash
chezmoi apply
```

即可在 `~/.claude/` 下生成 `settings.json`，run_after 会按清单将 skills 安装到 `~/.claude/skills/`。

## 日常使用

- **修改 settings**：编辑 `dotfiles/dot_claude/settings.json.tmpl`，在仓库根目录执行 `chezmoi apply`。
- **修改 token/URL**：在 KeePassXC 中编辑 `Claude Code` 条目（或使用 `make keepassxc-entry edit`），再执行 `chezmoi apply` 重新生成 `settings.json`。
- **修改或新增 skills**：编辑 `dotfiles/dot_claude/skills_manifest.txt` 后执行 `chezmoi apply`。

### 本机已改配置如何回写仓库

若在本机直接改过 `~/.claude/settings.json` 或 `~/.claude/skills_manifest.txt`，希望把变更同步回仓库：

- **settings.json**：**禁止**执行 `chezmoi add ~/.claude/settings.json`，否则会把明文 token 写进仓库。应手动把本机文件中的**结构、键、非敏感值**合并到 `dotfiles/dot_claude/settings.json.tmpl`，并**保留** `ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_BASE_URL` 的模板写法（`{{ (keepassxc "Claude Code").Password }}`、`{{ (keepassxc "Claude Code").URL }}`）。保存后执行 `chezmoi apply` 验证。
- **skills_manifest.txt**：可编辑仓库中的 `dotfiles/dot_claude/skills_manifest.txt` 与本机清单保持一致；或在仓库根执行 `chezmoi add ~/.claude/skills_manifest.txt`，用本机文件覆盖源文件（该文件无敏感信息）。

## 参考

- 模板语法与 KeePassXC 集成见主 [README](../README.md) 中「模板与应用配置」。
- KeePassXC 数据库解密与 run_before 顺序见 README「配置 chezmoi」与 `dotfiles/.chezmoiscripts/run_before_00-decrypt-keepassxc.sh`。
