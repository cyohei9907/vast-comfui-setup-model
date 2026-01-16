#!/usr/bin/env bash
set -x  # Enable debug mode
set -euo pipefail

# -------- config --------
BASE_DIR="/workspace/ComfyUI/models"
COMFYUI_DIR="/workspace/ComfyUI"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_FILE="$SCRIPT_DIR/model.yaml"

# Global arrays for tracking
enabled_workflows=()
global_nodes=()
global_pip_packages=()

# Minimal parse function for debugging
parse_and_download() {
  if [[ ! -f "$MODEL_FILE" ]]; then
    echo "[ERROR] Model file not found: $MODEL_FILE" >&2
    exit 1
  fi

  echo "[INFO] Parsing model file: $MODEL_FILE"
  
  # First pass: count total items
  echo "[INFO] Scanning configuration to count total items..."
  local total_models=0
  local temp_in_workflow=false
  
  echo "[DEBUG] Starting while loop to read file..."
  while IFS= read -r line; do
    echo "[DEBUG] Processing line: $line"
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*#.*: ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Check for global_nodes
    if [[ "$line" =~ ^global_nodes:[[:space:]]*\[(.*)\] ]]; then
      echo "[DEBUG] Found global_nodes line"
      local items="${BASH_REMATCH[1]}"
      items="${items//\'/}"; items="${items//\"/}"
      echo "[DEBUG] Items before split: $items"
      local old_ifs="$IFS"
      IFS=',' read -ra ITEMS <<< "$items"
      IFS="$old_ifs"
      echo "[DEBUG] Number of items in ITEMS array: ${#ITEMS[@]}"
      for item in "${ITEMS[@]}"; do
        item="$(echo "$item" | xargs)"
        if [[ -n "$item" ]]; then
          global_nodes+=("$item")
          echo "[DEBUG] Added node: $item"
        fi
      done
    fi
  done < "$MODEL_FILE"
  
  echo "[INFO] Found: $total_models model(s), ${#global_nodes[@]} node(s), ${#global_pip_packages[@]} package(s)"
}

# -------- Main execution --------
echo "============================================================"
echo "ComfyUI Model & Workflow Setup (DEBUG MODE)"
echo "============================================================"

parse_and_download

echo "[DEBUG] Script completed successfully!"
