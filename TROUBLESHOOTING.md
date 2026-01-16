# 如何在 Vast.ai 上查看安装日志

## 方法 1: 查看日志文件

所有安装日志都会保存到 `/workspace/setup.log` 文件中。

### SSH 连接后查看：
```bash
# 实时查看日志（滚动显示）
tail -f /workspace/setup.log

# 查看完整日志
cat /workspace/setup.log

# 查看最后 100 行
tail -n 100 /workspace/setup.log

# 搜索特定内容
grep "DOWNLOADING" /workspace/setup.log
grep "ERROR" /workspace/setup.log
```

## 方法 2: 通过 Vast.ai 控制台

1. 进入你的 Vast.ai 实例页面
2. 点击 "SSH" 或 "Jupyter Terminal" 连接
3. 运行以下命令：

```bash
# 查看安装进度
tail -f /workspace/setup.log
```

## 方法 3: 检查进程状态

```bash
# 查看是否还在运行
ps aux | grep generate.sh

# 查看 ComfyUI 目录
ls -lh /workspace/ComfyUI/models/

# 查看已下载的文件数量
find /workspace/ComfyUI/models/ -type f | wc -l
```

## 方法 4: 查看 Docker 容器日志

在本地终端（如果你有访问权限）：

```bash
# 查看容器日志
vast ssh-url <instance_id>
docker logs C.30105695 2>&1 | grep -A 20 "ComfyUI Setup"
```

## 预期日志输出示例

```
============================================================
[2026-01-16 12:41:30] LTX-2 ComfyUI Setup - Main Installer
============================================================
Log file: /workspace/setup.log

[2026-01-16 12:41:30] Checking for git...
[OK] Git found: /usr/bin/git

[2026-01-16 12:41:30] Creating installation directory...
[OK] Directory created: /workspace/shell

[2026-01-16 12:41:30] Setting up repository...
[INFO] Cloning repository from https://github.com/cyohei9907/vast-comfui-setup-model.git...
[OK] Repository cloned

============================================================
[2026-01-16 12:41:35] Starting Model Download and Setup
============================================================

============================================================
ComfyUI Model & Workflow Setup
============================================================
[INFO] HuggingFace token detected
[INFO] Parsing model file: /workspace/shell/vast-comfui-setup-model/model.yaml
[INFO] Scanning configuration to count total items...
[INFO] Found: 12 model(s), 2 node(s), 2 package(s)

============================================================
Processing workflow: video_wan2_2_14B_i2v_subgraphed
============================================================

[CATEGORY] diffusion_models
============================================================
[1/12] [DOWNLOADING]
URL : https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors
DEST: /workspace/ComfyUI/models/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors
------------------------------------------------------------
[OK] Downloaded: 28.5G
...
```

## 如果没有看到日志

1. **检查脚本是否在运行：**
   ```bash
   ps aux | grep -E "(main.sh|generate.sh)"
   ```

2. **手动运行脚本：**
   ```bash
   cd /workspace/shell/vast-comfui-setup-model
   bash main.sh
   ```

3. **查看错误：**
   ```bash
   cat /workspace/setup.log | grep ERROR
   ```

4. **检查磁盘空间：**
   ```bash
   df -h /workspace
   ```

## 安装完成标志

当你看到以下消息时，说明安装完成：

```
============================================================
[ALL DONE] Setup completed successfully!
============================================================
Models location: /workspace/ComfyUI/models
Workflows location: /workspace/ComfyUI/user/default/workflows
Installed 2 custom node(s)
Installed 2 PIP package(s)
```

## 故障排查

### 问题：长时间没有输出
可能原因：正在下载大文件（某些模型文件超过 20GB）

解决方法：
```bash
# 检查网络活动
watch -n 5 'ls -lh /workspace/ComfyUI/models/*/wan2* 2>/dev/null'

# 检查进程
top | grep curl
```

### 问题：下载失败
查看具体错误：
```bash
grep -A 5 "ERROR" /workspace/setup.log
```

### 问题：空间不足
```bash
# 检查可用空间
df -h /workspace

# 查看最大的文件
du -sh /workspace/ComfyUI/models/* | sort -h
```
