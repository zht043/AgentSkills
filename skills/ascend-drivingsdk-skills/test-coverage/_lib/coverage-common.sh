#!/usr/bin/env bash
# coverage-common.sh — 覆盖率工具共享函数
# 用法: source "$SKILL_DIR/_lib/coverage-common.sh"

# 向上查找项目根目录（含 .git 或 CMakeLists.txt）
resolve_project_root() {
    local dir="${1:-$(pwd)}"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -f "$dir/CMakeLists.txt" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "错误: 未找到项目根目录" >&2
    return 1
}

# 从 config.yaml 读取简单值（避免 yq 依赖）
# 用法: read_config_value "coverage.cpp.output_dir" [config_path]
read_config_value() {
    local key="$1"
    local config="${2:-$SKILL_DIR/config.yaml}"
    [ -f "$config" ] || return 1
    local leaf="${key##*.}"
    grep -E "^\s+${leaf}:" "$config" 2>/dev/null | head -1 | sed 's/.*:\s*//' | sed 's/\s*$//' | tr -d '"'"'"
}

# 检查必要工具是否安装
ensure_tool() {
    local tool="$1" msg="${2:-}"
    if ! command -v "$tool" &>/dev/null; then
        echo "错误: 未找到 ${tool}${msg:+, $msg}" >&2
        return 1
    fi
}

# 从 config.yaml 读取列表值（YAML - item 格式），逗号分隔输出
# 用法: read_config_list "test_dirs" [config_path]
# 示例: test_dirs: \n  - torch \n  - onnx  →  "torch,onnx"
read_config_list() {
    local key="$1"
    local config="${2:-$SKILL_DIR/config.yaml}"
    [ -f "$config" ] || return 1
    awk -v key="$key" '
        $0 ~ key":" { found=1; next }
        found && /^[[:space:]]+-[[:space:]]/ {
            val=$0; sub(/^[[:space:]]+-[[:space:]]*/, "", val)
            gsub(/["\047[:space:]]/, "", val)
            items = items ? items "," val : val
            next
        }
        found && !/^[[:space:]]*$/ { found=0 }
        END { if (items) print items }
    ' "$config"
}
