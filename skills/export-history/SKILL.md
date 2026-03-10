---
name: export-history
description: Claude Code对话历史导出为可视化HTML
---

# export-history

## 功能
将 `~/.claude/projects/` 下所有 Claude Code 对话导出为可视化 HTML 文件，支持会话浏览、搜索。

## 运行环境
- **跨平台**：Windows、macOS、Linux（需要 Node.js）

## 使用
```bash
node scripts/export-claude-history.mjs
```

输出文件：`~/Desktop/claude-history.html`，用浏览器打开即可浏览所有对话。
