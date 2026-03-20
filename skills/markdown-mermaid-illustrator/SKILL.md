---
name: markdown-mermaid-illustrator
description: 为 Markdown 文档生成高质量 Mermaid 图表，支持 Dark/Light 双主题兼容、语义化形状、紧凑排版、模板匹配与 LLM 自主设计
metadata:
  type: capability
  version: "2.1"
  tags: [markdown, mermaid, diagram, documentation, design, architecture, flowchart, sequence, mindmap, gantt, statediagram, er, class, swimlane, quadrant, journey]
  domain: documentation
  risk_level: low
  platform: cross-platform
---

# markdown-mermaid-illustrator

## 概述

分析 Markdown 技术文档，生成高质量的 Mermaid 图表，用户确认后替换。混合模板匹配与 LLM 理解两条路径。

**解决的核心痛点：**

| 痛点 | 根因 | 解法 |
| :--- | :--- | :--- |
| Dark 模式 subgraph 呈现刺眼白块 | 浅色 hex 固定不变，与暗色页面产生强对比 | subgraph 改用中色调固定色（L ≈ 70-80%），视觉重量在两种模式下均可接受 |
| 节点颜色 Dark 模式下失效 | 使用浅色系 classDef fill | 改用中饱和度填充色（L ≈ 40-60%），渲染引擎可自动推断文字颜色 |
| 硬编码文字颜色不可读 | `color:#fff` 写死 | 禁用 `color:` 属性，由引擎自动计算 |
| 文字溢出节点 | 节点文本过长 | 强制 `<br/>` 换行，精简到短语级 |
| 视觉单调 | 未用形状语义化和 classDef | 按语义分配圆角/菱形/圆柱，classDef 统一风格 |
| 渲染 Bug 率高 | 节点 ID 含特殊字符 | 语法自检清单，节点 ID 纯英文 |
| 图表纵向过长 | 默认 TD 布局 | 默认 LR，subgraph 分层叠加 |
| 排版不对称 | 各层级节点数不均衡 | 主动平衡节点数，`~~~` 对齐 |

## 适用场景

- 为技术文档新建 Mermaid 图表（架构图、流程图、时序图、概念图、决策树）
- 重构现有图表修复 Dark 模式兼容问题
- 将 ASCII 图表升级为 Mermaid 格式

## 运行环境

**跨平台**：纯文本处理，适配 GitHub、GitLab、Obsidian、MkDocs、Docusaurus 等所有支持 Mermaid 的环境。

---

## 图表类型路由指南

### 第零步：不确定时主动询问用户

当以下任意情况出现时，**必须先询问用户再动手**，不要自行猜测：
- 同一内容可以用 2 种以上截然不同的图表类型表达（如"关系"可以是流程图、思维导图或 ER 图）
- 用户描述含有模糊词（"画个图看看""展示一下关系""做个分析"）
- 内容涉及数据可视化，不确定是否有具体数据

**询问格式（输出给用户）**：
```
我理解你想表达「[内容摘要]」，有以下几种图表方式，你倾向于哪种？

1. [图表类型 A]——[一句话说明适合原因]
2. [图表类型 B]——[一句话说明适合原因]
3. [图表类型 C]——[一句话说明适合原因]（如有第三选项）

或者告诉我你的偏好，我来设计。
```

---

### 图表类型速查表

#### ✅ Mermaid 原生支持（直接生成）

