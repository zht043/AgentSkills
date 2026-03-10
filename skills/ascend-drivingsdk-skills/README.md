# ascend-drivingsdk-skills

Ascend NPU [DrivingSDK](https://gitcode.com/Ascend/DrivingSDK) 开发辅助 skill 套件。

## Skill 列表

| Skill | 功能 |
|-------|------|
| [test-coverage](test-coverage/) | C++/Python 代码覆盖率收集（gcov/lcov + coverage 模块） |
| [container-deploy](container-deploy/) | 容器环境一键部署（镜像管理、NPU设备挂载、SSH、conda） |

## 前置条件

- 宿主机已安装昇腾 NPU 驱动（`/usr/local/Ascend/driver` 存在）
- 宿主机已安装 Docker
- 远程场景通过 [ssh-dev-suite](../ssh-dev-suite/) 连接

## 共享库

`_lib/` 目录下的公共脚本供各子模块复用：

| 脚本 | 功能 |
|------|------|
| `coverage-common.sh` | 配置文件读取、路径处理等通用函数 |

各 skill 独立自包含，详见对应子目录的 README.md。
