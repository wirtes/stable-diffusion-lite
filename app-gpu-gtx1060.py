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
    """Load the Stable Diffusion model optimized for GTX 1060"""
    global pipeline
    
    try:
        logger.info("Loading Stable Diffusion model for GTX 1060...")
        
        # Auto-detect device
        device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {device}")
        
        if device == "cuda":
            logger.info(f"GPU: {torch.cuda.get_device_name(0)}")
            logger.info(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
            
            # Check if it's a GTX 1060 (compute capability 6.1)
            gpu_name = torch.cuda.get_device_name(0).lower()
            is_gtx_1060 = "gtx 1060" in gpu_name or "1060" in gpu_name
            
            if is_gtx_1060:
                logger.info("GTX 1060 detected - applying optimizations")
        
        model_id = "runwayml/stable-diffusion-v1-5"
        
        # GTX 1060 optimizations - use float16 but with more conservative settings
        torch_dtype = torch.float16 if device == "cuda" else torch.float32
        
        # Suppress tokenizer warnings
        os.environ["TOKENIZERS_PARALLELISM"] = "false"
        
        # Load pipeline with GTX 1060-specific optimizations
        pipeline = StableDiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=torch_dtype,
            safety_checker=None,  # Disable safety checker for speed and memory
            requires_safety_checker=False,
            use_safetensors=True
        )
        
        # Move to device and optimize for GTX 1060
        pipeline = pipeline.to(device)
        
        if device == "cuda":
            # GTX 1060 specific optimizations
            pipeline.enable_attention_slicing()  # Reduce memory usage
            pipeline.enable_sequential_cpu_offload()  # Offload to CPU when not in use
            
            # Don't use xformers on older GPUs as it may not be compatible
            try:
                # Only enable if available and compatible
                pipeline.enable_xformers_memory_efficient_attention()
                logger.info("xformers optimization enabled")
            except Exception as e:
                logger.info(f"xformers not available (normal for GTX 1060): {e}")
        else:
            # CPU optimizations
            pipeline.enable_attention_slicing()
        
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
        
        # Add GTX 1060 specific info
        gpu_name = torch.cuda.get_device_name(0).lower()
        if "gtx 1060" in gpu_name or "1060" in gpu_name:
            device_info["optimized_for"] = "GTX 1060"
    
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
        
        # GTX 1060 optimized defaults
        device = "cuda" if torch.cuda.is_available() else "cpu"
        
        if device == "cuda":
            # GTX 1060 conservative defaults for 6GB VRAM
            num_inference_steps = data.get('steps', 25)  # Slightly fewer steps
            width = data.get('width', 512)
            height = data.get('height', 512)
            
            # Limit to 512x512 for GTX 1060 to avoid VRAM issues
            width = min(width, 512)
            height = min(height, 512)
        else:
            # CPU defaults
            num_inference_steps = data.get('steps', 20)
            width = data.get('width', 512)
            height = data.get('height', 512)
        
        guidance_scale = data.get('guidance_scale', 7.5)
        seed = data.get('seed', random.randint(0, 2**32 - 1))
        
        logger.info(f"Generating image for prompt: '{prompt}' with seed: {seed} on {device}")
        
        # Generate image with GTX 1060 optimizations
        generator = torch.Generator(device=device).manual_seed(seed)
        
        # Clear CUDA cache before generation (important for GTX 1060)
        if device == "cuda":
            torch.cuda.empty_cache()
        
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
        
        # Clear CUDA cache after generation
        if device == "cuda":
            torch.cuda.empty_cache()
        
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
        
        # Clear CUDA cache on error
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Load model on startup
    load_model()
    
    # Run Flask app
    app.run(host='0.0.0.0', port=8000, debug=False)