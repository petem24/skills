#!/usr/bin/env bash
# Upload images to ImgBB and print a markdown image link for each one.
#
# Usage: upload.sh [-e seconds] image...
#   -e  delete the images after this many seconds (60-15552000)
#
# Requires IMGBB_API_KEY in the environment. Uploaded images are public.
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") [-e seconds] image..." >&2
  exit 2
}

expiration=""
while getopts "e:" opt; do
  case "$opt" in
    e) expiration="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ "$#" -gt 0 ] || usage

if [ -z "${IMGBB_API_KEY:-}" ]; then
  echo "IMGBB_API_KEY is not set. Run: bash <(curl -fsSL https://raw.githubusercontent.com/petem24/skills/main/setup.sh)" >&2
  exit 1
fi

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "Not a file: $file" >&2
    exit 1
  fi

  name="$(basename "$file")"
  args=(-sS --fail-with-body -F "key=$IMGBB_API_KEY" -F "image=@$file" -F "name=${name%.*}")
  [ -n "$expiration" ] && args+=(-F "expiration=$expiration")

  if ! response="$(curl "${args[@]}" https://api.imgbb.com/1/upload)"; then
    echo "Upload failed for $file: $response" >&2
    exit 1
  fi

  url="$(printf '%s' "$response" | grep -o '"url":"[^"]*"' | head -n 1 | cut -d '"' -f 4 | sed 's#\\/#/#g')"
  if [ -z "$url" ]; then
    echo "Unexpected response for $file: $response" >&2
    exit 1
  fi

  echo "![${name%.*}]($url)"
done
