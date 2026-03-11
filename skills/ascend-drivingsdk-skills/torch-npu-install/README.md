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
torch_npu 导入报错 No module named 'yaml'，帮我修复
```

```
帮我从源码编译安装 torch_npu
```

## 版本对应（参考）

| CANN 版本 | PyTorch | torch_npu | Python |
|----------|---------|-----------|--------|
| 8.5.0    | 2.8.0 / 2.7.1 / 2.6.0 | 对应 post 版本 | 3.9-3.11 |
| 8.0.0    | 2.4.0 / 2.3.1 / 2.1.0 | 对应 post 版本 | 3.8-3.11 |

以官方文档为准：[Ascend/pytorch](https://gitcode.com/Ascend/pytorch)

## 注意事项

- CANN 必须先安装好且 `set_env.sh` 已 source
- PyTorch 和 torch_npu 主版本号必须一致
- x86_64 需安装 CPU 版 PyTorch，aarch64 直接安装
- torch_npu 运行依赖 `pyyaml` 和 `numpy`，需先安装
- 默认推荐预编译 whl 包安装，源码编译适合特殊需求
- 源码编译需 cmake >=3.19 且 <4.0，agent 会自动检查并安装
