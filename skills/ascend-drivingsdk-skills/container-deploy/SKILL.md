---
name: ascend-drivingsdk-skills/container-deploy
description: DrivingSDK容器环境一键部署，含镜像管理、SSH配置、conda环境
---

# container-deploy

## 功能
部署 DrivingSDK 容器开发环境：拉取/加载镜像 → 创建容器（NPU设备+驱动挂载）→ 配置容器内SSH → 配置conda环境 → 打印环境信息 → 生成部署档案。

不耦合SSH，远程场景由 ssh-dev-suite 通过 ssh-exec.sh 调用本脚本。

## 前置条件
- 宿主机已安装 Docker
- 宿主机已安装昇腾 NPU 驱动（/usr/local/Ascend/driver 存在）

## 交互流程

Agent 按以下顺序通过 AskUserQuestion 引导用户。**容器一旦创建，挂载路径无法修改**，因此挂载相关的配置必须在创建前充分确认，不可跳过或自行决定。

### 第〇阶段：工作空间与数据

0. 询问用户服务器上是否有现成的 workspace 目录
   - 若有 → 使用该路径作为挂载基准（如 `/home/user/workspace`）
   - 若无 → 询问用户希望的 workspace 路径，由 agent 创建
   - **注意**：agent 不应自行决定 workspace 路径（如 `/root/workspace`），必须询问用户，避免增加管理负担
   - 项目代码将同步到该 workspace 内的子目录中（如 `<workspace>/DrivingSDK_DT`）

1. 询问用户是否需要挂载数据集目录
   - 若有 → 询问宿主机路径和容器内映射路径（如 `/data/datasets:/datasets`）
   - 若无 → 跳过，但需告知用户容器创建后无法补加挂载
   - **注意**：这一步也不可跳过，必须明确询问

2. 询问用户是否还有其他需要挂载的路径（循环询问直到用户说不需要）
   - 如日志目录、模型权重目录、共享存储等

### 第一阶段：镜像

3. 执行 `uname -m` 检测架构，告知用户，允许覆盖
4. 读取 config.yaml 的 images.versions，作为选择题让用户选镜像版本，提供"自定义"选项
5. 执行脚本拉取镜像。若退出码为 2（拉取失败），进入降级流程：
   - A：执行 `docker images` 展示已有镜像让用户选择（--image 参数）— **优先尝试**
   - B：用户提供完整镜像 pull 地址（--image 参数）
   - C：用户提供本地 .tar 文件路径（--image-file 参数）

### 第二阶段：容器配置

6. 容器名（必填）
7. SSH 端口：容器内 sshd 监听端口（--network=host 下直接绑宿主机端口），用于 VSCode Remote SSH。可留空跳过
8. 额外暴露端口：Jupyter/TensorBoard 等，可留空
9. 容器 root 密码（仅在指定 SSH 端口时询问）

### 第三阶段：环境配置

10. torch 版本选择题：
    - 2.1.0（Python 3.8）
    - 2.6.0（Python 3.10）
    - 2.7.1（Python 3.10）
    - 不指定（用户自行管理 conda 环境）
11. 若指定 torch → 询问 conda 环境自定义名称（可留空使用原名）

### 第三阶段补充：代理/网络配置

容器使用 `--network=host`，共享宿主机网络栈。若宿主机无外网或需要代理：

12. 询问用户是否需要配置 HTTP 代理
    - 若需要 → 询问代理地址（如 `http://127.0.0.1:7897`）
    - 典型场景：通过 ssh-dev-suite 的反向代理隧道将本地代理转发到宿主机
    - agent 在容器内执行时将代理环境变量注入命令：
      ```bash
      docker exec <container> bash -c "export http_proxy=<proxy> https_proxy=<proxy> && <command>"
      ```
    - 也可持久化写入容器 `~/.bashrc`
    - 代理可用于：pip install、git clone、curl/wget 等

**反向代理使用示例**（配合 ssh-dev-suite）：
```bash
# 本地建立反向代理隧道（本机代理端口转发到远程宿主机）
bash ssh-tunnel.sh proxy <profile> --local-proxy-port 7897
# 容器内即可通过 http://127.0.0.1:7897 访问外网
```

### 第四阶段：执行

拼接参数调用脚本：

```bash
bash scripts/deploy-container.sh \
  --image-tag "8.5.0_alpha001" \
  --container-name "my_sdk" \
  --mount "/home/user/workspace:/workspace" \
  --mount "/data/datasets:/datasets" \
  --ssh-port 2222 \
  --root-password "xxx" \
  --torch-version "2.1.0" \
  --conda-name "my_env"
```

### 第五阶段：部署档案

脚本执行完成后，agent **必须**：

1. **收集完整环境信息**并以结构化方式展示给用户，包括：
   - 宿主机信息：IP、操作系统、架构、内核版本
   - NPU 信息：型号、数量、驱动版本、npu-smi 版本
   - 容器信息：镜像名（含 tag）、容器名、进入方式（`docker exec -it <name> bash`）
   - 挂载路径列表：每一条 `宿主机路径 → 容器路径`
   - SSH 配置：端口、连接命令、VSCode Remote SSH 配置块
   - 代理配置：代理地址（若配置了）
   - 开发环境：conda 环境名、Python 版本
   - SDK 版本链：CANN → torch → torch_npu → mx_driving（含各版本号）
   - 部署时间戳
   - 常用命令速查：进入容器、激活 conda、source CANN 环境、构建项目、运行测试

2. **生成部署档案文件** `deployment-manifest.md`，保存到容器内 workspace 根目录（如 `/workspace/deployment-manifest.md`），内容为上述信息的 markdown 格式，方便后续查阅。

## 配置
参考本目录 `config.example.yaml`，复制为 `config.yaml` 后由 agent 引导填写。

## 跨平台兼容
- 脚本包含 Windows 换行符（`\r\n`）自动修复：从 Windows 传输到 Linux 时，脚本首次运行会自动 `sed` 清理并 `exec` 重新执行
- Agent 通过 scp 传输脚本时无需额外处理换行符
- 从 Windows 向 Linux 传输项目源码时，`.sh`、`.py`、`CMakeLists.txt` 等文件可能带有 `\r\n`，agent 应在首次构建前批量修复：`find . -name "*.sh" -o -name "*.py" -o -name "CMakeLists.txt" | xargs sed -i 's/\r$//'`

## Token约束
- 脚本输出：直接展示给用户，不做额外处理
- docker pull 输出：只关注成功/失败状态
- 环境信息：完整展示
- 部署档案：完整生成，不截断
