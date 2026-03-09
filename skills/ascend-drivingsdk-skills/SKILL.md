---
name: ascend-drivingsdk-skills
description: Ascend NPU DrivingSDK开发工具套件：覆盖率收集、设备管理等
type: capability
---

# ascend-drivingsdk-skills

## 功能
Ascend NPU DrivingSDK 开发工具套件，提供覆盖率收集等自动化能力。

## 模块
- **test-coverage**：C++/Python代码覆盖率收集 → `test-coverage/SKILL.md`

## 配置
`config.yaml`由agent引导生成，参考`config.example.yaml`。

## Token约束
所有子模块遵循统一原则：
- 覆盖率报告：只输出摘要统计，不读取完整HTML
- 命令输出：优先使用过滤参数
- 重复信息：不复述已知内容
