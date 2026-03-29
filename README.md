# AgentSkills (Deprecated)

> **本仓库已停止维护。** 所有 skill 已拆分为独立仓库，请前往下方链接获取最新版本。

## 独立仓库

| 仓库 | 说明 | 原目录 |
|------|------|--------|
| [agent-skill-architect](https://github.com/zht043/agent-skill-architect) | Skill 架构设计元技能（原 skill-creator，已更名避免与官方冲突） | `skill-creator/` |
| [ssh-dev-suite](https://github.com/zht043/ssh-dev-suite) | SSH 远程开发套件（连接、部署、隧道、调试、长耗时任务） | `skills/ssh-dev-suite/` |
| [ascend-drivingsdk-skills](https://github.com/zht043/ascend-drivingsdk-skills) | 昇腾 NPU DrivingSDK 开发辅助套件（CANN/PyTorch/SDK 安装、容器部署、覆盖率） | `skills/ascend-drivingsdk-skills/` |

## 为什么拆分？

原 monorepo 同时承担了作者工作区、技能索引、分发载体三种角色，导致：
- `skill-creator` 与 Anthropic 官方同名冲突
- 部分 skill 默认假设所有 skill 在同一仓内
- 无法独立安装单个 skill suite
- 缺少 eval 结构和 plugin 分发层

拆分后每个仓库独立管理、独立安装、独立演进，并遵循 portable core 设计：
- SKILL.md 采用最小 frontmatter（name + description）
- 支持 Claude Code + Codex 双平台
- 无跨仓硬耦合

## 尚未迁移的 Skill

以下 skill 暂留本仓库，后续将独立迁出：

| Skill | 说明 | 状态 |
|-------|------|------|
| [markdown-mermaid-illustrator](skills/markdown-mermaid-illustrator/) | Mermaid 图表设计（canonical 版本） | 待迁出 |
| [doc-illustrator](skills/doc-illustrator/) | 文档插图生成（legacy，推荐使用 markdown-mermaid-illustrator） | 待归档 |
| [export-history](skills/export-history/) | Claude Code 对话历史导出 | 待迁出 |

## License

MIT
