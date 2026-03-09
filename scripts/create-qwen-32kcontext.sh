#!/bin/bash
# Creates a Qwen3 32B model with 32k context window
# Runs inside the ollama-server Docker container

set -e

CONTAINER="ollama-server"
MODEL_NAME="qwen3:32b-ctx32k"
BASE_MODEL="qwen3:32b"
CONTEXT_SIZE=32768

echo "Creating Qwen3 32B model: $MODEL_NAME"
echo "Container: $CONTAINER"
echo "Base model: $BASE_MODEL"
echo "Context size: $CONTEXT_SIZE"
echo ""

# Create the Modelfile inside the container and build the model
docker exec "$CONTAINER" sh -c "cat > /tmp/Modelfile << 'EOF'
FROM $BASE_MODEL
PARAMETER num_ctx $CONTEXT_SIZE
PARAMETER num_gpu 99
EOF
"

echo "Created Modelfile in container"

# Create the model
echo "Building model (this may take a moment)..."
docker exec "$CONTAINER" ollama create "$MODEL_NAME" -f /tmp/Modelfile

echo ""
echo "✓ Model $MODEL_NAME created successfully!"
echo ""

# List models to verify
echo "Available models:"
docker exec "$CONTAINER" ollama list