#!/usr/bin/env node
/**
 * Claude Code 对话历史导出工具
 * 将 ~/.claude/projects/ 下所有对话导出为可视化 HTML
 */

import fs from 'fs';
import path from 'path';
import os from 'os';

const PROJECTS_DIR = path.join(os.homedir(), '.claude', 'projects');
const OUTPUT_FILE = path.join(os.homedir(), 'Desktop', 'claude-history.html');

// ─── 读取所有会话 ───────────────────────────────────────────────────────────

function getAllSessions() {
  const sessions = [];

  for (const projectDir of fs.readdirSync(PROJECTS_DIR)) {
    const projectPath = path.join(PROJECTS_DIR, projectDir);
    if (!fs.statSync(projectPath).isDirectory()) continue;

    // 将目录名还原为项目路径
    const projectName = projectDir.replace(/--/g, ' > ').replace(/-/g, '/');

    for (const file of fs.readdirSync(projectPath)) {
      if (!file.endsWith('.jsonl')) continue;

      const sessionId = file.replace('.jsonl', '');
      const filePath = path.join(projectPath, file);
      const stat = fs.statSync(filePath);

      try {
        const messages = parseSession(filePath);
        if (messages.length === 0) continue;

        sessions.push({
          sessionId,
          projectDir,
          projectName,
          filePath,
          mtime: stat.mtime,
          size: stat.size,
          messages,
        });
      } catch (e) {
        // skip broken files
      }
    }
  }

  // 按时间倒序
  sessions.sort((a, b) => b.mtime - a.mtime);
  return sessions;
}

function parseSession(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n').filter(Boolean);
  const messages = [];

  for (const line of lines) {
    try {
      const d = JSON.parse(line);
      if (d.type !== 'user' && d.type !== 'assistant') continue;

      const role = d.type; // 'user' or 'assistant'
      const timestamp = d.timestamp || null;
      let text = '';

      if (d.message) {
        // 提取文本内容
        if (typeof d.message === 'string') {
          text = d.message;
        } else if (d.message.content) {
          const content = d.message.content;
          if (typeof content === 'string') {
            text = content;
          } else if (Array.isArray(content)) {
            for (const block of content) {
              if (block.type === 'text') text += block.text;
              else if (block.type === 'thinking') {
                // skip thinking blocks
              } else if (block.type === 'tool_use') {
                text += `\n[Tool: ${block.name}]\n`;
              } else if (block.type === 'tool_result') {
                // skip tool results for brevity
              }
            }
          }
        }
      }

      text = text.trim();
      if (!text) continue;

      messages.push({ role, text, timestamp });
    } catch (e) {
      // skip
    }
  }

  return messages;
}

// ─── 生成 HTML ──────────────────────────────────────────────────────────────

function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function formatTime(date) {
  if (!date) return '';
  return new Date(date).toLocaleString('zh-CN', {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit',
  });
}

