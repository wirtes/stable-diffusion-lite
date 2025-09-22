#!/bin/bash
# save_image.sh - Generate and save Stable Diffusion images via API

# Check if prompt is provided
if [ -z "$1" ]; then
    echo "Usage: $0 \"prompt\" [filename] [steps] [size]"
    echo "Example: $0 \"a cute cat\" my_cat.png 20 512"
    exit 1
fi

PROMPT="$1"
FILENAME="${2:-generated_$(date +%s).png}"
STEPS="${3:-20}"
SIZE="${4:-512}"

# Build JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "prompt": "$PROMPT",
  "steps": $STEPS,
  "width": $SIZE,
  "height": $SIZE
}
EOF
)

echo "Generating image with prompt: '$PROMPT'"
echo "Steps: $STEPS, Size: ${SIZE}x${SIZE}"
echo "This may take 2-5 minutes on CPU..."

# Make API call and save image
RESPONSE=$(curl -s -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

# Check if request was successful
if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo "$RESPONSE" | jq -r '.image' | sed 's/data:image\/png;base64,//' | base64 -d > "$FILENAME"
    echo "✓ Image saved as: $FILENAME"
else
    echo "✗ Error generating image:"
    echo "$RESPONSE" | jq -r '.error // "Unknown error"'
    exit 1
fi