| 分类 | 图表类型 | Mermaid 语法 | 关键词触发 | 模板 |
| :--- | :--- | :--- | :--- | :--- |
| **发散/结构** | 思维导图 | `mindmap` | 发散、脑图、思维导图、主题、头脑风暴 | mindmap.yaml |
| **发散/结构** | 树状/组织图 | `flowchart TD` | 层级、树状、组织架构、部门、岗位 | tree.yaml |
| **发散/结构** | 亲和图/分组 | `flowchart LR` + subgraph | 归类、分组、聚类、亲和 | affinity.yaml |
| **流程/过程** | 流程图 | `flowchart LR/TD` | 流程、步骤、执行、触发、判断 | flow.yaml |
| **流程/过程** | 泳道图 | `flowchart LR` + subgraph lanes | 角色、部门、泳道、谁负责 | swimlane.yaml |
| **流程/过程** | 状态图 | `stateDiagram-v2` | 状态、转换、生命周期、FSM | state.yaml |
| **流程/过程** | 用户旅程图 | `journey` | 用户旅程、体验、触点、情绪 | journey.yaml |
| **关系/网络** | 架构/关系图 | `flowchart LR` | 架构、组件、模块、依赖、服务 | architecture.yaml |
| **关系/网络** | 时序图 | `sequenceDiagram` | 时序、交互、调用链、请求响应 | sequence.yaml |
| **关系/网络** | ER 图 | `erDiagram` | 实体、数据库、表、关系、外键 | er.yaml |
| **关系/网络** | 类图 | `classDiagram` | 类、对象、继承、接口、UML | class.yaml |
| **时间/计划** | 甘特图 | `gantt` | 甘特、排期、任务计划、项目进度 | gantt.yaml |
| **时间/计划** | 时间线 | `timeline` | 时间线、历史、演进、里程碑顺序 | timeline.yaml |
| **分析/决策** | 四象限/矩阵 | `quadrantChart` | 四象限、优先级矩阵、波士顿、SWOT | quadrant.yaml |
| **分析/决策** | 决策树 | `flowchart TD/LR` | 决策、选型、如果…那么、判断分支 | decision.yaml |
| **分析/决策** | 鱼骨图 | `flowchart LR` 近似 | 鱼骨、根因、原因分析、为什么 | fishbone.yaml |
| **数据/对比** | 饼图 | `pie` | 占比、比例、分布、份额 | pie.yaml |
| **数据/对比** | 折线/柱状图 | `xychart-beta` | 趋势、数值变化、对比、增长 | xychart.yaml |
| **数据/对比** | 桑基图 | `sankey-beta` | 流向、流量、能源流、资金流 | sankey.yaml |

#### ⚠️ Mermaid 近似支持（有局限，先告知用户）

| 图表类型 | 近似方案 | 主要局限 |
| :--- | :--- | :--- |
| 甘特 PERT 图 | `gantt` 近似 | 无法准确表达关键路径和浮动时间 |
| BPMN 业务流程图 | `flowchart` 近似 | 无法表达 BPMN 正式符号集 |
| 价值流图 | `flowchart LR` 近似 | 无法表达精确的时间流和浪费标注 |
| 因果回路图 | `flowchart` 带循环箭头 | 仅能近似，无法完整表达系统动力学符号 |
| 知识图谱（大规模） | `flowchart` 小规模可用 | 超过 20 节点建议用专业工具 |

#### ❌ 超出 Mermaid 能力范围（告知用户并推荐替代工具）

| 图表类型 | 推荐工具 |
| :--- | :--- |
| 散点图、雷达图、热力图、气泡图 | ECharts、Plotly、Vega-Lite |
| 大规模网络图、社交网络图 | Gephi、Cytoscape |
| 专业 BPMN | draw.io（diagrams.net）、Camunda |
| 路线图（Roadmap，带跨期可视化） | Miro、Roadmunk、ProductPlan |
| 矩阵热力图 | ECharts、Tableau |

当内容落入"超出范围"时，**不要强行用 Mermaid 近似**，应告知用户局限并推荐替代工具，再询问是否仍想要 Mermaid 的近似版本。

---

## 核心设计规范

### 规范 1：Frontmatter 配置

每个图表头部必须包含：

```
---
config:
  theme: neutral
  look: neo
---
```

- `theme: neutral`：中性主题，文字颜色由渲染引擎自动计算。
- `look: neo`：圆角现代风格。

> **GitHub 特例**：GitHub 会根据用户 appearance 设置自动切换 Mermaid 主题，但前提是图表无任何 `config` / `%%{init}%%` 指令。若目标平台只有 GitHub，可省略 Frontmatter 完全依赖自动切换；其他平台保留。

---

### 规范 2：节点配色——中饱和度色板

**为什么不用浅色系（如 `#e3f2fd`）？**
Mermaid `classDef` 的 `fill` 是固定 hex，不随 dark/light 模式变化。浅色系在暗色背景下产生刺眼"亮泡"效果。中饱和度填充色（L ≈ 40-60%）在两种背景下都有足够视觉重量，且渲染引擎能从中正确推断文字颜色。

**禁止写法：**

