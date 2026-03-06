---
name: skill-creator
description: 用于创建和提炼新skill的元技能，指导从探索到正式skill的全流程
type: process
---

# Skill开发指南

## 概述
通过探索打通能力，再提炼为标准化skill。一个skill只做一件事。

## Skill类型
- **能力型（capability）**：封装具体操作能力，重心在脚本，SKILL.md做调度说明
- **流程型（process）**：指导工作流程方法论，重心在SKILL.md本身

## Skill形态

### 单体Skill
功能单一、文件少的skill，平铺结构。

```
skills/<skill-name>/
  SKILL.md             # 核心文档（给agent看，精简可靠）
  README.md            # 使用说明（给用户看，含prompt示例）
  config.yaml          # 可选，能力型使用，不入库
  config.example.yaml  # 可选，配置模板，入库
  scripts/             # 可选，工具脚本目录
    *.sh / *.py / *.js
```

### Skill Suite
多个相关子模块共同组成完整能力时，使用 suite 结构。

```
skills/<suite-name>/
  SKILL.md             # Suite入口：总览 + 路由逻辑（引导agent到正确子模块）
  README.md            # 使用说明（整个suite）
  config.example.yaml  # 可选，共享配置模板
  _lib/                # 可选，共享工具脚本（下划线前缀 = 内部基础设施）
    *.sh / *.py
  <module>/            # 子模块目录（每个子模块一个目录）
    SKILL.md           # 子模块文档
    scripts/           # 可选，子模块专属脚本（纯流程型无此目录）
      *.sh / *.py
```

Suite规范：
- 入口SKILL.md只做总览和路由，不包含具体操作细节
- 子模块各有独立SKILL.md，替代`SKILL-<module>.md`命名
- 共享工具放`_lib/`，子模块专属脚本放`<module>/scripts/`
- config.example.yaml留在suite根目录（配置跨模块共享）

## SKILL.md头部格式
```yaml
---
name: skill名称
description: 一句话描述，用于agent判断何时调用
type: capability | process
---
```

## 能力型模板
```
# Skill名称
## 功能（1-2句）
## 配置（config.yaml字段说明）
## 使用（调用脚本的步骤）
## 注意事项（可选）
```

## 流程型模板
```
# Skill名称
## 概述（核心原则1-2句）
## 适用场景
## 流程步骤（编号，每步有明确产出）
## 检查清单（可选）
```

## 开发流程

两个阶段：**探索** → **提炼**。探索阶段可选，已有清晰材料可跳过。

### 探索阶段（可选）

目标：打通能力，验证可行性。

启动方式灵活：
- **用户主导**：用户逐步指令，agent执行反馈
- **agent主导**：用户描述目标，agent自主探索
- **协作探索**：双方交替推进

agent在探索中记录：关键命令、参数、踩坑点、成功路径。

### 提炼阶段

输入来源：探索阶段的记录 / 用户描述 / 已有文档 / 任意组合。

agent执行：
1. 判断skill类型（能力型 or 流程型）和形态（单体 or suite）
2. 按对应模板生成SKILL.md（精简，去除冗余）
3. 提炼可复用命令为脚本，放入scripts/目录（如适用）
4. 生成config.example.yaml（如适用）
5. 生成README.md（用户导向的使用说明）
6. 输出到 skills/<skill-name>/ 或 skills/<suite-name>/ 目录

### 收尾

**验证**：新会话中试用skill，确认agent能正确执行

**入库**：提交到skills/目录

## 规范约束
- 文档语言：中文
- SKILL.md面向agent：精简、可靠、无冗余说明
- README.md面向用户：使用方法、prompt示例、注意事项
- 能力型SKILL.md ≤ 1KB，流程型 ≤ 3KB，超过则拆分
- 脚本统一放在`scripts/`目录下（单体skill）或`<module>/scripts/`下（suite）
- 脚本须自包含、可独立运行、有头部注释（功能、用法、依赖）
- 脚本优先命令行参数，备选从config.yaml读取
- 成功返回0，失败返回非0并输出错误到stderr
- 脚本超过200行 → 考虑拆分

## 配置引导规则
- agent执行skill前读取config.yaml，缺失字段交互引导用户填写并回填
- 敏感值按优先级：环境变量 > MCP/外部工具 > 明文（需告知风险）
- 环境变量方式需引导用户按操作系统设置

## Token约束
- 探索记录：精简关键命令和结果，不保存完整输出
- 文档生成：一次性写入，不重复展示内容
- 验证测试：只输出关键状态，不粘贴完整日志
- 重复信息：不复述已知内容
