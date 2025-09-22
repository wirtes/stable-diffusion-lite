# save_image.sh
#!/bin/bash
PROMPT="$1"
FILENAME="${2:-generated_$(date +%s).png}"
STEPS="$3"
DIMENSION="$4"

curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d "{
    \"prompt\": \"$PROMPT\",
    \"steps\": \"$STEPS\",
    \"width\": \"$DIMENSION\",
    \"height\": \"$DIMENSION\"
  }" \
  | jq -r '.image' \
  | sed 's/data:image\/png;base64,//' \
  | base64 -d > "$FILENAME"

echo "Image saved as: $FILENAME"