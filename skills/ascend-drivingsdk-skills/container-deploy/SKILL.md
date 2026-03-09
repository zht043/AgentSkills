---
name: ascend-drivingsdk-skills/container-deploy
description: DrivingSDK容器环境一键部署，含镜像管理、SSH配置、conda环境
type: capability
---

# container-deploy

## 功能
部署 DrivingSDK 容器开发环境：拉取/加载镜像 → 创建容器（NPU设备+驱动挂载）→ 配置容器内SSH → 配置conda环境 → 打印环境信息。

不耦合SSH，远程场景由 ssh-dev-suite 通过 ssh-exec.sh 调用本脚本。

## 前置条件
- 宿主机已安装 Docker
- 宿主机已安装昇腾 NPU 驱动（/usr/local/Ascend/driver 存在）

## 交互流程

Agent 按以下顺序通过 AskUserQuestion 引导用户：

### 第一阶段：镜像

1. 执行 `uname -m` 检测架构，告知用户，允许覆盖
2. 读取 config.yaml 的 images.versions，作为选择题让用户选镜像版本，提供"自定义"选项
3. 执行脚本拉取镜像。若退出码为 2（拉取失败），进入降级流程：
   - A：用户提供完整镜像 pull 地址（--image 参数）
   - B：用户提供本地 .tar 文件路径（--image-file 参数）
   - C：执行 `docker images` 展示已有镜像让用户选择（--image 参数）

### 第二阶段：容器配置

4. 容器名（必填）
5. datasets 挂载：宿主机路径:容器路径，可留空跳过
6. workspace 挂载：宿主机路径:容器路径，可留空跳过
7. 循环询问是否还要挂载其他路径
8. SSH 端口：容器内 sshd 监听端口（--network=host 下直接绑宿主机端口），用于 VSCode Remote SSH。可留空跳过
9. 额外暴露端口：Jupyter/TensorBoard 等，可留空
10. 容器 root 密码（仅在指定 SSH 端口时询问）

### 第三阶段：环境配置

11. torch 版本选择题：
    - 2.1.0（Python 3.8）
    - 2.6.0（Python 3.10）
    - 2.7.1（Python 3.10）
    - 不指定（用户自行管理 conda 环境）
12. 若指定 torch → 询问 conda 环境自定义名称（可留空使用原名）

### 第四阶段：执行

拼接参数调用脚本：

```bash
bash scripts/deploy-container.sh \
  --image-tag "8.5.0_alpha001" \
  --container-name "my_sdk" \
  --mount "/data/datasets:/datasets" \
  --ssh-port 2222 \
  --root-password "xxx" \
  --torch-version "2.1.0" \
  --conda-name "my_env"
```

脚本输出包含环境信息和 SSH 连接方式，直接展示给用户。

## 配置
参考本目录 `config.example.yaml`，复制为 `config.yaml` 后由 agent 引导填写。

## Token约束
- 脚本输出：直接展示给用户，不做额外处理
- docker pull 输出：只关注成功/失败状态
- 环境信息：完整展示
