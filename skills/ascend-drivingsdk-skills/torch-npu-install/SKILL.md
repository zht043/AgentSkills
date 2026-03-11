---
name: ascend-drivingsdk-skills/torch-npu-install
description: PyTorch和torch_npu安装，含版本选择、预编译包、源码编译
---

# torch-npu-install

## 概述
引导用户安装 PyTorch 和 torch_npu（昇腾 NPU 的 PyTorch 适配层），确保版本匹配。

## 适用场景
- 搭建 PyTorch + torch_npu 环境
- 升级/切换 PyTorch 和 torch_npu 版本
- 修复 torch_npu 安装问题

## 运行环境
- **平台**：Linux（已安装 CANN）
- **架构**：aarch64（ARM）、x86_64
- 若在远程服务器上操作，需要具备远程执行能力（在可用 skill 中寻找提供此功能的工具）

## 前置条件
- CANN 已安装且 `set_env.sh` 已 source（若不确定，寻找提供 CANN 安装能力的 skill）
- `npu-smi info` 输出正常

## 交互流程

### 第一步：收集配置信息

Agent 通过一次交互收集：

1. **环境管理方式**（必问）：
   - conda / venv / 无环境管理
   - 若用户选择 conda 但机器上未安装，agent 需先帮助安装 Miniconda：
     ```bash
     wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$(uname -m).sh -O miniconda.sh
     bash miniconda.sh -b -p $HOME/miniconda3
     eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
     conda init
     ```
   - 若选择 venv，确认 `python -m venv` 可用
   - 帮助用户创建/激活环境

2. **版本选择**（必问）：
   - PyTorch 版本（如 2.1.0、2.6.0、2.7.1 等）
   - torch_npu 版本须与 PyTorch 主版本一致

3. **安装方式**（二选一）：
   - A：**预编译 whl 包**（推荐，快速）— 通过 pip 或用户提供 whl 文件
   - B：**源码编译** — 从 gitcode/github 克隆源码编译 wheel 包

4. **环境检测**（agent 自动执行）：
   - `uname -m` — 架构
   - 当前 CANN 版本
   - 当前 Python 版本
   - 当前是否已有 PyTorch/torch_npu

### 第二步：安装 PyTorch

根据官方 README，PyTorch 安装方式因架构而异：

**aarch64（ARM）**：
```bash
pip3 install torch==<版本>
```

**x86_64**：
```bash
pip3 install torch==<版本>+cpu --index-url https://download.pytorch.org/whl/cpu
```

**说明**：昇腾 NPU 计算由 torch_npu 接管，x86 架构需安装 CPU 版 PyTorch（避免下载不必要的 CUDA 依赖），aarch64 版 PyTorch 本身不含 CUDA，直接安装即可。此为 [torch_npu 官方 README](https://gitcode.com/Ascend/pytorch) 明确指导。

### 第三步：安装 torch_npu

#### 方式 A：预编译 whl 包（推荐）

```bash
# 安装 torch_npu 运行依赖（torch_npu 导入时需要 pyyaml 和 numpy）
pip3 install pyyaml numpy

pip3 install torch-npu==<版本>
```

若 pip 源中无对应版本，引导用户从 [Ascend/pytorch Releases](https://gitcode.com/Ascend/pytorch/releases) 下载 whl 包后本地安装。

#### 方式 B：源码编译

```bash
# 1. 克隆仓库（分支命名规则：v{PyTorch版本}-{CANN内部版本}）
git clone https://gitcode.com/Ascend/pytorch.git -b <对应分支> --depth 1
cd pytorch

# 2. 安装编译依赖
pip install -r requirements.txt
pip install pyyaml setuptools

# 3. 检查并安装正确版本的 cmake（>=3.19 且 <4.0）
CMAKE_VER=$(cmake --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+')
if [ -z "$CMAKE_VER" ] || [ "$(echo "$CMAKE_VER < 3.19" | bc)" = "1" ] || [ "$(echo "$CMAKE_VER >= 4.0" | bc)" = "1" ]; then
    echo "cmake 版本不满足要求（需 >=3.19, <4.0），正在安装..."
    pip install 'cmake>=3.19,<3.30'
fi

# 4. 编译（推荐使用 Docker 环境，或确保 gcc 版本满足要求）
bash ci/build.sh --python=<Python版本>

# 5. 安装 wheel 包
pip install dist/torch_npu-*.whl
```

**cmake 版本要求**：>=3.19 且 <4.0（4.x 与 torch_npu CMakeLists.txt 不兼容）。若版本不满足，agent 应自动通过 `pip install 'cmake>=3.19,<3.30'` 安装。

### 第四步：验证安装

```bash
python -c "import torch; import torch_npu; print(f'PyTorch: {torch.__version__}, torch_npu: {torch_npu.__version__}')"
python -c "import torch; import torch_npu; print(f'NPU available: {torch.npu.is_available()}, count: {torch.npu.device_count()}')"
```

## 版本对应关系

Agent 应从官方 README 获取最新版本对应关系：[Ascend/pytorch README - Ascend Auxiliary Software](https://gitcode.com/Ascend/pytorch#ascend-auxiliary-software)。

常见组合（仅供参考，以官方文档为准）：

| CANN 版本 | PyTorch | torch_npu 版本 | 分支 |
|----------|---------|---------------|------|
| 8.5.0    | 2.8.0 / 2.7.1 / 2.6.0 | 对应 post 版本 | v{ver}-7.3.0 |
| 8.3.RC1  | 2.8.0 / 2.7.1 / 2.6.0 / 2.1.0 | 对应 post 版本 | v{ver}-7.2.0 |
| 8.0.0    | 2.4.0 / 2.3.1 / 2.1.0 | 对应 post 版本 | v{ver}-6.0.0 |
| 7.0.0    | 2.1.0 / 2.0.1 / 1.11.0 | 对应版本 | v{ver}-5.0.0 |

**Python 版本支持**：

| PyTorch | Python |
|---------|--------|
| 2.7.1 / 2.8.0 | 3.9-3.11 |
| 2.6.0 | 3.9-3.11 |
| 2.1.0 | 3.8-3.11 |

## 注意事项
- 默认推荐预编译 whl 包安装（`pip install torch-npu`），源码编译适合特殊需求
- x86_64 需安装 CPU 版 PyTorch，aarch64 直接安装即可（官方 README 指导）
- torch_npu 运行依赖 `pyyaml` 和 `numpy`，安装 torch_npu 前需先安装
- cmake 版本必须 >=3.19 且 <4.0，不满足时 agent 应自动安装
- 升级时先 `pip uninstall torch_npu torch -y` 再重新安装
- 编译推荐 gcc 版本：ARM gcc 10.2，x86 gcc 9.3.1
