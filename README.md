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

In use on `hearth`. This Caddy serves both `gharbaar.duckdns.org` (Gharbaar API) and `bpaplatform.duckdns.org` (BPA API). Gharbaar's compose file no longer contains a Caddy.

## Branches

Work goes to `develop`. `main` holds merged work.

## Migration runner

`migrate/migrate.sh` applies database changes for any app on the server.

- Each app keeps its SQL files in its own repo (for example `server/db/migrations`).
- The runner applies each file once, in name order, inside a transaction together with its record in `schema_migrations`.
- A failed file stops the run and leaves nothing recorded.
- Existing databases created before the runner: set `BASELINE_FILE` to the first file, so it is marked as applied and not run again.

It is run as a one-shot container before the app's API starts. The app's compose file mounts its migrations folder at `/migrations` and this folder at `/infra`. The `migrate` service in the app compose file is added when that app's first new migration is ready.
