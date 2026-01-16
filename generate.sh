#!/usr/bin/env bash
set -euo pipefail

# -------- config --------
BASE_DIR="/workspace/ComfyUI/models"
COMFYUI_DIR="/workspace/ComfyUI"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_FILE="$SCRIPT_DIR/model.yaml"

# Use curl for robust download
# -L follow redirects
# -C - resume
# --retry retry on failure
# --retry-all-errors: retry on transient errors
CURL_OPTS=(-L -C - --retry 5 --retry-delay 2 --retry-all-errors)

# Authentication tokens (can be set via environment variables)
HF_TOKEN="${HF_TOKEN:-}"
CIVITAI_TOKEN="${CIVITAI_TOKEN:-}"

# Global arrays for tracking
enabled_workflows=()
global_nodes=()
global_pip_packages=()

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

  # Add authentication header if needed
  local auth_header=""
  if [[ -n "$HF_TOKEN" && "$url" =~ huggingface\.co ]]; then
    auth_header="Authorization: Bearer $HF_TOKEN"
    echo "[AUTH] Using HuggingFace token"
  elif [[ -n "$CIVITAI_TOKEN" && "$url" =~ civitai\.com ]]; then
    auth_header="Authorization: Bearer $CIVITAI_TOKEN"
    echo "[AUTH] Using Civitai token"
  fi

  if [[ -n "$auth_header" ]]; then
    curl "${CURL_OPTS[@]}" -H "$auth_header" -o "$dest" "$url"
  else
    curl "${CURL_OPTS[@]}" -o "$dest" "$url"
  fi

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
  # Array to track enabled workflows
  enabled_workflows=()
  
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Check for commented workflow section (starts with # followed by workflow name:)
    if [[ "$line" =~ ^#[[:space:]]*([a-zA-Z0-9_-]+):$ ]]; then
      echo ""
      echo "============================================================"
      echo "SKIPPING commented workflow: ${BASH_REMATCH[1]}"
      echo "============================================================"
      in_workflow=false
      continue
    fi
    
    # Skip other comment lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Check for workflow section (ends with :)
    if [[ "$line" =~ ^([a-zA-Z0-9_-]+):$ ]]; then
      current_workflow="${BASH_REMATCH[1]}"
      enabled_workflows+=("$current_workflow")
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
  local skipped=0
  
  for workflow_file in "$workflow_src_dir"/*.json; do
    [[ -e "$workflow_file" ]] || continue
    
    local filename=$(basename "$workflow_file")
    local workflow_name="${filename%.json}"
    local dest="$workflow_dest_dir/$filename"
    
    # Check if this workflow is enabled in model.txt
    local is_enabled=false
    for enabled_wf in "${enabled_workflows[@]}"; do
      if [[ "$enabled_wf" == "$workflow_name" ]]; then
        is_enabled=true
        break
 

# -------- Install ComfyUI nodes --------
install_nodes() {
  if [[ ${#global_nodes[@]} -eq 0 ]]; then
    echo ""
    echo "============================================================"
    echo "No custom nodes to install"
    echo "============================================================"
    return
  fi

  echo ""
  echo "============================================================"
  echo "Installing ComfyUI Custom Nodes"
  echo "============================================================"

  local custom_nodes_dir="$COMFYUI_DIR/custom_nodes"
  mkdir -p "$custom_nodes_dir"

  for repo in "${global_nodes[@]}"; do
# Check for authentication tokens
if [[ -n "$HF_TOKEN" ]]; then
  echo "[INFO] HuggingFace token detected"
fi
if [[ -n "$CIVITAI_TOKEN" ]]; then
  echo "[INFO] Civitai token detected"
fi

# Install PIP packages first
parse_and_download
install_pip_packages

# Install custom nodes
install_nodes

# Download all models (already called in parse_and_download)
# Models are downloaded during parse_and_download

# Install workflow files
move_workflows

echo ""
echo "============================================================"
echo "[ALL DONE] Setup completed successfully!"
echo "============================================================"
echo "Models location: $BASE_DIR"
echo "Workflows location: /workspace/ComfyUI/user/default/workflows"
if [[ ${#global_nodes[@]} -gt 0 ]]; then
  echo "Installed ${#global_nodes[@]} custom node(s)"
fi
if [[ ${#global_pip_packages[@]} -gt 0 ]]; then
  echo "Installed ${#global_pip_packages[@]} PIP package(s)"
fi
        pip install --no-cache-dir -r "$requirements" || echo "[WARNING] Failed to install requirements for $dir_name"
      fi
    else
      echo ""
      echo "[CLONE] Cloning node: $repo"
      git clone "$repo" "$node_path" --recursive || {
        echo "[ERROR] Failed to clone $repo" >&2
        continue
      }
      
      if [[ -f "$requirements" ]]; then
        echo "[INSTALL] Installing requirements for $dir_name"
        pip install --no-cache-dir -r "$requirements" || echo "[WARNING] Failed to install requirements for $dir_name"
      fi
    fi
  done

  echo "[OK] Node installation complete"
}

# -------- Install PIP packages --------
install_pip_packages() {
  if [[ ${#global_pip_packages[@]} -eq 0 ]]; then
    echo ""
    echo "============================================================"
    echo "No additional PIP packages to install"
    echo "============================================================"
    return
  fi

  echo ""
  echo "============================================================"
  echo "Installing PIP Packages"
  echo "============================================================"

  for package in "${global_pip_packages[@]}"; do
    echo "[INSTALL] $package"
    pip install --no-cache-dir "$package" || echo "[WARNING] Failed to install $package"
  done

  echo "[OK] PIP package installation complete"
}     fi
    done
    
    if [[ "$is_enabled" == true ]]; then
      echo "[COPYING] $filename -> $dest"
      cp "$workflow_file" "$dest"
      ((count++))
    else
      echo "[SKIPPING] $filename (commented or not in model.txt)"
      ((skipped++))
    fi
  done
  
  echo "[OK] Installed $count workflow files, skipped $skipped"
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
