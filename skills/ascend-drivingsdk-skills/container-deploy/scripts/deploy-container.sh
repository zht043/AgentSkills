#!/usr/bin/env bash
# deploy-container.sh — DrivingSDK 容器一键部署
# 功能：拉取/加载镜像 → 创建容器 → 配置容器内SSH → 配置conda环境 → 打印环境信息
# 用法：bash deploy-container.sh [options]
# 退出码：0=成功, 1=参数/系统错误, 2=镜像拉取失败（需用户介入）

set -euo pipefail

# ========== 默认值 ==========
IMAGE=""
IMAGE_TAG=""
IMAGE_FILE=""
ARCH=""
CONTAINER_NAME=""
MOUNTS=()
SSH_PORT=""
EXPOSE_PORTS=()
ROOT_PASSWORD=""
TORCH_VERSION=""
CONDA_NAME=""
PROXY_URL=""
REGISTRY="swr.cn-south-1.myhuaweicloud.com/ascendhub/drivingsdk"

# ========== 参数解析 ==========
usage() {
    cat <<'USAGE'
用法: bash deploy-container.sh [options]

镜像来源（三选一，互斥）:
  --image <name:tag>         直接指定完整镜像名
  --image-file <path.tar>    从本地文件加载镜像
  --image-tag <tag>          镜像版本标签，与 --arch 配合自动拼接地址

容器配置:
  --arch <aarch64|x86_64>    宿主机架构（默认自动检测）
  --container-name <name>    容器名称（必填）
  --mount <host:container>   挂载路径，可多次指定
  --ssh-port <port>          容器内 sshd 监听端口
  --expose <port>            额外暴露端口，可多次指定
  --root-password <pwd>      容器 root 密码

环境配置:
  --torch-version <ver>      torch 版本（2.1.0/2.6.0/2.7.1），可选
  --conda-name <name>        conda 环境自定义名称（需配合 --torch-version）
  --proxy <url>              HTTP 代理地址（如 http://127.0.0.1:7897），持久化到容器
  --registry <url>           镜像仓库地址（默认华为 SWR）
USAGE
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)        IMAGE="$2"; shift 2 ;;
        --image-tag)    IMAGE_TAG="$2"; shift 2 ;;
        --image-file)   IMAGE_FILE="$2"; shift 2 ;;
        --arch)         ARCH="$2"; shift 2 ;;
        --container-name) CONTAINER_NAME="$2"; shift 2 ;;
        --mount)        MOUNTS+=("$2"); shift 2 ;;
        --ssh-port)     SSH_PORT="$2"; shift 2 ;;
        --expose)       EXPOSE_PORTS+=("$2"); shift 2 ;;
        --root-password) ROOT_PASSWORD="$2"; shift 2 ;;
        --torch-version) TORCH_VERSION="$2"; shift 2 ;;
        --conda-name)   CONDA_NAME="$2"; shift 2 ;;
        --proxy)        PROXY_URL="$2"; shift 2 ;;
        --registry)     REGISTRY="$2"; shift 2 ;;
        -h|--help)      usage ;;
        *)              echo "未知参数: $1"; usage ;;
    esac
done

# ========== 参数校验 ==========
if [ -z "$CONTAINER_NAME" ]; then
    echo "错误: 必须指定 --container-name" >&2
    exit 1
fi

# 镜像来源互斥检查
SRC_COUNT=0
[ -n "$IMAGE" ] && ((SRC_COUNT++)) || true
[ -n "$IMAGE_TAG" ] && ((SRC_COUNT++)) || true
[ -n "$IMAGE_FILE" ] && ((SRC_COUNT++)) || true
if [ "$SRC_COUNT" -eq 0 ]; then
    echo "错误: 必须指定镜像来源（--image / --image-tag / --image-file）" >&2
    exit 1
fi
if [ "$SRC_COUNT" -gt 1 ]; then
    echo "错误: --image、--image-tag、--image-file 三者互斥" >&2
    exit 1
