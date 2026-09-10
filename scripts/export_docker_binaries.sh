#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-siemens_to_ismrmrd_artifacts}"
CONTAINER_NAME="${CONTAINER_NAME:-siemens_artifacts}"
OUTPUT_DIR="${1:-$ROOT_DIR/dist}"

BINARIES=(
  siemens_to_ismrmrd
  ismrmrd_to_siemens
)

mkdir -p "$OUTPUT_DIR"

docker build \
  --target siemens_to_ismrmrd_artifacts \
  -f "$ROOT_DIR/Dockerfile" \
  -t "$IMAGE_NAME" \
  "$ROOT_DIR"

if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

docker create --name "$CONTAINER_NAME" "$IMAGE_NAME" >/dev/null

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for binary in "${BINARIES[@]}"; do
  docker cp "$CONTAINER_NAME:/$binary" "$OUTPUT_DIR/$binary"
done

echo "Exported binaries to $OUTPUT_DIR"
