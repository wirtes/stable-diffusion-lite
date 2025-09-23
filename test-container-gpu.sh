#!/bin/bash
# Test GPU access specifically in our Stable Diffusion container

echo "🔍 Testing GPU Access in Stable Diffusion Container"
echo "=================================================="

# Get the running container ID
CONTAINER_ID=$(docker compose -f docker-compose.gpu.gtx1060.yml ps -q stable-diffusion-api)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No running container found. Starting container..."
    docker compose -f docker-compose.gpu.gtx1060.yml up -d
    sleep 30
    CONTAINER_ID=$(docker compose -f docker-compose.gpu.gtx1060.yml ps -q stable-diffusion-api)
fi

if [ -n "$CONTAINER_ID" ]; then
    echo "✅ Container found: $CONTAINER_ID"
    echo ""
    
    echo "1. Testing nvidia-smi in container:"
    docker exec "$CONTAINER_ID" nvidia-smi
    echo ""
    
    echo "2. Testing Python/PyTorch GPU detection:"
    docker exec "$CONTAINER_ID" python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'CUDA version: {torch.version.cuda}')
if torch.cuda.is_available():
    print(f'Device count: {torch.cuda.device_count()}')
    print(f'Current device: {torch.cuda.current_device()}')
    print(f'Device name: {torch.cuda.get_device_name(0)}')
    print(f'Device memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
else:
    print('❌ CUDA not available in PyTorch')
"
    echo ""
    
    echo "3. Testing container environment variables:"
    docker exec "$CONTAINER_ID" env | grep -E "(CUDA|NVIDIA)" || echo "No CUDA/NVIDIA env vars found"
    echo ""
    
    echo "4. Testing CUDA libraries in container:"
    docker exec "$CONTAINER_ID" ls -la /usr/local/cuda*/lib64/libcudart* 2>/dev/null || echo "CUDA runtime libraries not found"
    echo ""
    
    echo "5. Testing our app's GPU detection:"
    docker exec "$CONTAINER_ID" python -c "
import torch
device = 'cuda' if torch.cuda.is_available() else 'cpu'
print(f'App would use device: {device}')
if device == 'cuda':
    print('✅ GPU will be used by the app')
else:
    print('❌ App will fall back to CPU')
"
else
    echo "❌ Could not find or start container"
    exit 1
fi