#!/usr/bin/env bash
set -euo pipefail

# Script to parse all workflow JSON files and extract model URLs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$SCRIPT_DIR/workflow"
OUTPUT_FILE="$SCRIPT_DIR/model.yaml"

echo "Parsing workflow files in: $WORKFLOW_DIR"
echo "Output file: $OUTPUT_FILE"

# Clear output file
> "$OUTPUT_FILE"

# Process each JSON file
for json_file in "$WORKFLOW_DIR"/*.json; do
    [[ -e "$json_file" ]] || continue
    
    filename=$(basename "$json_file" .json)
    echo "Processing: $filename"
    
    # Extract URLs and directories using grep and sed
    urls=$(grep -oP '"url":\s*"https://[^"]+' "$json_file" | sed 's/"url":\s*"//' | sort -u)
    
    if [[ -z "$urls" ]]; then
        echo "  No URLs found in $filename"
        continue
    fi
    
    # Organize by category
    declare -A categories
    
    while IFS= read -r url; do
        # Extract filename and determine category from URL
        model_file=$(basename "$url")
        
        # Determine directory based on context in JSON
        category=""
        
        # Search for directory context around this URL
        dir_context=$(grep -B5 -A5 "\"$url\"" "$json_file" | grep -oP '"directory":\s*"\K[^"]+' | head -1)
        
        if [[ -n "$dir_context" ]]; then
            category="$dir_context"
        else
            # Fallback: guess from filename
            if [[ "$model_file" =~ safetensors$ ]]; then
                if [[ "$url" =~ lora|LoRA ]]; then
                    category="loras"
                elif [[ "$url" =~ upscal ]]; then
                    category="latent_upscale_models"
                elif [[ "$url" =~ text_encoder|gemma ]]; then
                    category="text_encoders"
                else
                    category="checkpoints"
                fi
            fi
        fi
        
        [[ -z "$category" ]] && category="unknown"
        
        # Add to category array
        if [[ -z "${categories[$category]:-}" ]]; then
            categories[$category]="$url"
        else
            categories[$category]="${categories[$category]}|$url"
        fi
        
    done <<< "$urls"
    
    # Write to output file
    echo "${filename}:" >> "$OUTPUT_FILE"
    
    for cat in "${!categories[@]}"; do
        # Convert pipe-separated URLs to array format
        IFS='|' read -ra url_array <<< "${categories[$cat]}"
        
        # Format as YAML-style list
        echo -n "  ${cat}: [" >> "$OUTPUT_FILE"
        
        first=true
        for u in "${url_array[@]}"; do
            if [[ "$first" == true ]]; then
                echo -n "'$u'" >> "$OUTPUT_FILE"
                first=false
            else
                echo -n ", '$u'" >> "$OUTPUT_FILE"
            fi
        done
        
        echo "]" >> "$OUTPUT_FILE"
    done
    
    echo "" >> "$OUTPUT_FILE"
    
    # Clear the associative array for next iteration
    unset categories
    declare -A categories
done

echo ""
echo "Model URLs extracted to: $OUTPUT_FILE"
echo "Done!"
