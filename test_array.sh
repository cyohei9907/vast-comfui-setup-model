#!/usr/bin/env bash
set -euo pipefail

global_nodes=()
global_pip_packages=()

# Add some items
global_nodes+=("item1")
global_nodes+=("item2")
global_pip_packages+=("pkg1")
global_pip_packages+=("pkg2")

total_models=12

echo "Test 1: Accessing array sizes directly"
echo "Nodes: ${#global_nodes[@]}"
echo "Packages: ${#global_pip_packages[@]}"
echo "Models: $total_models"

echo ""
echo "Test 2: In echo statement like the script"
echo "[INFO] Found: $total_models model(s), ${#global_nodes[@]} node(s), ${#global_pip_packages[@]} package(s)"

echo ""
echo "All tests passed!"
