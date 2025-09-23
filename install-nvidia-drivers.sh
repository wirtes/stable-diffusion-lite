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

# Backup sources.list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Add non-free repositories for Debian 12
echo "📦 Configuring repositories for Debian 12..."
echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/debian-non-free.list
echo "deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/debian-non-free.list

# Update package lists
sudo apt update

# Check what NVIDIA packages are available
echo "📋 Available NVIDIA packages:"
apt search nvidia-driver 2>/dev/null | grep "^nvidia-driver" | head -5

# Try different driver installation methods
echo "📥 Installing NVIDIA drivers..."

# Method 1: Try nvidia-driver metapackage
if sudo apt install -y nvidia-driver firmware-misc-nonfree 2>/dev/null; then
    echo "✅ Installed nvidia-driver metapackage"
# Method 2: Try specific driver version
elif sudo apt install -y nvidia-driver-525 firmware-misc-nonfree 2>/dev/null; then
    echo "✅ Installed nvidia-driver-525"
# Method 3: Try legacy driver
elif sudo apt install -y nvidia-legacy-390xx-driver firmware-misc-nonfree 2>/dev/null; then
    echo "✅ Installed legacy nvidia driver"
# Method 4: Manual detection and installation
else
    echo "🔍 Auto-detecting best driver..."
    
    # Install nvidia-detect to find the right driver
    sudo apt install -y nvidia-detect
    
    # Get recommended driver
    RECOMMENDED_DRIVER=$(nvidia-detect | grep -o "nvidia-driver-[0-9]*" | head -1)
    
    if [ -n "$RECOMMENDED_DRIVER" ]; then
        echo "📥 Installing recommended driver: $RECOMMENDED_DRIVER"
        sudo apt install -y "$RECOMMENDED_DRIVER" firmware-misc-nonfree
    else
        echo "❌ Could not determine appropriate driver. Manual options:"
        echo ""
        echo "Available drivers:"
        apt search nvidia-driver 2>/dev/null | grep "^nvidia-driver"
        echo ""
        echo "Try manually:"
        echo "  sudo apt install nvidia-driver-525 firmware-misc-nonfree"
        echo "  sudo apt install nvidia-driver-470 firmware-misc-nonfree"
        exit 1
    fi
fi

echo ""
echo "✅ NVIDIA drivers installed successfully!"
echo ""
echo "🔄 IMPORTANT: You must reboot now for the drivers to take effect:"
echo "   sudo reboot"
echo ""
echo "After reboot, run:"
echo "   nvidia-smi  # to verify drivers work"
echo "   ./setup-nvidia-docker.sh  # to setup Docker GPU support"
echo ""
echo "If nvidia-smi doesn't work after reboot, try:"
echo "   sudo modprobe nvidia"
echo "   sudo nvidia-modprobe -u -c=0"