```
%% 禁止 1：硬编码文字颜色
style NodeA fill:#4A90D9,stroke:#333,color:#fff

%% 禁止 2：浅色系 fill（dark 模式下亮泡）
classDef core fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
```

**正确写法：**

```
%% classDef 不指定 color，引擎自动适配
classDef core fill:#3D7DC8,stroke:#1A4E8A,stroke-width:2px
NodeA:::core
```

**推荐节点色板（Light / Dark 双模式兼容）：**

| 语义 | 名称 | fill | stroke | 用途 |
| :--- | :--- | :--- | :--- | :--- |
| 核心/主要 | `core` | `#3D7DC8` | `#1A4E8A` | 主流程、核心组件 |
| 数据/存储 | `data` | `#48A880` | `#256B4E` | 数据库、缓存、文件 |
| 警告/条件 | `warning` | `#D97F2A` | `#8B4500` | 判断节点、条件分支 |
| 危险/错误 | `danger` | `#C94444` | `#8B1A1A` | 错误处理、异常路径 |
| AI/思考 | `brain` | `#7055BB` | `#412A88` | LLM 推理、Agent 规划 |
| 外部服务 | `ext` | `#D4822A` | `#8B5000` | Cloud API、第三方 |

---

### 规范 3：subgraph 背景色

**问题**：`rgba()` 不被 Mermaid 解析器支持；8位 hex（`#RRGGBBAA`）同样不支持。
**解法**：用中色调实色（L ≈ 70-80%），通过底部 `style SubgraphID` 指令单独设置，每个 subgraph 可独立配色。

```
flowchart LR
    subgraph Local["🖥️ 本地环境"]
        A:::core --> B:::data
    end
    subgraph Cloud["☁️ Cloud 服务端"]
        C:::ext
    end

    style Local fill:#C4D3E8,stroke:#5599CC,stroke-width:2px
    style Cloud fill:#E8D5B8,stroke:#CC8833,stroke-width:2px
```

**推荐 subgraph 背景色板：**

| 区域语义 | fill | stroke | 对应节点色 |
| :--- | :--- | :--- | :--- |
| 本地/客户端 | `#C4D3E8` | `#5599CC` | `core` 蓝 |
| 核心服务 | `#D0C8E8` | `#9977DD` | `brain` 紫 |
| 数据层 | `#C4D8CC` | `#55AA88` | `data` 绿 |
| 外部/Cloud | `#E8D5B8` | `#CC8833` | `ext` 琥珀 |
| 危险/警告区 | `#E8C8C8` | `#CC5555` | `danger` 红 |

> subgraph 背景色应比对应节点色**更浅**（L 高 20-30%），形成明确的层次感。虚线外框（`stroke-dasharray:5 5`）区分外部/第三方区域。

---

### 规范 4：布局方向

**默认 LR（从左到右）**，仅在以下情况用 TD：
- 明确表达"层级从上到下"语义（如决策树）
- 节点数 ≤ 5 且无分支

**多层级叠加**：外层 `flowchart LR`，subgraph 内部 `direction TB`：

```
flowchart LR
    subgraph L1["第一层"]
        direction TB
        A --> B
    end
    subgraph L2["第二层"]
        direction TB
        C --> D
    end
    L1 --> L2
```

**文本换行**：超过 6 个字用 `<br/>`：

```
A(["执行核心<br/>业务逻辑"])   %% 正确
A(["执行核心业务逻辑并返回处理结果"])  %% 错误
```

---

### 规范 5：形状语义化

| 节点类型 | 语法 | 适用 |
| :--- | :--- | :--- |
| 一般流程/组件 | `A(["文本"])` | 服务、模块、步骤 |
| 数据库/存储 | `A[("数据库")]` | PostgreSQL、Redis |
| 判断/条件 | `A{"条件？"}` | 分支决策 |
| 外部系统 | `A[["外部 API"]]` | 第三方服务 |
| 输入/输出 | `A[/"数据"/]` | 数据流入口/出口 |

---

### 规范 6：图标增强

每个节点文本前置一个 Emoji。以下为参考，**不限于此**——根据节点具体语义自主推断最贴切图标，同一图表内不同语义节点使用不同图标，所有 subgraph 标题也带图标：

