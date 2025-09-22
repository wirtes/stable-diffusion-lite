# Dockerized Stable Diffusion API

A lightweight, CPU-optimized Stable Diffusion API designed for systems with low resources and no GPU.

## Features

- CPU-only inference optimized for low resource usage
- RESTful API with simple JSON interface
- Docker containerized for easy deployment
- Memory and CPU usage limits
- Health check endpoint
- Base64 image output

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start the service
docker compose up --build

# The API will be available at http://localhost:8080
```

### Using Docker directly

```bash
# Build the image
docker build -t stable-diffusion-api .

# Run the container
docker run -p 8080:8000 --memory=4g --cpus=2.0 stable-diffusion-api
```

## API Usage

### Health Check

```bash
curl http://localhost:8080/health
```

### Generate Image

Basic example (save response to file):
```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful sunset over mountains"
  }' > response.json
```

Generate and extract image to PNG file (requires jq):
```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a detailed portrait of a cat wearing a hat",
    "steps": 30,
    "width": 256,
    "height": 256
  }' | jq -r '.image' | sed 's/data:image\/png;base64,//' | base64 -d > cat_portrait.png
```

Alternative without jq (using grep and sed):
```bash
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a simple flower",
    "steps": 10,
    "width": 256,
    "height": 256
  }' | grep -o '"image":"[^"]*"' | sed 's/"image":"//g' | sed 's/"$//g' | sed 's/data:image\/png;base64,//g' | base64 -d > flower.png
```

### Saving Images with Helper Script

The included `save_image.sh` script makes it easy to generate and save images (no jq required):

```bash
# Make the script executable
chmod +x save_image.sh

# Basic usage
./save_image.sh "a cute robot"

# With custom filename
./save_image.sh "a cute robot" my_robot.png

# With custom parameters (steps and size)
./save_image.sh "a sunset landscape" sunset.png 30 256
```

The script automatically:
- Handles JSON formatting and escaping
- Shows generation progress
- Extracts and decodes the base64 image
- Provides error handling and feedback
- Works without requiring jq installation

### Parameters

- `prompt` (required): Text description of the image to generate
- `steps` (optional, default: 20): Number of inference steps
  - **10-15**: Fast generation (~1-2 minutes)
  - **20-30**: Balanced quality/speed (~2-4 minutes)
  - **40-50**: High quality (~5-8 minutes)
- `guidance_scale` (optional, default: 7.5): How closely to follow the prompt (1.0-20.0)
- `width` (optional, default: 512): Image width in pixels
  - **256x256**: Fast, low memory usage
  - **512x512**: Standard quality (recommended max for CPU)
- `height` (optional, default: 512): Image height in pixels

### Image Size Examples

**Small (256x256)** - Fast generation, low memory:
```json
{"width": 256, "height": 256}
```

**Medium (384x384)** - Balanced size and speed:
```json
{"width": 384, "height": 384}
```

**Large (512x512)** - Best quality, slower generation:
```json
{"width": 512, "height": 512}
```

**Portrait (384x512)** - Vertical orientation:
```json
{"width": 384, "height": 512}
```

**Landscape (512x384)** - Horizontal orientation:
```json
{"width": 512, "height": 384}
```

## Testing

Run the included test script:

```bash
python test_api.py
```

This will test both the health endpoint and image generation, saving a test image as `generated_image.png`.

## Performance Notes

- **First run**: Model download (~4GB) and loading takes 5-10 minutes
- **Generation time**: 2-5 minutes per image on CPU (depending on hardware)
- **Memory usage**: ~3-4GB RAM during generation
- **Optimizations**: 
  - Attention slicing enabled for lower memory usage
  - Safety checker disabled for faster inference
  - Limited to 512x512 images for efficiency

## Resource Requirements

- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Storage**: ~6GB for model and dependencies

## Troubleshooting

### Out of Memory Errors
- Reduce image dimensions (e.g., 256x256)
- Reduce inference steps
- Increase Docker memory limit

### Slow Generation
- This is expected on CPU - consider reducing steps to 10-15 for faster results
- Ensure no other heavy processes are running

### Model Download Issues
- Ensure stable internet connection
- The model cache is persisted in `./cache` directory