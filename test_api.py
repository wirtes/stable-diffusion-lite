#!/usr/bin/env python3
"""
Test script for the Stable Diffusion API
"""

import requests
import json
import base64
from PIL import Image
import io

def test_health():
    """Test the health endpoint"""
    try:
        response = requests.get("http://localhost:8080/health")
        print(f"Health check: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_generate_image(prompt="a cute cat sitting on a table"):
    """Test image generation"""
    try:
        payload = {
            "prompt": prompt,
            "steps": 15,  # Reduced for faster testing
            "guidance_scale": 7.5,
            "width": 512,
            "height": 512
        }
        
        print(f"Generating image for: '{prompt}'")
        response = requests.post(
            "http://localhost:8080/generate",
            json=payload,
            timeout=300  # 5 minute timeout for CPU generation
        )
        
        if response.status_code == 200:
            result = response.json()
            print("Image generated successfully!")
            
            # Save the image
            if "image" in result:
                # Extract base64 data
                image_data = result["image"].split(",")[1]
                image_bytes = base64.b64decode(image_data)
                
                # Save to file
                with open("generated_image.png", "wb") as f:
                    f.write(image_bytes)
                
                print("Image saved as 'generated_image.png'")
            
            return True
        else:
            print(f"Error: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"Image generation failed: {e}")
        return False

if __name__ == "__main__":
    print("Testing Stable Diffusion API...")
    
    # Test health endpoint
    if test_health():
        print("✓ Health check passed")
        
        # Test image generation
        if test_generate_image():
            print("✓ Image generation test passed")
        else:
            print("✗ Image generation test failed")
    else:
        print("✗ Health check failed - make sure the API is running")