---
name: ascend-drivingsdk-skills/test-coverage
description: C++/Python代码覆盖率收集，支持gcov/lcov和coverage模块
type: capability
---

# test-coverage

## 功能
收集 C++（gcov/lcov）和 Python（coverage 模块）代码覆盖率，生成 HTML/XML 报告。

## 前置条件
项目需完成构建集成，参考 `docs/build-integration.md`。

### 测试依赖安装

覆盖率收集前需确保测试依赖已安装（参考 `tests/README.md`）：

1. 根目录依赖：`pip install -r requirements.txt`
2. 测试专用依赖：`pip install -r tests/requirements.txt`
   - 包含：torch_scatter, torchvision, hypothesis, expecttest, pyyaml, prettytable, pydantic
3. mmcv 源码编译（需要网络访问，如需代理可配合 ssh-dev-suite 反向代理）：
   ```bash
   git clone -b 1.x https://github.com/open-mmlab/mmcv.git
   cd mmcv
   MMCV_WITH_OPS=1 FORCE_NPU=1 python setup.py build_ext
   MMCV_WITH_OPS=1 FORCE_NPU=1 python setup.py develop
   cd ../
   ```

**注意**：如环境无外网访问，先通过 ssh-dev-suite 的反向代理隧道配置代理：
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

## Token约束
- 覆盖率报告：只读 summary 行，不读完整 HTML
- 测试输出：失败时只看失败用例