fi

# ========== 架构检测 ==========
if [ -z "$ARCH" ]; then
    ARCH=$(uname -m)
    echo "自动检测架构: $ARCH"
fi

# 映射架构后缀
case "$ARCH" in
    aarch64) ARCH_TAG="arm64" ;;
    x86_64)  ARCH_TAG="x86_64" ;;
    arm64)   ARCH_TAG="arm64" ;;
    *)       echo "未知架构: $ARCH" >&2; exit 1 ;;
esac

# ========== 获取镜像 ==========
if [ -n "$IMAGE_FILE" ]; then
    echo "从本地文件加载镜像: $IMAGE_FILE"
    if [ ! -f "$IMAGE_FILE" ]; then
        echo "错误: 文件不存在: $IMAGE_FILE" >&2
        exit 1
    fi
    LOAD_OUTPUT=$(docker load -i "$IMAGE_FILE")
    echo "$LOAD_OUTPUT"
    # 从 docker load 输出中提取镜像名
    IMAGE=$(echo "$LOAD_OUTPUT" | grep -oP 'Loaded image: \K.*' || echo "$LOAD_OUTPUT" | grep -oP 'Loaded image ID: \K.*' || true)
    if [ -z "$IMAGE" ]; then
        echo "错误: 无法从 docker load 输出中提取镜像名" >&2
        exit 1
    fi
elif [ -n "$IMAGE_TAG" ]; then
    # 尝试拼接地址拉取
    IMAGE="${REGISTRY}:${IMAGE_TAG}-${ARCH_TAG}"
    echo "尝试拉取镜像: $IMAGE"
    if ! docker pull "$IMAGE" 2>&1; then
        # 降级：尝试不带架构后缀
        IMAGE="${REGISTRY}:${IMAGE_TAG}"
        echo "尝试不带架构后缀: $IMAGE"
        if ! docker pull "$IMAGE" 2>&1; then
            echo "PULL_FAILED: 无法拉取镜像，请通过 --image 或 --image-file 提供替代来源" >&2
            exit 2
        fi
    fi
    echo "镜像拉取成功: $IMAGE"
elif [ -n "$IMAGE" ]; then
    # 检查本地是否已存在
    if ! docker image inspect "$IMAGE" &>/dev/null; then
        echo "本地不存在镜像 $IMAGE，尝试拉取..."
        if ! docker pull "$IMAGE"; then
            echo "错误: 镜像拉取失败: $IMAGE" >&2
            exit 2
        fi
    fi
    echo "使用镜像: $IMAGE"
fi

# ========== 构建 docker run 命令 ==========
DOCKER_CMD=(docker run -d
    --ipc=host
    --network=host
    --privileged
    -u=root
    --name "$CONTAINER_NAME"
)

# NPU 设备挂载（仅挂载实际存在的设备，支持多卡场景 davinci0-15）
for i in $(seq 0 15); do
    if [ -e "/dev/davinci${i}" ]; then
        DOCKER_CMD+=(--device="/dev/davinci${i}")
    fi
done
for dev in davinci_manager devmm_svm hisi_hdc; do
    if [ -e "/dev/${dev}" ]; then
        DOCKER_CMD+=(--device="/dev/${dev}")
    fi
done

# 驱动和工具挂载（仅挂载实际存在的路径）
[ -d "/usr/local/Ascend/driver" ] && DOCKER_CMD+=(-v "/usr/local/Ascend/driver:/usr/local/Ascend/driver")
[ -f "/usr/local/sbin/npu-smi" ] && DOCKER_CMD+=(-v "/usr/local/sbin/npu-smi:/usr/local/sbin/npu-smi")
[ -f "/usr/bin/hccn_tool" ] && DOCKER_CMD+=(-v "/usr/bin/hccn_tool:/usr/bin/hccn_tool")

