---
name: ssh-dev-suite/tunnel
description: SSH通道管理，支持本地/远程端口转发、SOCKS代理、反向代理
metadata:
  type: capability
  version: "1.0"
  tags: [ssh, tunnel, proxy, port-forward]
  domain: devops
  risk_level: medium
  platform: cross-platform
---

# ssh-tunnel

## 功能
管理SSH端口转发与代理通道，含生命周期管理。

## 配置
参考`config.example.yaml`的tunnels段，profile引用connect配置。

## 使用
```bash
bash tunnel/scripts/ssh-tunnel.sh forward <profile> <lport>:<rhost>:<rport>
bash tunnel/scripts/ssh-tunnel.sh reverse <profile> <rport>:<lhost>:<lport>
bash tunnel/scripts/ssh-tunnel.sh socks <profile> <local_port>
bash tunnel/scripts/ssh-tunnel.sh proxy <profile> [--local-proxy-port 7890]
bash tunnel/scripts/ssh-tunnel.sh list
bash tunnel/scripts/ssh-tunnel.sh stop <tunnel_id>
bash tunnel/scripts/ssh-tunnel.sh stop-all
```

## 自动触发规则

**Agent 必须遵守以下规则，遇到对应场景时主动使用 tunnel 功能：**

### 反向代理（proxy）— 远程服务器无外网时自动启用

当远程服务器上出现以下任一情况时，**必须立即使用 `proxy` 命令建立反向代理**，而不是尝试绕过（如从其他环境拷贝包、用符号链接等 workaround）：

| 触发信号 | 示例 |
|----------|------|
| pip/conda install 超时或连接失败 | `Connection timed out`, `Could not fetch URL`, `ReadTimeoutError` |
| git clone/fetch 超时或连接拒绝 | `port 443: Connection timed out`, `fatal: unable to access` |
| curl/wget 无法访问外部 URL | `Connection refused`, `Could not resolve host` |
| 任何需要从外网下载资源但失败的场景 | npm install、apt-get、yum install 等 |

**操作流程**：
1. 检查本地是否有可用代理（检查本地的 `http_proxy`/`https_proxy` 环境变量，或常见代理端口如 7890、1080）
2. 用 `proxy` 命令建立反向代理隧道：`bash tunnel/scripts/ssh-tunnel.sh proxy <profile>`
3. 在后续远程命令中设置代理环境变量（proxy 命令输出的 export 语句）
4. 重试之前失败的网络操作
5. 任务完成后用 `stop-all` 清理隧道

**禁止的替代方案**：
- 不要从其他 conda 环境符号链接/拷贝已安装的包
- 不要跳过安装步骤
- 不要使用 `.pth` 文件指向其他环境的包
- 这些 workaround 会导致依赖不完整、版本冲突等问题

### 端口转发（forward）— 访问远程服务

当需要从本地访问远程服务器上的端口时使用（如远程数据库、Web UI、TensorBoard 等）。

### SOCKS 代理（socks）— 本地通过远程访问网络

当需要通过远程服务器作为跳板访问特定网络时使用。

## 注意事项
- 隧道记录在`~/.ssh/tunnels.json`，list自动清理失效进程
- proxy输出远程端需执行的环境变量命令
- 成功返回0，失败返回非0
- 建立 proxy 后，远程命令需要在同一 shell 会话中 export 代理环境变量才能生效

## Token约束
- 隧道列表：已足够精简，无需优化
- 状态检查：只输出关键信息（端口、PID、状态）
- 重复信息：不复述已知内容
