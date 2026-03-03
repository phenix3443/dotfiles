# Cursor 配置管理

本仓库通过 chezmoi 管理 Cursor 编辑器的用户配置，支持 macOS、Linux、Windows 三平台。

## 配置位置

Cursor 用户配置按平台存放在以下路径：

| 平台 | 路径 |
|------|------|
| **Linux** | `~/.config/Cursor/User/` |
| **macOS** | `~/Library/Application Support/Cursor/User/` |
| **Windows** | `%APPDATA%\Cursor\User\` |

常用文件与目录：

- `settings.json`：编辑器设置
- `keybindings.json`：自定义快捷键
- `snippets/`：代码片段目录

## 纳入 chezmoi

本仓库可按 macOS / Linux / Windows 三平台管理 Cursor 配置；若使用共享模板（如 `.chezmoitemplates/`），按 OS 应用到对应路径。

**在新机器上首次纳入 Cursor 配置**（在对应平台执行）：

- **macOS**：

  ```bash
  chezmoi add "$HOME/Library/Application Support/Cursor/User/settings.json"
  chezmoi add "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  chezmoi add "$HOME/Library/Application Support/Cursor/User/snippets"
  ```

- **Linux**：

  ```bash
  chezmoi add ~/.config/Cursor/User/settings.json
  chezmoi add ~/.config/Cursor/User/keybindings.json
  chezmoi add ~/.config/Cursor/User/snippets
  ```

- **Windows**：

  ```bash
  chezmoi add "$APPDATA/Cursor/User/settings.json"
  chezmoi add "$APPDATA/Cursor/User/keybindings.json"
  chezmoi add "$APPDATA/Cursor/User/snippets"
  ```

## 日常编辑与同步

- **改配置后应用**：编辑源中的模板（如 `cursor-settings.json.tmpl`、`cursor-keybindings.json.tmpl`），在仓库根目录执行 `chezmoi apply`。
- **在 Cursor 里改完后同步回 dotfiles**：在对应平台对当前路径执行上述 `chezmoi add`，把 settings/keybindings/snippets 合并回源中的模板；snippets 若多平台共用，需在各平台路径下保持一致。

## 路径类设置（按 OS 生成）

部分设置依赖本机路径，可按 OS 在模板中区分：

- `Preda.path`：仅在 Linux 下用 `{{ .chezmoi.homeDir }}` 等生成。
- `clangd.path`、`GCL.path`：仅在 Windows 下生成。

若本机路径与模板中相对 home 的路径不一致，可在 Cursor 里本地覆盖，或扩展模板条件。
