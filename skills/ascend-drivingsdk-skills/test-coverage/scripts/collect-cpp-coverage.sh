#!/usr/bin/env bash
# collect-cpp-coverage.sh — C++ 覆盖率收集（lcov/gcov）
# 用法: bash collect-cpp-coverage.sh [--project-root DIR] [--output-dir DIR] [--exclude PATTERN]
# 依赖: lcov >= 2.0, gcov
# 返回: 0=成功, 1=无覆盖率数据

# 自动修复 Windows 换行符
if grep -qP '\r$' "$0" 2>/dev/null; then
    sed -i 's/\r$//' "$0"
    exec bash "$0" "$@"
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SKILL_DIR/_lib/coverage-common.sh"

# 默认值
PROJECT_ROOT=""
OUTPUT_DIR=""
EXCLUDE_ARGS=""

# 解析参数
while [ $# -gt 0 ]; do
    case "$1" in
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        --output-dir)   OUTPUT_DIR="$2"; shift 2 ;;
        --exclude)      EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude '$2'"; shift 2 ;;
        -h|--help)
            sed -n '2,4p' "$0" | sed 's/^# *//'
            exit 0 ;;
        *) echo "未知参数: $1" >&2; exit 1 ;;
    esac
done

# 回退到 config.yaml 或自动检测
[ -z "$PROJECT_ROOT" ] && PROJECT_ROOT=$(read_config_value "project_root" 2>/dev/null || true)
[ -z "$PROJECT_ROOT" ] && PROJECT_ROOT=$(resolve_project_root)
[ -z "$OUTPUT_DIR" ] && OUTPUT_DIR=$(read_config_value "output_dir" 2>/dev/null || echo "cpp_lcov_result")
OUTPUT_DIR="${PROJECT_ROOT}/${OUTPUT_DIR}"

# 默认排除
if [ -z "$EXCLUDE_ARGS" ]; then
    EXCLUDE_ARGS="--exclude '**/include/**'"
fi

ensure_tool lcov "请安装 lcov >= 2.0"

INFO_FILE="${PROJECT_ROOT}/test.info"

echo "=== C++ 覆盖率收集 ==="
echo "项目根目录: ${PROJECT_ROOT}"
echo "输出目录: ${OUTPUT_DIR}"

# 收集覆盖率数据（lcov 2.x 兼容）
echo ">>> 收集 gcov 数据..."
eval lcov --rc branch_coverage=1 -c -o "$INFO_FILE" -d "$PROJECT_ROOT" --no-external \
     $EXCLUDE_ARGS \
     --ignore-errors inconsistent,unused,mismatch

if [ ! -f "$INFO_FILE" ]; then
    echo "错误: ${INFO_FILE} 未生成。请确认项目以 COVERAGE=ON 构建并已执行测试" >&2
    exit 1
fi

# 生成 HTML 报告
echo ">>> 生成 HTML 报告..."
genhtml --rc branch_coverage=1 "$INFO_FILE" -o "$OUTPUT_DIR" \
        --ignore-errors inconsistent,mismatch

echo ""
echo "=== C++ 覆盖率报告已生成 ==="
echo "打开 ${OUTPUT_DIR}/index.html 查看报告"
echo ""

# 输出摘要
lcov --rc branch_coverage=1 --summary "$INFO_FILE" --ignore-errors inconsistent,mismatch
