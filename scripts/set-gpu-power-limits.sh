#!/bin/bash
# Set power limits on RTX 3090 GPUs
# Optimal setting: 280W (maintains 95% performance while saving 70-110W per GPU)

set -e

# Check if nvidia-smi exists
command -v nvidia-smi &> /dev/null || { echo >&2 "nvidia-smi not found ... exiting."; exit 1; }

# Power limit setting (280W is optimal for RTX 3090)
POWER_LIMIT=280

echo "Setting GPU power limits to ${POWER_LIMIT}W..."

# Enable persistence mode (keeps driver loaded)
echo "Enabling persistence mode..."
nvidia-smi -pm 1

# Set power limit for both GPUs
echo "Setting power limit for GPU 0..."
nvidia-smi -i 0 -pl ${POWER_LIMIT}

echo "Setting power limit for GPU 1..."
nvidia-smi -i 1 -pl ${POWER_LIMIT}

echo ""
echo "Power limits set successfully!"
echo ""

# Display current settings
nvidia-smi --query-gpu=index,name,power.limit --format=csv