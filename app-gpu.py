import os
import io
import base64
import random
from flask import Flask, request, jsonify
from diffusers import StableDiffusionPipeline
import torch
from PIL import Image
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global pipeline variable
pipeline = None

def load_model():
    """Load the Stable Diffusion model with GPU optimization"""
    global pipeline
    
    try:
        logger.info("Loading Stable Diffusion model...")
        
        # Auto-detect device
        device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {device}")
        
        if device == "cuda":
            logger.info(f"GPU: {torch.cuda.get_device_name(0)}")
            logger.info(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
        
        model_id = "runwayml/stable-diffusion-v1-5"
        
        # Choose optimal settings based on device
        torch_dtype = torch.float16 if device == "cuda" else torch.float32
        
        # Load pipeline with device-specific optimizations
        pipeline = StableDiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=torch_dtype,
            safety_checker=None,  # Disable safety checker for speed
            requires_safety_checker=False
        )
        
        # Move to device and optimize
        pipeline = pipeline.to(device)
        
        if device == "cuda":
            # GPU optimizations
            pipeline.enable_memory_efficient_attention()
            pipeline.enable_model_cpu_offload()  # Offload to CPU when not in use
            try:
                pipeline.enable_xformers_memory_efficient_attention()
                logger.info("xformers optimization enabled")
            except Exception as e:
                logger.warning(f"xformers not available: {e}")
        else:
            # CPU optimizations
            pipeline.enable_attention_slicing()  # Reduce memory usage
        
        logger.info("Model loaded successfully!")
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        raise e

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    device_info = {
        "device": "cuda" if torch.cuda.is_available() else "cpu",
        "model_loaded": pipeline is not None
    }
    
    if torch.cuda.is_available():
        device_info["gpu_name"] = torch.cuda.get_device_name(0)
        device_info["gpu_memory_gb"] = round(torch.cuda.get_device_properties(0).total_memory / 1024**3, 1)
    
    return jsonify({"status": "healthy", **device_info})

@app.route('/generate', methods=['POST'])
def generate_image():
    """Generate image from text prompt"""
    try:
        if pipeline is None:
            return jsonify({"error": "Model not loaded"}), 500
            
        data = request.get_json()
        
        if not data or 'prompt' not in data:
            return jsonify({"error": "Missing 'prompt' in request"}), 400
            
        prompt = data['prompt']
        
        # Optional parameters with device-appropriate defaults
        device = "cuda" if torch.cuda.is_available() else "cpu"
        
        if device == "cuda":
            # GPU defaults - can handle more steps and larger images
            num_inference_steps = data.get('steps', 30)
            width = data.get('width', 512)
            height = data.get('height', 512)
        else:
            # CPU defaults - conservative for performance
            num_inference_steps = data.get('steps', 20)
            width = data.get('width', 512)
            height = data.get('height', 512)
        
        guidance_scale = data.get('guidance_scale', 7.5)
        seed = data.get('seed', random.randint(0, 2**32 - 1))
        
        # Limit image size based on device
        max_size = 768 if device == "cuda" else 512
        width = min(width, max_size)
        height = min(height, max_size)
        
        logger.info(f"Generating image for prompt: '{prompt}' with seed: {seed} on {device}")
        
        # Generate image
        generator = torch.Generator(device=device).manual_seed(seed)
        
        with torch.no_grad():
            result = pipeline(
                prompt=prompt,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                width=width,
                height=height,
                generator=generator
            )
            
        image = result.images[0]
        
        # Convert image to base64
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG')
        img_buffer.seek(0)
        img_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
        
        logger.info("Image generated successfully!")
        
        return jsonify({
            "success": True,
            "image": f"data:image/png;base64,{img_base64}",
            "prompt": prompt,
            "steps": num_inference_steps,
            "guidance_scale": guidance_scale,
            "dimensions": f"{width}x{height}",
            "seed": seed,
            "device": device
        })
        
    except Exception as e:
        logger.error(f"Error generating image: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Load model on startup
    load_model()
    
    # Run Flask app
    app.run(host='0.0.0.0', port=8000, debug=False)