#!/bin/bash
# Install NVIDIA drivers on Debian 12 (Bookworm)

set -e

echo "🔧 Installing NVIDIA drivers on Debian 12..."

# Check if we have an NVIDIA GPU
if ! lspci | grep -i nvidia > /dev/null; then
    echo "❌ No NVIDIA GPU detected. Checking available GPUs:"
    lspci | grep -i vga
    echo ""
    echo "If you have an NVIDIA GPU but it's not showing, you may need to:"
    echo "1. Enable it in BIOS/UEFI"
    echo "2. Check if it's properly seated"
    echo "3. Use CPU mode instead: docker compose -f docker-compose.cpu.yml up --build"
    exit 1
fi

echo "✓ NVIDIA GPU detected:"
lspci | grep -i nvidia

# Add non-free repositories (needed for NVIDIA drivers)
echo "📦 Adding non-free repositories..."
sudo apt update

# Check if non-free is already enabled
if ! grep -q "non-free" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "Adding non-free repositories to sources.list..."
    sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt update
else
    echo "✓ Non-free repositories already enabled"
fi

# Install NVIDIA drivers
echo "📥 Installing NVIDIA drivers..."
sudo apt install -y nvidia-driver firmware-misc-nonfree

echo "✅ NVIDIA drivers installed successfully!"
echo ""
echo "🔄 IMPORTANT: You must reboot now for the drivers to take effect:"
echo "   sudo reboot"
echo ""
echo "After reboot, run:"
echo "   nvidia-smi  # to verify drivers work"
echo "   ./setup-nvidia-docker.sh  # to setup Docker GPU support"