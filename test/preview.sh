#!/usr/bin/env bash
# Buduje obraz z Mintem + skryptami Babci i uruchamia podgląd pulpitu w przeglądarce.
#   ./test/preview.sh                 # Mint 22.3, 1366x768
#   GEOMETRY=1024x768 ./test/preview.sh
#   BASE_IMAGE=linuxmintd/mint22.2-amd64:latest ./test/preview.sh
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE=babcia-preview
build_args=()
[[ -n "${BASE_IMAGE:-}" ]] && build_args+=(--build-arg "BASE_IMAGE=$BASE_IMAGE")

docker build "${build_args[@]}" -t "$IMAGE" -f test/Dockerfile .
docker rm -f "$IMAGE" >/dev/null 2>&1 || true
exec docker run --rm -it --name "$IMAGE" \
  --shm-size=1g \
  -e GEOMETRY="${GEOMETRY:-1366x768}" \
  -p 127.0.0.1:6080:6080 \
  "$IMAGE"
