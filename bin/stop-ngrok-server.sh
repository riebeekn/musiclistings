#!/usr/bin/env bash
#
# stop-ngrok-server.sh — stop the ngrok tunnel started by start-ngrok-server.sh.
#
# Kills any background ngrok agent and cleans up the temp log/QR files it left
# behind. Safe to run even if no tunnel is currently up.
#
# Usage:
#   ./bin/stop-ngrok-server.sh

set -euo pipefail

NGROK_LOG="/tmp/ngrok-server-ngrok.log"
QR_PNG="/tmp/ngrok-server-qr.png"

# 1. Stop the ngrok agent if it's running.
if pgrep -f 'ngrok http' >/dev/null 2>&1; then
  pkill -f 'ngrok http'
  echo "✓ Stopped ngrok tunnel."
else
  echo "No ngrok tunnel running — nothing to stop."
fi

# 2. Tidy up the temp files ngrok-server.sh created.
rm -f "${NGROK_LOG}" "${QR_PNG}"
