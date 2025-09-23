#!/bin/bash
# Quick test of GPU in container

echo "Testing GPU in Stable Diffusion container..."

# Get container ID
CONTAINER_ID=$(docker ps --filter "name=stable-diffusion" --format "{{.ID}}" | head -1)

if [ -n "$CONTAINER_ID" ]; then
    echo "Container ID: $CONTAINER_ID"
    echo ""
    echo "1. nvidia-smi in container:"
    docker exec $CONTAINER_ID nvidia-smi
    echo ""
    echo "2. PyTorch CUDA test:"
    docker exec $CONTAINER_ID python -c "import torch; print('CUDA available:', torch.cuda.is_available())"
else
    echo "No container found. Is it running?"
    echo "Start with: docker compose -f docker-compose.gpu.gtx1060.yml up -d"
fi