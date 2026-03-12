---
name: ascend-drivingsdk-skills/container-deploy
description: DrivingSDK容器环境一键部署，含镜像管理、SSH配置、conda环境
metadata:
  type: capability
  version: "1.0"
  tags: [docker, container, deploy]
  domain: ai-infra
  risk_level: high
  platform: cross-platform
---

# container-deploy

## 功能
部署 DrivingSDK 容器开发环境：拉取/加载镜像 → 创建容器（NPU设备+驱动挂载）→ 配置容器内SSH → 配置conda环境 → 打印环境信息 → 生成部署档案。

不耦合SSH，远程场景由具备 SSH 远程执行能力的 skill（如 SSH 隧道/远程执行工具）调用本脚本。

## 运行环境
- **宿主机**：Linux（openEuler/Ubuntu 等 Ascend NPU 支持的发行版）
- **架构**：aarch64、x86_64

## 前置条件
- 宿主机已安装 Docker
- 宿主机已安装昇腾 NPU 驱动（/usr/local/Ascend/driver 存在）

## 交互流程

Agent 通过 **两阶段** 引导用户完成部署。

### 第一阶段：一次性配置收集

Agent 通过 AskUserQuestion **一口气收集以下所有容器创建配置**，不要拆成多轮对话。**容器一旦创建，挂载路径无法修改**，必须在创建前充分确认。Conda 环境选择在容器创建后进行（因为需要先检测容器内实际可用环境）。

收集项（agent 在一次交互中呈现所有问题）：

1. **环境检测**（agent 自动执行，结果展示给用户）：
   - `uname -m` — 宿主机架构
   - `cat /etc/os-release` — 宿主机操作系统
   - 告知用户以上信息，供镜像选择参考

2. **镜像来源**（三选一，平等呈现，无优先级）：
   - A：使用宿主机已有镜像 — agent 执行 `docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"` 展示列表让用户选择（`--image` 参数）
   - B：用户提供本地 `.tar` 文件路径（`--image-file` 参数）
   - C：从 registry 拉取 — 读取 config.yaml 的 `images.versions` 作为选择题，或用户提供完整地址（`--image-tag` 或 `--image` 参数）
   - ⚠️ 镜像需匹配宿主机 OS 和架构，agent 应提醒用户确认兼容性

3. **工作空间**（必问，不可跳过或自行决定）：
   - 服务器上是否有现成的 workspace 目录？路径是什么？
   - agent 不应自行决定路径（如 `/root/workspace`），必须询问用户

4. **数据集挂载**（必问）：
   - 是否需要挂载数据集目录？宿主机路径和容器内映射路径
   - 告知用户容器创建后无法补加挂载

5. **其他挂载路径**：日志目录、模型权重等（可选，可留空）

6. **容器名**（必填）

7. **SSH 端口**（可选，留空跳过）：容器内 sshd 监听端口（`--network=host` 下绑宿主机端口）

8. **容器 root 密码**（仅在指定 SSH 端口时需要）

9. **HTTP 代理**（可选）：
   - 代理地址（如 `http://127.0.0.1:7897`）
   - 典型场景：通过反向代理隧道（如有提供 SSH 隧道功能的 skill 可用，优先使用）将本地代理转发到宿主机

### 第二阶段：执行与 conda 配置

收集完配置后，agent 自动执行：

1. **拼接参数调用脚本**：

```bash
bash scripts/deploy-container.sh \
  --image "已有镜像名" \
  --container-name "my_sdk" \
  --mount "/home/user/workspace:/workspace" \
  --mount "/data/datasets:/datasets" \
  --ssh-port 2222 \
  --root-password "xxx" \
  --proxy "http://127.0.0.1:7897"
```

2. **Conda 环境选择**（容器创建后）：
   - 执行 `bash scripts/deploy-container.sh --list-conda-envs`（或直接 `docker exec <container> bash -c 'source <conda.sh> && conda env list'`）列出容器内实际可用的 conda 环境
   - 将环境列表展示给用户，让用户选择要激活的环境（或选择跳过）
   - 若用户选择了环境，**必须询问是否要重命名（clone）该环境**：
     - 向用户解释：重命名实质是 `conda create --clone <原名> -n <新名>`，原环境保留不变
     - 提供推荐命名供用户选择或自定义，推荐命名基于项目/用途语义，例如：`sdk-dev`、`driving-dev`、`<容器名>-dev`、`my-env`
     - 若用户选择重命名，使用 `--conda-name <新名>` 参数
     - 若用户选择保持原名，仅使用 `--conda-env <原名>` 即可
   - 再次调用脚本（或手动配置）：`--conda-env <选择的环境名> [--conda-name <新名>]`

3. **项目依赖安装**（conda 配置完成后，可选）：
   - 询问用户是否需要安装项目依赖（推荐在此时完成，避免后续运行测试或覆盖率时报 ModuleNotFoundError）
   - 若用户确认，按以下顺序在容器内执行：
     1. 根目录依赖：`pip install -r requirements.txt`（若存在）
     2. 测试依赖：`pip install -r tests/requirements.txt`（若存在，典型包：expecttest, hypothesis, pyyaml, prettytable, pydantic 等）
     3. 提醒用户：部分依赖可能需要网络（如 mmcv 源码编译），若容器无外网访问，需先配置代理
   - 若用户选择跳过，提醒后续首次运行测试前需手动安装

4. **部署档案**：

脚本执行完成后，agent **必须**：

- **收集完整环境信息**并以结构化方式展示给用户：宿主机信息、NPU 信息、容器信息、挂载路径、SSH 配置、代理、conda 环境、SDK 版本链、常用命令速查
- **生成部署档案文件** `deployment-manifest.md`，保存到容器内 workspace 根目录
- **将档案完整内容打印到对话中**，让用户无需进入容器即可直接查阅：以 Markdown 代码块或引用块格式完整输出档案正文，不截断

## 配置
参考本目录 `config.example.yaml`，复制为 `config.yaml` 后由 agent 引导填写。

## 跨平台兼容

### 脚本换行符修复（强制前置步骤）

从 Windows 向 Linux 传输脚本时，`\r\n` 换行符会导致 bash 报 `syntax error near unexpected token $'\r'`。脚本虽内置自修复逻辑，但 **自修复依赖 bash 能解析到修复代码行**——若 `\r\n` 导致更早的语法错误，自修复无法生效。

**Agent 必须**：在远程执行任何 `.sh` 脚本前，**先执行换行符清理**，不依赖脚本自修复：

```bash
# 上传脚本到远程后，执行前先清理
sed -i 's/\r$//' /path/to/deploy-container.sh
```

### 项目源码换行符

从 Windows 向 Linux 传输项目源码时，`.sh`、`.py`、`CMakeLists.txt` 等文件可能带有 `\r\n`，agent 应在首次构建前批量修复：

```bash
find . -name "*.sh" -o -name "*.py" -o -name "CMakeLists.txt" | xargs sed -i 's/\r$//'
```

## Token约束
- 脚本输出：直接展示给用户，不做额外处理
- docker pull 输出：只关注成功/失败状态
- 环境信息：完整展示
- 部署档案：完整生成并打印到对话，不截断
