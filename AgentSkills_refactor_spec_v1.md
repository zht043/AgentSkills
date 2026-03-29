# AgentSkills 仓库重构与分发方案 Spec v1

## 文档状态
- **项目**：`zht043/AgentSkills`
- **目标**：为当前 meta skill 改名；按最新官方 skill 实践补齐评测与触发设计；将 monorepo 拆成多个独立仓；补充 command / plugin 分发层；确保 **Claude Code + Codex** 双兼容
- **产出形式**：可直接交给 agent 执行的迁移规范
- **文档语言**：中文

---

## 1. 背景与问题定义

当前仓库已经有几项很好的方向：

- 把 skill 当作**可复用能力包**，而不是一次性 prompt
- skill suite 采用了**入口路由 → 子模块执行**的多级结构
- 当前 `skill-creator` 的核心价值其实是 **探索 → 提炼 → 标准化**
- 某些 skill 已经开始避免“硬编码引用其他 skill 名称”，而是描述“需要什么能力”

但它也出现了几个明显问题：

1. **命名冲突**：你自己的 `skill-creator` 与 Anthropic 官方 `skill-creator` 重名
2. **角色混杂**：当前仓库同时承担了作者工作区、技能索引、分发载体三种角色
3. **单仓耦合**：部分 skill 默认假设“所有 skill 都在同一个仓里”
4. **评测缺位**：缺少与最新官方 skill-creator 思路对齐的 eval / benchmark 结构
5. **目录索引漂移**：仓库中已有 `markdown-mermaid-illustrator`，但主 README / 根路由并未把它当成一等公民来呈现
6. **平台边界不清**：有些 skill 可跨 agent 使用，有些本质上是 Claude Code 专属，但仓库里没有显式区分

本 spec 的目标，是在不破坏原有优点的前提下，把这些问题系统性解决掉。

---

## 2. 核心决策

## 2.1 给当前 `skill-creator` 改名
**最终决定**：将当前 `skill-creator` 重命名为 **`skill-architect`**

### 为什么选这个名字
`skill-architect` 比 `skill-creator` 更准确地描述了它的真实职责，因为它的重点不是“帮你生一个 skill”，而是：

- 帮你判断这是 **单体 skill** 还是 **skill suite**
- 帮你划定 **边界、模块、路由**
- 帮你判断是 **能力型** 还是 **流程型**
- 帮你把一次探索中不稳定的聊天记录，抽取成稳定结构
- 更像一个 **skill 架构师 / 技能设计师**，而不是一个全生命周期评测器

### 备选名字
- `skill-distiller`：很贴近“经验蒸馏”，但容易和模型蒸馏语义混在一起
- `skill-foundry`：品牌感不错，但“架构设计 / 路由设计”含义不够明确
- `skill-studio`：过于宽泛，和官方 creator 区分度不够

### 最终命名规范
- 原目录名：`skill-creator`
- 新目录名：`skill-architect`
- skill frontmatter 中的 `name`：`skill-architect`
- 独立仓库名建议：`agent-skill-architect`

---

## 2.2 与官方 `skill-creator` 的职责分工
重命名后的 `skill-architect`，职责应明确限定为：

- 发现机会点
- 划定边界
- 设计 suite 拓扑
- 设计路由
- 从探索中提炼稳定模式
- 把 tacit knowledge（隐性经验）转成 portable skill structure

而 **官方 `skill-creator`** 更适合承担：

- 初稿生成
- eval 生成
- benchmark 对比
- description 触发优化
- 迭代改进闭环

### 必须新增的能力
`skill-architect` 必须新增一个明确的 **handoff 模式**：

> 当 skill 的拓扑、边界和模块拆分已经稳定后，可以把结果交给官方 `skill-creator` 去做 eval、benchmark 和 trigger 优化。

也就是说，这两个 skill 不是互斥关系，而是：

- `skill-architect`：做“结构设计与沉淀”
- 官方 `skill-creator`：做“测试、评估、优化”

---

## 3. 本次改造必须达成的结果

1. 消除与官方 `skill-creator` 的命名冲突
2. 分离 **authoring（编写）**、**catalog（索引）**、**distribution（分发）**
3. 保持 **skill suite 整体不拆**
4. 提升触发质量、安全边界和可测试性
5. 对适合分发的 skill / suite 增加 **plugin** 形态
6. 保留一个 **Claude Code + Codex 都能用的 portable core**
7. 显式标出哪些 skill 是平台专属，不再“假装全部可移植”

