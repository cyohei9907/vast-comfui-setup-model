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
  local progress="${3:-}"  # Optional progress indicator like "[1/5]"

  local dir
  dir="$(dirname "$dest")"
  mkdir -p "$dir"

  # Check if file already exists and is not empty
  if [[ -f "$dest" && -s "$dest" ]]; then
    echo "============================================================"
    if [[ -n "$progress" ]]; then
      echo "$progress [SKIPPING] File already exists"
    else
      echo "[SKIPPING] File already exists"
    fi
    echo "FILE: $dest"
    echo "SIZE: $(ls -lh "$dest" | awk '{print $5}')"
    echo "------------------------------------------------------------"
    return 0
  fi

  echo "============================================================"
  if [[ -n "$progress" ]]; then
    echo "$progress [DOWNLOADING]"
  else
    echo "[DOWNLOADING]"
  fi
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

  echo "[OK] Downloaded: $(ls -lh "$dest" | awk '{print $5}')"
}

# Parse model.yaml and download files
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
  
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*#.*: ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Check for global_nodes
    if [[ "$line" =~ ^global_nodes:[[:space:]]*\[(.*)\] ]]; then
      local items="${BASH_REMATCH[1]}"
      items="${items//\'/}"; items="${items//\"/}"
      local old_ifs="$IFS"
      IFS=',' read -ra ITEMS <<< "$items"
      IFS="$old_ifs"
      for item in "${ITEMS[@]}"; do
        item="$(echo "$item" | xargs)"
        if [[ -n "$item" ]]; then
          global_nodes+=("$item")
        fi
      done
    # Check for global_pip_packages
    elif [[ "$line" =~ ^global_pip_packages:[[:space:]]*\[(.*)\] ]]; then
      local items="${BASH_REMATCH[1]}"
      items="${items//\'/}"; items="${items//\"/}"
      local old_ifs="$IFS"
      IFS=',' read -ra ITEMS <<< "$items"
      IFS="$old_ifs"
      for item in "${ITEMS[@]}"; do
        item="$(echo "$item" | xargs)"
        if [[ -n "$item" ]]; then
          global_pip_packages+=("$item")
        fi
      done
    # Check for workflow sections
    elif [[ "$line" =~ ^([a-zA-Z0-9_-]+):$ ]]; then
      temp_in_workflow=true
    elif [[ "$temp_in_workflow" == true ]]; then
      # Check for nodes within workflow
      if [[ "$line" =~ ^[[:space:]]+nodes:[[:space:]]*\[(.*)\] ]]; then
        local items="${BASH_REMATCH[1]}"
        items="${items//\'/}"; items="${items//\"/}"
        local old_ifs="$IFS"
        IFS=',' read -ra ITEMS <<< "$items"
        IFS="$old_ifs"
        for item in "${ITEMS[@]}"; do
          item="$(echo "$item" | xargs)"
          if [[ -n "$item" ]]; then
            # Add to global_nodes if not already present
            local found=false
            if [[ ${#global_nodes[@]} -gt 0 ]]; then
              for existing_node in "${global_nodes[@]}"; do
                [[ "$existing_node" == "$item" ]] && found=true && break
              done
            fi
            [[ "$found" == false ]] && global_nodes+=("$item")
          fi
        done
      # Check for pip_packages within workflow
      elif [[ "$line" =~ ^[[:space:]]+pip_packages:[[:space:]]*\[(.*)\] ]]; then
        local items="${BASH_REMATCH[1]}"
        items="${items//\'/}"; items="${items//\"/}"
        local old_ifs="$IFS"
        IFS=',' read -ra ITEMS <<< "$items"
        IFS="$old_ifs"
        for item in "${ITEMS[@]}"; do
          item="$(echo "$item" | xargs)"
          if [[ -n "$item" ]]; then
            # Add to global_pip_packages if not already present
            local found=false
            if [[ ${#global_pip_packages[@]} -gt 0 ]]; then
              for existing_pkg in "${global_pip_packages[@]}"; do
                [[ "$existing_pkg" == "$item" ]] && found=true && break
              done
            fi
            [[ "$found" == false ]] && global_pip_packages+=("$item")
          fi
        done
      # Count model URLs
      elif [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*\[(.*)\][[:space:]]*$ ]]; then
        local urls="${BASH_REMATCH[2]}"
        urls="${urls//\'/}"; urls="${urls//\"/}"
        local old_ifs="$IFS"
        IFS=',' read -ra URL_ARRAY <<< "$urls"
        IFS="$old_ifs"
        for url in "${URL_ARRAY[@]}"; do
          url="$(echo "$url" | xargs)"
          [[ -n "$url" ]] && ((total_models++))
        done
      elif [[ ! "$line" =~ ^[[:space:]] ]]; then
        temp_in_workflow=false
      fi
    fi
  done < "$MODEL_FILE"
  
  echo "[INFO] Found: $total_models model(s), ${#global_nodes[@]} node(s), ${#global_pip_packages[@]} package(s)"
  echo ""
  
  # Second pass: actual processing with progress counter
  local current_model=0
  local current_workflow=""
  local in_workflow=false
  enabled_workflows=()
  
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Check for commented workflow section
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
    
    # Skip global settings
    [[ "$line" =~ ^global_ ]] && continue
    
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
      # Skip nodes and pip_packages (already processed)
      if [[ "$line" =~ ^[[:space:]]+nodes: ]] || [[ "$line" =~ ^[[:space:]]+pip_packages: ]]; then
        continue
      fi
      
      # Extract category (checkpoints, text_encoders, etc.)
      if [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*\[(.*)\][[:space:]]*$ ]]; then
        local current_category="${BASH_REMATCH[1]}"
        local urls="${BASH_REMATCH[2]}"
        
        echo ""
        echo "[CATEGORY] $current_category"
        
        # Remove quotes and split by comma
        urls="${urls//\'/}"
        urls="${urls//\"/}"
        
        local old_ifs="$IFS"
        IFS=',' read -ra URL_ARRAY <<< "$urls"
        IFS="$old_ifs"
        
        for url in "${URL_ARRAY[@]}"; do
          # Trim whitespace
          url="$(echo "$url" | xargs)"
          
          if [[ -n "$url" ]]; then
            # Extract filename from URL
            filename="${url##*/}"
            dest_path="$BASE_DIR/$current_category/$filename"
            
            ((current_model++))
            download "$url" "$dest_path" "[${current_model}/${total_models}]"
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
  
  # Count total workflows
  local total_workflows=0
  for wf in "$workflow_src_dir"/*.json; do
    [[ -e "$wf" ]] && ((total_workflows++))
  done
  
  echo "[INFO] Found $total_workflows workflow file(s)"
  
  local count=0
  local skipped=0
  local current=0
  
  for workflow_file in "$workflow_src_dir"/*.json; do
    [[ -e "$workflow_file" ]] || continue
    ((current++))
    
    local filename=$(basename "$workflow_file")
    local workflow_name="${filename%.json}"
    local dest="$workflow_dest_dir/$filename"
    
    # Check if this workflow is enabled in model.yaml
    local is_enabled=false
    for enabled_wf in "${enabled_workflows[@]}"; do
      if [[ "$enabled_wf" == "$workflow_name" ]]; then
        is_enabled=true
        break
      fi
    done
    
    if [[ "$is_enabled" == true ]]; then
      echo "[${current}/${total_workflows}] [COPYING] $filename -> $dest"
      cp "$workflow_file" "$dest"
      ((count++))
    else
      echo "[${current}/${total_workflows}] [SKIPPING] $filename (commented or not in model.yaml)"
      ((skipped++))
    fi
  done
  
  echo "[OK] Installed $count workflow files, skipped $skipped"
}

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
  echo "Installing ComfyUI Custom Nodes (Total: ${#global_nodes[@]})"
  echo "============================================================"

  local custom_nodes_dir="$COMFYUI_DIR/custom_nodes"
  mkdir -p "$custom_nodes_dir"

  local current_node=0
  for repo in "${global_nodes[@]}"; do
    ((current_node++))
    
    # Extract repo name from URL
    local dir_name="${repo##*/}"
    dir_name="${dir_name%.git}"
    local node_path="$custom_nodes_dir/$dir_name"
    local requirements="$node_path/requirements.txt"
    
    if [[ -d "$node_path" ]]; then
      echo ""
      echo "[${current_node}/${#global_nodes[@]}] [UPDATE] Updating existing node: $dir_name"
      cd "$node_path" && git pull || echo "[WARNING] Failed to update $dir_name"
      
      if [[ -f "$requirements" ]]; then
        echo "[INSTALL] Installing requirements for $dir_name"
        pip install --no-cache-dir -r "$requirements" || echo "[WARNING] Failed to install requirements for $dir_name"
      fi
    else
      echo ""
      echo "[${current_node}/${#global_nodes[@]}] [CLONE] Cloning node: $repo"
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
  echo "Installing PIP Packages (Total: ${#global_pip_packages[@]})"
  echo "============================================================"

  local current_package=0
  for package in "${global_pip_packages[@]}"; do
    ((current_package++))
    echo "[${current_package}/${#global_pip_packages[@]}] [INSTALL] $package"
    pip install --no-cache-dir "$package" || echo "[WARNING] Failed to install $package"
  done

  echo "[OK] PIP package installation complete"
}

# -------- Main execution --------
echo "============================================================"
echo "ComfyUI Model & Workflow Setup"
echo "============================================================"

# Check for authentication tokens
if [[ -n "$HF_TOKEN" ]]; then
  echo "[INFO] HuggingFace token detected"
fi
if [[ -n "$CIVITAI_TOKEN" ]]; then
  echo "[INFO] Civitai token detected"
fi

# Parse and download models (also extracts nodes and packages)
parse_and_download

# Install PIP packages
install_pip_packages

# Install custom nodes
install_nodes

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