- 用户/入口：👤 🧑‍💻
- 启动/发布：🚀
- 数据/存储：💾 🗄️ 📦
- 认证/安全：🔐 🔑 🛡️
- 执行/处理：⚡ ⚙️ 🔧
- 观察/检查：👁️ 🔍 📊
- 完成：✅ 🎯 &nbsp;&nbsp; 失败：❌ ⚠️
- AI 推理：🧠 💭 &nbsp;&nbsp; 循环：🔄
- 网络/云：☁️ 🌐 📡
- 文件：📄 📁 📝 &nbsp;&nbsp; 消息：📨 🔔
- 时间：⏱️ &nbsp;&nbsp; 配置：🎛️

---

### 规范 7：线条语义化

```
A ==> B      %% 主链路（同步调用）粗实线
A --> B       %% 普通流程细实线
A -.-> B      %% 异步/事件/缓存虚线
A -->|"说明"| B   %% 带标签（用双引号）
A & B --> C   %% 并列汇聚
A ~~~ B       %% 不可见连接（仅对齐布局用）
```

---

### 规范 8：对称性设计

在不牺牲语义的前提下主动追求布局对称：

**subgraph 节点均衡**：并列 subgraph 内节点数尽量相等。节点少的一侧可拆分信息或补充关联节点，或用 `~~~` 添加对齐占位。

**同层节点对齐**：用 `~~~` 声明同层关系：

```
R1 ~~~ R2 ~~~ R3   %% 强制 R1 R2 R3 视觉等高
```

**节点宽度一致**：同类节点文本长度应相近，用 `<br/>` 调整换行点使节点宽度趋于统一。

---

### 规范 9：语法自检清单

输出前逐项确认：

- [ ] Frontmatter 包含 `theme: neutral` + `look: neo`
- [ ] 节点 ID 纯英文字母/数字，无中文、空格、特殊符号
- [ ] 含括号/引号/斜杠的显示文本用双引号包裹：`A["User (Client)"]`
- [ ] 无 `color:#fff` / `color:#000` 硬编码文字颜色
- [ ] `classDef` 定义在图表顶部（紧跟类型声明）
- [ ] `subgraph` 标题用双引号：`subgraph ID["标题"]`
- [ ] `classDef` fill 使用中饱和度色（非浅色系）
- [ ] subgraph 背景通过 `style ID fill:...,stroke:...` 设置（文件底部）
- [ ] 超过 6 字的节点文本使用 `<br/>` 换行
- [ ] 各 subgraph 节点数大致均衡，同层节点已 `~~~` 对齐
- [ ] 未使用实验性语法（`block-beta`、`architecture` 等）

---

## 标准模板库

### 模板 A：分层架构图

```
---
config:
  theme: neutral
  look: neo
---
flowchart LR
    classDef core fill:#3D7DC8,stroke:#1A4E8A,stroke-width:2px
    classDef data fill:#48A880,stroke:#256B4E,stroke-width:2px
    classDef ext  fill:#D4822A,stroke:#8B5000,stroke-width:2px

    subgraph Client["👤 客户端层"]
        direction TB
        Web(["🌐 Web App"]):::core
        App(["📱 Mobile App"]):::core
    end

    subgraph Services["⚙️ 核心服务层"]
        direction TB
        Auth(["🔐 Auth"]):::core
        Biz(["⚡ Business"]):::core
    end

    subgraph Storage["💾 数据层"]
        direction TB
        DB[("🗄️ PostgreSQL")]:::data
        Cache[("⚡ Redis")]:::data
    end

    Client --> Services
    Services ==> DB
    Services -.-> Cache

    style Client   fill:#C4D3E8,stroke:#5599CC,stroke-width:2px
    style Services fill:#D0C8E8,stroke:#9977DD,stroke-width:2px
    style Storage  fill:#C4D8CC,stroke:#55AA88,stroke-width:2px
```

### 模板 B：流程图（带判断分支）

```
---
config:
  theme: neutral
  look: neo
---
flowchart LR
    classDef core    fill:#3D7DC8,stroke:#1A4E8A,stroke-width:2px
    classDef warning fill:#D97F2A,stroke:#8B4500,stroke-width:2px
    classDef danger  fill:#C94444,stroke:#8B1A1A,stroke-width:2px

    Start(["🚀 开始"]) --> Check{"🔐 校验<br/>权限"}:::warning
    Check -- "通过" --> Process(["⚡ 执行<br/>核心逻辑"]):::core
    Check -- "拒绝" --> Reject(["❌ 返回<br/>403 错误"]):::danger
    Process --> DB[("💾 保存数据")]
    DB --> End(["✅ 结束"])
    Reject --> End
```