# 用户挂载
for m in "${MOUNTS[@]}"; do
    DOCKER_CMD+=(-v "$m")
done

# 镜像和启动命令
DOCKER_CMD+=("$IMAGE" tail -f /dev/null)

echo "创建容器: $CONTAINER_NAME"
echo "执行: ${DOCKER_CMD[*]}"

# 如果同名容器已存在，先移除
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
"${DOCKER_CMD[@]}"

# 等待容器就绪
sleep 2
if ! docker inspect "$CONTAINER_NAME" &>/dev/null; then
    echo "错误: 容器创建失败" >&2
    exit 1
fi
echo "容器创建成功: $CONTAINER_NAME"

# ========== 容器内执行辅助函数 ==========
dexec() {
    docker exec "$CONTAINER_NAME" bash -c "$*"
}

# ========== 配置容器内 SSH ==========
if [ -n "$SSH_PORT" ]; then
    echo "配置容器内 SSH（端口: $SSH_PORT）..."

    # 安装 openssh-server（如未安装）
    dexec "command -v sshd >/dev/null 2>&1 || { yum install -y openssh-server 2>/dev/null || { apt-get update -o Acquire::Check-Valid-Until=false 2>/dev/null; apt-get install -y openssh-server 2>/dev/null; } || echo '警告: openssh-server 安装失败，请手动安装'; }"

    # 生成 host keys（如缺失）
    dexec "ssh-keygen -A 2>/dev/null || true"

    # 配置 sshd
    dexec "sed -i 's/^#*Port .*/Port $SSH_PORT/' /etc/ssh/sshd_config"
    dexec "sed -i 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config"
    dexec "sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config"

    # 设置 root 密码
    if [ -n "$ROOT_PASSWORD" ]; then
        dexec "echo 'root:$ROOT_PASSWORD' | chpasswd"
    fi

    # 启动 sshd
    dexec "mkdir -p /run/sshd && /usr/sbin/sshd 2>/dev/null || systemctl start sshd 2>/dev/null || true"

    echo "SSH 已配置，端口: $SSH_PORT"
fi

# ========== 配置代理 ==========
if [ -n "$PROXY_URL" ]; then
    echo "配置容器内代理: $PROXY_URL"
    dexec "cat >> /root/.bashrc << 'PROXY_EOF'

# HTTP/HTTPS 代理配置
export http_proxy=$PROXY_URL
export https_proxy=$PROXY_URL
export HTTP_PROXY=$PROXY_URL
export HTTPS_PROXY=$PROXY_URL
export no_proxy=localhost,127.0.0.1
export NO_PROXY=localhost,127.0.0.1
PROXY_EOF"
    echo "代理已持久化到 ~/.bashrc"
fi

# ========== 配置 conda 环境 ==========
# 自动检测容器内 conda 路径（排除 pkgs 缓存目录）
CONDA_SH=$(docker exec "$CONTAINER_NAME" bash -c "find /opt /root /home -path '*/pkgs/*' -prune -o -path '*/etc/profile.d/conda.sh' -print 2>/dev/null | head -1")
if [ -z "$CONDA_SH" ]; then
    echo "警告: 未检测到 conda，跳过 conda 配置"
else
    echo "检测到 conda: $CONDA_SH"
fi