---

## 4. 当前仓库的改进点

## 4.1 全局层面的改进点

### 问题 A：当前 frontmatter 适合内部管理，但不是最稳妥的双端兼容合同
当前 skills 在 `SKILL.md` 顶部放了较多自定义字段，例如：

- `metadata.type`
- `metadata.version`
- `metadata.tags`
- `metadata.domain`
- `metadata.risk_level`
- `metadata.platform`

这些字段对人类维护者很有价值，但不应该成为 Claude Code + Codex 的主契约。

### 改进要求
采用**双层元数据模型**：

#### 第一层：portable core（放在 `SKILL.md`）
默认只保留最小必要 frontmatter：

```yaml
---
name: skill-name
description: 精准描述何时应该触发、何时不该触发
---
```

#### 第二层：平台适配层
- **Codex**：需要 OpenAI 侧依赖、MCP 绑定、外观配置时，写入 `agents/openai.yaml`
- **Claude Code**：需要控制触发/权限/子 agent 时，再加 Claude 专属字段，例如：
  - `disable-model-invocation`
  - `user-invocable`
  - `allowed-tools`
  - `context: fork`
  - `agent`
  - `paths`

#### 第三层：人类/目录元数据
把 `type / tags / risk_level / platform` 这类信息放到下列位置之一：
- `references/skill-manifest.md`
- `skill.json`
- repo `README.md`
- catalog 自动生成清单

**原则**：不要把“自定义 frontmatter”当作跨 agent 的核心协议。

---

### 问题 B：缺少正式 eval 结构
当前仓库重心更偏“怎么写 skill”，而不是“怎么证明 skill 真的会在正确场景下触发、真的比 baseline 更好”。

### 改进要求
每个被拆出去的 skill repo / suite repo，都必须引入最小 eval 结构。

#### 最低要求
- `evals/trigger-eval.json`
  - 至少 **16~20** 条真实查询
  - 包含 should-trigger 和 should-not-trigger
- `evals/task-prompts/`
  - 至少 **3** 条代表性任务 prompt
- `evals/acceptance.md`
  - 说明通过标准
- 如有必要，再补 `benchmarks/`

#### 执行策略
优先用**官方 `skill-creator`** 来做：
- trigger eval 生成
- with-skill vs no-skill 对比
- description 优化

---

### 问题 C：部分 `SKILL.md` 承载了太多会持续变动的信息
例如：

- 版本矩阵
- 大段 troubleshooting
- 过长的背景说明
- 很多“原理解释”与“执行规则”混在一起

这些内容现在有帮助，但长期会让：
- `SKILL.md` 过长
- 维护成本上升
- agent 加载时不够经济

### 改进要求
统一内容分层：

#### `SKILL.md` 只放：
- 何时用
- 何时不用
- 路由规则 / 执行流程
- 最小安全约束
- 脚本与 references 指针

#### `references/` 放：
- 版本表
- 兼容性矩阵
- 排障手册
- 长示例
- 背景说明

#### `scripts/` 放：
- 稳定的执行动作
- 环境探测
- 自包含 helper

---

### 问题 D：高副作用 skill 没有清晰区分“自动触发”和“手动触发”
像部署、创建容器、导出历史这类操作，不应随便被自动触发。

### 改进要求
对于 **高风险 / 高副作用** workflow，在 Claude 包装层中加入显式控制：

- `disable-model-invocation: true`
- 需要参数时加 `argument-hint`
- 能做只读限制的 skill 加 `allowed-tools`

尤其适用于：
- `ssh-dev-suite/deploy`
- `ascend-drivingsdk-skills/container-deploy`
- `export-history`（按包装方式决定）

---

### 问题 E：索引已经开始漂移
当前仓库中已经存在：
- `skills/markdown-mermaid-illustrator/`

但主 README / 根级索引仍然主要在讲：
- `doc-illustrator`

这说明目录索引和实际 skill 清单已经开始不同步。

### 改进要求
在正式拆仓前，先做一次 **inventory normalization**：

1. 枚举当前所有 skill / suite
2. 对照 README / 根路由 / 列表说明
3. 识别：
   - 重叠 skill
   - 别名 skill
   - 已废弃 skill
   - canonical skill

---

## 4.2 逐个 skill / suite 的改进要求

## A. `skill-architect`（原 `skill-creator`）

### 应保留的优点
- 探索 → 提炼 的方法论
- capability / process 区分
- 单体 / suite 区分
- 禁止硬编码依赖其它 skill 的原则
- 强调 `SKILL.md`、脚本、README 各司其职

