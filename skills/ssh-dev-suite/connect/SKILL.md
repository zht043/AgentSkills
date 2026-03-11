---
name: ssh-dev-suite/connect
description: SSH连接管理、远程命令执行、文件传输、后台任务
---

# ssh-connect

## 功能
SSH连接测试、远程命令执行、文件上传下载、后台任务管理。容器场景自动包装docker/kubectl。

## 运行环境
- **客户端**：Windows（Git Bash/MSYS2）、macOS、Linux
- **服务端**：Linux

## 使用
```bash
bash connect/scripts/ssh-test.sh <profile>
bash connect/scripts/ssh-exec.sh <profile> <command>
bash connect/scripts/ssh-upload.sh <profile> <local> <remote>
bash connect/scripts/ssh-download.sh <profile> <remote> <local>
bash connect/scripts/ssh-job.sh start|status|output|kill|list|stream <profile> [args]
```

## ssh-exec 与 ssh-job 选择策略

**关键原则**：ssh-exec 的输出在命令完全结束后才回传，长时间运行的命令会导致用户看不到任何进度。

| 场景 | 工具 | 原因 |
|------|------|------|
| 快速命令（<30s）：`ls`、`cat`、`docker images`、`conda env list` | ssh-exec | 即时返回，无需后台 |
| 中等耗时（30s-2min）：`pip install`、`docker pull`、单个测试 | ssh-job + 轮询 | 可随时查看进度 |
| 长耗时（>2min）：批量测试、编译构建、模型训练 | ssh-job + checkpoint | 支持跨会话恢复 |

**ssh-job 用法模式**（替代 ssh-exec 用于中长耗时任务）：

```bash
# 1. 启动后台任务
bash connect/scripts/ssh-job.sh start <profile> "<command>"

# 2. 定期查看进度（根据预计耗时调整频率）
bash connect/scripts/ssh-job.sh output <profile> <job_id> --tail 20

# 3. 搜索错误
bash connect/scripts/ssh-job.sh output <profile> <job_id> --grep 'error|fail|ERROR'
```

**Agent 必须遵守**：
- 预计耗时 >30 秒的命令，**禁止使用 ssh-exec**，改用 ssh-job
- 使用 ssh-job 时，每次轮询只读尾部（`--tail`）或搜索关键词（`--grep`），不读完整日志
- 批量执行多个子任务（如逐文件跑测试）时，为整个批量任务使用一个 ssh-job，在命令中加入进度打印（如 `echo "[$(date +%H:%M:%S)] Running test_xxx.py..."`），便于通过 `--tail` 观察进度

## 引号与特殊字符

远程命令经过多层 shell 解释（本地 shell → ssh → 远端 shell → docker exec → 容器内 shell），引号嵌套极易出错。

- **复杂命令**（含引号、变量、管道等）：推荐写成脚本文件，通过 `ssh-upload.sh` 上传到服务器后执行，避免内联命令的多层引号嵌套
- **简单命令**：可直接内联传递，脚本已处理基本转义
- 密码认证通过环境变量（`sshpass -e`）传递，不在命令行暴露

## Windows 客户端注意事项

- ControlMaster 会话复用在 Windows 上不可用（脚本已自动检测并跳过）
- `$PATH` 等环境变量在 Git Bash 中可能被 Windows 路径展开，导致传递到远端时出错。建议用上传脚本方式代替内联命令中的 `$PATH` 引用
- identity_file 路径含空格时已自动处理引用

## 网络问题处理

**当远程命令因网络问题失败时**（如 pip install 超时、git clone 失败、curl 连接拒绝等），**不要尝试绕过，必须使用 tunnel 模块的 proxy 功能**建立反向代理：

```bash
# 1. 建立反向代理隧道（将本地代理共享给远程服务器）
bash tunnel/scripts/ssh-tunnel.sh proxy <profile>

# 2. 在远程命令前加上代理环境变量（proxy 命令会输出具体的 export 语句）
bash connect/scripts/ssh-exec.sh <profile> "export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 && pip install ..."
```

详见 `tunnel/SKILL.md` 的自动触发规则。

## Token约束
- 远程命令输出：优先使用过滤参数（--tail/--head/--grep），禁止读取完整大日志
- 后台任务输出：先用status查看大小，>10KB只读tail，>100KB先grep错误
- 状态检查：先查摘要，按需深入
- 重复信息：不复述已知内容
