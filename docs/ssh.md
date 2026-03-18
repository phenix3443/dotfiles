# SSH 配置管理

模块化的 SSH 配置，`.sconf` 文件使用 age 加密存储，辅助脚本管理多环境连接。

## 配置结构

```
~/.ssh/
├── config                    # 主配置文件（Include ~/.ssh/config.d/*.sconf）
├── config.d/                 # 模块化配置
│   ├── personal.sconf        # 个人设备（Tailscale/LAN 自动切换）
│   ├── raspi.sconf           # 树莓派
│   ├── vps.sconf             # VPS
│   ├── zkme.sconf            # 工作环境
│   ├── idea.sconf            # 测试环境
│   └── perf.sconf            # 性能优化（ControlMaster）
└── bin/                      # 辅助脚本
    ├── ssh-detect-env         # 检测当前网络环境（home/idea/cloud）
    └── ssh-tailscale-up       # 检测 Tailscale 是否在线
```

### Chezmoi 源文件结构

```
dotfiles/private_dot_ssh/
├── config                                 # 明文
├── config.d/
│   ├── encrypted_personal.sconf.age       # age 加密
│   ├── encrypted_raspi.sconf.age
│   └── ...
└── bin/
    ├── executable_ssh-detect-env          # 明文，可执行
    └── executable_ssh-tailscale-up
```

- `private_` 前缀确保 `~/.ssh/` 目录权限为 700，文件权限为 600
- `encrypted_` 前缀 + `.age` 后缀表示 age 加密存储
- `executable_` 前缀确保辅助脚本有执行权限

## 日常使用

### 同步本地修改到仓库

```bash
make sync-ssh
```

自动将 `~/.ssh/config`、`~/.ssh/config.d/*.sconf`（加密）和 `~/.ssh/bin/*` 同步到 chezmoi 源目录。

### 从仓库应用到本地

```bash
make apply-ssh
```

### 添加新的配置模块

```bash
vim ~/.ssh/config.d/newhost.sconf
make sync-ssh                             # 同步到仓库（自动加密）
git add dotfiles/private_dot_ssh/ && git commit -m "add: SSH newhost config"
```

## 自动监控

推荐使用通用文件监控服务，会自动覆盖 SSH 配置：

```bash
make install-chezmoi-watcher              # 安装通用监控（含 SSH）
```

如果只需要监控 SSH 配置：

```bash
make install-ssh-watcher                  # SSH 专用监控
```

详见 [docs/watcher.md](watcher.md)。

## 命令速查

| 命令 | 说明 |
|------|------|
| `make sync-ssh` | 同步本地 SSH 配置到仓库 |
| `make apply-ssh` | 从仓库应用 SSH 配置 |
| `make install-ssh-watcher` | 安装 SSH 专用监控服务 |
| `make status-ssh-watcher` | 查看 SSH 监控状态 |
| `make logs-ssh-watcher` | 查看 SSH 监控日志 |
| `make uninstall-ssh-watcher` | 卸载 SSH 监控服务 |

## 相关文件

- `scripts/sync-ssh-config.sh` -- 同步脚本
- `scripts/watch-ssh-config.sh` -- SSH 专用监控脚本
- `scripts/install-ssh-watcher.sh` -- SSH 监控服务安装脚本
- `make/ssh.mk` -- Makefile 目标定义
