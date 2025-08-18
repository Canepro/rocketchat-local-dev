#!/usr/bin/env bash
set -euo pipefail

# Create .env if missing
if [ ! -f .env ]; then
  echo "🔵 Creating .env from .env.example..."
  cp .env.example .env
  echo "✅ .env created. Edit it if you want to change versions or ports, then rerun ./up.sh"
  exit 0
fi

ENGINE=""
ENGINE_PRETTY=""
SOCKET_PATH=""

# Prefer Docker if available
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  ENGINE="docker compose"
  ENGINE_PRETTY="docker compose"
  # Detect if the docker CLI is actually a Podman shim (multiple heuristics)
  if docker compose version 2>&1 | grep -qi "Emulate Docker CLI using podman" \
    || docker info 2>&1 | grep -qi "podman" \
    || docker -v 2>&1 | grep -qi "podman"; then
    SOCKET_PATH="/run/user/$(id -u)/podman/podman.sock"
    systemctl --user enable --now podman.socket 2>/dev/null || true
    ENGINE_PRETTY="docker compose (podman shim)"
  else
    SOCKET_PATH="/var/run/docker.sock"
  fi
# Podman (newer: 'podman compose')
elif command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  ENGINE="podman compose"
  ENGINE_PRETTY="podman compose"
  SOCKET_PATH="/run/user/$(id -u)/podman/podman.sock"
  systemctl --user enable --now podman.socket 2>/dev/null || true
# Podman (older: 'podman-compose')
elif command -v podman >/dev/null 2>&1 && command -v podman-compose >/dev/null 2>&1; then
  ENGINE="podman-compose"
  ENGINE_PRETTY="podman-compose"
  SOCKET_PATH="/run/user/$(id -u)/podman/podman.sock"
  systemctl --user enable --now podman.socket 2>/dev/null || true
else
  echo "❌ Neither Docker (with Compose) nor Podman (with compose) was found."
  echo "   Install Docker Desktop OR Podman + podman-compose."
  exit 1
fi

# If using Podman socket, persist it to .env for docker-compose v1 compatibility
if [ -n "$SOCKET_PATH" ] && [ "$SOCKET_PATH" != "/var/run/docker.sock" ]; then
  if grep -q '^CONTAINER_SOCKET=' .env 2>/dev/null; then
    sed -i "s|^CONTAINER_SOCKET=.*$|CONTAINER_SOCKET=$SOCKET_PATH|" .env 2>/dev/null || true
  else
    printf '\nCONTAINER_SOCKET=%s\n' "$SOCKET_PATH" >> .env
  fi
fi

# Export the socket path so docker-compose.yml can mount it
export CONTAINER_SOCKET="${CONTAINER_SOCKET:-$SOCKET_PATH}"

echo "🚀 Starting with ${ENGINE_PRETTY}..."
# shellcheck disable=SC2086
$ENGINE up -d

# Wait for MongoDB to be ready
echo "⏳ Waiting for MongoDB to be ready..."
# shellcheck disable=SC2086
until $ENGINE exec -T mongo mongosh --eval "db.runCommand('ping').ok" >/dev/null 2>&1; do
  echo -n "."
  sleep 2
done
echo
echo "✅ MongoDB is ready."

# Initialize replica set (idempotent)
echo "⚙️ Initializing MongoDB replica set (if needed)..."
# shellcheck disable=SC2086
$ENGINE exec -T mongo mongosh --quiet --eval "try { rs.status().ok } catch (e) { 0 }" | grep -q "1" || \
# shellcheck disable=SC2086
$ENGINE exec -T mongo mongosh --eval "rs.initiate()"

HTTP_PORT="$(grep -E '^TRAEFIK_HTTP_PORT=' .env | cut -d '=' -f2 || true)"
HTTP_PORT="${HTTP_PORT:-8080}"

echo "🎉 Rocket.Chat should be available at: http://localhost:${HTTP_PORT}"
echo "📊 Traefik dashboard (insecure, dev only): http://localhost:8081"
