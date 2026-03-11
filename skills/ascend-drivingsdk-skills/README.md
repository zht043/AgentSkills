# ascend-drivingsdk-skills

Ascend NPU [DrivingSDK](https://gitcode.com/Ascend/DrivingSDK) 开发辅助 skill 集合（skills）。

## Skill 列表

### 环境搭建

| Skill | 功能 |
|-------|------|
| [npu-basics](npu-basics/) | NPU 基础命令：状态监控、版本查询、设备指定、进程管理、日志排查 |
| [cann-install](cann-install/) | CANN 安装（社区版/商业版，run包/conda/下载三种方式） |
| [torch-npu-install](torch-npu-install/) | PyTorch + torch_npu 安装（预编译包/源码编译） |
| [drivingsdk-install](drivingsdk-install/) | DrivingSDK（mx_driving）编译安装与更新 |

### 开发工具

| Skill | 功能 |
|-------|------|
| [test-coverage](test-coverage/) | C++/Python 代码覆盖率收集（gcov/lcov + coverage 模块） |
| [container-deploy](container-deploy/) | 容器环境一键部署（镜像管理、NPU设备挂载、SSH、conda、部署档案） |

## 典型使用顺序

首次搭建完整 DrivingSDK 开发环境的推荐顺序：

```
npu-basics（确认 NPU 可用）
  → cann-install（安装 CANN）
    → torch-npu-install（安装 PyTorch + torch_npu）
      → drivingsdk-install（编译安装 DrivingSDK）
```

## 共享库

`_lib/` 目录下的公共脚本供各子模块复用：

| 脚本 | 功能 |
|------|------|
| `coverage-common.sh` | 配置文件读取、路径处理等通用函数 |

各 skill 独立自包含，详见对应子目录的 README.md。

