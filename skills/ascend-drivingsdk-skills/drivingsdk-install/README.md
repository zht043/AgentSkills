# drivingsdk-install

DrivingSDK（mx_driving）编译安装 skill，含首次安装和更新重装流程。

## 使用方式

在 Claude Code 对话中描述需求，agent 会引导完成安装。

### Prompt 示例

```
帮我编译安装 DrivingSDK
```

```
我更新了 DrivingSDK 的代码，帮我重新编译安装
```

```
编译 DrivingSDK 时报错 acl_base.h 找不到，帮我修复
```

```
帮我验证 DrivingSDK 是否安装正确
```

## 版本对应（参考）

| DrivingSDK 分支 | PyTorch | torch_npu | CPU 架构 |
|----------------|---------|-----------|---------|
| master         | 2.1.0 / 2.6.0 / 2.7.1 / 2.8.0 | 对应版本 | x86 & aarch64 |
| branch_v7.3.0  | 2.1.0 / 2.6.0 / 2.7.1 / 2.8.0 | 对应版本 | x86 & aarch64 |

以官方文档为准：[Ascend/DrivingSDK](https://gitcode.com/Ascend/DrivingSDK)

## 注意事项

- 需要先安装好 CANN + PyTorch + torch_npu
- 默认推荐 Release 模式（wheel 包安装），Develop 模式适合开发调试
- 编译需要 cmake >=3.19 且 <4.0，agent 会自动检查并安装
- 更新重装前先清理 `dist/` 和 `build/` 目录
- `mx_driving` 没有 `__version__`，用 `pip show mx-driving` 查看版本
- 验证导入时须从非源码目录执行，避免导入本地源码
