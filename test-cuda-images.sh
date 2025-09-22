#!/bin/bash
# Test script to check available CUDA images

echo "Testing CUDA image availability..."

images=(
    "nvidia/cuda:11.7-devel-ubuntu20.04"
    "nvidia/cuda:11.8-devel-ubuntu20.04"
    "nvidia/cuda:12.0-devel-ubuntu20.04"
    "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-devel"
    "pytorch/pytorch:latest"
)

for image in "${images[@]}"; do
    echo -n "Testing $image: "
    if docker pull "$image" >/dev/null 2>&1; then
        echo "✓ Available"
        docker rmi "$image" >/dev/null 2>&1
    else
        echo "✗ Not found"
    fi
done

echo ""
echo "Recommended: Use pytorch/pytorch:2.0.1-cuda11.7-cudnn8-devel"
echo "This is the most reliable option with PyTorch pre-installed."