#!/usr/bin/env bash
set -euo pipefail

# -------- config --------
BASE_DIR="/workspace/ComfyUI/models"

# Use curl for robust download
# -L follow redirects
# -C - resume
# --retry retry on failure
# --retry-all-errors: retry on transient errors
CURL_OPTS=(-L -C - --retry 5 --retry-delay 2 --retry-all-errors)

download() {
  local url="$1"
  local dest="$2"

  local dir
  dir="$(dirname "$dest")"
  mkdir -p "$dir"

  echo "============================================================"
  echo "[DOWNLOADING]"
  echo "URL : $url"
  echo "DEST: $dest"
  echo "------------------------------------------------------------"

  curl "${CURL_OPTS[@]}" -o "$dest" "$url"

  if [[ ! -s "$dest" ]]; then
    echo "[ERROR] Download failed or file is empty: $dest" >&2
    exit 1
  fi

  echo "[OK] Downloaded: $(ls -lh "$dest")"
}

# -------- downloads --------

# 1) checkpoint
download \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors" \
  "$BASE_DIR/checkpoints/ltx-2-19b-dev-fp8.safetensors"

# 2) text encoder
download \
  "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors" \
  "$BASE_DIR/text_encoders/gemma_3_12B_it.safetensors"

# 3) latent upscaler
download \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
  "$BASE_DIR/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors"

# 4) lora distilled
download \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors" \
  "$BASE_DIR/loras/ltx-2-19b-distilled-lora-384.safetensors"

# 5) lora camera control dolly left
download \
  "https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors" \
  "$BASE_DIR/loras/ltx-2-19b-lora-camera-control-dolly-left.safetensors"

# 6) Move workflow file
WORKFLOW_SRC="./workflow/video_ltx2_i2v.json"
WORKFLOW_DEST="/workspace/ComfyUI/user/default/workflows/video_ltx2_i2v.json"

if [[ -f "$WORKFLOW_SRC" ]]; then
  echo "============================================================"
  echo "[MOVING WORKFLOW]"
  echo "FROM: $WORKFLOW_SRC"
  echo "TO  : $WORKFLOW_DEST"
  echo "------------------------------------------------------------"
  
  mkdir -p "$(dirname "$WORKFLOW_DEST")"
  cp "$WORKFLOW_SRC" "$WORKFLOW_DEST"
  
  echo "[OK] Workflow moved successfully."
else
  echo "[WARNING] Workflow file not found: $WORKFLOW_SRC" >&2
fi

echo "============================================================"
echo "[ALL DONE] LTX-2 models downloaded successfully."
echo "Check folders:"
echo "  - $BASE_DIR/checkpoints"
echo "  - $BASE_DIR/text_encoders"
echo "  - $BASE_DIR/latent_upscale_models"
echo "  - $BASE_DIR/loras"
echo "  - $WORKFLOW_DEST"
