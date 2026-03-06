# doc-illustrator

为技术文档自动生成Mermaid配图的skill。

## 功能

- 分析文档内容，识别需要插图的位置
- 使用Neo look风格，不硬编码颜色，自动适配dark/light主题
- 混合模板匹配（常见类型）和LLM理解（特殊场景）两条路径
- 用户确认后自动替换到文档中
- 支持将新方案沉淀为模板

## 支持的图表类型

| 类型 | 模板 | 适用场景 |
|------|------|---------|
| 架构图 | architecture.yaml | 分层架构、组件关系、环境栈 |
| 流程图 | flow.yaml | 执行流程、决策分支、操作序列 |
| 概念图 | concept.yaml | 概念映射、替换机制、数据转换 |
| 时序图 | sequence.yaml | 组件交互、调用链、生命周期 |

## 使用方式

### Prompt 示例

**改进现有文档插图：**
> 请用 doc-illustrator 改进 README.md 中的插图

**为新文档添加插图：**
> 请用 doc-illustrator 为 docs/architecture.md 添加配图

**指定图表类型：**
> 请用 doc-illustrator 为这段描述生成一个流程图

## 注意事项

- Mermaid 在 GitHub、GitLab、多数现代文档工具中原生渲染
- 默认使用 Neo look + Default 主题，自动适配用户的 dark/light 偏好
- 节点使用圆角格式，适当添加图标增加辨识度
