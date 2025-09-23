#!/bin/bash
# Deep diagnosis of GPU access issues

echo "🔍 Deep GPU Diagnosis"
echo "===================="

# Check 1: Host GPU status
echo "1. Host GPU Status:"
nvidia-smi
echo ""

# Check 2: Docker version and configuration
echo "2. Docker Configuration:"
echo "Docker version: $(docker --version)"
echo "Docker info (GPU runtime):"
docker info | grep -i nvidia || echo "No NVIDIA runtime found"
echo ""

# Check 3: NVIDIA Container Toolkit status
echo "3. NVIDIA Container Toolkit:"
if command -v nvidia-ctk &> /dev/null; then
    echo "✅ nvidia-ctk installed: $(nvidia-ctk --version)"
else
    echo "❌ nvidia-ctk not found"
fi

if command -v nvidia-container-runtime &> /dev/null; then
    echo "✅ nvidia-container-runtime found"
else
    echo "❌ nvidia-container-runtime not found"
fi
echo ""

# Check 4: Docker daemon configuration
echo "4. Docker Daemon Configuration:"
if [ -f /etc/docker/daemon.json ]; then
    echo "daemon.json exists:"
    cat /etc/docker/daemon.json
else
    echo "❌ No daemon.json found"
fi
echo ""

# Check 5: Available runtimes
echo "5. Available Docker Runtimes:"
docker info | grep -A 10 "Runtimes:" || echo "Could not get runtime info"
echo ""

# Check 6: Test different GPU access methods
echo "6. Testing Different GPU Access Methods:"

echo "Method 1: --gpus all"
docker run --rm --gpus all hello-world > /dev/null 2>&1 && echo "✅ --gpus all works" || echo "❌ --gpus all fails"

echo "Method 2: --runtime=nvidia"
docker run --rm --runtime=nvidia hello-world > /dev/null 2>&1 && echo "✅ --runtime=nvidia works" || echo "❌ --runtime=nvidia fails"

echo "Method 3: nvidia-docker (legacy)"
if command -v nvidia-docker &> /dev/null; then
    nvidia-docker run --rm hello-world > /dev/null 2>&1 && echo "✅ nvidia-docker works" || echo "❌ nvidia-docker fails"
else
    echo "❌ nvidia-docker not installed"
fi
echo ""

# Check 7: Kernel modules
echo "7. NVIDIA Kernel Modules:"
lsmod | grep nvidia || echo "❌ No NVIDIA kernel modules loaded"
echo ""

# Check 8: Device files
echo "8. NVIDIA Device Files:"
ls -la /dev/nvidia* 2>/dev/null || echo "❌ No NVIDIA device files found"
echo ""

# Check 9: User permissions
echo "9. User Permissions:"
groups $USER | grep -q docker && echo "✅ User in docker group" || echo "❌ User not in docker group"
echo ""

# Recommendations
echo "💡 Recommendations:"
echo ""

if ! lsmod | grep nvidia > /dev/null; then
    echo "🔧 NVIDIA kernel modules not loaded. Try:"
    echo "   sudo modprobe nvidia"
    echo "   sudo modprobe nvidia-uvm"
fi

if ! ls /dev/nvidia* > /dev/null 2>&1; then
    echo "🔧 NVIDIA device files missing. Try:"
    echo "   sudo nvidia-modprobe -u -c=0"
fi

if ! groups $USER | grep -q docker; then
    echo "🔧 Add user to docker group:"
    echo "   sudo usermod -aG docker $USER"
    echo "   newgrp docker"
fi

if ! command -v nvidia-ctk &> /dev/null; then
    echo "🔧 Install NVIDIA Container Toolkit:"
    echo "   ./setup-nvidia-docker.sh"
fi

echo ""
echo "🔄 If all else fails, try a system reboot:"
echo "   sudo reboot"