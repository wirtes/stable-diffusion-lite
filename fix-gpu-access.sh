#!/bin/bash
# Fix GPU access for Docker containers

echo "🔧 Fixing GPU access for Docker containers..."

# Step 1: Test basic GPU access on host
echo "1. Testing GPU access on host:"
if nvidia-smi; then
    echo "✅ Host can access GPU"
else
    echo "❌ Host cannot access GPU - drivers may not be installed"
    exit 1
fi

echo ""

# Step 2: Test Docker GPU access
echo "2. Testing Docker GPU access:"
if docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi; then
    echo "✅ Docker can access GPU"
else
    echo "❌ Docker cannot access GPU"
    echo "🔧 Attempting to fix Docker GPU access..."
    
    # Restart Docker
    sudo systemctl restart docker
    sleep 5
    
    # Test again
    if docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi; then
        echo "✅ Docker GPU access fixed after restart"
    else
        echo "❌ Still cannot access GPU. Checking configuration..."
        
        # Check if nvidia-container-toolkit is installed
        if ! command -v nvidia-ctk &> /dev/null; then
            echo "Installing nvidia-container-toolkit..."
            ./setup-nvidia-docker.sh
        fi
        
        # Configure Docker runtime
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        
        # Final test
        if docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi; then
            echo "✅ Docker GPU access fixed"
        else
            echo "❌ Could not fix Docker GPU access"
            echo "💡 Try rebooting the system"
            exit 1
        fi
    fi
fi

echo ""

# Step 3: Stop and rebuild the container
echo "3. Rebuilding Stable Diffusion container with GPU access:"
docker compose -f docker-compose.gpu.gtx1060.yml down
docker compose -f docker-compose.gpu.gtx1060.yml build --no-cache
docker compose -f docker-compose.gpu.gtx1060.yml up -d

echo ""

# Step 4: Wait for container to start and test
echo "4. Waiting for container to start..."
sleep 30

echo "5. Testing GPU access in Stable Diffusion container:"
CONTAINER_ID=$(docker compose -f docker-compose.gpu.gtx1060.yml ps -q)

if [ -n "$CONTAINER_ID" ]; then
    echo "Testing nvidia-smi in container:"
    if docker exec "$CONTAINER_ID" nvidia-smi; then
        echo "✅ Container can access GPU"
    else
        echo "❌ Container cannot access GPU"
    fi
    
    echo ""
    echo "Testing PyTorch CUDA in container:"
    docker exec "$CONTAINER_ID" python -c "
import torch
print(f'PyTorch CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU name: {torch.cuda.get_device_name(0)}')
    print(f'CUDA version: {torch.version.cuda}')
"
else
    echo "❌ Container not running"
fi

echo ""
echo "6. Testing API health:"
sleep 10
curl http://localhost:8080/health

echo ""
echo "🎯 If the health check now shows 'device': 'cuda', GPU access is working!"
echo "🚀 Try generating an image: ./save_image.sh 'test image' test.png"