#!/bin/bash
# Check which app is actually running in the container

echo "🔍 Checking which app is running in the container..."

CONTAINER_ID=$(docker ps --filter "name=stable-diffusion" --format "{{.ID}}" | head -1)

if [ -n "$CONTAINER_ID" ]; then
    echo "Container ID: $CONTAINER_ID"
    echo ""
    
    echo "1. Checking app.py content in container:"
    docker exec $CONTAINER_ID head -20 app.py
    echo ""
    
    echo "2. Looking for GTX 1060 specific code:"
    docker exec $CONTAINER_ID grep -n "GTX 1060" app.py || echo "❌ No GTX 1060 code found"
    echo ""
    
    echo "3. Checking if torch.cuda.is_available() in the running app:"
    docker exec $CONTAINER_ID python -c "
import torch
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
"
    echo ""
    
    echo "4. Testing the health endpoint directly in container:"
    docker exec $CONTAINER_ID python -c "
import torch
device_info = {
    'device': 'cuda' if torch.cuda.is_available() else 'cpu',
    'model_loaded': True
}
if torch.cuda.is_available():
    device_info['gpu_name'] = torch.cuda.get_device_name(0)
    device_info['gpu_memory_gb'] = round(torch.cuda.get_device_properties(0).total_memory / 1024**3, 1)
print('Expected health response:', device_info)
"
else
    echo "❌ No container running"
fi