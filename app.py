import os
import io
import base64
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
    """Load the Stable Diffusion model optimized for CPU"""
    global pipeline
    
    try:
        logger.info("Loading Stable Diffusion model...")
        
        # Use a smaller, CPU-optimized model
        model_id = "runwayml/stable-diffusion-v1-5"
        
        # Load pipeline with CPU optimizations
        pipeline = StableDiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=torch.float32,  # Use float32 for CPU
            safety_checker=None,  # Disable safety checker for speed
            requires_safety_checker=False
        )
        
        # Move to CPU and optimize
        pipeline = pipeline.to("cpu")
        pipeline.enable_attention_slicing()  # Reduce memory usage
        
        logger.info("Model loaded successfully!")
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        raise e

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "model_loaded": pipeline is not None})

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
        
        # Optional parameters with defaults for low resource usage
        num_inference_steps = data.get('steps', 20)  # Reduced steps for speed
        guidance_scale = data.get('guidance_scale', 7.5)
        width = data.get('width', 512)
        height = data.get('height', 512)
        
        # Limit image size for low resource systems
        width = min(width, 512)
        height = min(height, 512)
        
        logger.info(f"Generating image for prompt: '{prompt}'")
        
        # Generate image
        with torch.no_grad():
            result = pipeline(
                prompt=prompt,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                width=width,
                height=height,
                generator=torch.Generator().manual_seed(42)  # Fixed seed for consistency
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
            "dimensions": f"{width}x{height}"
        })
        
    except Exception as e:
        logger.error(f"Error generating image: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Load model on startup
    load_model()
    
    # Run Flask app
    app.run(host='0.0.0.0', port=8000, debug=False)