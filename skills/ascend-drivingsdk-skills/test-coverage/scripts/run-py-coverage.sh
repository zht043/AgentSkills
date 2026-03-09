#!/usr/bin/env bash
# run-py-coverage.sh — Python 覆盖率收集
# 用法: bash run-py-coverage.sh [--test-dir DIR] [--source PKG] [--format html|xml] [--exclude PATTERN] [--sub-dirs d1,d2]
# 依赖: python3, coverage (pip)
# 返回: 0=全部通过, 1=有测试失败（覆盖率报告仍会生成）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SUITE_DIR/_lib/coverage-common.sh"

# 默认值
TEST_DIR=""
SOURCE=""
FORMAT=""
EXCLUDE_PATTERN=""
SUB_DIRS=""

# 解析参数
while [ $# -gt 0 ]; do
    case "$1" in
        --test-dir)  TEST_DIR="$2"; shift 2 ;;
        --source)    SOURCE="$2"; shift 2 ;;
        --format)    FORMAT="$2"; shift 2 ;;
        --exclude)   EXCLUDE_PATTERN="$2"; shift 2 ;;
        --sub-dirs)  SUB_DIRS="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,4p' "$0" | sed 's/^# *//'
            exit 0 ;;
        *) echo "未知参数: $1" >&2; exit 1 ;;
    esac
done

# 从 config.yaml 回退
[ -z "$TEST_DIR" ] && TEST_DIR=$(resolve_project_root)/tests
[ -z "$SOURCE" ] && SOURCE=$(read_config_value "source" 2>/dev/null || echo "mx_driving")
[ -z "$FORMAT" ] && FORMAT=$(read_config_value "format" 2>/dev/null || echo "html")
[ -z "$SUB_DIRS" ] && SUB_DIRS="torch,patcher"

ensure_tool python3 "请安装 Python 3" || ensure_tool python "请安装 Python 3"
PYTHON=$(command -v python3 2>/dev/null || command -v python)

echo "=== Python 覆盖率收集 ==="
echo "测试目录: ${TEST_DIR}"
echo "被测包: ${SOURCE}"
echo "输出格式: ${FORMAT}"

# 清理旧数据
$PYTHON -m coverage erase 2>/dev/null || true

# 发现测试文件
TESTS=()
IFS=',' read -ra DIRS <<< "$SUB_DIRS"
for d in "${DIRS[@]}"; do
    sub_path="${TEST_DIR}/${d}"
    [ -d "$sub_path" ] || continue
    while IFS= read -r f; do
        # 排除检查
        if [ -n "$EXCLUDE_PATTERN" ] && echo "$f" | grep -qE "$EXCLUDE_PATTERN"; then
            continue
        fi
        TESTS+=("$f")
    done < <(find "$sub_path" -name "test_*.py" -type f | sort)
done

echo "发现 ${#TESTS[@]} 个测试文件"
echo ""

# 执行测试
PASSED=0
FAILED=0
FAILED_LIST=()

for test_file in "${TESTS[@]}"; do
    rel_path="${test_file#$TEST_DIR/}"
    echo ">>> 执行 ${rel_path} ..."

    if $PYTHON -m coverage run -p --source="$SOURCE" --branch "$test_file" 2>&1; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_LIST+=("$rel_path")
        echo "<<< 失败: ${rel_path}"
    fi
done

# 合并覆盖率数据
echo ""
echo ">>> 合并覆盖率数据..."
$PYTHON -m coverage combine
$PYTHON -m coverage report -i

# 生成报告
if [ "$FORMAT" = "xml" ]; then
    $PYTHON -m coverage xml
    echo "XML 报告已生成: coverage.xml"
else
    $PYTHON -m coverage html
    echo "HTML 报告已生成: htmlcov/index.html"
fi

# 输出摘要
echo ""
echo "=========================================="
echo "通过: ${PASSED}  失败: ${FAILED}  总计: ${#TESTS[@]}"
if [ ${FAILED} -gt 0 ]; then
    echo ""
    echo "失败的测试:"
    for f in "${FAILED_LIST[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
echo "全部通过"