### 应新增的改进
1. 增加 **scope decision** 小节  
   让它先判断：这是 skill、suite、command wrapper，还是 plugin 更合适。

2. 增加 **handoff to official skill-creator**  
   当结构稳定后，明确建议交给官方 creator 做 eval 和 trigger 优化。

3. 增加 **portable core checklist**  
   说明哪些内容必须 agent-agnostic，哪些可以放到 Claude / Codex adapter 里。

4. 增加 **split-readiness 检查项**
   - 是否假设 monorepo 一定存在
   - 是否写死了 sibling path
   - 是否 README 默认依赖其它 repo 同时安装

5. 增加 **plugin packaging 决策逻辑**
   - 什么情况下只做本地 skill
   - 什么情况下应升级成 plugin

### 拆仓后仓库定位
- 仓库名：`agent-skill-architect`
- 核心职责：skill 架构设计、能力沉淀、suite 设计、路由设计
- README 中必须写清楚：  
  “如需 eval / benchmark / trigger tuning，建议配合官方 `skill-creator` 使用”

---

## B. `ssh-dev-suite`

### 应保留的优点
- suite 拆分很清楚
- 模块边界明确
- `ssh-exec` vs `ssh-job` 决策规则非常实用
- proxy / long-task 的规则已经有“状态触发”意识

### 应新增的改进
1. 增加更明确的 **suite 路由表**
   - 用户目标 → 模块
   - 运行中出现什么信号 → 自动切换到哪个模块

2. `deploy` 必须改成 **手动触发优先**
   - 不应默认允许自动触发部署

3. 增加正式 eval
   - 快速命令 vs 后台任务
   - 网络失败 → proxy
   - local forward / reverse / SOCKS / proxy 的区分

4. README 中显式区分：
   - 哪些能力允许自动路由
   - 哪些能力必须显式调用

5. 增加 plugin 分发层

### 建议补的 command wrappers
- `/ssh-connect [profile] [command]`
- `/ssh-tunnel [profile] [mode]`
- `/ssh-deploy [profile] [environment]`
- `/ssh-debug [profile] [symptom]`
- `/ssh-long-task [profile] [task]`

### 形态判断
这个 suite 非常适合：
- 保留为一个完整 suite repo
- 再提供一个 plugin 安装包

**不要**把内部子模块拆成多个仓。

---

## C. `ascend-drivingsdk-skills`

### 应保留的优点
- 领域价值很强
- 前置条件清楚
- 交互流程完整
- 已经有“能力依赖而非具名依赖”的意识

### 应新增的改进
1. 把时效性很强的内容移出 `SKILL.md`
   - 版本表
   - 兼容矩阵
   - 长 troubleshooting

2. 把高副作用流程改成手动触发优先
   - 特别是 `container-deploy`

3. 增加端到端 eval 场景
   - 全新环境
   - 已有环境检测
   - 无外网场景
   - 容器场景

4. 强化决策树
   - 走已有安装还是新装
   - conda / venv / 无环境管理
   - 预编译包还是源码编译

### 建议补的 command wrappers
- `/ascend-audit`
- `/cann-install [version]`
- `/torch-npu-install [torch-version]`
- `/drivingsdk-install [mode]`
- `/container-deploy [workspace]`
- `/test-coverage [cpp|python]`

### 形态判断
它同样应该：
- 保持为一个完整 suite repo
- 再补一个 plugin 分发层

**不要**把内部模块拆成多个 repo。

---

## D. `doc-illustrator` 与 `markdown-mermaid-illustrator`

### 当前问题
这两个 skill 的职责已经明显重叠，不适合同时作为一等主 skill 长期维护。

### 改进要求
先决策一个 **canonical repo**，另一个转为：
- 废弃 alias
- 或轻量 wrapper

### 推荐方案
把 **`markdown-mermaid-illustrator`** 设为 canonical skill，因为它已经更完整、更具体、更像 v2。

### 迁移方案
- `doc-illustrator` 不再作为主 skill 独立演进
- 如果保留，则 README 必须明确写：
  - 它是 legacy alias
  - 推荐使用 canonical repo

### 形态判断
- 适合作为 portable standalone skill repo
- plugin 不是最高优先级，但可以后补

---

## E. `export-history`

### 当前问题
这个 skill 实质上绑定了 Claude Code 的历史目录约定。

### 改进要求
把它明确归类为 **平台专属 skill**，不要再宣传成通用 skill。

