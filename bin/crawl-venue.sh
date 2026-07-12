#!/bin/bash
#
# crawl-venue.sh
#
# Crawls the given venues from THIS machine and writes the results straight to the
# production database on Render (via $PROD_DB_URL).
#
# This exists because some venues' origin servers silently drop Render's egress IP
# at the TCP layer, so the nightly crawl can never reach them - the connection just
# times out. They are reachable from a home/residential connection, so we crawl them
# here instead. The nightly crawl summary email prints the exact command to run for
# any venue that reported "No events found".
#
# Usage:
#   ./bin/crawl-venue.sh WiggleRoomParser
#   ./bin/crawl-venue.sh WiggleRoomParser JunctionUndergroundParser
#   ./bin/crawl-venue.sh --yes WiggleRoomParser

set -euo pipefail

SKIP_CONFIRM=false
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
  SKIP_CONFIRM=true
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "Error: no venues given."
  echo
  echo "Usage (venues are named by their parser module):"
  echo "  ./bin/crawl-venue.sh WiggleRoomParser"
  echo "  ./bin/crawl-venue.sh WiggleRoomParser JunctionUndergroundParser"
  exit 1
fi

if [[ -z "${PROD_DB_URL:-}" ]]; then
  echo "Error: PROD_DB_URL is not set."
  echo "Run 'source .envrc' (or enable direnv) and try again."
  exit 1
fi

if [[ "$SKIP_CONFIRM" != true ]]; then
  echo "This will crawl the following venues and write the results to the"
  echo "PRODUCTION database on Render:"
  echo
  for venue in "$@"; do
    echo "  - ${venue}"
  done
  echo
  read -r -p "Continue? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "==> Crawling against the production database..."
USE_PROD_DB=true mix crawl_venue "$@"
