#!/bin/bash
# Fix broken NVIDIA repository configuration

echo "🔧 Fixing broken NVIDIA repository configuration..."

# Remove broken repository files
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /etc/apt/sources.list.d/nvidia-docker.list

# Clear apt cache
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Update package lists
sudo apt-get update

echo "✅ Repository configuration cleaned up"
echo ""
echo "Now run the setup script again:"
echo "  ./setup-nvidia-docker.sh"