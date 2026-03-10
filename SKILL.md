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

3. **跨 skill 引用**：当 skill A 引用了 skill B（如 container-deploy 引用 ssh-dev-suite 的反向代理），agent 也应读取被引用的 skill B 的相关子模块文档

### 常见错误

- ❌ 只读了 suite 的入口 SKILL.md，跳过了子模块的 SKILL.md
- ❌ 读了 SKILL.md 但没读脚本，不了解参数和退出码
- ❌ 看到"参考 xxx skill"但没有去读对应的 skill 文档
- ❌ 没有读 config.example.yaml，不了解可配置项
- ❌ 在交互流程中自作主张跳过了 skill 规定的步骤（如 workspace 路径询问、数据集挂载询问）
- ❌ 自行决定了本应询问用户的配置（如服务器上的工作目录路径）

### 验证方法

Agent 读取完 skill 后，应能回答以下问题：
- 这个 skill 有哪些子模块？每个子模块做什么？
- 脚本有哪些参数？哪些必填？退出码含义？
- 交互流程有哪些阶段？每个阶段问什么？
- 有哪些跨 skill 的依赖？

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