function buildHtml(sessions) {
  const totalMessages = sessions.reduce((s, sess) => s + sess.messages.length, 0);

  const navItems = sessions.map((sess, i) => {
    const firstMsg = sess.messages.find(m => m.role === 'user');
    const preview = firstMsg ? firstMsg.text.slice(0, 60).replace(/\n/g, ' ') : '(空)';
    return `
      <div class="nav-item" onclick="showSession(${i})" id="nav-${i}">
        <div class="nav-project">${escapeHtml(sess.projectDir)}</div>
        <div class="nav-preview">${escapeHtml(preview)}…</div>
        <div class="nav-meta">${formatTime(sess.mtime)} · ${sess.messages.length} 条</div>
      </div>`;
  }).join('');

  const sessionPanels = sessions.map((sess, i) => {
    const msgs = sess.messages.map(m => {
      const roleClass = m.role === 'user' ? 'msg-user' : 'msg-assistant';
      const roleLabel = m.role === 'user' ? '你' : 'Claude';
      const textLines = escapeHtml(m.text).replace(/\n/g, '<br>');
      return `
        <div class="message ${roleClass}">
          <div class="msg-header">
            <span class="msg-role">${roleLabel}</span>
            <span class="msg-time">${m.timestamp ? formatTime(m.timestamp) : ''}</span>
          </div>
          <div class="msg-body">${textLines}</div>
        </div>`;
    }).join('');

    return `
      <div class="session-panel" id="session-${i}" style="display:none">
        <div class="session-header">
          <div class="session-project">${escapeHtml(sess.projectName)}</div>
          <div class="session-id">Session: ${sess.sessionId}</div>
          <div class="session-meta">${formatTime(sess.mtime)} · ${sess.messages.length} 条消息</div>
        </div>
        <div class="messages">${msgs}</div>
      </div>`;
  }).join('');

  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Claude 对话历史</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: #0f0f0f; color: #e0e0e0; height: 100vh; display: flex; flex-direction: column; }

  .top-bar {
    background: #1a1a1a; border-bottom: 1px solid #333;
    padding: 12px 20px; display: flex; align-items: center; gap: 16px; flex-shrink: 0;
  }
  .top-bar h1 { font-size: 16px; font-weight: 600; color: #fff; }
  .top-bar .stats { font-size: 12px; color: #888; }
  .search-box {
    margin-left: auto; background: #2a2a2a; border: 1px solid #444; border-radius: 6px;
    padding: 6px 12px; color: #e0e0e0; font-size: 13px; width: 240px;
    outline: none;
  }
  .search-box:focus { border-color: #6c8ebf; }

  .main { display: flex; flex: 1; overflow: hidden; }

  /* Sidebar */
  .sidebar {
    width: 320px; flex-shrink: 0; background: #161616; border-right: 1px solid #2a2a2a;
    overflow-y: auto;
  }
  .nav-item {
    padding: 12px 16px; border-bottom: 1px solid #1e1e1e; cursor: pointer;
    transition: background 0.15s;
  }
  .nav-item:hover { background: #1f2a3a; }
  .nav-item.active { background: #1e3a5f; border-left: 3px solid #4a90d9; }
  .nav-project { font-size: 10px; color: #5a8abf; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
  .nav-preview { font-size: 13px; color: #ccc; margin-bottom: 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .nav-meta { font-size: 11px; color: #555; }

  /* Content */
  .content { flex: 1; overflow-y: auto; padding: 0; }
  .welcome {
    display: flex; align-items: center; justify-content: center; height: 100%;
    color: #444; font-size: 16px;
  }

  .session-panel { max-width: 860px; margin: 0 auto; padding: 24px 24px 60px; }
  .session-header {
    background: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 8px;
    padding: 16px; margin-bottom: 24px;
  }
  .session-project { font-size: 11px; color: #5a8abf; margin-bottom: 4px; }
  .session-id { font-size: 11px; color: #444; font-family: monospace; margin-bottom: 4px; }
  .session-meta { font-size: 12px; color: #666; }

  .message { margin-bottom: 16px; border-radius: 8px; overflow: hidden; }
  .msg-user { background: #1a2535; border: 1px solid #243348; }
  .msg-assistant { background: #1a1a1a; border: 1px solid #2a2a2a; }
  .msg-header {
    display: flex; align-items: center; gap: 8px; padding: 8px 14px;
    background: rgba(255,255,255,0.03); border-bottom: 1px solid rgba(255,255,255,0.05);
  }
  .msg-role { font-size: 12px; font-weight: 600; }
  .msg-user .msg-role { color: #4a90d9; }
  .msg-assistant .msg-role { color: #6bc47a; }
  .msg-time { font-size: 11px; color: #555; margin-left: auto; }
  .msg-body {
    padding: 12px 14px; font-size: 14px; line-height: 1.65; color: #ccc;
    white-space: pre-wrap; word-break: break-word;
    max-height: 600px; overflow-y: auto;
  }

  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }
</style>
</head>
<body>
<div class="top-bar">
  <h1>Claude 对话历史</h1>
  <span class="stats">${sessions.length} 个会话 · ${totalMessages} 条消息</span>
  <input class="search-box" type="text" placeholder="搜索会话..." oninput="filterSessions(this.value)" />
</div>
<div class="main">
  <div class="sidebar" id="sidebar">${navItems}</div>
  <div class="content" id="content">
    <div class="welcome" id="welcome">← 选择左侧会话查看对话</div>
    ${sessionPanels}
  </div>
</div>
<script>
  let current = -1;
  const sessions = ${JSON.stringify(sessions.map(s => ({
    projectDir: s.projectDir,
    mtime: s.mtime,
    msgCount: s.messages.length,
    preview: (s.messages.find(m => m.role === 'user')?.text || '').slice(0, 60),
  })))};

  function showSession(i) {
    if (current >= 0) {
      document.getElementById('session-' + current).style.display = 'none';
      document.getElementById('nav-' + current)?.classList.remove('active');
    }
    document.getElementById('welcome').style.display = 'none';
    document.getElementById('session-' + i).style.display = 'block';
    document.getElementById('nav-' + i)?.classList.add('active');
    document.getElementById('content').scrollTop = 0;
    current = i;
  }

  function filterSessions(q) {
    q = q.toLowerCase();
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach((el, i) => {
      const s = sessions[i];
      const match = !q ||
        s.projectDir.toLowerCase().includes(q) ||
        s.preview.toLowerCase().includes(q);
      el.style.display = match ? '' : 'none';
    });
  }

  // 默认选中第一个
  if (${sessions.length} > 0) showSession(0);
</script>
</body>
</html>`;
}

// ─── 主流程 ─────────────────────────────────────────────────────────────────

console.log('正在扫描对话历史...');
const sessions = getAllSessions();
console.log(`找到 ${sessions.length} 个有效会话`);

const html = buildHtml(sessions);
fs.writeFileSync(OUTPUT_FILE, html, 'utf8');

const sizeMB = (fs.statSync(OUTPUT_FILE).size / 1024 / 1024).toFixed(1);
console.log(`\n导出完成！`);
console.log(`文件: ${OUTPUT_FILE}`);
console.log(`大小: ${sizeMB} MB`);
console.log(`\n直接用浏览器打开该文件即可查看。`);
