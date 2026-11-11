#!/bin/sh
# Shared migration runner for every app on the server.
#
# Applies each *.sql file in $MIGRATIONS_DIR (default /migrations), in name order.
# Each file runs once: its name is recorded in schema_migrations inside the same
# transaction as the file, so a failed file leaves nothing half-applied.
#
# Needs these environment variables from the caller:
#   PGHOST, PGUSER, PGDATABASE, PGPASSWORD
# Optional:
#   BASELINE_FILE  for a database that was created before this runner existed
#                  (for example 001_init.sql). Marked as applied, not re-run.
set -eu

MIGRATIONS_DIR="${MIGRATIONS_DIR:-/migrations}"

q() { psql -v ON_ERROR_STOP=1 -At -q -c "$1"; }

q "create table if not exists schema_migrations (
       filename   text primary key,
       applied_at timestamptz not null default now()
   );" >/dev/null

if [ -n "${BASELINE_FILE:-}" ]; then
    applied=$(q "select count(*) from schema_migrations")
    has_users=$(q "select to_regclass('public.users') is not null")
    if [ "$applied" = "0" ] && [ "$has_users" = "t" ]; then
        q "insert into schema_migrations (filename) values ('$BASELINE_FILE') on conflict do nothing" >/dev/null
        echo "baseline: marked $BASELINE_FILE as already applied"
    fi
fi

for file in "$MIGRATIONS_DIR"/*.sql; do
    [ -e "$file" ] || { echo "no migration files in $MIGRATIONS_DIR"; exit 0; }
    name=$(basename "$file")

    case "$name" in
        *[!A-Za-z0-9_.-]*) echo "refusing file name: $name" >&2; exit 1 ;;
    esac

    done_before=$(q "select count(*) from schema_migrations where filename = '$name'")
    if [ "$done_before" != "0" ]; then
        continue
    fi

    {
        echo "begin;"
        cat "$file"
        echo ";"
        echo "insert into schema_migrations (filename) values ('$name');"
        echo "commit;"
    } | psql -v ON_ERROR_STOP=1 -q
    echo "applied $name"
done

echo "migrations up to date"
