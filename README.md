# ComfyUI LTX-2 Model Setup Script

Automated setup script for downloading LTX-2 models and configuring ComfyUI workflows.

## 📋 Features

- **Automatic Model Download**: Downloads all required LTX-2 models from HuggingFace
- **Workflow Integration**: Automatically installs the i2v workflow to ComfyUI
- **Resume Support**: Uses curl with resume capability for interrupted downloads
- **Error Handling**: Validates downloads and provides clear error messages

## 📦 Downloaded Models

This script downloads the following models:

1. **Checkpoint** - `ltx-2-19b-dev-fp8.safetensors` (19.8 GB)
2. **Text Encoder** - `gemma_3_12B_it.safetensors` (24.2 GB)
3. **Latent Upscaler** - `ltx-2-spatial-upscaler-x2-1.0.safetensors`
4. **LoRA Distilled** - `ltx-2-19b-distilled-lora-384.safetensors`
5. **LoRA Camera Control** - `ltx-2-19b-lora-camera-control-dolly-left.safetensors`

## 🚀 Quick Start

### For Vast.ai / Cloud GPU Platforms

The script runs automatically when you set the provisioning URL in Vast.ai:

```
Provisioning Script URL:
https://raw.githubusercontent.com/cyohei9907/vast-comfui-setup-model/refs/heads/main/main.sh
```

**查看安装日志：**

```bash
# SSH 连接到容器后，查看实时日志
tail -f /workspace/setup.log

# 或查看完整日志
cat /workspace/setup.log

# 查看下载进度
grep "DOWNLOADING" /workspace/setup.log | tail -n 20
```

### For Manual Installation (Linux)

```bash
# 1. Clone the repository
git clone https://github.com/cyohei9907/vast-comfui-setup-model.git
cd vast-comfui-setup-model

# 2. Fix line endings (important!)
sed -i 's/\r$//' *.sh

# 3. Make scripts executable
chmod +x *.sh

# 4. Run setup
./main.sh
```

### Alternative: One-line Installation

```bash
curl -sSL https://raw.githubusercontent.com/cyohei9907/vast-comfui-setup-model/main/main.sh | bash
```

## 📁 Installation Paths

Models will be installed to:
```
/workspace/ComfyUI/models/
├── checkpoints/
├── text_encoders/
├── latent_upscale_models/
└── loras/
```

Workflow will be installed to:
```
/workspace/ComfyUI/user/default/workflows/video_ltx2_i2v.json
```

## ⚙️ Requirements

- **Bash** shell environment
- **curl** command-line tool
- **~50+ GB** free disk space
- **Internet connection** to HuggingFace

## 🛠️ Troubleshooting

### 查看安装日志

所有日志都保存在 `/workspace/setup.log`：

```bash
# 实时查看安装进度
tail -f /workspace/setup.log

# 查看下载进度 [已下载/总数]
grep "\[.*/.* \[DOWNLOADING\]" /workspace/setup.log

# 检查错误
grep "ERROR" /workspace/setup.log

# 查看已下载的模型
ls -lh /workspace/ComfyUI/models/*/*.safetensors
```

### Line Ending Issues

If you see errors like `invalid option name pipefail`:

```bash
# Convert Windows line endings to Unix
cd /workspace/shell/vast-comfui-setup-model
sed -i 's/\r$//' *.sh
chmod +x *.sh
bash main.sh
```

### 手动运行脚本

如果自动provisioning没有执行：

```bash
cd /workspace/shell/vast-comfui-setup-model
bash main.sh
```

### Download Interrupted

The script uses curl with resume support. Simply run it again:

```bash
cd /workspace/shell/vast-comfui-setup-model
bash generate.sh
```

### 检查安装进度

```bash
# 查看正在运行的进程
ps aux | grep -E "(main.sh|generate.sh|curl)"

# 查看最新下载的文件（实时更新）
watch -n 5 'ls -lht /workspace/ComfyUI/models/*/*.safetensors | head -n 10'

# 检查磁盘空间
df -h /workspace
```

更多详细的故障排查，请查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Disk Space

Check available space before running:

```bash
df -h /workspace
```

## 📝 File Structure

```
vast-comfui-setup-model/
├── main.sh                      # Main entry point
├── create_video_ltx2_i2v.sh    # Download and setup script
├── workflow/
│   └── video_ltx2_i2v.json     # ComfyUI workflow file
└── README.md                    # This file
```

## 🔗 Links

- [LTX-2 Model on HuggingFace](https://huggingface.co/Lightricks/LTX-2)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)

## 📄 License

See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
