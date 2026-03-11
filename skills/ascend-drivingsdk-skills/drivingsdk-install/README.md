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

## 注意事项

- 需要先安装好 CANN + PyTorch + torch_npu
- torch_npu 必须用 wheel 包安装（非 editable install）
- 更新重装前先清理 `dist/` 和 `build/` 目录
- `mx_driving` 没有 `__version__`，用 `pip show mx-driving` 查看版本
