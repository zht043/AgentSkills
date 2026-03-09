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
