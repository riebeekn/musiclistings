#!/bin/bash
#
# pull-prod-db.sh
#
# Dumps the production database from Render (via $PROD_DB_URL) and restores it
# into the local development database, so you can develop/test against the
# latest crawl data without running the crawler locally.
#
# Requires $PROD_DB_URL to be set (see .envrc). Run `source .envrc` or use
# direnv first if it isn't. Pass --yes/-y to skip the confirmation prompt.

set -euo pipefail

# Local dev database settings (defaults match config/dev.exs).
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASS="${LOCAL_DB_PASS:-postgres}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-music_listings_dev}"

SKIP_CONFIRM=false
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
  SKIP_CONFIRM=true
fi

if [[ -z "${PROD_DB_URL:-}" ]]; then
  echo "Error: PROD_DB_URL is not set."
  echo "Run 'source .envrc' (or enable direnv) and try again."
  exit 1
fi

if [[ "$SKIP_CONFIRM" != true ]]; then
  echo "This will DROP and overwrite your local database '${LOCAL_DB_NAME}'"
  echo "on ${LOCAL_DB_HOST}:${LOCAL_DB_PORT} with production data."
  read -r -p "Continue? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

PG_DUMP="${PG_DUMP:-pg_dump}"

DUMP_FILE="$(mktemp -t music_listings_prod.XXXXXX.sql)"
trap 'rm -f "$DUMP_FILE"' EXIT

echo "==> Dumping production database from Render (using ${PG_DUMP})..."
PGSSLMODE=require "$PG_DUMP" "$PROD_DB_URL" \
  --no-owner --no-privileges --no-acl \
  --file "$DUMP_FILE"

echo "==> Recreating local database '${LOCAL_DB_NAME}'..."
export PGPASSWORD="$LOCAL_DB_PASS"
dropdb --if-exists --force -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" "$LOCAL_DB_NAME"
createdb -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" "$LOCAL_DB_NAME"

echo "==> Restoring production data into '${LOCAL_DB_NAME}'..."
psql -q -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$LOCAL_DB_NAME" -f "$DUMP_FILE"

echo "==> Done. '${LOCAL_DB_NAME}' now contains the latest production data."
