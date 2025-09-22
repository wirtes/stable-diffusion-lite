# Dockerized Stable Diffusion API

A flexible Stable Diffusion API with both CPU and GPU support, designed to work efficiently on any system.

## Features

- **Dual deployment options**: CPU-only or GPU-accelerated
- **Auto-device detection**: Automatically uses GPU when available in GPU mode
- **Optimized performance**: Device-specific optimizations for best speed
- **RESTful API** with simple JSON interface
- **Docker containerized** for easy deployment
- **Health check endpoint** with device information
- **Base64 image output** for easy integration
- **Reproducible generation** with seed support
- **Memory efficient** with attention slicing and model offloading

## Performance Comparison

| Mode | Generation Time | Image Quality | Memory Usage | Requirements |
|------|----------------|---------------|--------------|--------------|
| **CPU** | 2-5 minutes | Good | 3-4GB RAM | Any system |
| **GPU** | 5-15 seconds | Excellent | 4-6GB VRAM | NVIDIA GPU + CUDA |

## Quick Start

Choose the deployment method based on your hardware:

### 🖥️ CPU-Only Mode (Any System)

For systems without NVIDIA GPU or when you want to use CPU only:

```bash
# Build and start CPU version
docker compose -f docker-compose.cpu.yml up --build

# The API will be available at http://localhost:8080
```

### 🚀 GPU-Accelerated Mode (NVIDIA GPU Required)

For systems with NVIDIA GPU and Docker GPU support:

**Prerequisites:**
- NVIDIA GPU with CUDA support
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed
- Docker Compose with GPU support

```bash
# Build and start GPU version
docker compose -f docker-compose.gpu.yml up --build

# The API will be available at http://localhost:8080
```

### 🐳 Direct Docker Commands

**CPU Version:**
```bash
docker build -f Dockerfile.cpu -t stable-diffusion-api-cpu .
docker run -p 8080:8000 --memory=4g --cpus=2.0 stable-diffusion-api-cpu
```

**GPU Version:**
```bash
docker build -f Dockerfile.gpu -t stable-diffusion-api-gpu .
docker run --gpus all -p 8080:8000 stable-diffusion-api-gpu
```

## API Usage

### Health Check

Check API status and device information:

```bash
curl http://localhost:8080/health
```

**CPU Response:**
```json
{
  "status": "healthy",
  "device": "cpu",
  "model_loaded": true
}
```

**GPU Response:**
```json
{
  "status": "healthy",
  "device": "cuda",
  "model_loaded": true,
  "gpu_name": "NVIDIA GeForce RTX 4090",
  "gpu_memory_gb": 24.0
}
```

### Generate Image

Basic example:
```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful sunset over mountains"
  }'
```

Generate with all parameters:
```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a detailed portrait of a cat wearing a hat",
    "steps": 30,
    "width": 512,
    "height": 512,
    "guidance_scale": 8.0,
    "seed": 12345
  }' | jq -r '.image' | sed 's/data:image\/png;base64,//' | base64 -d > cat_portrait.png
```

### Saving Images with Helper Script

The included `save_image.sh` script works with both CPU and GPU modes:

```bash
# Make the script executable
chmod +x save_image.sh

# Basic usage
./save_image.sh "a cute robot"

# With custom parameters
./save_image.sh "a sunset landscape" sunset.png 30 512
```

## API Parameters

**Required:**
- `prompt` (string): Text description of the image to generate

**Optional:**
- `steps` (integer): Number of inference steps
  - **CPU default**: 20 (10-50 range)
  - **GPU default**: 30 (20-100 range)
- `guidance_scale` (float, default: 7.5): How closely to follow the prompt (1.0-20.0)
- `width` (integer, default: 512): Image width in pixels
  - **CPU max**: 512px
  - **GPU max**: 768px
- `height` (integer, default: 512): Image height in pixels
- `seed` (integer, optional): Random seed for reproducible results

## API Response

```json
{
  "success": true,
  "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "prompt": "a beautiful sunset over mountains",
  "steps": 30,
  "guidance_scale": 7.5,
  "dimensions": "512x512",
  "seed": 1847392847,
  "device": "cuda"
}
```

## Example API Calls

**Fast generation:**
```json
{
  "prompt": "a simple cat drawing",
  "steps": 15,
  "width": 256,
  "height": 256
}
```

**High quality (GPU):**
```json
{
  "prompt": "a photorealistic portrait",
  "steps": 50,
  "width": 768,
  "height": 768,
  "guidance_scale": 8.0
}
```

**Reproducible generation:**
```json
{
  "prompt": "a magical forest",
  "seed": 42,
  "steps": 30
}
```

## Testing

Run the test script (works with both modes):

```bash
python test_api.py
```

## Model Information

- **Model**: `runwayml/stable-diffusion-v1-5`
- **Size**: ~4GB download
- **Cache**: Models cached in `./cache` directory

## Resource Requirements

### CPU Mode
- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Generation time**: 2-5 minutes per image

### GPU Mode
- **GPU**: NVIDIA GPU with 4GB+ VRAM
- **RAM**: 4GB system RAM
- **Generation time**: 5-15 seconds per image

## Troubleshooting

### GPU Mode Issues

**Docker Image Not Found:**

If the CUDA image fails to pull, try the PyTorch-based alternative:

```bash
# Use the PyTorch-based Dockerfile instead
docker build -f Dockerfile.gpu.pytorch -t stable-diffusion-api-gpu .
docker run --gpus all -p 8080:8000 stable-diffusion-api-gpu

# Or update docker-compose.gpu.yml to use:
# dockerfile: Dockerfile.gpu.pytorch
```

**Manual image troubleshooting:**
```bash
# Test which CUDA images are available
chmod +x test-cuda-images.sh
./test-cuda-images.sh

# Force clean rebuild (clears Docker cache)
docker compose -f docker-compose.gpu.yml build --no-cache

# Manual image testing
docker pull pytorch/pytorch:2.0.1-cuda11.7-cudnn8-devel
```

**For Debian users:** The PyTorch-based image is recommended as it's more universally available.

**GPU Not Detected:**
- Install NVIDIA Container Toolkit: [Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Test GPU access: `docker run --rm --gpus all nvidia/cuda:11.8-devel-ubuntu22.04 nvidia-smi`
- Check driver: `nvidia-smi`

**Build Errors:**
```bash
# Clean rebuild
docker compose -f docker-compose.gpu.yml build --no-cache

# Check CUDA compatibility with your GPU driver
nvidia-smi
```

### CPU Mode Issues

**Out of Memory:**
- Reduce image dimensions to 256x256
- Reduce inference steps to 10-15
- Increase Docker memory limit

**Slow Generation:**
- Expected on CPU - reduce steps for speed
- Ensure no other heavy processes running

### General Issues

**Port Conflicts:**
- Change port in docker-compose files if 8080 is in use

**Model Download Issues:**
- Ensure stable internet connection
- Clear cache if corrupted: `rm -rf ./cache`

## File Structure

```
├── README.md                    # This file
├── docker-compose.cpu.yml       # CPU deployment
├── docker-compose.gpu.yml       # GPU deployment
├── Dockerfile.cpu              # CPU Docker image
├── Dockerfile.gpu              # GPU Docker image
├── app-cpu.py                  # CPU-optimized application
├── app-gpu.py                  # GPU-optimized application
├── requirements-cpu.txt        # CPU dependencies
├── requirements-gpu.txt        # GPU dependencies
├── save_image.sh              # Helper script
├── test_api.py                # Test script
└── cache/                     # Model cache (auto-created)
```

## License

This project uses Stable Diffusion v1.5. Please review the model license before commercial use.