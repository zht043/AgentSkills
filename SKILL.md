---
name: agent-skills
description: AI Agent 技能库项目规范，指导 agent 正确阅读和使用 skill
---

# AgentSkills

## 项目目标
开发泛用、简洁、稳定、专业的 agent skills。

## Agent 阅读规范（极其重要）

**Agent 在使用任何 skill 前，必须深入阅读其完整文档树。** 仅读取入口 SKILL.md 是不够的。

### 必读规则

1. **Suite / Skills 类型**（含多个子模块的 skill 集合）：入口 SKILL.md 只是路由索引。Agent 必须递归读取所有子模块的 SKILL.md 和关键脚本
   ```
   skills/<suite-name>/
     SKILL.md            ← 读（路由索引，不含执行细节）
     README.md           ← 读（使用说明）
     config.example.yaml ← 读（配置模板，了解可配置项）
     <module-1>/
       SKILL.md          ← 必须读（子模块完整交互流程和规范）
       scripts/*.sh      ← 必须读（理解脚本参数、行为、退出码）
     <module-2>/
       SKILL.md          ← 必须读
       scripts/*.sh      ← 必须读
     _lib/               ← 选读（共享工具库）
   ```

2. **单体 skill**：SKILL.md + scripts/ 目录下的脚本都需要读取

3. **能力依赖发现**：当 skill 描述中提到需要某种能力（如"需要 SSH 隧道能力"、"需要反向代理"），agent 应在本项目 `skills/` 目录下扫描可用 skill，找到能提供该能力的 skill 并读取其文档。参见下方"能力索引"

### 能力索引

当 skill 描述中提到需要以下能力时，优先在 `skills/` 目录下寻找匹配的 skill：

| 能力需求 | 匹配 skill 目录 | 说明 |
|----------|-----------------|------|
| SSH 远程连接/执行 | `ssh-dev-suite/connect/` | 多 profile 连接管理、远程命令执行、文件传输 |
| SSH 隧道/端口转发/反向代理 | `ssh-dev-suite/tunnel/` | 端口转发、代理隧道 |
| 远程部署/同步 | `ssh-dev-suite/deploy/` | 项目同步、部署钩子、回滚 |
| 远程调试/排查 | `ssh-dev-suite/debug/` | 远程问题排查 |
| 长耗时远程任务 | `ssh-dev-suite/long-task/` | 断连恢复、checkpoint 管理 |

> **注意**：此索引仅对本项目 skills/ 目录生效。skill 文档本身不直接引用其他 skill 名称，以保持独立可移植性。当 skill 被拷贝到其他项目使用时，用户需根据自己环境的可用工具替换上述映射。

### SSH 远程开发规范

当 agent 需要通过 SSH 连接远程服务器执行操作时（无论是用户直接要求还是其他 skill 提到需要远程能力），**必须**：

1. 先检查 `skills/` 下是否有提供 SSH 能力的 skill（本项目为 `ssh-dev-suite`）
2. 读取该 skill 的完整文档树（入口 SKILL.md + 相关子模块 SKILL.md + 脚本）
3. 按其规范的 profile 管理、ControlMaster 会话复用、容器感知等机制操作
4. **不要自行拼接裸 ssh/scp 命令**，应使用 SSH skill 提供的脚本和流程

### 常见错误

- ❌ 只读了 suite 的入口 SKILL.md，跳过了子模块的 SKILL.md
- ❌ 读了 SKILL.md 但没读脚本，不了解参数和退出码
- ❌ skill 提到需要某种能力但没有在 skills/ 下寻找匹配工具
- ❌ 有可用的 SSH skill 却自行拼接裸 ssh/scp 命令
- ❌ 没有读 config.example.yaml，不了解可配置项
- ❌ 在交互流程中自作主张跳过了 skill 规定的步骤（如 workspace 路径询问、数据集挂载询问）
- ❌ 自行决定了本应询问用户的配置（如服务器上的工作目录路径）

### 验证方法

Agent 读取完 skill 后，应能回答以下问题：
- 这个 skill 有哪些子模块？每个子模块做什么？
- 脚本有哪些参数？哪些必填？退出码含义？
- 交互流程有哪些阶段？每个阶段问什么？
- 需要哪些外部能力？本项目 skills/ 下有匹配工具吗？

如果无法回答，说明阅读不够深入。

## 目录结构
```
skill-creator/               # Meta skill（开发规范与模板）
  SKILL.md
  README.md

skills/<skill-name>/          # 单体 skill
  SKILL.md                    # 核心文档（给 agent 看）
  README.md                   # 使用说明（给用户看）
  config.example.yaml         # 可选，配置模板，入库
  scripts/                    # 可选，工具脚本目录

skills/<suite-name>/          # Skill suite / Skills 集合（多子模块）
  SKILL.md                    # Suite 入口：总览 + 路由
  README.md                   # 使用说明（整个 suite）
  config.example.yaml         # 可选，共享配置
  _lib/                       # 可选，共享工具脚本
  <module>/                   # 子模块目录
    SKILL.md                  # 子模块文档
    scripts/                  # 可选，子模块脚本

docs/plans/                   # 设计与计划文档
```

## 开发规范
所有 skill 的开发模板、规范约束、配置引导规则详见 `skill-creator/SKILL.md`。

开发新 skill 时，请先阅读该 meta skill。
