#!/bin/bash
# Debug script to diagnose NVIDIA setup issues on Debian 12

echo "🔍 NVIDIA Setup Diagnostic Tool for Debian 12"
echo "=============================================="

# Check system info
echo "📋 System Information:"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

# Check for NVIDIA hardware
echo "🔍 Hardware Detection:"
if lspci | grep -i nvidia > /dev/null; then
    echo "✓ NVIDIA GPU found:"
    lspci | grep -i nvidia
else
    echo "❌ No NVIDIA GPU detected"
    echo "Available GPUs:"
    lspci | grep -i vga
fi
echo ""

# Check repositories
echo "📦 Repository Configuration:"
if grep -r "non-free" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "✓ Non-free repositories configured"
else
    echo "❌ Non-free repositories not found"
    echo "Need to add: contrib non-free non-free-firmware"
fi
echo ""

# Check available NVIDIA packages
echo "📋 Available NVIDIA Packages:"
apt list --installed | grep nvidia 2>/dev/null || echo "No NVIDIA packages installed"
echo ""
echo "Available for installation:"
apt search nvidia-driver 2>/dev/null | grep "^nvidia-driver" | head -3 || echo "No nvidia-driver packages found"
echo ""

# Check if drivers are loaded
echo "🔧 Driver Status:"
if command -v nvidia-smi &> /dev/null; then
    echo "✓ nvidia-smi available"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || echo "nvidia-smi failed to run"
else
    echo "❌ nvidia-smi not found"
fi

if lsmod | grep nvidia > /dev/null; then
    echo "✓ NVIDIA kernel modules loaded:"
    lsmod | grep nvidia
else
    echo "❌ NVIDIA kernel modules not loaded"
fi
echo ""

# Check Docker
echo "🐳 Docker Status:"
if command -v docker &> /dev/null; then
    echo "✓ Docker installed: $(docker --version)"
    if docker run --rm hello-world > /dev/null 2>&1; then
        echo "✓ Docker working"
    else
        echo "❌ Docker not working properly"
    fi
    
    # Check GPU access
    if docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
        echo "✓ Docker GPU access working"
    else
        echo "❌ Docker GPU access not working"
    fi
else
    echo "❌ Docker not installed"
fi
echo ""

# Recommendations
echo "💡 Recommendations:"
if ! lspci | grep -i nvidia > /dev/null; then
    echo "1. No NVIDIA GPU detected - use CPU mode:"
    echo "   docker compose -f docker-compose.cpu.yml up --build"
elif ! grep -r "non-free" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "1. Add non-free repositories:"
    echo "   echo 'deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware' | sudo tee /etc/apt/sources.list.d/debian-non-free.list"
    echo "   sudo apt update"
elif ! command -v nvidia-smi &> /dev/null; then
    echo "1. Install NVIDIA drivers:"
    echo "   sudo apt install nvidia-detect"
    echo "   nvidia-detect"
    echo "   sudo apt install nvidia-driver-525 firmware-misc-nonfree"
    echo "   sudo reboot"
elif ! docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
    echo "1. Setup Docker GPU support:"
    echo "   ./setup-nvidia-docker.sh"
else
    echo "1. Everything looks good! Try:"
    echo "   docker compose -f docker-compose.gpu.yml up --build"
fi