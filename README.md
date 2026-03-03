# chezmoi + KeePassXC Dotfiles 管理方案

使用 chezmoi 管理 dotfiles，通过 KeePassXC 安全存储和注入敏感信息（API keys、tokens、密码等）。

## 核心特性

- ✅ **安全管理敏感信息**：API keys、tokens、密码存储在 KeePassXC 中，不提交到 git
- ✅ **跨机器同步**：dotfiles 模板可在多台机器间同步，敏感信息本地管理
- ✅ **自动化部署**：一键安装依赖、配置 hooks、应用配置
- ✅ **敏感信息检测**：集成 gitleaks 防止意外提交密钥

## 工作流程

```mermaid
flowchart LR
    subgraph Source [chezmoi 源文件]
        Template["*.tmpl 模板文件"]
        Data["chezmoi 配置"]
    end

    subgraph KeePassXC [KeePassXC 数据库]
        Entries["敏感信息条目<br/>(API keys, tokens, 密码)"]
    end

    subgraph Output [生成的配置文件]
        Config["应用配置文件<br/>(注入敏感信息)"]
    end

    Template -->|keepassxc 函数读取| Entries
    Template -->|chezmoi apply| Config
    Data -->|配置数据库路径| Entries
```

## 快速开始

### 1. 安装依赖

使用 Makefile 一键安装所有依赖：

支持 Linux、macOS、Windows 多平台，自动检测包管理器：

```bash
make install              # 安装所有依赖并配置 hooks
make install-chezmoi      # 仅安装 chezmoi
make install-keepassxc-cli # 仅安装 keepassxc-cli
make install-age         # 仅安装 age（用于 chezmoi 加密）
make install-lefthook    # 仅安装 lefthook
make install-gitleaks    # 仅安装 gitleaks
make setup-hooks         # 配置 git hooks（需先安装 lefthook）
make keepassxc-entry [cmd] # KeePassXC 条目增删改查（add|show|edit|rm|ls|search）
make test                # 运行测试
make help                # 查看所有命令
```

**支持平台：**

- **Linux**：apt、dnf、pacman、apk、zypper、xbps-install、nix-env、snap；无包管理器时使用 chezmoi 官方安装脚本
- **macOS**：Homebrew、MacPorts、Nix
- **Windows**（MSYS2/Git Bash）：winget、Scoop、Chocolatey

可通过 `INSTALL_BIN` 指定二进制安装目录，默认 `~/.local/bin`：

```bash
make install-chezmoi INSTALL_BIN=~/bin
```

### 2. 创建 KeePassXC 数据库和条目

在 KeePassXC 中创建条目存储敏感信息（API keys、tokens、密码等）。

#### 方式一：交互式脚本（推荐）

```bash
make keepassxc-entry add         # 添加条目
./scripts/keepassxc-entry.sh add
./scripts/keepassxc-entry.sh show    # 查看
./scripts/keepassxc-entry.sh edit    # 编辑
./scripts/keepassxc-entry.sh rm      # 删除
./scripts/keepassxc-entry.sh ls      # 列表
./scripts/keepassxc-entry.sh search  # 搜索
./scripts/keepassxc-entry.sh --help  # 帮助
```

脚本支持完整的 CRUD 操作。添加条目时：
- 数据库路径（默认 `~/.config/keepassxc/chezmoi.kdbx`）
- 条目路径（必填，支持 `Group/Entry` 层级）
- Username/URL/Notes（可选）
- 密码由 keepassxc-cli 原生提示

#### 方式二：KeePassXC 图形界面

1. 打开 KeePassXC，打开或新建数据库（如 `~/.config/keepassxc/chezmoi.kdbx`）
2. 在左侧分组中右键 → **添加新条目**（或 Ctrl+N）
3. 填写 **标题**、**用户名**、**密码**、**URL** 等字段
4. 保存（Ctrl+S）

**自定义属性**：若需存储额外字段（如 `base_url`），在条目编辑界面点击 **属性** → **添加**。模板中用 `keepassxcAttribute "条目名" "属性名"` 读取。**注意**：自定义属性仅支持通过图形界面添加，keepassxc-cli 暂不支持。

### 3. 配置 chezmoi 使用 KeePassXC

