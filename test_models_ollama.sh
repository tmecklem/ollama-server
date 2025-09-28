#!/bin/bash

set -e

# Build and start Ollama Docker container
echo "Building Ollama Docker image..."
docker build -f Dockerfile.ollama -t ollama-server .

echo "Starting Ollama server..."
docker run -d \
    --name ollama-server \
    --gpus all \
    -p 11434:11434 \
    -v ollama_data:/root/.ollama \
    ollama-server

# Wait for server to be ready
echo "Waiting for Ollama server to start..."
sleep 10

# Function to download and test a model
test_model() {
    local model=$1
    local description=$2
    
    echo ""
    echo "====================================="
    echo "Testing: $description"
    echo "Model: $model"
    echo "====================================="
    
    # Pull the model
    echo "Downloading model..."
    docker exec ollama-server ollama pull $model
    
    # Test the model
    echo "Testing model..."
    curl -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"prompt\": \"Write a haiku about GPUs:\",
            \"stream\": false
        }" | python3 -m json.tool
    
    echo "Test completed for $description"
    echo ""
}

# Models optimized for 42GB total VRAM setup
echo "Starting model tests..."

# 1. Mixtral 8x7B - Quantized (26GB)
test_model "mixtral:8x7b-instruct-v0.1-q4_K_M" "Mixtral 8x7B Q4_K_M (26GB)"

# 2. Llama 3.1 70B - Heavily Quantized (28GB)
test_model "llama3.1:70b-instruct-q2_K" "Llama 3.1 70B Q2_K (28GB)"

# 3. Qwen 2.5 72B - Quantized (30GB)
test_model "qwen2.5:72b-instruct-q2_K" "Qwen 2.5 72B Q2_K (30GB)"

# 4. DeepSeek Coder 33B - Higher quality quantization (27GB)
test_model "deepseek-coder:33b-instruct-q6_K" "DeepSeek Coder 33B Q6_K (27GB)"

# 5. Alternative: Llama 3.1 8B Full Precision (16GB) for comparison
test_model "llama3.1:8b-instruct-fp16" "Llama 3.1 8B FP16 (16GB)"

echo "All models have been tested!"
echo ""
echo "To interact with a model, use:"
echo "docker exec -it ollama-server ollama run <model-name>"