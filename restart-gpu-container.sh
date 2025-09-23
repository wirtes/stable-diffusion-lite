#!/bin/bash
# Restart the GPU container with proper configuration

echo "🔄 Restarting GPU container with correct configuration..."

# Stop current container
echo "1. Stopping current container..."
docker compose -f docker-compose.gpu.gtx1060.yml down

# Remove any cached images to force rebuild
echo "2. Removing cached images..."
docker image rm $(docker images -q "*stable-diffusion*") 2>/dev/null || true

# Rebuild with no cache
echo "3. Rebuilding container..."
docker compose -f docker-compose.gpu.gtx1060.yml build --no-cache

# Start the container
echo "4. Starting container..."
docker compose -f docker-compose.gpu.gtx1060.yml up -d

# Wait for startup
echo "5. Waiting for startup..."
sleep 45

# Test the health endpoint
echo "6. Testing health endpoint..."
curl -s http://localhost:8080/health | python -m json.tool

echo ""
echo "7. Testing a quick generation..."
curl -s -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test", "steps": 10, "width": 256, "height": 256}' | \
  python -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'device' in data:
        print(f'✅ Generation used: {data[\"device\"]}')
        if 'seed' in data:
            print(f'Seed: {data[\"seed\"]}')
    else:
        print('❌ No device info in response')
        print(json.dumps(data, indent=2))
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "🎯 If health check now shows GPU info, the container is working correctly!"