本仓库的 `dot_config/chezmoi/chezmoi.toml.tmpl` 中示例配置的 KeePassXC 数据库路径为 `~/.config/keepassxc/chezmoi.kdbx`（你可以根据自己的习惯调整，例如与实际 `keepassxc.ini` 所在目录保持一致），并启用 age 加密（见下节）。该路径本身不受 chezmoi 保护，可直接用 `chezmoi add --encrypt` 加入仓库。使用 `{{ .chezmoi.homeDir }}` 实现跨机器可移植。若数据库无密码，可在模板中添加：

```toml
args = ["--no-password"]
prompt = false
```

#### KeePassXC 数据库用 age 加密托管

KeePassXC 数据库文件（`chezmoi.kdbx`）以 age 加密形式存放在仓库中（`dot_config/keepassxc/chezmoi.kdbx.age`），`chezmoi apply` 时会自动解密到 `~/.config/keepassxc/chezmoi.kdbx`。

**首次执行 `chezmoi apply`（新机器或 init 后）：**

1. 将 age 私钥放到 `~/.config/chezmoi/age.txt`（若尚未放置）。
2. 在仓库根目录执行一次引导脚本，写入完整 config（encryption + age + keepassxc）：
   ```bash
   make bootstrap-chezmoi-config
   ```
   或直接运行 `./scripts/bootstrap-chezmoi-config.sh`。
3. 执行 `chezmoi apply`。run_before 会先解密 kdbx，再应用所有 target。

**首次或本机准备：**

1. **生成 age 密钥并写入 recipient**（私钥仅保存在本机，不要提交到 git）：
   ```bash
   make setup-age-keys
   ```
   或手动执行 `./scripts/age-keys-configure.sh`。脚本会生成 `~/.config/chezmoi/age.txt`（若不存在），并将公钥写入 `dot_config/chezmoi/chezmoi.toml.tmpl` 的 `recipient`。

2. **让 chezmoi 使用当前配置（含 age 加密）**：  
   执行一次 `chezmoi apply`，把源里的 `dot_config/chezmoi/chezmoi.toml.tmpl` 应用到 `~/.config/chezmoi/chezmoi.toml`。这样 chezmoi 才能读到 `encryption = "age"`，后续 `chezmoi add --encrypt` 才会生效。

3. **将数据库加入仓库并加密**：  
   将现有数据库放到 `~/.config/keepassxc/chezmoi.kdbx`（可先 `mkdir -p ~/.config/keepassxc`），然后执行：
   ```bash
   chezmoi add --encrypt ~/.config/keepassxc/chezmoi.kdbx
   ```
   源目录会生成 `dot_config/keepassxc/chezmoi.kdbx.age`，提交到 git 即可。

**新机器：**  
将私钥文件放到 `~/.config/chezmoi/age.txt`，在仓库根目录执行 `make bootstrap-chezmoi-config` 后再执行 `chezmoi apply`，即可自动解密得到 `~/.config/keepassxc/chezmoi.kdbx` 及正确配置。

#### 用 chezmoi 管理 KeePassXC 应用配置

数据库已与 KeePassXC 应用配置同目录（`~/.config/keepassxc/`）。应用配置（界面、快捷键等）在 `keepassxc.ini`。若要一并纳入 dotfiles，在已有该文件后执行：

```bash
chezmoi add ~/.config/keepassxc/keepassxc.ini
```

源目录会生成 `dot_config/keepassxc/keepassxc.ini`，之后由 chezmoi 统一应用即可。

### 4. 创建配置模板

在 chezmoi 源目录创建模板文件，使用 `keepassxc` 函数读取敏感信息。

#### 示例：Claude Code 配置

创建 `dot_claude/settings.json.tmpl`：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "{{ (keepassxc \"Claude Code\").Password }}",
    "ANTHROPIC_BASE_URL": "{{ (keepassxc \"Claude Code\").URL }}",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  },
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

**模板语法说明**：
- `keepassxc "条目名"`：读取 KeePassXC 条目
- `.Password`、`.Username`、`.URL`：访问条目字段
- `keepassxcAttribute "条目名" "属性名"`：读取自定义属性

条目名需与 KeePassXC 中完全一致（区分大小写）。如使用层级（如 `Internet/MyApp`），按 KeePassXC 路径格式填写。

### 5. 应用配置

