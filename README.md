# GPU Server Setup for LLMs

## GPU Configuration
- 4x Quadro P4000 (8GB VRAM each)
- 2x Quadro P2000 (5GB VRAM each)
- **Total VRAM: 42GB** (32GB + 10GB)
- Compute Capability: 6.1 (Pascal architecture)

## Model Recommendations

### Optimal Models for Your Setup (42GB total VRAM)

#### Large Models (30-40GB range):
1. **Mixtral 8x7B (Q4_K_M quantized)** - ~26GB
   - Excellent performance, mixture of experts
   - `ollama pull mixtral:8x7b-instruct-v0.1-q4_K_M`

2. **Llama 3.1 70B (Q2_K quantized)** - ~28GB
   - Latest Meta model, highly capable
   - `ollama pull llama3.1:70b-instruct-q2_K`

3. **Qwen 2.5 72B (Q2_K quantized)** - ~30GB
   - Strong multilingual and coding capabilities
   - `ollama pull qwen2.5:72b-instruct-q2_K`

4. **DeepSeek Coder 33B (Q6_K)** - ~27GB
   - Specialized for code generation
   - `ollama pull deepseek-coder:33b-instruct-q6_K`

#### Medium Models (Better speed/quality balance):
1. **Llama 3.1 8B (FP16)** - ~16GB
   - Full precision, excellent quality
   - `ollama pull llama3.1:8b-instruct-fp16`

2. **Mixtral 8x7B (Q6_K)** - ~35GB
   - Higher quality quantization
   - `ollama pull mixtral:8x7b-instruct-v0.1-q6_K`

## Quick Start

### Using Ollama (Recommended for ease of use):
```bash
# Build and start Ollama server
docker-compose up -d ollama

# Pull a model
docker exec ollama-server ollama pull mixtral:8x7b-instruct-v0.1-q4_K_M

# Test the API
curl http://localhost:11434/api/generate -d '{
  "model": "mixtral:8x7b-instruct-v0.1-q4_K_M",
  "prompt": "Hello, how are you?"
}'
```

### Using vLLM (Better for production, OpenAI-compatible API):
```bash
# Download model first
mkdir -p models
# Use huggingface-cli or git to download model to ./models/

# Start vLLM server
docker-compose up -d vllm

# Test the API
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model-name",
    "prompt": "Hello, how are you?",
    "max_tokens": 100
  }'
```

## Performance Notes
- Pascal architecture (Compute 6.1) supports INT8 operations but not bfloat16
- Tensor parallelism across 6 GPUs may have some overhead
- Consider using 4x P4000 only for better balance (32GB total)
- Monitor GPU memory usage with `nvidia-smi` during inference

## Troubleshooting
- If CUDA out of memory: reduce `--gpu-memory-utilization` or use smaller quantization
- For better performance: use only the 4x P4000 GPUs by setting `CUDA_VISIBLE_DEVICES=0,3,4,5`
- Check GPU utilization: `watch -n 1 nvidia-smi`