#!/bin/bash
# Setup script for NVIDIA Container Toolkit on Debian

set -e

echo "🔧 Setting up NVIDIA Container Toolkit for Docker on Debian..."

# Detect Debian version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
    echo "📋 Detected: $PRETTY_NAME"
else
    echo "❌ Cannot detect OS version"
    exit 1
fi

# Check if nvidia-smi works
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ NVIDIA drivers not found. Please install NVIDIA drivers first:"
    echo "   sudo apt update && sudo apt install nvidia-driver"
    echo "   Then reboot and run this script again."
    exit 1
fi

echo "✓ NVIDIA drivers detected:"
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader

# Add NVIDIA Container Toolkit repository (Debian-specific)
echo "📦 Adding NVIDIA Container Toolkit repository for Debian..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
echo "📋 Using distribution: $distribution"

# Try modern method first
if curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list; then
    
    echo "📥 Installing NVIDIA Container Toolkit (modern method)..."
    sudo apt-get update
    if sudo apt-get install -y nvidia-container-toolkit; then
        INSTALL_SUCCESS=true
    else
        echo "⚠️  Modern method failed, trying legacy method..."
        INSTALL_SUCCESS=false
    fi
else
    INSTALL_SUCCESS=false
fi

# Fallback to legacy method for older Debian versions
if [ "$INSTALL_SUCCESS" != "true" ]; then
    echo "📥 Installing NVIDIA Container Toolkit (legacy method)..."
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    
    sudo apt-get update
    sudo apt-get install -y nvidia-docker2
fi

# Configure Docker runtime
echo "⚙️  Configuring Docker runtime..."
if command -v nvidia-ctk &> /dev/null; then
    sudo nvidia-ctk runtime configure --runtime=docker
else
    echo "⚠️  nvidia-ctk not found, using legacy configuration..."
    # Legacy configuration for nvidia-docker2
    sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
fi

# Restart Docker
echo "🔄 Restarting Docker..."
sudo systemctl restart docker

# Test GPU access
echo "🧪 Testing GPU access in Docker..."
if docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi; then
    echo "✅ Success! GPU is accessible in Docker containers."
    echo ""
    echo "🚀 You can now run the GPU version:"
    echo "   docker compose -f docker-compose.gpu.yml up --build"
else
    echo "❌ GPU test failed. You may need to:"
    echo "   1. Reboot your system"
    echo "   2. Check Docker daemon logs: sudo journalctl -u docker"
    echo "   3. Verify GPU driver compatibility"
    echo "   4. Try: sudo docker run --rm --runtime=nvidia nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi"
fi