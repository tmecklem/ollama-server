# Ollama GUI Access - Open WebUI

## ✅ Setup Complete!

### Access Points
- **Open WebUI (GUI)**: http://localhost:3000
- **Ollama API**: http://localhost:11434

## Available Models
1. **Mixtral 8x7B** (28GB) - Excellent general purpose
2. **Llama 3.1 8B FP16** (16GB) - High quality, faster response

## First Time Setup
1. Open http://localhost:3000 in your browser
2. Create an account (first user becomes admin)
3. The interface will automatically detect your Ollama models

## Features in Open WebUI
- **Model Management**: Download, delete, and switch between models
- **Chat Interface**: Clean, ChatGPT-like interface
- **Document Upload**: RAG support for document analysis
- **Model Settings**: Adjust temperature, context length, etc.
- **Chat History**: All conversations are saved
- **Multi-user Support**: Create multiple accounts

## Managing Models via GUI
1. Click on the model selector (top of chat)
2. Click "Manage" (wrench icon)
3. From here you can:
   - Download new models by typing model name
   - Delete existing models
   - View model details

## Quick Commands

### Check container status
```bash
docker ps | grep -E "ollama|webui"
```

### View logs
```bash
docker logs open-webui
docker logs ollama-server
```

### Restart services
```bash
docker restart open-webui
docker restart ollama-server
```

### Download new model via CLI
```bash
docker exec ollama-server ollama pull <model-name>
```

## Recommended Models to Try
- `deepseek-coder:33b-instruct-q6_K` - For coding tasks
- `llama3.1:70b-instruct-q2_K` - Larger, more capable
- `qwen2.5:72b-instruct-q2_K` - Multilingual support

## Troubleshooting
If Open WebUI can't connect to Ollama:
1. Ensure both containers are running
2. Try accessing with: http://host.docker.internal:11434
3. Check logs: `docker logs open-webui`

## GPU Usage
Monitor GPU while using models:
```bash
watch -n 1 nvidia-smi
```

Current usage: ~44GB across both models loaded in memory