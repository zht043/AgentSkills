# cann-install

CANN（昇腾异构计算架构）安装 skill，支持社区版和商业版，提供 run 包、conda、社区下载三种安装方式。

## 使用方式

在 Claude Code 对话中描述需求，agent 会引导完成安装。

### Prompt 示例

```
帮我在这台 NPU 服务器上安装 CANN 8.5.0 社区版
```

```
我已经下载好了 CANN 的 run 包，帮我安装
```

```
用 conda 方式安装 CANN
```

```
帮我升级 CANN 到最新版本
```

## 注意事项

- 需要先安装 NPU 驱动（`/usr/local/Ascend/driver` 存在）
- run 包安装时 `--quiet` 参数必须加，否则会卡在 EULA 确认
- 不同 CANN 版本的 `set_env.sh` 路径不同，agent 会自动查找
- 安装完成后建议将 `source set_env.sh` 写入 `~/.bashrc`
- 从社区下载可能需要登录昇腾社区账号