**应用配置**：

```bash
chezmoi apply         # 应用所有配置
chezmoi apply ~/.config/app/config.json  # 应用特定文件
```

应用时会提示输入 KeePassXC 数据库密码。生成的配置文件包含从 KeePassXC 读取的真实敏感信息，由 chezmoi 管理，不应手动长期修改。

## 版本控制与安全

### 可提交到 git

- ✅ 模板文件（`*.tmpl`）：不包含实际敏感信息
- ✅ chezmoi 配置（`dot_config/chezmoi/chezmoi.toml.tmpl`）：使用 `{{ .chezmoi.homeDir }}` 无硬编码路径
- ✅ 脚本和工具配置

### 不提交到 git

- ❌ KeePassXC 数据库明文文件（`*.kdbx`）
- ❌ age 私钥（如 `~/.config/chezmoi/age.txt`）
- ❌ 生成的配置文件（由 chezmoi apply 生成）

仓库中仅提交 age 加密后的数据库（`dot_config/keepassxc/chezmoi.kdbx.age`），不提交明文 kdbx 或 age 私钥。

### 敏感信息检测（多层防护）

采用**分层扫描策略**，在不同阶段检测敏感信息泄露：

#### 1. Pre-commit Hook（本地防护）

使用 [gitleaks](https://github.com/gitleaks/gitleaks) 在提交前检测：

- **速度快**：毫秒级扫描，不影响开发体验
- **150+ 检测规则**：API key、密码、私钥、token 等
- **自定义配置**：`.gitleaks.toml` 配置规则和白名单
- 提交时自动运行，发现敏感信息会阻止提交
- 如遇误报，可使用 `git commit --no-verify` 跳过

**安装和配置**：

```bash
make install           # 安装所有依赖（包含 gitleaks）
make install-gitleaks  # 仅安装 gitleaks
make setup-hooks       # 配置 git hooks
```

或手动执行：

```bash
lefthook install         # 安装 hooks 到 .git/hooks/
lefthook run pre-commit  # 手动运行 pre-commit 检查
gitleaks git --pre-commit # 单独运行 gitleaks
```

#### 2. GitHub Actions（CI/CD 防护）

使用 [TruffleHog](https://github.com/trufflesecurity/trufflehog) 在 CI/CD 中深度扫描：

- **更全面**：800+ 检测器，覆盖更多密钥类型
- **凭证验证**：测试检测到的密钥是否仍然有效（减少误报）
- **全历史扫描**：扫描整个 git 历史，防止遗漏
- 自动在 PR 和 push 时运行

工作流配置见 `.github/workflows/secret-scanning.yml`。

**为什么使用两个工具？**

- **Gitleaks**：本地快速检查，开发时即时反馈
- **TruffleHog**：CI/CD 深度扫描，双重保险

根据行业最佳实践，这种分层策略可将密钥泄露风险降低 13 倍。[参考](https://appsecsanta.com/gitleaks-vs-trufflehog)

**配置文件**：

- `lefthook.yml`：hook 管理配置
- `.gitleaks.toml`：gitleaks 自定义规则和白名单
- `.github/workflows/secret-scanning.yml`：GitHub Actions 工作流

## 高级用法

### 机器特定配置

使用 `.chezmoidata.toml` 提供机器特定变量：

```toml
[data]
email = "user@example.com"
hostname = "workstation"
```

在模板中使用：`{{ .email }}`

### 覆盖 KeePassXC 数据库路径

在 `~/.config/chezmoi/chezmoi.toml` 中覆盖：

```toml
[keepassxc]
database = "/custom/path/to/database.kdbx"
```

### 预览模板生成结果

```bash
chezmoi execute-template < dot_config/app/config.tmpl
```

会提示输入 KeePassXC 密码并显示生成内容，但不写入文件。

## 注意事项

1. **keepassxc-cli 依赖**：chezmoi 依赖 `keepassxc-cli` 读取数据库，确保已安装
2. **条目名称匹配**：模板中的条目名必须与 KeePassXC 中完全一致（区分大小写）
3. **层级路径**：若条目在子组中，使用完整路径，如 `Internet/MyApp`
4. **密码提示**：每次 `chezmoi apply` 会提示输入数据库密码，可配置 KeePassXC 浏览器集成避免重复输入
