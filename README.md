# Rocket.Chat Local Dev Stack

![Compose Lint](https://github.com/Canepro/rocketchat-local-dev/actions/workflows/compose-lint.yml/badge.svg?branch=main)

A local development docker-compose stack: Rocket.Chat + MongoDB + Redis + Traefik.

## Quickstart
`pwsh
cp .env.example .env

docker compose up -d
# Access: http://localhost:3000

# Reset volumes
docker compose down -v
`

## Upgrade
- Update image tags in .env.example and your .env
- docker compose pull && docker compose up -d

## License
MIT