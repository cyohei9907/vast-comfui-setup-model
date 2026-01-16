#!/usr/bin/env bash
set -euo pipefail

# Setup logging
LOG_FILE="/workspace/setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LTX-2 ComfyUI Setup - Main Installer"
echo "============================================================"
echo "Log file: $LOG_FILE"
echo ""

# Configuration
REPO_URL="https://github.com/cyohei9907/vast-comfui-setup-model.git"
INSTALL_DIR="/workspace/shell"
REPO_DIR="$INSTALL_DIR/vast-comfui-setup-model"

# Check if git is installed
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for git..."
if ! command -v git &> /dev/null; then
    echo "[ERROR] Git is not installed. Please install git first."
    exit 1
fi
echo "[OK] Git found: $(which git)"
echo ""

# Create installation directory if it doesn't exist
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating installation directory..."
mkdir -p "$INSTALL_DIR"
echo "[OK] Directory created: $INSTALL_DIR"
echo ""

# Clone or update repository
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setting up repository..."
if [ -d "$REPO_DIR" ]; then
    echo "[INFO] Repository already exists at $REPO_DIR. Updating..."
    cd "$REPO_DIR"
    git pull
    echo "[OK] Repository updated"
else
    echo "[INFO] Cloning repository from $REPO_URL..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    echo "[OK] Repository cloned"
fi
echo ""

echo "============================================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Model Download and Setup"
echo "============================================================"
echo ""

# Fix line endings for Linux (in case downloaded from Windows)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Preparing generate.sh..."
sed -i 's/\r$//' generate.sh 2>/dev/null || true
chmod +x generate.sh
echo "[OK] Script prepared"
echo ""

# Execute the download and setup script
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing generate.sh..."
echo "============================================================"
echo ""
bash generate.sh

echo ""
echo "============================================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setup completed successfully!"
echo "============================================================"
echo "Full log available at: $LOG_FILE"
echo ""
