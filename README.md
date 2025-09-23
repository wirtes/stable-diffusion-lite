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

**For GTX 1060 users:**
```bash
# Use GTX 1060 optimized version
docker compose -f docker-compose.gpu.gtx1060.yml up --build
```

**For newer GPUs (RTX series, etc.):**

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
# For newer GPUs
docker build -f Dockerfile.gpu -t stable-diffusion-api-gpu .
docker run --gpus all -p 8080:8000 stable-diffusion-api-gpu

# For GTX 1060
docker build -f Dockerfile.gpu.gtx1060 -t stable-diffusion-api-gtx1060 .
docker run --gpus all -p 8080:8000 stable-diffusion-api-gtx1060
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

## Expected Startup Messages

When running the GPU version, you may see these **normal** messages:

```
** DEPRECATION NOTICE! **
THIS IMAGE IS DEPRECATED and is scheduled for DELETION.
```
This is just a warning about the base CUDA image - it doesn't affect functionality.

```
FutureWarning: `clean_up_tokenization_spaces` was not set.
```
This is a harmless warning from the transformers library.

**Success indicators:**
- `INFO:__main__:Loading Stable Diffusion model...`
- `Loading pipeline components...`
- `Model loaded successfully!`
- API responds at `http://localhost:8080/health`

**⚠️ Performance Issue: Same Speed as CPU?**

If GPU and CPU versions have the same performance (~2-5 minutes), the GPU isn't being used:

```bash
# Test GPU detection and performance
python test-gpu-usage.py

# Check Docker GPU access
chmod +x check-docker-gpu.sh
./check-docker-gpu.sh

# Check API health (should show "device": "cuda")
curl http://localhost:8080/health
```

**Common fixes:**
```bash
# 1. Restart Docker service
sudo systemctl restart docker

# 2. Rebuild container with GPU access
docker compose -f docker-compose.gpu.yml down
docker compose -f docker-compose.gpu.yml build --no-cache
docker compose -f docker-compose.gpu.yml up

# 3. Verify GPU access in container
docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi
```

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

**GPU Not Detected / "could not select device driver nvidia":**

This usually means either NVIDIA drivers aren't installed or NVIDIA Container Toolkit isn't set up.

**Step 1: Install NVIDIA Drivers (if not already installed):**
```bash
# Check if you have NVIDIA drivers
nvidia-smi

# If that fails, install drivers first
chmod +x install-nvidia-drivers.sh
./install-nvidia-drivers.sh
# Then reboot: sudo reboot

# Alternative manual method for Debian 12:
sudo apt update
sudo apt install nvidia-detect
nvidia-detect  # Shows recommended driver
sudo apt install nvidia-driver-525 firmware-misc-nonfree  # Use recommended version
sudo reboot
```

**Step 2: Install NVIDIA Container Toolkit for Debian:**

```bash
# 1. First, verify you have NVIDIA drivers installed
nvidia-smi

# 2. Install NVIDIA Container Toolkit for Debian
# Add NVIDIA's GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add repository (Debian-specific)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install the toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 3. Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 4. Test GPU access
docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi
```

**For older Debian versions (if above fails):**
```bash
# Alternative method for Debian 10/11
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

**Complete Setup Process:**
```bash
# 0. Diagnose any issues first
chmod +x debug-nvidia.sh
./debug-nvidia.sh

# 1. Install NVIDIA drivers (if needed)
chmod +x install-nvidia-drivers.sh
./install-nvidia-drivers.sh
sudo reboot  # Required after driver installation

# 2. After reboot, setup Docker GPU support
chmod +x setup-nvidia-docker.sh
./setup-nvidia-docker.sh

# 3. Run GPU version
docker compose -f docker-compose.gpu.yml up --build
```

**If you encounter errors:**
```bash
# For repository/sources.list errors:
chmod +x fix-nvidia-repo.sh
./fix-nvidia-repo.sh
./setup-nvidia-docker.sh  # Try again

# Run diagnostic tool to identify issues:
./debug-nvidia.sh

# Manual NVIDIA Container Toolkit installation:
wget https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v1.14.3/nvidia-container-toolkit_1.14.3-1_amd64.deb
sudo dpkg -i nvidia-container-toolkit_1.14.3-1_amd64.deb
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**Alternative: Use CPU mode while setting up GPU:**
```bash
# Run CPU version instead (works immediately)
docker compose -f docker-compose.cpu.yml up --build
```

**Manual verification steps:**
```bash
# 1. Check NVIDIA drivers
nvidia-smi

# 2. Check Docker can access GPU
docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi

# 3. If step 2 fails, restart Docker
sudo systemctl restart docker
```

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