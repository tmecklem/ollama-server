#!/bin/bash

set -e

# Create models directory
mkdir -p models/cache

# Function to download model from Hugging Face
download_model() {
    local model_id=$1
    local model_dir=$2
    echo "Downloading $model_id..."
    
    # Use git lfs to clone the model
    cd models
    if [ ! -d "$model_dir" ]; then
        git clone https://huggingface.co/$model_id $model_dir
    else
        echo "Model $model_dir already exists, skipping download"
    fi
    cd ..
}

# Function to test model with vLLM
test_model() {
    local model_path=$1
    local model_name=$2
    
    echo "Testing $model_name..."
    
    # Start vLLM with the specific model
    docker run -d \
        --name vllm-test \
        --gpus all \
        -v $(pwd)/models:/models \
        -p 8000:8000 \
        vllm-server \
        python3 -m vllm.entrypoints.openai.api_server \
        --model /models/$model_path \
        --host 0.0.0.0 \
        --port 8000 \
        --tensor-parallel-size 6 \
        --gpu-memory-utilization 0.90 \
        --max-model-len 4096 \
        --dtype auto \
        --quantization awq
    
    # Wait for server to be ready
    echo "Waiting for vLLM server to start..."
    sleep 60
    
    # Test the model
    curl -X POST http://localhost:8000/v1/completions \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model_path\",
            \"prompt\": \"Hello, please write a short poem about GPUs:\",
            \"max_tokens\": 100,
            \"temperature\": 0.7
        }" | python3 -m json.tool
    
    # Stop and remove container
    docker stop vllm-test
    docker rm vllm-test
    
    echo "Test completed for $model_name"
    echo "-----------------------------------"
    sleep 5
}

# Install git-lfs if not already installed
if ! command -v git-lfs &> /dev/null; then
    echo "Installing git-lfs..."
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt-get install git-lfs
    git lfs install
fi

# Build the Docker image
echo "Building vLLM Docker image..."
docker build -f Dockerfile.vllm -t vllm-server .

# Download and test each model
echo "Starting model downloads and tests..."

# 1. Mixtral 8x7B AWQ
download_model "casperhansen/mixtral-instruct-awq" "mixtral-8x7b-awq"
test_model "mixtral-8x7b-awq" "Mixtral 8x7B AWQ"

# 2. Llama 3.1 70B AWQ (quantized version)
download_model "hugging-quants/Meta-Llama-3.1-70B-Instruct-AWQ-INT4" "llama3.1-70b-awq"
test_model "llama3.1-70b-awq" "Llama 3.1 70B AWQ"

# 3. Qwen 2.5 72B GPTQ
download_model "Qwen/Qwen2.5-72B-Instruct-GPTQ-Int4" "qwen2.5-72b-gptq"
test_model "qwen2.5-72b-gptq" "Qwen 2.5 72B GPTQ"

# 4. DeepSeek Coder 33B 
download_model "deepseek-ai/deepseek-coder-33b-instruct" "deepseek-coder-33b"
test_model "deepseek-coder-33b" "DeepSeek Coder 33B"

echo "All models have been downloaded and tested!"