### 推荐改名
- 仓库名：`agent-skill-claude-history-export`
- skill name：`claude-history-export`

### 兼容性政策
- Claude Code：支持
- Codex：当前不承诺，除非以后新增 Codex 对话历史适配器

### 形态判断
- 可以作为独立 skill repo
- plugin 化优先级不高

---

## 5. 拆仓后的整体结构

## 5.1 目标仓库清单

### Repo 1：保留 `AgentSkills`
**新定位**：catalog / landing / docs / marketplace index

它应该包含：
- 总 README
- 技能清单
- 兼容性矩阵
- 安装说明
- 各独立 repo 链接
- plugin marketplace 索引
- 迁移说明
- contribution guide

它**不再**作为所有 skill 的唯一 canonical runtime 存储地。

---

### Repo 2：`agent-skill-architect`
来源：当前 `skill-creator/`

包含：
- portable `SKILL.md`
- `README.md`
- checklists / templates / references
- handoff to official skill-creator 的说明

---

### Repo 3：`ssh-dev-suite`
来源：当前 `skills/ssh-dev-suite/`

包含：
- suite 根目录
- 全部内部模块
- config 模板
- references
- evals
- plugin 包装层

---

### Repo 4：`ascend-drivingsdk-skills`
来源：当前 `skills/ascend-drivingsdk-skills/`

包含：
- suite 根目录
- 全部内部模块
- config 模板
- references
- evals
- plugin 包装层

---

### Repo 5：Mermaid canonical repo
推荐保留：
- `markdown-mermaid-illustrator`

来源：
- 当前 `skills/markdown-mermaid-illustrator/`

而 `doc-illustrator`：
- 作为 legacy alias 保留，或直接归档

---

### Repo 6：`agent-skill-claude-history-export`
来源：
- 当前 `skills/export-history/`

包含：
- Claude Code 专属导出 skill
- 明确的平台边界说明

---

## 5.2 拆分规则
1. **skill suite 不拆内部子模块**
2. **允许 suite 内部继续使用相对引用**
3. **去掉对“其它 suite 一定和我在同一仓”这种假设**
4. **不要再保留一个会假定所有 skill 共仓存在的根 runtime `SKILL.md`**
5. **跨 repo 的公共知识，放到 catalog/docs，不放到 runtime 路由里**

---

## 6. 耦合检查与解耦要求

## 6.1 必须拆掉的耦合

### 耦合 1：根 `SKILL.md` 的单仓能力映射
当前根 `SKILL.md` 维护了一张“能力 → 本仓路径”的映射表。

在 monorepo 里这很方便，但拆仓后会变成错误前提。

### 改进要求
拆仓后：
- catalog repo 不再作为运行时能力索引
- 把它改成人类可读的 catalog / comparison table
- 如需机器可读索引，单独生成 catalog manifest，而不是继续用 runtime `SKILL.md`

---

### 耦合 2：README 默认假设其它 sibling skill 一定存在
所有 README / 说明文档中，如果默认假设“某某 suite 就在隔壁目录”，都必须改写。

### 改进要求
统一改为两种表达之一：

#### 能力描述写法
- “需要 SSH 远程执行能力”
- “需要反向代理能力”

#### 可选集成写法
- “如果安装了 SSH remote suite，可与之联动”

不要再默认指定 sibling repo 一定同时安装。

---

### 耦合 3：目录索引漂移
主 README、根路由、skills 目录，不能继续出现内容不同步。

### 改进要求
迁移时先产出一张 canonical inventory：
- 实际 skill 单元
- 废弃 alias
- canonical 名
- plugin 包
- 支持的 runtime

---

## 6.2 允许保留的耦合
下列耦合是合理的：

- **suite 内部**模块之间的相对引用
- 同一 repo README 对 companion repo 的“可选推荐”
- plugin 有意打包多个 skill 的组合关系

---

## 7. skill、command、plugin 三者的关系与增补方案

## 7.1 总原则
采用这套层级：

### Skill
作为**作者格式 / 核心工作流格式**

### Command
作为**手动入口 UX 层**
适用于：
- 高副作用操作
- 参数明确的操作
- 用户经常直接点名调用的操作

### Plugin
作为**分发单位**
适用于：
- 想降低安装门槛
- 想打包多个 skill
- 想附带 app / MCP 配置
- 想做团队级分发

---

## 7.2 哪些 skill / suite 应该补 command

