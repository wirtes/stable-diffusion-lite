#!/bin/bash
# Check if Docker can actually access the GPU

echo "🔍 Checking Docker GPU Access"
echo "=============================="

# Test 1: Basic GPU access
echo "1. Testing basic GPU access in Docker:"
if docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi; then
    echo "✅ Docker can access GPU"
else
    echo "❌ Docker cannot access GPU"
    echo "💡 Try: sudo systemctl restart docker"
    exit 1
fi

echo ""

# Test 2: Check if our container can see GPU
echo "2. Checking if Stable Diffusion container can access GPU:"
CONTAINER_ID=$(docker compose -f docker-compose.gpu.yml ps -q stable-diffusion-api)

if [ -n "$CONTAINER_ID" ]; then
    echo "Container ID: $CONTAINER_ID"
    echo "Running nvidia-smi inside container:"
    if docker exec "$CONTAINER_ID" nvidia-smi; then
        echo "✅ Container can access GPU"
    else
        echo "❌ Container cannot access GPU"
        echo "💡 Container may not have GPU access configured"
    fi
    
    echo ""
    echo "Checking Python/PyTorch GPU access in container:"
    docker exec "$CONTAINER_ID" python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
    print(f'GPU name: {torch.cuda.get_device_name(0)}')
else:
    print('❌ PyTorch cannot see CUDA')
"
else
    echo "❌ No running container found"
    echo "💡 Start the container first: docker compose -f docker-compose.gpu.yml up -d"
fi

echo ""
echo "3. Host GPU status:"
nvidia-smi