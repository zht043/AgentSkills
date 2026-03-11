# torch-npu-install

PyTorch + torch_npu 安装 skill，支持预编译包和源码编译两种方式。

## 使用方式

在 Claude Code 对话中描述需求，agent 会引导完成安装。

### Prompt 示例

```
帮我安装 PyTorch 2.1 和对应的 torch_npu
```

```
我需要升级 torch_npu 到 2.3 版本
```

```
torch_npu 编译 DrivingSDK 时报错找不到 acl_base.h，帮我修复
```

```
帮我从源码编译安装 torch_npu
```

## 注意事项

- CANN 必须先安装好且 `set_env.sh` 已 source
- PyTorch 和 torch_npu 主版本号必须一致
- **禁止使用 `pip install -e .`**，必须用 wheel 包安装
- cmake 版本要求 >=3.18 且 <4.0
- 源码编译耗时较长，建议后台执行