### `ssh-dev-suite`
**应该补**
原因：
- 这是明显的操作型套件
- 很多任务天然适合显式入口
- 用 command 可以显著降低心智负担

### `ascend-drivingsdk-skills`
**应该补**
原因：
- 它是阶段式工作流
- 用命名命令更利于安装、调试、部署分段执行

### `markdown-mermaid-illustrator`
**可以补，但不是最高优先级**

### `claude-history-export`
**可以补**
原因：
- 动作非常明确
- 很适合作为“点名执行”的单命令工具

### `skill-architect`
**可选**
原因：
- 它偏 meta design
- 不是强操作型，但保留一个显式入口也有价值

---

## 7.3 command 的实现策略

### Portable core
不要把 command 语义硬编码成唯一使用方式。  
核心 skill 仍然应以 portable `SKILL.md` 为主。

### Claude Code
利用 skill 生成 slash-command 入口：
- 包装型 skill
- `disable-model-invocation: true`
- `argument-hint`
- 必要时 `allowed-tools`

### Codex
以显式 skill 调用 + plugin 安装为主：
- 明确 mention skill
- 通过 plugin 提升可发现性和可安装性

---

## 7.4 哪些更适合打包成 plugin

### 强烈建议 plugin 化
- `ssh-dev-suite`
- `ascend-drivingsdk-skills`

### 可选 plugin 化
- `markdown-mermaid-illustrator`
- `claude-history-export`

### 以 skill repo 为主，plugin 为辅
- `skill-architect`

### 核心判断
- **skill 是作者格式**
- **plugin 是安装/分发格式**

---

## 8. Claude Code + Codex 双兼容策略

## 8.1 基本原则
每个可移植 skill repo 都采用：

> **portable core 优先，平台适配层后置**

### Portable core
- `SKILL.md`
- `scripts/`
- `references/`
- `assets/`（如需要）
- 平台无关 README

### Claude 适配层
只在需要时添加：
- Claude 专属 frontmatter
- Claude plugin manifest
- Claude hooks / agents / MCP 配置

### Codex 适配层
只在需要时添加：
- `agents/openai.yaml`
- `.codex-plugin/plugin.json`
- 本地 marketplace 配置
- MCP 依赖声明

---

## 8.2 兼容性分级

### Tier A：双端可移植
应同时支持 Claude Code + Codex：
- `skill-architect`
- `ssh-dev-suite`
- `ascend-drivingsdk-skills`
- `markdown-mermaid-illustrator`

### Tier B：平台专属
只承诺单平台：
- `claude-history-export`

不要再对 Tier B 做“默认双兼容”宣传。

---

## 8.3 编写规范
1. `SKILL.md` 必须在不依赖 Claude 私有特性的情况下也能读懂
2. 不要把 Claude 专属 frontmatter 作为 correctness 的前提
3. 不要把 Codex 专属 metadata 作为 correctness 的前提
4. 持久、稳定的 workflow logic 放在 portable layer
5. 平台控制旋钮放 adapter layer

---

## 9. 交给 agent 的具体执行任务

## 9.1 先做 inventory 与规范化
1. 枚举当前所有 skill 目录
2. 对照 README / 根路由 / skill 列表
3. 找出：
   - 重叠 skill
   - alias
   - 已废弃 skill
   - canonical skill
4. 输出 inventory 表

---

## 9.2 重命名 meta skill
1. 目录 `skill-creator/` → `skill-architect/`
2. frontmatter `name` 更新
3. README / 示例 / 根文档全部替换
4. 增加“与官方 skill-creator 协同使用”的说明
5. 增加 handoff 说明

---

## 9.3 抽取独立仓库
对每个目标 repo：
1. 创建新目录
2. 仅复制对应单元
3. 重写 README 中的相对链接
4. 添加 `LICENSE`
5. 添加 repo 级 `README.md`
6. 添加 compatibility matrix
7. 添加 `evals/`
8. 添加 release checklist

### 历史保留策略
如时间允许，优先采用路径提取保留历史。  
如果实现成本过高，v1 可接受“复制 + 干净初始提交”。

---

## 9.4 自动创建 GitHub 仓库
执行 agent 应通过 GitHub 自动化能力：
1. 创建新仓
2. 设置 description / topics / README
3. push 内容
4. 设置默认分支
5. 必要时打首个 tag/release

---

## 9.5 增加 plugin 分发层
优先给 suite 做：
- Codex plugin manifest
- Claude plugin manifest
- 本地 marketplace 示例
- 可选的 dist/ 或平台清单目录

