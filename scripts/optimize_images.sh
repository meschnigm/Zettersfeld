#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="bilder"
OUTPUT_DIR="bilder/optimized"
WIDTHS=(800 1600)
QUALITY=78
DELETE_ORIGINALS=false

if [[ "${1:-}" == "--delete-originals" ]]; then
  DELETE_ORIGINALS=true
fi

mkdir -p "$OUTPUT_DIR"

slugify() {
  local name="$1"
  name="${name,,}"
  name="${name//ä/ae}"
  name="${name//ö/oe}"
  name="${name//ü/ue}"
  name="${name//ß/ss}"
  name="${name// /-}"
  name="${name//_/-}"
  name="$(echo "$name" | sed -E 's/[^a-z0-9.-]+/-/g; s/-+/-/g; s/^-|-$//g')"
  echo "$name"
}

mapfile -d '' files < <(find "$INPUT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.tif" -o -iname "*.tiff" -o -iname "*.heic" -o -iname "*.heif" \) ! -path "$OUTPUT_DIR/*" -print0)

for input in "${files[@]}"; do
  rel="${input#$INPUT_DIR/}"
  stem="${rel%.*}"
  slug="$(slugify "$stem")"

  for width in "${WIDTHS[@]}"; do
    output="$OUTPUT_DIR/${slug}-${width}.webp"
    ffmpeg -y -hide_banner -loglevel error \
      -i "$input" \
      -vf "scale='min(${width},iw)':-2" \
      -q:v "$QUALITY" \
      "$output"
  done

  if [[ "$DELETE_ORIGINALS" == true && "$input" != "$OUTPUT_DIR"/* ]]; then
    rm -f "$input"
  fi

done

echo "Optimierte Bilder erstellt in: $OUTPUT_DIR"
if [[ "$DELETE_ORIGINALS" == true ]]; then
  echo "Originaldateien wurden gelöscht."
fi
