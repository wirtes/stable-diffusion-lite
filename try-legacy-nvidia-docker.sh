#!/bin/bash
# Try legacy nvidia-docker approach as fallback

echo "🔧 Trying Legacy NVIDIA Docker Approach"
echo "======================================="

# Install nvidia-docker2 (legacy method)
echo "1. Installing nvidia-docker2 (legacy)..."

# Remove any existing nvidia-docker packages
sudo apt-get remove -y nvidia-docker nvidia-docker2 nvidia-container-toolkit

# Add nvidia-docker repository
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

# Try different distributions
for dist in "debian12" "debian11" "ubuntu20.04" "ubuntu18.04"; do
    echo "Trying repository for $dist..."
    if curl -s -f -L "https://nvidia.github.io/nvidia-docker/$dist/nvidia-docker.list" > /dev/null 2>&1; then
        curl -s -L "https://nvidia.github.io/nvidia-docker/$dist/nvidia-docker.list" | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        break
    fi
done

# Install nvidia-docker2
sudo apt-get update
if sudo apt-get install -y nvidia-docker2; then
    echo "✅ nvidia-docker2 installed"
else
    echo "❌ nvidia-docker2 installation failed"
    exit 1
fi

# Restart Docker
sudo systemctl restart docker

# Test legacy method
echo "2. Testing legacy nvidia-docker..."
if docker run --runtime=nvidia --rm nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi; then
    echo "✅ Legacy nvidia-docker works!"
    
    # Create legacy docker-compose file
    echo "3. Creating legacy docker-compose configuration..."
    cat > docker-compose.gpu.legacy.yml << 'EOF'
version: '3.8'

services:
  stable-diffusion-api:
    build:
      context: .
      dockerfile: Dockerfile.gpu.gtx1060
    ports:
      - "8080:8000"
    runtime: nvidia
    environment:
      - PYTHONUNBUFFERED=1
      - NVIDIA_VISIBLE_DEVICES=all
    volumes:
      - ./cache:/root/.cache
    restart: unless-stopped
EOF
    
    echo "4. Starting with legacy configuration..."
    docker compose -f docker-compose.gpu.legacy.yml up --build -d
    
    echo "5. Testing API..."
    sleep 30
    curl http://localhost:8080/health
    
else
    echo "❌ Legacy nvidia-docker also failed"
    echo ""
    echo "💡 Final troubleshooting steps:"
    echo "1. Reboot the system: sudo reboot"
    echo "2. Check BIOS settings - ensure GPU is enabled"
    echo "3. Verify GPU is properly seated in PCIe slot"
    echo "4. Check power connections to GPU"
    echo "5. Try different NVIDIA driver version"
fi