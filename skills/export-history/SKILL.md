---
name: export-history
description: Claude Code对话历史导出为可视化HTML，支持会话浏览和搜索
metadata:
  type: capability
  version: "1.0"
  tags: [export, history, html]
  domain: general
  risk_level: low
  platform: cross-platform
---

# export-history

## 功能
将 `~/.claude/projects/` 下所有 Claude Code 对话导出为可视化 HTML 文件，支持会话浏览、搜索和按项目分类查看。

## 运行环境
- **跨平台**：Windows、macOS、Linux（需要 Node.js）

## 使用
```bash
node scripts/export-claude-history.mjs
```

输出文件：`~/Desktop/claude-history.html`，用浏览器打开即可浏览所有对话。

## 注意事项
- 脚本读取 `~/.claude/projects/` 目录下的 `.jsonl` 会话文件
- 输出为单文件 HTML，无外部依赖，可直接分享
- 若 `~/.claude/projects/` 不存在或为空，脚本会提示无会话数据
