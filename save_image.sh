#!/bin/bash
# save_image.sh - Generate and save Stable Diffusion images (no jq required)

# Check if prompt is provided
if [ -z "$1" ]; then
    echo "Usage: $0 \"prompt\" [filename] [steps] [size]"
    echo "Example: $0 \"a cute cat\" my_cat.png 20 512"
    echo ""
    echo "To make executable: chmod +x save_image.sh"
    exit 1
fi

PROMPT="$1"
FILENAME="${2:-generated_$(date +%s).png}"
STEPS="${3:-20}"
SIZE="${4:-512}"

# Escape quotes in prompt for JSON
ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/"/\\"/g')

# Build JSON payload
JSON_PAYLOAD="{\"prompt\": \"$ESCAPED_PROMPT\", \"steps\": $STEPS, \"width\": $SIZE, \"height\": $SIZE}"

echo "Generating image with prompt: '$PROMPT'"
echo "Steps: $STEPS, Size: ${SIZE}x${SIZE}"
echo "This may take 2-5 minutes on CPU..."

# Make API call and save to temp file
TEMP_FILE=$(mktemp)
curl -s -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" > "$TEMP_FILE"

# Check if request was successful (look for "success":true)
if grep -q '"success"[[:space:]]*:[[:space:]]*true' "$TEMP_FILE"; then
    # Extract base64 image data using sed and grep
    BASE64_DATA=$(grep -o '"image"[[:space:]]*:[[:space:]]*"[^"]*"' "$TEMP_FILE" | \
                  sed 's/"image"[[:space:]]*:[[:space:]]*"//g' | \
                  sed 's/"$//g' | \
                  sed 's/data:image\/png;base64,//g')
    
    # Decode and save image
    echo "$BASE64_DATA" | base64 -d > "$FILENAME"
    echo "✓ Image saved as: $FILENAME"
else
    echo "✗ Error generating image:"
    # Try to extract error message
    ERROR_MSG=$(grep -o '"error"[[:space:]]*:[[:space:]]*"[^"]*"' "$TEMP_FILE" | \
                sed 's/"error"[[:space:]]*:[[:space:]]*"//g' | \
                sed 's/"$//g')
    
    if [ -n "$ERROR_MSG" ]; then
        echo "$ERROR_MSG"
    else
        echo "Unknown error occurred"
        cat "$TEMP_FILE"
    fi
    rm -f "$TEMP_FILE"
    exit 1
fi

# Clean up
rm -f "$TEMP_FILE"