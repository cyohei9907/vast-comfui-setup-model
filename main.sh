#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "LTX-2 ComfyUI Setup - Main Installer"
echo "============================================================"

# Configuration
REPO_URL="https://github.com/cyohei9907/vast-comfui-setup-model.git"
INSTALL_DIR="/workspace/shell"
REPO_DIR="$INSTALL_DIR/vast-comfui-setup-model"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "[ERROR] Git is not installed. Please install git first."
    exit 1
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Clone or update repository
if [ -d "$REPO_DIR" ]; then
    echo "[INFO] Repository already exists at $REPO_DIR. Updating..."
    cd "$REPO_DIR"
    git pull
else
    echo "[INFO] Cloning repository to $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

echo ""
echo "============================================================"
echo "Starting Model Download and Setup"
echo "============================================================"

# Fix line endings for Linux (in case downloaded from Windows)
sed -i 's/\r$//' generate.sh 2>/dev/null || true

# Make script executable
chmod +x generate.sh

# Execute the download and setup script
bash generate.sh

echo ""
echo "============================================================"
echo "Setup completed successfully!"
echo "============================================================"
