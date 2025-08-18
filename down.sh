#!/usr/bin/env bash
set -euo pipefail

ENGINE=""
ENGINE_PRETTY=""

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  ENGINE="docker compose"
  ENGINE_PRETTY="docker compose"
elif command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  ENGINE="podman compose"
  ENGINE_PRETTY="podman compose"
elif command -v podman-compose >/dev/null 2>&1; then
  ENGINE="podman-compose"
  ENGINE_PRETTY="podman-compose"
else
  echo "❌ Neither Docker nor Podman compose found."
  exit 1
fi

echo "🧹 Stopping and removing containers, networks, and volumes with ${ENGINE_PRETTY}..."
# shellcheck disable=SC2086
$ENGINE down -v --remove-orphans
echo "✅ Done."