### 模板 C：Agent 循环（Think-Act-Observe）

```
---
config:
  theme: neutral
  look: neo
---
flowchart LR
    classDef brain   fill:#7055BB,stroke:#412A88,stroke-width:2px
    classDef action  fill:#3D7DC8,stroke:#1A4E8A,stroke-width:2px
    classDef observe fill:#48A880,stroke:#256B4E,stroke-width:2px
    classDef io      fill:#D97F2A,stroke:#8B4500,stroke-width:2px

    User(["👤 用户输入"]) --> Think

    subgraph Loop["🔄 Agent 循环"]
        direction LR
        Think(["🧠 思考<br/>规划意图"]):::brain
        Act(["⚡ 执行<br/>调用工具"]):::action
        Observe(["👁️ 观察<br/>读取结果"]):::observe
        Think --> Act --> Observe --> Think
    end

    Observe --> Done{"✅ 完成？"}
    Done -- "否" --> Think
    Done -- "是" --> Output(["📤 输出结果"]):::io

    style Loop fill:#D0C8E8,stroke:#9977DD,stroke-width:2px
```

### 模板 D：时序图

```
---
config:
  theme: neutral
  look: neo
---
sequenceDiagram
    autonumber
    participant U as 👤 用户
    participant G as ⚙️ Gateway
    participant A as 🔐 Auth
    participant S as 🚀 Service
    participant D as 💾 DB

    U->>G: POST /api/data
    G->>A: 验证 Token
    A-->>G: ✅ 通过
    G->>S: 转发请求
    S->>D: 查询数据
    D-->>S: 返回结果
    S-->>G: 200 + payload
    G-->>U: 响应数据
```

### 模板 E：决策树

```
---
config:
  theme: neutral
  look: neo
---
flowchart TD
    classDef decision fill:#D97F2A,stroke:#8B4500,stroke-width:2px
    classDef result   fill:#48A880,stroke:#256B4E,stroke-width:2px
    classDef hot      fill:#C94444,stroke:#8B1A1A,stroke-width:2px

    Q1{"🤔 最在意<br/>什么？"}:::decision
    Q1 -- "性能优先" --> R1(["🚀 方案 A"]):::hot
    Q1 -- "成本优先" --> Q2{"🌍 国内还是<br/>海外？"}:::decision
    Q1 -- "开源可控" --> R3(["🔓 方案 C"]):::result
    Q2 -- "国内"     --> R2A(["🏠 方案 B1"]):::result
    Q2 -- "海外"     --> R2B(["✈️ 方案 B2"]):::result

    R1 ~~~ Q2 ~~~ R3
```

---

## 流程步骤

**1. 分析文档** — 识别所有插图位置（已有 Mermaid 块、ASCII 图、应配图章节），产出插图清单。

**2. 选模板** — 匹配 `templates/` YAML 的关键词，选最近似模板；无匹配时 LLM 自主设计。

**3. 设计图表** — 默认 `flowchart LR`；按规范 2-8 分配形状、色板、图标、subgraph 背景、对称布局。

**4. 自检** — 按规范 9 清单逐项核对。

**5. 展示确认** — 输出完整可渲染代码，用户选择：满意 / 重新生成 / 修改建议。

**6. 应用** — 替换原文档对应区域。

**7. 模板沉淀（可选）** — 被采纳的 LLM 方案可保存为新 YAML 模板。

---

## 注意事项

- 每次输出的 Mermaid 代码必须完整可渲染，不输出片段或省略号。
- 时序图（`sequenceDiagram`）本身纵向，不适用"默认 LR"规则；参与者数量控制在 ≤ 7 个。
- Mermaid **不支持** `rgba()` 或 8位 hex alpha（`#RRGGBBAA`）——务必使用标准 6位 hex。
- 图表文本与文档语言保持一致。

## Token 约束

- Mermaid 代码生成后不重复粘贴，只确认已写入文件。
- 文档内容只读取必要部分，不全文复制。
