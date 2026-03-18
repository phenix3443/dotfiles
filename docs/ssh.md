# SSH 配置管理

模块化的 SSH 配置，支持 Tailscale / 局域网多环境自动切换，`.sconf` 文件使用 age 加密存储。

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
│   └── perf.sconf            # 性能优化（ControlMaster + 客户端加速）
├── bin/                      # 辅助脚本
│   ├── ssh-detect-env         # 检测当前网络环境（home/idea/ts/cloud）
│   └── ssh-tailscale-up       # 检测 Tailscale 是否在线
└── cm/                       # ControlMaster socket 目录
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

## 多环境连接策略

每台主机通过 OpenSSH `Match exec` 按优先级匹配连接地址：

1. **Tailscale 在线** -- 使用 Tailscale IP（100.x）
2. **home 网段** -- 使用 `192.168.122.*` 局域网 IP
3. **idea 网段** -- 使用 `192.168.3.*` 局域网 IP

OpenSSH 对同一关键字取首次匹配值，因此三段 `Match` 按上述顺序排列即可。

| 场景 | 使用的地址 |
|------|-----------|
| Tailscale 正常（本机有 100.x） | Tailscale IP |
| TS 不可用，在 home 网段 | home 局域网 IP |
| TS 不可用，在 idea 网段 | idea 局域网 IP |

### 辅助脚本

**`ssh-tailscale-up`** -- 检测 Tailscale 是否可用：
- 退出码 0：`tailscale ip -4` 返回 `100.*`（已接入）
- 退出码 1：不可用
- 不写 stdout，供 `Match exec` 直接使用

**`ssh-detect-env`** -- 检测当前网络环境：
- stdout：`home` / `idea` / `ts` / `cloud`
- 按本机 IP 地址段判断，`Match` 中通过 `$(~/.ssh/bin/ssh-detect-env) = home` 比较

### 探测缓存

两个脚本均实现 5 秒进程级缓存（`${TMPDIR:-/tmp}/.ssh-ts.$UID`、`.ssh-env.$UID`），同一次 `ssh` 内多段 `Match exec` 不重复探测。

清除缓存（换网后如需立即生效）：

```bash
rm -f "${TMPDIR:-/tmp}/.ssh-ts.$UID" "${TMPDIR:-/tmp}/.ssh-env.$UID"
```

探测快路径按 OS 优化：
- **macOS** -- `ipconfig getifaddr en0..en7`，避免遍历所有接口
- **Linux** -- `ip -4 -o addr show scope global` + `grep`

## 连接加速

### ControlMaster 复用（perf.sconf）

首条到 `user@host:port` 的会话作为 master，后续同目标会话复用同一 TCP 连接，省去 TCP + SSH 握手，第二条起从秒级降到百毫秒级。

配置要点：`ControlMaster auto`、`ControlPath ~/.ssh/cm/%C`、`ControlPersist 600`。需先 `mkdir -p ~/.ssh/cm`。

### 客户端优化（perf.sconf / Host *）

| 配置项 | 作用 |
|--------|------|
| `GSSAPIAuthentication no` | 跳过 Kerberos 尝试，省数百 ms |
| `AddressFamily inet` | 强制 IPv4，避免 IPv6 回退延迟 |
| `IdentitiesOnly yes` + `IdentityFile` | 只试指定密钥，避免 agent 多钥匙逐个尝试 |
| `ConnectTimeout 5` | 失败时快速超时 |

密钥类型优先 Ed25519（协商与验签比 RSA 更快）。

### 服务端优化（sshd_config）

`UseDNS no` 可显著减少首连尾部等待（不对客户端 IP 做反向 DNS）。

### 调试连接耗时

```bash
ssh -G mini 2>/dev/null | egrep '^(hostname|user|port|identityfile) '
time ssh -vvv mini true 2>&1 | tail -80
```

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
