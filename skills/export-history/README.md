# export-history

Claude Code 对话历史导出工具，将所有对话导出为可视化 HTML。

## 使用

```bash
node scripts/export-claude-history.mjs
```

输出到桌面 `claude-history.html`，浏览器打开即可查看。

## 功能

- 自动扫描 `~/.claude/projects/` 下所有 `.jsonl` 会话文件
- 按时间倒序排列，提取用户和 Claude 的对话内容
- 生成暗色主题的单文件 HTML，含侧边栏导航和搜索
- 跳过 thinking blocks 和 tool results，保留关键对话内容

## 依赖

- Node.js（无额外 npm 依赖）
