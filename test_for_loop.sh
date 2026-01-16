#!/usr/bin/env bash
set -euo pipefail

echo "Test 1: Simple for loop with xargs"
urls="url1, url2, url3"
IFS=',' read -ra URL_ARRAY <<< "$urls"
echo "Array size: ${#URL_ARRAY[@]}"

total_models=0
for url in "${URL_ARRAY[@]}"; do
  echo "Processing: $url"
  url="$(echo "$url" | xargs)" || true
  echo "Trimmed: $url"
  [[ -n "$url" ]] && ((total_models++))
  echo "Count: $total_models"
done

echo "Total: $total_models"
echo ""

echo "Test 2: Nested in while loop"
total=0
while IFS= read -r line; do
  echo "Line: $line"
  if [[ "$line" =~ urls:[[:space:]]*\[(.*)\] ]]; then
    local items="${BASH_REMATCH[1]}"
    echo "Items: $items"
    IFS=',' read -ra ARR <<< "$items"
    for item in "${ARR[@]}"; do
      item="$(echo "$item" | xargs)" || true
      [[ -n "$item" ]] && ((total++))
      echo "Item count: $total"
    done
  fi
done << EOF
urls: [a, b, c]
EOF

echo "Final total: $total"
