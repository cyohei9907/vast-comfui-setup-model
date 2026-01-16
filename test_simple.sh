#!/usr/bin/env bash
set -euo pipefail

MODEL_FILE="/workspace/shell/vast-comfui-setup-model/model.yaml"

echo "============================================================"
echo "Testing YAML parsing"
echo "============================================================"

# Count models
total_models=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  
  if [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*\[(.*)\][[:space:]]*$ ]]; then
    urls="${BASH_REMATCH[2]}"
    urls="${urls//\'/}"; urls="${urls//\"/}"
    IFS=',' read -ra URL_ARRAY <<< "$urls"
    for url in "${URL_ARRAY[@]}"; do
      url="$(echo "$url" | xargs)"
      [[ -n "$url" ]] && ((total_models++)) && echo "Found URL: $url"
    done
  fi
done < "$MODEL_FILE"

echo ""
echo "Total models found: $total_models"
echo "Test completed!"
