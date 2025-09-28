# Ollama Server Model Status

## Container Status
- **Container**: ollama-server (running)
- **API Endpoint**: http://localhost:11434
- **GPU Configuration**: 6 GPUs (4x P4000 8GB, 2x P2000 5GB) = 42GB total VRAM

## Available Models

### Currently Loaded
| Model | Size | Status | Notes |
|-------|------|--------|-------|
| mixtral:8x7b-instruct-v0.1-q4_K_M | 28 GB | ✅ Ready | Tested successfully, excellent quality |
| llama3.1:8b-instruct-fp16 | 16 GB | ⏳ Downloading (90%) | Full precision, high quality |

### Recommended Models to Try

#### Large Models (Best quality/size trade-off for 42GB VRAM)
1. **DeepSeek Coder 33B Q6_K** (~27GB) - Specialized for code
   ```bash
   docker exec ollama-server ollama pull deepseek-coder:33b-instruct-q6_K
   ```

2. **Llama 3.1 70B Q2_K** (~28GB) - Latest Meta model
   ```bash
   docker exec ollama-server ollama pull llama3.1:70b-instruct-q2_K
   ```

3. **Qwen 2.5 72B Q2_K** (~30GB) - Strong multilingual
   ```bash
   docker exec ollama-server ollama pull qwen2.5:72b-instruct-q2_K
   ```

## Quick Usage

### Interactive Chat
```bash
docker exec -it ollama-server ollama run mixtral:8x7b-instruct-v0.1-q4_K_M
```

### API Call
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mixtral:8x7b-instruct-v0.1-q4_K_M",
    "prompt": "Your prompt here",
    "stream": false
  }'
```

### Check GPU Usage
```bash
nvidia-smi
```

### List Available Models
```bash
docker exec ollama-server ollama list
```

## Performance Notes
- Mixtral model uses ~28GB distributed across all 6 GPUs
- Response time: ~2s for simple prompts, ~17s total including model loading
- Network download speeds: 100-120 MB/s observed

## Next Steps
1. ✅ Mixtral 8x7B model ready for use
2. ⏳ Llama 3.1 8B downloading (for comparison)
3. Consider DeepSeek Coder for code-specific tasks
4. vLLM setup available if OpenAI-compatible API needed