# container-deploy

DrivingSDK 容器开发环境一键部署工具。支持架构自动检测、多种镜像来源、NPU 设备挂载、容器内 SSH、conda 环境配置和代理设置。

## 快速开始

### 通过 Agent 使用（推荐）

直接告诉 agent：

> "帮我部署一个 DrivingSDK 容器"

Agent 会引导你完成配置：架构检测、镜像选择、容器命名、路径挂载、SSH配置、conda环境、代理设置。

### 通过脚本直接使用

```bash
bash scripts/deploy-container.sh \
  --image-tag "8.5.0_alpha001" \
  --container-name "my_drivingsdk" \
  --mount "/data/datasets:/datasets" \
  --mount "/home/user/workspace:/workspace" \
  --ssh-port 2222 \
  --root-password "mypassword" \
  --torch-version "2.1.0" \
  --conda-name "dev" \
  --proxy "http://127.0.0.1:7897"
```

### 镜像来源（三选一）

| 参数 | 说明 |
|------|------|
| `--image-tag` | 从 config 中的 registry 拉取，自动拼接架构后缀 |
| `--image` | 指定完整镜像地址（自有 registry 或本地已有镜像） |
| `--image-file` | 从本地 `.tar` 文件 docker load |

### 架构检测

脚本自动执行 `uname -m` 检测宿主机架构（aarch64/x86_64），用于拼接镜像 tag。可通过 `--arch` 手动覆盖。

## 完整参数

```
--image-tag TAG        镜像版本 tag（与 --arch 配合拼接完整地址）
--arch ARCH            架构（默认自动检测：aarch64→arm64, x86_64→x86_64）
--image IMAGE          完整镜像地址
--image-file FILE      本地镜像 tar 文件路径
--container-name NAME  容器名（必填）
--mount SRC:DST        路径挂载，可多次指定
--ssh-port PORT        容器内 SSH 端口（--network=host 下绑宿主机端口）
--expose PORT          额外暴露端口，可多次指定
--root-password PASS   容器 root 密码（SSH 登录用）
--torch-version VER    torch 版本（2.1.0/2.6.0/2.7.1），激活对应 conda 环境
--conda-name NAME      自定义 conda 环境名
--proxy URL            HTTP/HTTPS 代理地址，持久化到容器 ~/.bashrc
```

## 代理配置

容器使用 `--network=host` 共享宿主机网络栈。通过 `--proxy` 参数配置代理，自动写入容器 `~/.bashrc`：

```bash
# 配合 ssh-dev-suite 反向代理隧道
bash ssh-tunnel.sh proxy <profile> --local-proxy-port 7897

# 部署时指定代理
bash scripts/deploy-container.sh --proxy "http://127.0.0.1:7897" ...
```

## 配置

复制 `config.example.yaml` 为 `config.yaml`，添加自定义镜像版本。`config.yaml` 已被 `.gitignore` 排除。

## VSCode Remote SSH

部署完成后，在 `~/.ssh/config` 添加：

```
Host drivingsdk
    HostName <宿主机IP>
    Port 2222
    User root
```

远程服务器场景，配合 ssh-dev-suite 的 tunnel 模块做端口转发。

## 退出码

| 退出码 | 含义 |
|--------|------|
| 0 | 部署成功 |
| 1 | 参数错误或系统异常 |
| 2 | 镜像拉取失败，需提供替代来源 |
