# Kubernetes kubeconfig 管理

`~/.kube/config` 以 age 加密形式由 chezmoi 管理，与 KeePassXC 数据库共用同一套 age 密钥。

## 如何保存

- **源文件（仓库内）**：`private_dot_kube/config.age`（age 加密后的内容）
- **目标文件（本机）**：`~/.kube/config`（`chezmoi apply` 时自动解密生成，权限 600）
- **密钥**：使用 `~/.config/chezmoi/age.txt` 中的 age 私钥解密，与 `dot_config/chezmoi/chezmoi.toml.tmpl` 中配置的 identity 一致。

## 更新流程

修改本机 `~/.kube/config` 后，需要重新加密并写回仓库中的 `private_dot_kube/config.age`。

1. 在仓库根目录执行脚本（脚本会从 `dot_config/chezmoi/chezmoi.toml.tmpl` 读取 recipient 并加密）：

   ```bash
   make encrypt-kubeconfig
   ```

   或直接运行：`./scripts/encrypt-kubeconfig.sh`

2. 提交并推送（可选）：`git add private_dot_kube/config.age && git commit -m "Update kubeconfig" && git push`

3. 在其他机器上拉取后执行 `chezmoi apply`，即可得到最新的 `~/.kube/config`。

## 注意

- 确保已安装 age 且 `~/.config/chezmoi/age.txt` 存在；新机器需先放置同一私钥或使用本仓库的 age 配置。
- 不要将明文 `~/.kube/config` 或 age 私钥提交到 git；仅提交 `private_dot_kube/config.age`。
