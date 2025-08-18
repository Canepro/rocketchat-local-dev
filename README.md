# Rocket.Chat Local Dev Stack

![Compose Lint](https://github.com/Canepro/rocketchat-local-dev/actions/workflows/compose-lint.yml/badge.svg?branch=main)

Set up Rocket.Chat locally with MongoDB, Redis, and Traefik in one command.
Works with Docker or Podman. Designed to be beginner‑friendly.

## Prerequisites

- One of:
  - Docker Desktop (or Docker Engine with Compose)
  - Podman + podman-compose (or Podman with `podman compose`)
- Bash shell (macOS, Linux, or WSL)

Tip for Windows users: run this in WSL for the smoothest experience.

## Quick start (one command)

```bash
./up.sh
```

What this does:

- Creates `.env` from `.env.example` if it doesn’t exist
- Detects Docker or Podman automatically
- Starts all services
- Waits for MongoDB and initializes the replica set (required by Rocket.Chat)

Open:

- Rocket.Chat: [http://localhost:8080](http://localhost:8080)
- Traefik Dashboard (dev only): [http://localhost:8081](http://localhost:8081)

If you get “permission denied” running scripts, make them executable once:

```bash
chmod +x up.sh down.sh upgrade.sh
```

## Common tasks

- Stop and remove everything:

  ```bash
  ./down.sh
  ```

- Upgrade Rocket.Chat (or other images):
  1) Edit `.env` and bump the image tag(s), e.g. `ROCKETCHAT_IMAGE=rocketchat/rocket.chat:7.5.1`
  2) Apply the upgrade:

  ```bash
  ./upgrade.sh
  ```

- Change the port (served by Traefik):

  ```env
  TRAEFIK_HTTP_PORT=8080
  ```

  Then restart:

  ```bash
  ./down.sh && ./up.sh
  ```

## How it works (simple overview)

- Traefik reverse‑proxies [http://localhost:8080](http://localhost:8080) → Rocket.Chat on port 3000
- We use Traefik’s file provider (no Docker/Podman socket needed)
- MongoDB runs as a single‑node replica set (Rocket.Chat requirement)
- Redis is used for performance and realtime features

## Best practices (local dev)

- Keep your customizations in `.env` (image tags, ports, project name)
- Prefer `podman compose` on Linux if you’re using Podman; the scripts detect it too
- Avoid mapping container ports publicly beyond what you need (we expose 8080 and 8081 only)
- Use volumes for data (`mongo-data` is persisted) and `./down.sh` to reset cleanly
- For production, do NOT use this stack as-is. Secure Traefik (TLS, auth), harden MongoDB, add backups, etc.

## Logs and troubleshooting

- Service logs:
  - Docker: `docker compose logs -f <service>`
  - Podman: `podman compose logs -f <service>` or `podman-compose logs -f <service>`
- Useful services to check: `rocketchat`, `mongo`, `traefik`
- If you previously saw `/var/run/docker.sock` permission errors: fixed. Traefik now uses a file provider.

## File layout

- `docker-compose.yml`: services (Traefik, MongoDB, Redis, Rocket.Chat)
- `traefik/dynamic.yml`: Traefik routing (no engine socket required)
- `up.sh` / `down.sh` / `upgrade.sh`: one‑click start/stop/upgrade scripts
- `.env.example`: defaults you can copy to `.env`

## License

MIT
