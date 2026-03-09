# test-coverage

C++/Python 代码覆盖率收集工具。

## 快速开始

```
帮我收集 C++ 覆盖率报告
运行 Python 测试并生成覆盖率
```

## 手动使用

```bash
# C++ 覆盖率
bash scripts/collect-cpp-coverage.sh --project-root /path/to/project

# Python 覆盖率
bash scripts/run-py-coverage.sh --test-dir /path/to/tests --source my_package
```

## 构建集成

首次使用前需完成一次性构建集成，参考 [docs/build-integration.md](docs/build-integration.md)。

## 注意事项

- C++ 覆盖率需先以 `COVERAGE=ON` 构建项目
- Python 覆盖率需安装 `coverage` 包（`pip install coverage`）
- `config.yaml` 含项目路径，不入库
