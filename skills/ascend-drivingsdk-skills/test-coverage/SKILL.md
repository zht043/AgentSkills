---
name: ascend-drivingsdk-skills/test-coverage
description: C++/Python代码覆盖率收集，支持gcov/lcov和coverage模块
type: capability
---

# test-coverage

## 功能
收集C++（gcov/lcov）和Python（coverage模块）代码覆盖率，生成HTML/XML报告。

## 前置条件
项目需完成构建集成，参考 `docs/build-integration.md`。

## 使用
```bash
# C++ 覆盖率收集（需先以 COVERAGE=ON 构建并执行测试）
bash test-coverage/scripts/collect-cpp-coverage.sh [--project-root DIR] [--output-dir DIR]

# Python 覆盖率收集
bash test-coverage/scripts/run-py-coverage.sh [--test-dir DIR] [--source PKG] [--format html|xml]
```

## 配置
参考套件根目录 `config.example.yaml` 的 `coverage:` 段。

## Token约束
- 覆盖率报告：只读summary行，不读完整HTML报告
- 测试输出：失败时只看失败用例，不看全部输出
