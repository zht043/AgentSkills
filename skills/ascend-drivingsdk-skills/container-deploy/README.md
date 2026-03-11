# container-deploy

DrivingSDK 容器开发环境一键部署工具。支持架构和 OS 自动检测、多种镜像来源、NPU 设备挂载、容器内 SSH、conda 环境配置、代理设置和部署档案生成。

## 快速开始

### 通过 Agent 使用（推荐）

直接告诉 agent：

> "帮我部署一个 DrivingSDK 容器"

Agent 会一次性收集所有配置：**环境检测（架构+OS）、镜像选择（三选一平等呈现）、工作空间路径、数据集挂载、容器命名、SSH配置、代理设置**。容器创建后再列出可用 conda 环境让你选择。部署完成后自动生成结构化部署档案。

> **重要**：容器一旦创建，挂载路径无法修改。Agent 会在创建前明确询问工作空间和数据集路径。

### 通过脚本直接使用

```bash
bash scripts/deploy-container.sh \
  --image "已有镜像名:tag" \
  --container-name "my_drivingsdk" \
  --mount "/data/datasets:/datasets" \
  --mount "/home/user/workspace:/workspace" \
  --ssh-port 2222 \
  --root-password "mypassword" \
  --conda-env "py310_mmcv1" \
  --proxy "http://127.0.0.1:7897"
```

### 镜像来源（三选一）

Agent 交互模式下平等呈现三种来源，无优先级。镜像需匹配宿主机 OS 和架构。

| 参数 | 说明 |
|------|------|
| `--image` | 指定完整镜像地址（宿主机已有镜像或自有 registry） |
| `--image-file` | 从本地 `.tar` 文件 docker load |
| `--image-tag` | 从 config 中的 registry 拉取，自动拼接架构后缀 |

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
--conda-env NAME       要激活的 conda 环境名（动态检测容器内可用环境）
--conda-name NAME      自定义 conda 环境名（配合 --conda-env 重命名）
--list-conda-envs      列出容器内可用 conda 环境并退出
--torch-version VER    [弃用] 旧参数，映射到 --conda-env
--proxy URL            HTTP/HTTPS 代理地址，持久化到容器 ~/.bashrc
--registry URL         镜像仓库地址（默认华为 SWR）
```

## 部署档案

脚本执行完成后自动生成 `deployment-manifest.md`，包含：

- 宿主机信息（IP、OS、内核、架构）
- NPU 信息（型号、数量、驱动版本）
- 容器信息（镜像、OS、磁盘、CANN 版本）
- SDK 版本链（torch、torch_npu、mx_driving）
- 服务配置（SSH、代理）
- VSCode Remote SSH 配置
- 常用命令速查

档案保存在容器内 workspace 根目录（无挂载则 `/root/`）。

## 代理配置

容器使用 `--network=host` 共享宿主机网络栈。通过 `--proxy` 参数配置代理，自动写入容器 `~/.bashrc`：

```bash
# 配合 SSH 隧道/反向代理工具（在可用 skill 中寻找）
# 建立反向代理隧道，将本地代理端口转发到远程宿主机

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

远程服务器场景，需配合具备 SSH 隧道/端口转发能力的工具做端口转发。

## 跨平台兼容

- 从 Windows 传输脚本到 Linux 时，agent 应先执行 `sed -i 's/\r$//' script.sh` 清理换行符。脚本内置自修复作为兜底，但可能因早期语法错误而失效
- 若自修复失败（bash 无法解析到修复代码），应在传输前先修复换行符

## 退出码

| 退出码 | 含义 |
|--------|------|
| 0 | 部署成功 |
| 1 | 参数错误或系统异常 |
| 2 | 镜像拉取失败，需提供替代来源 |
