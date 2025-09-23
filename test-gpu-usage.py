#!/usr/bin/env python3
"""
Test script to verify GPU is actually being used by the API
"""

import requests
import json
import time

def test_gpu_detection():
    """Test if the API detects GPU correctly"""
    try:
        response = requests.get("http://localhost:8080/health")
        if response.status_code == 200:
            health = response.json()
            print("🔍 API Health Check:")
            print(f"  Device: {health.get('device', 'unknown')}")
            print(f"  Model loaded: {health.get('model_loaded', False)}")
            
            if 'gpu_name' in health:
                print(f"  GPU: {health['gpu_name']}")
                print(f"  VRAM: {health['gpu_memory_gb']} GB")
                return health.get('device') == 'cuda'
            else:
                print("  ❌ No GPU information found")
                return False
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_generation_with_timing():
    """Test image generation and measure time"""
    payload = {
        "prompt": "a simple test image",
        "steps": 20,
        "width": 512,
        "height": 512
    }
    
    print("\n🧪 Testing image generation...")
    start_time = time.time()
    
    try:
        response = requests.post(
            "http://localhost:8080/generate",
            json=payload,
            timeout=300
        )
        
        end_time = time.time()
        duration = end_time - start_time
        
        if response.status_code == 200:
            result = response.json()
            device_used = result.get('device', 'unknown')
            
            print(f"✅ Generation successful!")
            print(f"  Time taken: {duration:.1f} seconds")
            print(f"  Device used: {device_used}")
            print(f"  Steps: {result.get('steps', 'unknown')}")
            print(f"  Dimensions: {result.get('dimensions', 'unknown')}")
            
            # Performance analysis
            if device_used == 'cuda' and duration > 60:
                print("⚠️  WARNING: GPU generation took over 1 minute - GPU may not be working properly")
            elif device_used == 'cpu' and duration > 120:
                print("ℹ️  Normal CPU performance")
            elif device_used == 'cuda' and duration < 30:
                print("🚀 Excellent GPU performance!")
            
            return True
        else:
            print(f"❌ Generation failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Generation error: {e}")
        return False

if __name__ == "__main__":
    print("🔍 GPU Usage Test for Stable Diffusion API")
    print("=" * 50)
    
    # Test 1: Check if GPU is detected
    gpu_detected = test_gpu_detection()
    
    # Test 2: Generate image and measure performance
    generation_success = test_generation_with_timing()
    
    print("\n📊 Summary:")
    if gpu_detected and generation_success:
        print("✅ GPU appears to be working correctly")
    elif not gpu_detected:
        print("❌ GPU not detected - API is running in CPU mode")
        print("💡 Suggestions:")
        print("  1. Check Docker GPU access: docker run --rm --gpus all nvidia/cuda:11.7-base-ubuntu20.04 nvidia-smi")
        print("  2. Restart the GPU container: docker compose -f docker-compose.gpu.yml restart")
        print("  3. Check container logs: docker compose -f docker-compose.gpu.yml logs")
    else:
        print("⚠️  GPU detected but performance issues")
        print("💡 Suggestions:")
        print("  1. Check GPU memory usage: nvidia-smi")
        print("  2. Verify CUDA version compatibility")
        print("  3. Try rebuilding: docker compose -f docker-compose.gpu.yml build --no-cache")