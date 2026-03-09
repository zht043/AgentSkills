# ascend-drivingsdk-skills

Ascend NPU DrivingSDK 开发工具套件。

## 模块

| 模块 | 功能 |
|------|------|
| test-coverage | C++/Python 代码覆盖率收集与报告生成 |

## 快速开始

### 配置
```
帮我配置覆盖率收集
```
agent 会引导填写项目信息，自动生成 config.yaml。

### 常用 Prompt

**覆盖率收集：**
- `帮我收集 C++ 覆盖率报告`
- `运行 Python 测试并生成覆盖率`
- `收集完整的 C++ 和 Python 覆盖率`

## 构建集成

首次使用前需完成项目构建集成，参考 `test-coverage/docs/build-integration.md`。

## 注意事项

- config.yaml 含项目路径信息不入库
- C++ 覆盖率需先以 `COVERAGE=ON` 构建项目
- Python 覆盖率需安装 `coverage` 包（`pip install coverage`）
