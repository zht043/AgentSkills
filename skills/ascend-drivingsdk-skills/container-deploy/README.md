# container-deploy

DrivingSDK 容器开发环境一键部署工具。

## 快速开始

### 通过 Agent 使用（推荐）

直接告诉 agent：

> "帮我部署一个 DrivingSDK 容器"

Agent 会引导你完成配置：镜像选择、容器命名、路径挂载、SSH配置、conda环境。

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
  --conda-name "dev"
```

### 使用本地镜像文件

```bash
bash scripts/deploy-container.sh \
  --image-file "/path/to/drivingsdk.tar" \
  --container-name "my_drivingsdk"
```

### 使用已有镜像

```bash
bash scripts/deploy-container.sh \
  --image "my-registry.com/drivingsdk:latest" \
  --container-name "my_drivingsdk"
```

## 配置

复制 `config.example.yaml` 为 `config.yaml`，添加自定义镜像版本。

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
