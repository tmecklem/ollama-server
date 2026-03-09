# Ollama Server Scripts

This directory contains utility scripts for managing Ollama models and GPU settings.

## Scripts

### Model Creation

#### `create-qwen-24kcontext.sh`
Creates a Qwen3 32B model with 24k context window.
- **Model**: qwen3:32b-ctx24k
- **Context**: 24,000 tokens
- **Parallel Requests**: 2 at full context

```bash
./create-qwen-24kcontext.sh
```

#### `create-qwen-32kcontext.sh`
Creates a Qwen3 32B model with native maximum 32k context window.
- **Model**: qwen3:32b-ctx32k
- **Context**: 32,768 tokens (native maximum without quality loss)
- **Parallel Requests**: 1 at full context

```bash
./create-qwen-32kcontext.sh
```

### GPU Power Management

#### `set-gpu-power-limits.sh`
Sets optimal power limits for RTX 3090 GPUs to reduce heat and extend lifespan.
- **Power Limit**: 280W per GPU (down from 350-390W stock)
- **Performance Impact**: Maintains 95% of stock performance
- **Benefits**: 20-30% power reduction, 10-15°C cooler, quieter operation

```bash
sudo ./set-gpu-power-limits.sh
```

#### `nvidia-power-limit.service`
Systemd service file for persistent GPU power limits across reboots.

To install:
```bash
# Copy service file
sudo cp nvidia-power-limit.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service at boot
sudo systemctl enable nvidia-power-limit.service

# Start service now
sudo systemctl start nvidia-power-limit.service

# Check status
sudo systemctl status nvidia-power-limit.service
```

## System Configuration

### Current Hardware
- **GPUs**: 2× NVIDIA RTX 3090 (24GB VRAM each)
- **RAM**: 62GB
- **CPU**: AMD Ryzen 9 3900X (12 cores, 24 threads)

### Model Details

#### Qwen3 32B Quantization
- **Format**: GGUF Q4_K_M (optimal quality/size ratio)
- **Size**: ~19.8GB
- **Quality**: ~2% perplexity increase vs FP16
- **Speed**: 2.5x faster inference than FP16

#### Context Window Limits
- **32k (32,768)**: Native maximum without YaRN scaling
- **Beyond 32k**: Requires YaRN rope scaling, degrades quality
- **Memory per request at 32k**: ~14GB (KV cache + activations)

### Docker Compose Settings

The parent `docker-compose.yml` is configured with:
- `OLLAMA_NUM_PARALLEL=1` (for 32k context)
- `OLLAMA_NUM_GPU=2` (dual RTX 3090s)
- `CUDA_VISIBLE_DEVICES=0,1`

## Monitoring

Check GPU status and power:
```bash
# Watch power and temperature
watch -n 1 'nvidia-smi --query-gpu=index,name,power.draw,temperature.gpu --format=csv'

# Check current power limits
nvidia-smi -q | grep -A 4 "Power Limit"

# Monitor Ollama logs
docker logs -f ollama-server
```

## Troubleshooting

### If power limits reset
Re-run the script or restart the systemd service:
```bash
sudo systemctl restart nvidia-power-limit.service
```

### If context errors occur
Verify model is using correct context:
```bash
docker exec ollama-server ollama show qwen3:32b-ctx32k --modelfile | grep num_ctx
```

### Check parallel request setting
```bash
docker exec ollama-server env | grep PARALLEL
```