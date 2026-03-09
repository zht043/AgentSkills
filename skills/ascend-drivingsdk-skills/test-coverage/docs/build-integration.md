# 构建集成指南

将覆盖率支持集成到 C++/Python 混合项目的一次性配置步骤。

## 1. 根 CMakeLists.txt

在项目根 `CMakeLists.txt` 顶部添加 COVERAGE 选项：

```cmake
option(COVERAGE "Enable code coverage (gcov)" OFF)
```

## 2. 每个 C++ Target 的 CMakeLists.txt

对需要覆盖率的 target，添加条件编译标志：

```cmake
if(COVERAGE)
    target_compile_options(<target_name> PRIVATE -fprofile-arcs -ftest-coverage)
    target_link_options(<target_name> PRIVATE -fprofile-arcs -ftest-coverage)
    target_link_libraries(<target_name> PRIVATE gcov)
endif()
```

将 `<target_name>` 替换为实际目标名（如 `_C`、`ascend_all_ops`、`cust_optiling`）。

## 3. setup.py

在 setup.py 中检测 COVERAGE 环境变量并传递给 CMake：

```python
detect_coverage = os.environ.get('COVERAGE', 'false').lower() == 'true'

# 在 cmake_args 中添加：
coverage = "ON" if detect_coverage else "OFF"
cmake_args.append(f"-DCOVERAGE={coverage}")
```

## 4. 构建脚本

在构建入口脚本（如 `ci/build.sh`）中添加 `--coverage` 参数支持：

```bash
COVERAGE='false'

# 参数解析部分添加：
--coverage)
    COVERAGE='true'
    shift
    ;;

# 构建前 export：
export COVERAGE
```

## 5. 使用流程

```bash
# 1. 以覆盖率模式构建
bash ci/build.sh --coverage

# 2. 执行测试（测试过程产生 .gcda 文件）
python -m pytest tests/

# 3. 收集 C++ 覆盖率
bash test-coverage/scripts/collect-cpp-coverage.sh

# 4. 收集 Python 覆盖率
bash test-coverage/scripts/run-py-coverage.sh
```
