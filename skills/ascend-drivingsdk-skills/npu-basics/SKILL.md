---
name: ascend-drivingsdk-skills/npu-basics
description: NPU基础命令：状态监控、设备管理、版本查询、环境变量配置
metadata:
  type: capability
  version: "1.0"
  tags: [npu, ascend, monitoring]
  domain: ai-infra
  risk_level: low
  platform: linux
---

# npu-basics

## 概述
昇腾 NPU 日常运维核心命令集，覆盖设备状态监控、版本查询、进程管理、设备指定和日志排查。

## 适用场景
- 查看 NPU 运行状态（使用率、温度、功耗、显存）
- 查询驱动/固件/CANN 版本信息
- 指定使用特定 NPU 设备
- 排查 NPU 异常、查看占用进程
- 容器场景下挂载 NPU 设备

## 运行环境
- **平台**：Linux（已安装昇腾 NPU 驱动）
- **远程场景**：需要 SSH 远程执行能力（在可用 skill 中寻找提供此功能的工具）

## 流程步骤

### 一、NPU 状态与监控（npu-smi）

1. **查看所有 NPU 总体状态**：
```bash
npu-smi info
```
输出含：芯片ID、温度、功耗、内存使用量、AI Core 利用率。

2. **实时监控**（每秒刷新）：
```bash
watch -n 1 npu-smi info
```

3. **查看设备健康状态**：
```bash
npu-smi info -t health -i <设备ID>
```

4. **查看板卡详细信息**：
```bash
npu-smi info -t board -i <设备ID>
```

5. **列出可用 NPU 设备**：
```bash
ls /dev | grep davinci
```
设备名格式：`/dev/davinci0`, `/dev/davinci1` 等。

### 二、版本查询（驱动、固件、CANN）

1. **NPU 驱动版本**：
```bash
cat /usr/local/Ascend/driver/version.info
```

2. **NPU 固件版本**：
```bash
cat /usr/local/Ascend/firmware/version.info
```

3. **CANN 版本**（路径因安装配置而异）：
```bash
# 方法1：在默认路径查找
cat /usr/local/Ascend/ascend-toolkit/latest/ascend_toolkit_install.info 2>/dev/null

# 方法2：自动查找（兼容自定义安装路径）
find /usr/local/Ascend /home -name "ascend_toolkit_install.info" -maxdepth 5 2>/dev/null | head -3

# 方法3：通过 set_env.sh 定位
find /usr/local/Ascend /home -name "set_env.sh" -path "*/ascend-toolkit/*" -maxdepth 5 2>/dev/null
```

### 三、指定 NPU 设备

通过环境变量控制进程可见的 NPU：
```bash
# 仅使用第0和第1号NPU
export ASCEND_RT_VISIBLE_DEVICES=0,1

# 仅使用第2号NPU
export ASCEND_RT_VISIBLE_DEVICES=2

# 查看当前设置
echo $ASCEND_RT_VISIBLE_DEVICES
```

**注意**：设置后，进程内的设备编号会重新从0开始映射。

### 四、进程与内存管理

1. **查看占用 NPU 的进程**：
```bash
npu-smi info watch
```
（部分版本参数可能不同，可用 `npu-smi info -h` 查看具体用法）

2. **重置 NPU 设备**（卡死/异常时使用，⚠️ 会中断所有占用进程）：
```bash
npu-smi set -t reset -i <设备ID> -c <芯片ID>
```

### 五、容器（Docker）运行相关

挂载 NPU 设备到容器的最小挂载集合：
```bash
docker run --rm -it \
  --device=/dev/davinci_manager \
  --device=/dev/devmm_svm \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  <镜像名> bash
```
具体挂载设备文件以官方文档为准，推荐使用 `ascend-docker-cli` 或配置 ascend runtime。

### 六、日志排查

1. **NPU 设备日志默认路径**：
```bash
ls /var/log/npu/slog/
```

2. **一键收集日志**：
```bash
/usr/local/Ascend/driver/tools/msnpureport -a
```

## 检查清单
- [ ] `npu-smi info` 能正常输出设备信息
- [ ] 驱动/固件版本文件可读取
- [ ] CANN set_env.sh 路径已确认
- [ ] `ASCEND_RT_VISIBLE_DEVICES` 设置后设备隔离生效
