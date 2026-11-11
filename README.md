# server-infra

Shared setup for the Oracle free-tier server. Every app on the server goes through the Caddy in this repo.

## What is here

- `edge/docker-compose.yml`: the one Caddy that owns ports 80 and 443 and creates the shared Docker network `edge`.
- `edge/Caddyfile`: one entry per public name. Each name points to an app's API.

## How apps connect

Each app repo has its own compose file and its own database. To be reachable through this Caddy, the app's API service:
1. joins the external network `edge`
2. has a network alias that matches the name in the Caddyfile (for example `gharbaar-api`, `bpa-api`)

Its database stays on the app's own private network, so it is never reachable from Caddy or the internet.

## Start order

1. `edge` first (creates the network): `cd edge && docker compose up -d`
2. then each app stack.

## Status

Not in use yet. Gharbaar still runs its own Caddy from `server/deploy` in the household-app repo. This repo is switched on when the BPA API is ready to deploy.

## Branches

Work goes to `develop`. `main` holds merged work.
