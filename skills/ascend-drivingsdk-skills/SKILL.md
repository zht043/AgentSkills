---
name: ascend-drivingsdk-skills
description: Ascend NPU DrivingSDK开发工具集
---

# ascend-drivingsdk-skills

Ascend DrivingSDK 开发辅助 skill 集合，每个子目录为独立 skill。

## ⚠️ Agent 必读

**这是一个 Skill Suite。本文件只是索引，不包含执行细节。**

使用任何子 skill 前，Agent 必须：
1. 读取对应子 skill 的 `SKILL.md`（完整交互流程和规范）
2. 读取对应子 skill 的 `scripts/*.sh`（脚本参数、行为、退出码）
3. 若子 skill 描述中提到需要某种能力（如 SSH 隧道、反向代理等），在当前项目可用的 skill 集合中寻找能提供该能力的 skill，并读取其相关文档
4. 读取 `config.example.yaml`（了解可配置项）

**不要跳过任何步骤。不要仅凭本文件的一句话描述就开始执行。**

## Skills
- **container-deploy**：DrivingSDK 容器环境一键部署 → `container-deploy/SKILL.md`
  - 含镜像管理、工作空间挂载、SSH配置、conda环境、代理配置、部署档案生成
  - 远程场景需要 SSH 远程执行和反向代理能力（在可用 skill 中寻找提供此能力的工具）
- **test-coverage**：C++/Python 代码覆盖率收集 → `test-coverage/SKILL.md`
  - 含 gcov/lcov（C++）和 coverage 模块（Python）
  - 依赖项目构建集成（参见 `test-coverage/docs/build-integration.md`）
