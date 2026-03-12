---
name: ascend-drivingsdk-skills/cann-install
description: CANN（昇腾异构计算架构）安装，支持社区版/商业版，run包/conda/下载三种方式
metadata:
  type: process
  version: "1.0"
  tags: [cann, install, ascend]
  domain: ai-infra
  risk_level: medium
  platform: linux
---

# cann-install

## 概述
引导用户安装 CANN（Compute Architecture for Neural Networks），支持社区版和商业版，提供三种安装方式。

## 适用场景
- 首次搭建 CANN 环境
- 升级/切换 CANN 版本
- 在容器内安装 CANN

## 运行环境
- **平台**：Linux（openEuler/Ubuntu/CentOS 等昇腾支持的发行版）
- **架构**：aarch64（ARM）、x86_64
- 若在远程服务器上操作，需要具备远程执行能力（在可用 skill 中寻找提供此功能的工具）

## 前置条件
- 已安装昇腾 NPU 驱动（`/usr/local/Ascend/driver` 存在）
- 已确认 NPU 可用：`npu-smi info` 输出正常（若不熟悉此命令，寻找提供 NPU 基础命令能力的 skill）

## 交互流程

### 第一步：收集安装信息

Agent 通过一次交互收集以下信息：

1. **检查已有 CANN 安装**（agent 自动执行）：
   - 检查公共路径是否已安装 CANN：
   ```bash
   find /usr/local/Ascend -name "ascend_toolkit_install.info" -maxdepth 4 2>/dev/null | xargs cat 2>/dev/null
   find /usr/local/Ascend -name "set_env.sh" -path "*/ascend-toolkit/*" -o -name "set_env.sh" -path "*/cann-*" 2>/dev/null | head -5
   ```
   - 若已有安装，告知用户已有版本信息，询问：
     - 直接使用已有安装（仅 source 环境变量）
     - 安装到自定义路径（与已有安装共存）

2. **环境管理方式**（必问）：
   - conda / venv / 无环境管理
   - 若用户选择 conda 但机器上未安装，agent 需先帮助安装 Miniconda：
     ```bash
     wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$(uname -m).sh -O miniconda.sh
     bash miniconda.sh -b -p $HOME/miniconda3
     eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
     conda init
     ```
   - 若选择 venv，确认 `python -m venv` 可用

3. **版本选择**：
   - 社区版（Community Edition）：免费，功能完整
   - 商业版（Commercial Edition）：商业授权，有技术支持
   - CANN 版本号（如 8.5.0、8.0.0 等）

4. **环境检测**（agent 自动执行）：
   - `uname -m` — 架构（aarch64/x86_64）
   - `cat /etc/os-release` — 操作系统
   - `cat /usr/local/Ascend/driver/version.info` — 驱动版本

5. **安装方式**（三选一）：
   - A：**用户提供已下载的 run 包** — 用户告知 run 包路径（toolkit + ops 两个包）
   - B：**conda 安装** — 使用 conda 从昇腾官方 channel 安装
   - C：**从社区下载** — 从昇腾社区官网下载 run 包

6. **安装路径**（方式 A/C 时）：
   - 默认：`/usr/local/Ascend`（系统级）
   - 自定义：如 `/home/<user>/CANN_<version>/`（用户级，推荐非 root 或多版本共存场景）

### 第二步：执行安装

#### 方式 A：用户提供 run 包

CANN 通常包含两个 run 包：toolkit（核心工具链）和 ops（算子库）。

**注意**：ops 包名因芯片型号不同而异，如 `Ascend-cann-910b-ops_*.run`（Ascend 910B）、`Ascend-cann-A3-ops_*.run`（Atlas A3）。需根据实际芯片选择正确的 ops 包。

```bash
chmod +x <toolkit_run包路径> <ops_run包路径>

# --quiet 自动接受 EULA，避免交互卡住
<toolkit_run包路径> --quiet --install --install-path=<安装路径>
<ops_run包路径> --quiet --install --install-path=<安装路径>
```

**关键**：`--quiet` 必须加，否则卡在 EULA 交互式确认。

#### 方式 B：conda 安装

```bash
conda config --add channels https://mirrors.huaweicloud.com/ascend/ascend-toolkit/
conda search cann-toolkit
conda install cann-toolkit=<版本号> cann-ops=<版本号> -y
```

conda 方式的 set_env.sh 路径在 conda 环境内，与 run 包安装不同。

#### 方式 C：从社区下载

引导用户访问下载页面：
- 社区版：`https://www.hiascend.com/developer/download/community/result?module=cann`
- 商业版：`https://www.hiascend.com/developer/download/commercial/result?module=cann`

根据架构（aarch64/x86_64）和 OS 选择正确的 run 包，下载后按方式 A 安装。

**注意**：下载可能需要登录昇腾社区账号。

### 第三步：配置环境变量

```bash
# 自动查找 set_env.sh（兼容不同版本目录结构）
SET_ENV_PATH=$(find <安装路径> -name "set_env.sh" -maxdepth 4 | head -1)
source "$SET_ENV_PATH"

# 建议持久化
echo "source $SET_ENV_PATH" >> ~/.bashrc
```

**注意**：不同 CANN 版本 set_env.sh 路径不同（旧版 `ascend-toolkit/set_env.sh`，8.5.0+ `cann-<版本号>/set_env.sh`），用 find 自动定位。

### 第四步：验证安装

```bash
find <安装路径> -name "ascend_toolkit_install.info" | xargs cat
npu-smi info
```

## 注意事项
- `--quiet` 参数必须加，否则 EULA 确认阻塞自动化流程
- set_env.sh 路径因版本而异，用 find 自动定位
- 同一机器可安装多个 CANN 版本，通过 source 不同 set_env.sh 切换
- conda 安装方式的环境变量配置与 run 包方式不同
