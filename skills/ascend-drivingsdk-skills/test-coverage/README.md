# test-coverage

C++/Python 代码覆盖率收集工具，支持 gcov/lcov（C++）和 coverage 模块（Python）。

## 快速开始

通过 agent 使用：

```
帮我收集 C++ 覆盖率报告
运行 Python 测试并生成覆盖率
```

## 手动使用

```bash
# C++ 覆盖率（需先以 COVERAGE=ON 构建并执行测试）
bash scripts/collect-cpp-coverage.sh --project-root /path/to/project

# Python 覆盖率
bash scripts/run-py-coverage.sh --test-dir /path/to/tests --source my_package
```

## 前置条件

### 构建集成

首次使用前需完成一次性构建集成，参考 [docs/build-integration.md](docs/build-integration.md)。

### 测试依赖

覆盖率收集前需确保测试依赖已安装：

1. 项目根目录依赖：`pip install -r requirements.txt`
2. 测试专用依赖：`pip install -r tests/requirements.txt`
   - 包含：torch_scatter, torchvision, hypothesis, expecttest, pyyaml, prettytable, pydantic
3. mmcv 源码编译（需网络访问）：
   ```bash
   git clone -b 1.x https://github.com/open-mmlab/mmcv.git
   cd mmcv
   MMCV_WITH_OPS=1 FORCE_NPU=1 python setup.py build_ext
   MMCV_WITH_OPS=1 FORCE_NPU=1 python setup.py develop
   ```

> 无外网环境可通过 ssh-dev-suite 的反向代理隧道配置代理访问。

## 配置

复制 `config.example.yaml` 为 `config.yaml`，按需修改项目路径。`config.yaml` 已被 `.gitignore` 排除。

## 注意事项

- C++ 覆盖率需先以 `COVERAGE=ON` 构建项目
- Python 覆盖率需安装 `coverage` 包（`pip install coverage`）
- 报告输出到 `--output-dir` 指定目录，默认 `coverage-report/`
- 从 Windows 传输脚本时自动修复换行符（`\r\n` → `\n`）
