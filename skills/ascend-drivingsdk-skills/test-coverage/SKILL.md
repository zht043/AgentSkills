---
name: ascend-drivingsdk-skills/test-coverage
description: C++/Python代码覆盖率收集，支持gcov/lcov和coverage模块
metadata:
  type: capability
  version: "1.0"
  tags: [coverage, gcov, pytest]
  domain: ai-infra
  risk_level: low
  platform: linux
---

# test-coverage

## 功能
收集 C++（gcov/lcov）和 Python（coverage 模块）代码覆盖率，生成 HTML/XML 报告。

## 运行环境
- **执行环境**：Linux（容器内，Ascend NPU 环境）

## 前置条件
项目需完成构建集成，参考 `docs/build-integration.md`。

### 测试依赖安装

覆盖率收集前 **必须** 确保测试依赖已安装。Agent **不能跳过此检查**——缺少依赖会导致所有测试在 import 阶段直接 FAIL（典型报错：`ModuleNotFoundError: No module named 'expecttest'`）。

**Agent 执行顺序**：

1. **先验证**：在容器内执行 `python -c "import expecttest; import hypothesis"` 快速检测核心测试依赖是否存在
2. **若缺失**，按顺序安装：
   - 根目录依赖：`pip install -r requirements.txt`
   - 测试专用依赖：`pip install -r tests/requirements.txt`
     - 包含：torch_scatter, torchvision, hypothesis, expecttest, pyyaml, prettytable, pydantic
3. mmcv 源码编译（需要网络访问，如需代理可在可用 skill 中寻找提供反向代理/SSH 隧道功能的工具）：
   ```bash
   git clone -b 1.x https://github.com/open-mmlab/mmcv.git
   cd mmcv
   MMCV_WITH_OPS=1 FORCE_NPU=1 python setup.py build_ext
   MMCV_WITH_OPS=1 FORCE_NPU=1 python setup.py develop
   cd ../
   ```

**注意**：如环境无外网访问，先通过反向代理隧道配置代理（在可用 skill 中寻找提供 SSH 隧道/反向代理功能的工具）：
```bash
export http_proxy=http://127.0.0.1:<proxy_port>
export https_proxy=http://127.0.0.1:<proxy_port>
```

## 使用
```bash
# C++ 覆盖率（需先以 COVERAGE=ON 构建并执行测试）
bash scripts/collect-cpp-coverage.sh [--project-root DIR] [--output-dir DIR]

# Python 覆盖率
bash scripts/run-py-coverage.sh [--test-dir DIR] [--source PKG] [--format html|xml]
```

## 配置
参考本目录 `config.example.yaml`，复制为 `config.yaml` 后由 agent 引导填写。

## 跨平台兼容
- 所有脚本包含 Windows 换行符（`\r\n`）自动修复
- Python 测试从测试文件所在目录执行（确保 `data_cache` 等相对 import 可用）
- 覆盖率数据文件（`.coverage.*`）从各测试子目录收集到项目根目录后合并

## Token约束
- 覆盖率报告：只读 summary 行，不读完整 HTML
- 测试输出：失败时只看失败用例
