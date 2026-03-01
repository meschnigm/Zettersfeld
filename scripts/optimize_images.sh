#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="bilder"
OUTPUT_DIR="bilder/optimized"
WIDTHS=(800 1600)
QUALITY=78

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

shopt -s nullglob
for input in "$INPUT_DIR"/*.{jpg,jpeg,JPG,JPEG,png,PNG,tif,tiff,TIF,TIFF}; do
  base="$(basename "$input")"
  stem="${base%.*}"
  slug="$(slugify "$stem")"

  for width in "${WIDTHS[@]}"; do
    output="$OUTPUT_DIR/${slug}-${width}.webp"
    ffmpeg -y -hide_banner -loglevel error \
      -i "$input" \
      -vf "scale='min(${width},iw)':-2" \
      -q:v "$QUALITY" \
      "$output"
  done

done

echo "Optimierte Bilder erstellt in: $OUTPUT_DIR"
