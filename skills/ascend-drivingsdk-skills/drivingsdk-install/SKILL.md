---
name: ascend-drivingsdk-skills/drivingsdk-install
description: DrivingSDK（mx_driving）编译安装与更新，含依赖处理和版本匹配
metadata:
  type: process
  version: "1.0"
  tags: [drivingsdk, compile, install]
  domain: ai-infra
  risk_level: medium
  platform: linux
---

# drivingsdk-install

## 概述
引导用户编译安装 DrivingSDK（mx_driving 包），含首次安装和更新重装流程。

## 适用场景
- 首次编译安装 DrivingSDK
- 代码更新后重新编译安装
- 修复安装问题

## 运行环境
- **平台**：Linux（openEuler/Ubuntu 等昇腾支持的发行版）
- **架构**：aarch64、x86_64
- 若在远程服务器上操作，需要具备远程执行能力（在可用 skill 中寻找提供此功能的工具）

## 前置条件
- CANN 已安装且 `set_env.sh` 已 source
- PyTorch 和 torch_npu 已安装
- 若不确定前置条件，寻找提供 CANN 安装、torch_npu 安装能力的 skill

## 交互流程

### 第一步：收集信息

Agent 通过一次交互收集：

1. **环境管理方式**（必问）：
   - conda / venv / 无环境管理
   - 若用户选择 conda 或 venv 但机器上未安装，agent 需先帮助安装：
     - conda：引导安装 Miniconda（`wget` + `bash Miniconda3-latest-Linux-$(uname -m).sh -b`）
     - venv：确认 `python -m venv` 可用（通常随 Python 自带）
   - 帮助用户创建/激活环境

2. **仓库来源**（必问）：
   - 用户是否已有本地仓库？路径是什么？
   - 若无，从哪里克隆？（默认：`https://gitcode.com/Ascend/DrivingSDK.git`）
   - 需要哪个分支？（默认：master）

3. **安装模式**（二选一）：
   - **Release 模式**（默认推荐）：`bash ci/build.sh` 编译 wheel 包后 `pip install`
   - **Develop 模式**：`python setup.py develop`，适合开发调试，修改代码后无需重新安装

4. **安装类型**：首次安装 / 更新重装

5. **环境检测**（agent 自动执行）：
```bash
npu-smi info | head -5
python -c "import torch; import torch_npu; print(f'PyTorch: {torch.__version__}, torch_npu: {torch_npu.__version__}')"
python --version
```

### 第二步：获取代码

若用户无本地仓库：
```bash
cd <工作目录>
git clone <仓库地址>
cd DrivingSDK
```

若已有仓库且需更新：
```bash
cd <仓库路径>
git pull origin <分支>
```

### 第三步：安装依赖

```bash
pip install -r requirements.txt

# 检查并安装 cmake（>=3.19, <4.0）
CMAKE_VER=$(cmake --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+')
if [ -z "$CMAKE_VER" ] || [ "$(echo "$CMAKE_VER < 3.19" | bc)" = "1" ] || [ "$(echo "$CMAKE_VER >= 4.0" | bc)" = "1" ]; then
    echo "cmake 版本不满足要求，正在安装..."
    pip install 'cmake>=3.19,<3.30'
fi
```

### 第四步：编译与安装

#### Release 模式（默认）

```bash
PYTHON_VERSION=$(python --version 2>&1 | grep -oP '\d+\.\d+')

# 更新重装时，先清理旧产物
rm -rf dist/ build/

# 编译
bash ci/build.sh --python=$PYTHON_VERSION

# 更新重装时，先卸载旧版本
pip uninstall mx_driving -y 2>/dev/null

# 安装（若已有旧的 develop 安装，需 --force-reinstall）
pip install dist/mx_driving-*.whl --force-reinstall 2>/dev/null || pip install dist/mx_driving-*.whl
```

#### Develop 模式

```bash
python setup.py develop
```

开发调试时可使用 `--kernel-name` 参数仅编译特定算子：
```bash
python setup.py develop --kernel-name="DeformableConv2d;MultiScaleDeformableAttn"
```

编译耗时约数分钟，建议使用后台任务管理能力（在可用 skill 中寻找）。

### 第五步：验证

```bash
# 查看版本（mx_driving 无 __version__ 属性，用 pip show）
pip show mx-driving | grep -E 'Name|Version'

# 验证导入（⚠️ 必须从非源码目录执行，否则会优先导入本地源码而非安装的包）
cd /tmp
python -c "import mx_driving; print('mx_driving imported successfully')"
```

## 版本对应关系

详见 `references/version-table.md`。

## 常见问题

详见 `references/troubleshooting.md`。

## 注意事项
- 默认推荐 Release 模式（wheel 包安装），Develop 模式适合开发调试
- 更新重装时必须先清理 `dist/` 和 `build/`，避免安装旧包
- `mx_driving` 没有 `__version__` 属性，用 `pip show mx-driving` 查看版本
- `ci/build.sh` 的 `--python` 参数需与当前激活的 Python 版本一致
- 编译需要 cmake >=3.19.0 且 <4.0，不满足时 agent 应自动安装
- 验证导入时必须 `cd` 到非源码目录，避免导入本地源码而非安装的 wheel 包
- 若已有 develop 模式安装，切换到 Release 模式时需 `--force-reinstall`