---

## 9.6 增加 eval 资产
每个 repo 至少补齐：
1. trigger eval set
2. task eval prompts
3. acceptance criteria
4. benchmark note
5. 必要时 review HTML 产物

---

## 10. 拆出去后的推荐目录模板

## 10.1 单体 portable skill repo
```text
repo/
  SKILL.md
  README.md
  scripts/
  references/
  assets/
  evals/
    trigger-eval.json
    task-prompts/
    acceptance.md
```

## 10.2 suite repo
```text
repo/
  SKILL.md
  README.md
  config.example.yaml
  _lib/
  module-a/
    SKILL.md
    scripts/
    references/
  module-b/
    SKILL.md
    scripts/
    references/
  evals/
```

## 10.3 Codex plugin 包装层
```text
repo/
  .codex-plugin/
    plugin.json
  skills/
    ...
  .mcp.json      # optional
  .app.json      # optional
  assets/        # optional
```

## 10.4 Claude plugin 包装层
```text
repo/
  .claude-plugin/
    plugin.json
  skills/
    ...
  agents/        # optional
  hooks/         # optional
  mcp/           # optional
  assets/        # optional
```

---

## 11. 验收标准

满足下列条件时，视为本次重构完成：

1. `skill-creator` 已完整更名为 `skill-architect`
2. 目录名、frontmatter、README、catalog 文档全部同步
3. `AgentSkills` 不再是所有 skill 的 canonical runtime 仓
4. 每个拆出的 repo 都能独立存在
5. skill suite 保持整体不拆
6. 跨 repo 的硬耦合已被移除或改写成能力描述
7. `ssh-dev-suite` 与 `ascend-drivingsdk-skills` 都有 plugin 包装层
8. 每个 portable repo 都具备最小 eval 结构
9. 平台专属 skill 已被显式标注
10. README / 清单 / 实际目录不再漂移
11. 对 Claude Code 与 Codex 的安装和使用路径都足够清晰

---

## 12. 非目标

本 spec **不要求**：

- 立刻给所有 skill 配 MCP
- 立刻把 `claude-history-export` 做成 Codex 兼容
- 为了拆仓而把 suite 再拆碎
- 一次性完成公开 marketplace 上架
- 保留所有历史路径名永久不变

---

## 13. 推荐执行顺序

### Phase 1：信息架构清理
- inventory
- 命名清理
- 重叠 skill 处理
- 兼容性政策确定

### Phase 2：拆仓与解耦
- 提取 repo
- 改写文档与链接
- 去掉 monorepo 假设

### Phase 3：质量补强
- 加 eval
- 加 command wrappers
- 加 plugin 包装层
- 验证安装流程

### Phase 4：发布
- 创建 GitHub 仓库
- 推送
- 设置 topics / description
- 更新 catalog repo

---

## 14. 最终建议总结

### 最好的新名字
**`skill-architect`**

### 最好的分层方式
- **用 skill 写核心能力**
- **用 command 提升显式调用体验**
- **用 plugin 做团队级分发**
- **先写 portable core，再补 Claude / Codex adapter**

### 最好的仓库结构
- 保留 `AgentSkills` 作为目录与入口
- 每个单体 skill / suite 独立仓管理
- suite 不再往下拆
- 对重叠 skill 做 canonical 化，而不是并行维护两个主版本

---

## 15. 执行 agent 的额外提示

1. 优先保证 portable core 简洁稳定，再加平台适配
2. 不确定内容该放 `SKILL.md` 还是 `references/` 时，优先把 `SKILL.md` 写短
3. 高副作用能力一律偏向手动触发
4. plugin 化优先级：先 `ssh-dev-suite`，再 `ascend-drivingsdk-skills`
5. `doc-illustrator` 与 `markdown-mermaid-illustrator` 的 canonical 决策必须先做
6. 这次迁移不是单纯“搬目录”，而是一次信息架构清理
7. 结构重构完成后，尽量再调用官方 `skill-creator` 做 eval、benchmark、description tuning

---

## 16. 实施时应参考的资料来源

本 spec 的判断依据包括：
- 当前 `AgentSkills` 仓库结构与现有 skill 文档
- Anthropic 最新的 skills / skill-creator / plugin 文档
- OpenAI Codex 最新的 skills / customization / plugin 文档
- Agent Skills 开放标准的可移植性方向

在真正生成最终 plugin manifest 或平台适配配置前，执行 agent 应再次核对最新官方文档。