if [ -n "$TORCH_VERSION" ] && [ -n "$CONDA_SH" ]; then
    echo "配置 conda 环境（torch ${TORCH_VERSION}）..."

    # 确定源环境名
    case "$TORCH_VERSION" in
        2.1.0) SRC_ENV="torch2.1.0_py38" ;;
        2.6.0) SRC_ENV="torch2.6.0_py310" ;;
        2.7.1) SRC_ENV="torch2.7.1_py310" ;;
        *)     echo "警告: 未知 torch 版本 $TORCH_VERSION，跳过 conda 配置" >&2; SRC_ENV="" ;;
    esac

    if [ -n "$SRC_ENV" ] && [ -n "$CONDA_NAME" ]; then
        # rename 环境: 先 clone 再删除原环境（兼容性更好）
        echo "重命名 conda 环境: $SRC_ENV → $CONDA_NAME"
        dexec "source $CONDA_SH && conda create -n $CONDA_NAME --clone $SRC_ENV -y && conda remove -n $SRC_ENV --all -y"

        # 设为默认激活环境
        dexec "echo 'conda activate $CONDA_NAME' >> /root/.bashrc"
        echo "conda 环境 $CONDA_NAME 已设为默认"
    elif [ -n "$SRC_ENV" ]; then
        # 未指定自定义名，直接激活原环境
        dexec "echo 'conda activate $SRC_ENV' >> /root/.bashrc"
        echo "conda 环境 $SRC_ENV 已设为默认"
    fi
fi

# ========== 打印环境信息 ==========
echo ""
echo "=========================================="
echo "  DrivingSDK 容器环境信息"
echo "=========================================="

# 确定要激活的环境
if [ -n "$CONDA_NAME" ]; then
    ACTIVATE_ENV="$CONDA_NAME"
elif [ -n "$TORCH_VERSION" ]; then
    case "$TORCH_VERSION" in
        2.1.0) ACTIVATE_ENV="torch2.1.0_py38" ;;
        2.6.0) ACTIVATE_ENV="torch2.6.0_py310" ;;
        2.7.1) ACTIVATE_ENV="torch2.7.1_py310" ;;
        *)     ACTIVATE_ENV="" ;;
    esac
else
    ACTIVATE_ENV=""
fi

# CANN 版本
echo ""
echo "--- CANN ---"
dexec "cat /usr/local/Ascend/ascend-toolkit/latest/version.cfg 2>/dev/null \
    || cat /usr/local/Ascend/ascend-toolkit/latest/version.info 2>/dev/null \
    || find /usr/local/Ascend -maxdepth 3 -name 'version.info' -path '*/compiler/*' -exec grep 'Version=' {} \; 2>/dev/null \
    || echo '未找到 CANN'"

# conda 环境列表
echo ""
echo "--- Conda 环境 ---"
if [ -n "$CONDA_SH" ]; then
    dexec "source $CONDA_SH && conda env list"
else
    echo "未检测到 conda"
fi

# torch / torch_npu / mx_driving 版本
if [ -n "$ACTIVATE_ENV" ] && [ -n "$CONDA_SH" ]; then
    echo ""
    echo "--- 当前环境: $ACTIVATE_ENV ---"
    dexec "source $CONDA_SH && conda activate $ACTIVATE_ENV && python -c \"
import torch; print(f'torch: {torch.__version__}')
try:
    import torch_npu; print(f'torch_npu: {torch_npu.__version__}')
except: print('torch_npu: 未安装')
try:
    import mx_driving; print(f'mx_driving: {mx_driving.__version__}')
except: print('mx_driving: 未安装')
\""
fi

# SSH 连接信息
if [ -n "$SSH_PORT" ]; then
    HOSTNAME=$(hostname -I 2>/dev/null | awk '{print $1}' || hostname)
    echo ""
    echo "--- SSH 连接 ---"
    echo "ssh root@${HOSTNAME} -p ${SSH_PORT}"
    echo ""
    echo "VSCode Remote SSH 配置:"
    echo "  Host drivingsdk-${CONTAINER_NAME}"
    echo "      HostName ${HOSTNAME}"
    echo "      Port ${SSH_PORT}"
    echo "      User root"
fi

# 代理信息
if [ -n "$PROXY_URL" ]; then
    echo ""
    echo "--- 代理 ---"
    echo "http_proxy=$PROXY_URL"
    echo "代理已持久化到容器 ~/.bashrc"
fi

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo "进入容器: docker exec -it $CONTAINER_NAME bash"
