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

### For Linux (Vast.ai, RunPod, etc.)

```bash
# 1. Download and extract
wget <your-release-url>/shell.tar
tar -xf shell.tar

# 2. Fix line endings (important!)
sed -i 's/\r$//' *.sh

# 3. Make scripts executable
chmod +x *.sh

# 4. Run setup
./main.sh
```

### Alternative: One-line Installation

```bash
tar -xf shell.tar && sed -i 's/\r$//' *.sh && chmod +x *.sh && ./main.sh
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

### Line Ending Issues

If you see errors like `invalid option name pipefail`:

```bash
# Convert Windows line endings to Unix
sed -i 's/\r$//' main.sh create_video_ltx2_i2v.sh
```

Or use `dos2unix`:

```bash
dos2unix *.sh
```

### Permission Denied

```bash
chmod +x main.sh create_video_ltx2_i2v.sh
```

### Download Interrupted

The script uses curl with resume support. Simply run it again:

```bash
./main.sh
```

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
