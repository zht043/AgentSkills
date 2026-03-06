# AgentSkills

## 项目目标
开发泛用、简洁、稳定、专业的agent skills。

## 目录结构
```
skill-creator/               # Meta skill（开发规范与模板）
  SKILL.md
  README.md

skills/<skill-name>/          # 单体skill
  SKILL.md                    # 核心文档（给agent看）
  README.md                   # 使用说明（给用户看）
  config.example.yaml         # 可选，入库
  scripts/                    # 可选，工具脚本目录

skills/<suite-name>/          # Skill suite（多子模块）
  SKILL.md                    # Suite入口：总览 + 路由
  README.md                   # 使用说明（整个suite）
  config.example.yaml         # 可选，共享配置
  _lib/                       # 可选，共享工具脚本
  <module>/                   # 子模块目录
    SKILL.md                  # 子模块文档
    scripts/                  # 可选，子模块脚本

docs/plans/                   # 设计与计划文档
```

## 开发规范
所有skill的开发模板、规范约束、配置引导规则详见 `skill-creator/SKILL.md`。

开发新skill时，请先阅读该meta skill。
