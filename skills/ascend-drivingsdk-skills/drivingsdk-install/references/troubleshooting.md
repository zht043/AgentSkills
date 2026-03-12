# DrivingSDK 常见问题

### 编译报错 `acl_base.h: No such file or directory`
原因：torch_npu 使用 editable install 时，ACL 头文件可能未复制到 site-packages。
修复：重新用 wheel 方式安装 torch_npu，然后重新编译 DrivingSDK。

### 编译报错缺少 cmake 或 cmake 版本不满足
DrivingSDK 编译要求 cmake >=3.19.0。agent 应自动检查并安装：
```bash
pip install 'cmake>=3.19,<3.30'
```

### git clone 失败（proxy 相关）
若服务器配置了 git proxy 但代理不可用，需临时取消：
```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
# clone 完成后恢复
```

### 编译报错缺少依赖
```bash
pip install -r requirements.txt
pip install -r tests/requirements.txt 2>/dev/null
```
