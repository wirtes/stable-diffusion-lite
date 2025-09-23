#!/bin/bash
# Rebuild container with fixed Dockerfile

echo "🔧 Rebuilding container with fixed Dockerfile..."

# Stop and remove current container
docker compose -f docker-compose.gpu.gtx1060.yml down

# Remove the image to force complete rebuild
docker image rm stable-diffusion-lite-stable-diffusion-api 2>/dev/null || true

# Rebuild with no cache
docker compose -f docker-compose.gpu.gtx1060.yml build --no-cache

# Start the container
docker compose -f docker-compose.gpu.gtx1060.yml up -d

echo "Waiting for container to start..."
sleep 30

echo "Testing health endpoint:"
curl -s http://localhost:8080/health

echo ""
echo ""
echo "If you still see only 'model_loaded' and 'status', run:"
echo "  chmod +x check-running-app.sh"
echo "  ./check-running-app.sh"