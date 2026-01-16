#!/usr/bin/env bash
set -euo pipefail

# -------- config --------
BASE_DIR="/workspace/ComfyUI/models"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_FILE="$SCRIPT_DIR/model.txt"

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

  # Check if file already exists and is not empty
  if [[ -f "$dest" && -s "$dest" ]]; then
    echo "============================================================"
    echo "[SKIPPING] File already exists"
    echo "FILE: $dest"
    echo "SIZE: $(ls -lh "$dest" | awk '{print $5}')"
    echo "------------------------------------------------------------"
    return 0
  fi

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

# Parse model.txt and download files
parse_and_download() {
  if [[ ! -f "$MODEL_FILE" ]]; then
    echo "[ERROR] Model file not found: $MODEL_FILE" >&2
    exit 1
  fi

  echo "[INFO] Parsing model file: $MODEL_FILE"
  
  local current_workflow=""
  local in_workflow=false
  
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Check for workflow section (ends with :)
    if [[ "$line" =~ ^([a-zA-Z0-9_-]+):$ ]]; then
      current_workflow="${BASH_REMATCH[1]}"
      echo ""
      echo "============================================================"
      echo "Processing workflow: $current_workflow"
      echo "============================================================"
      in_workflow=true
      continue
    fi
    
    # Process category lines within a workflow
    if [[ "$in_workflow" == true ]]; then
      # Extract category (checkpoints, text_encoders, etc.)
      if [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*\[(.*)\][[:space:]]*$ ]]; then
        local current_category="${BASH_REMATCH[1]}"
        local urls="${BASH_REMATCH[2]}"
        
        echo ""
        echo "[CATEGORY] $current_category"
        
        # Remove quotes and split by comma
        urls="${urls//\'/}"
        urls="${urls//\"/}"
        
        IFS=',' read -ra URL_ARRAY <<< "$urls"
        
        for url in "${URL_ARRAY[@]}"; do
          # Trim whitespace
          url="$(echo "$url" | xargs)"
          
          if [[ -n "$url" ]]; then
            # Extract filename from URL
            filename="${url##*/}"
            dest_path="$BASE_DIR/$current_category/$filename"
            
            download "$url" "$dest_path"
          fi
        done
      elif [[ ! "$line" =~ ^[[:space:]] ]]; then
        # Line doesn't start with space, we've left the workflow section
        in_workflow=false
      fi
    fi
  done < "$MODEL_FILE"
}

# -------- Move workflow files --------
move_workflows() {
  echo ""
  echo "============================================================"
  echo "Installing workflow files"
  echo "============================================================"
  
  local workflow_src_dir="$SCRIPT_DIR/workflow"
  local workflow_dest_dir="/workspace/ComfyUI/user/default/workflows"
  
  mkdir -p "$workflow_dest_dir"
  
  if [[ ! -d "$workflow_src_dir" ]]; then
    echo "[WARNING] Workflow directory not found: $workflow_src_dir"
    return
  fi
  
  local count=0
  for workflow_file in "$workflow_src_dir"/*.json; do
    [[ -e "$workflow_file" ]] || continue
    
    local filename=$(basename "$workflow_file")
    local dest="$workflow_dest_dir/$filename"
    
    echo "[COPYING] $filename -> $dest"
    cp "$workflow_file" "$dest"
    ((count++))
  done
  
  echo "[OK] Installed $count workflow files"
}

# -------- Main execution --------
echo "============================================================"
echo "ComfyUI Model & Workflow Setup"
echo "============================================================"

# Download all models from model.txt
parse_and_download

# Install workflow files
move_workflows

echo ""
echo "============================================================"
echo "[ALL DONE] Setup completed successfully!"
echo "============================================================"
echo "Models location: $BASE_DIR"
echo "Workflows location: /workspace/ComfyUI/user/default/workflows"
    
    local filename=$(basename "$workflow_file")
    local dest="$workflow_dest_dir/$filename"
    
    echo "[COPYING] $filename -> $dest"
    cp "$workflow_file" "$dest"
    ((count++))
  done
  
  echo "[OK] Installed $count workflow files"
}

# -------- Main execution --------
echo "============================================================"
echo "ComfyUI Model & Workflow Setup"
echo "============================================================"

# Download all models from model.txt
parse_and_download

# Install workflow files
move_workflows

echo ""
echo "============================================================"
echo "[ALL DONE] Setup completed successfully!"
echo "============================================================"
echo "Models location: $BASE_DIR"
echo "Workflows location: /workspace/ComfyUI/user/default/workflows"
  local in_workflow=false
  
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Check if we're in the correct workflow section
    if [[ "$line" =~ ^${WORKFLOW_NAME}: ]]; then
      in_workflow=true
      continue
    fi
    
    # If we hit another workflow name, stop
    if [[ "$line" =~ ^[a-zA-Z_-]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      in_workflow=false
    fi
    
    # Only process lines within our workflow
    if [[ "$in_workflow" == true ]]; then
      # Extract category (checkpoints, text_encoders, etc.)
      if [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*\[(.*)\] ]]; then
        current_category="${BASH_REMATCH[1]}"
        local urls="${BASH_REMATCH[2]}"
        
        # Remove quotes and split by comma
        urls="${urls//\'/}"
        urls="${urls//\"/}"
        
        IFS=',' read -ra URL_ARRAY <<< "$urls"
        
        for url in "${URL_ARRAY[@]}"; do
          # Trim whitespace
          url="$(echo "$url" | xargs)"
          
          if [[ -n "$url" ]]; then
            # Extract filename from URL
            filename="${url##*/}"
            dest_path="$BASE_DIR/$current_category/$filename"
            
            download "$url" "$dest_path"
          fi
        done
      fi
    fi
  done < "$MODEL_FILE"
}

# -------- downloads --------
echo "============================================================"
echo "Starting model downloads from $MODEL_FILE"
echo "============================================================"

parse_and_download

# -------- Move workflow file --------
WORKFLOW_SRC="$SCRIPT_DIR/workflow/${WORKFLOW_NAME}.json"
WORKFLOW_DEST="/workspace/ComfyUI/user/default/workflows/${WORKFLOW_NAME}.json"

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
