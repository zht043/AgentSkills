---
name: ssh-dev-suite/connect
description: SSH连接管理、远程命令执行、文件传输、后台任务
type: capability
---

# ssh-connect

## 功能
SSH连接测试、远程命令执行、文件上传下载、后台任务管理。容器场景自动包装docker/kubectl。

## 使用
```bash
bash connect/scripts/ssh-test.sh <profile>
bash connect/scripts/ssh-exec.sh <profile> <command>
bash connect/scripts/ssh-upload.sh <profile> <local> <remote>
bash connect/scripts/ssh-download.sh <profile> <remote> <local>
bash connect/scripts/ssh-job.sh start|status|output|kill|list|stream <profile> [args]
```

## Token约束
- 远程命令输出：优先使用过滤参数（--tail/--head/--grep），禁止读取完整大日志
- 后台任务输出：先用status查看大小，>10KB只读tail，>100KB先grep错误
- 状态检查：先查摘要，按需深入
- 重复信息：不复述已知内容
