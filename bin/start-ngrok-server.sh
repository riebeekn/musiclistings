#!/usr/bin/env bash
#
# start-ngrok-server.sh
#
# Starts an ngrok tunnel to the local server, grabs the public https URL, renders it
# as a QR code so you can scan it with your phone camera. Handy for checking
# mobile/iOS-only behaviour without deploying.
#
# Usage:
#   ./bin/start-ngrok-server.sh            # tunnels http://localhost:4000
#   ./bin/start-ngrok-server.sh 4001       # tunnels a different port
#
# Requirements: a running dev server, the `ngrok` agent (>= 3.20).
# Dev config already sets `check_origin: false`, so the LiveView socket accepts the
# tunnel host.

set -euo pipefail

PORT="${1:-4000}"
NGROK_LOG="/tmp/start-ngrok-server-ngrok.log"
QR_PNG="/tmp/start-ngrok-server-qr.png"

# 1. Make sure something is actually serving on the port.
if ! curl -s -o /dev/null --max-time 2 "http://localhost:${PORT}"; then
  echo "✗ No server responding on http://localhost:${PORT}"
  echo "  Start it first (e.g. 'mix phx.server' or 'iex -S mix phx.server'), then re-run."
  exit 1
fi

# 2. Start ngrok unless its local API (port 4040) is already up.
if ! curl -s -o /dev/null --max-time 2 http://localhost:4040/api/tunnels; then
  echo "Starting ngrok tunnel to port ${PORT}…"
  ngrok http "${PORT}" --log=stdout > "${NGROK_LOG}" 2>&1 &
fi

# 3. Poll ngrok's local API for the public https URL.
URL=""
for _ in $(seq 1 20); do
  URL=$(curl -s --max-time 2 http://localhost:4040/api/tunnels 2>/dev/null \
        | sed -n 's/.*"public_url":"\(https:[^"]*\)".*/\1/p' | head -1)
  [ -n "${URL}" ] && break
  sleep 1
done

if [ -z "${URL}" ]; then
  echo "✗ Couldn't get an ngrok URL. Recent log:"
  tail -n 12 "${NGROK_LOG}" 2>/dev/null || true
  echo "  (If it mentions the agent is too old, run 'ngrok update'.)"
  exit 1
fi

TARGET="${URL}/events"
echo "✓ Public URL: ${TARGET}"

# 4. Render a QR code — prefer the local qrencode tool, fall back to a web service.
if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ANSIUTF8 "${TARGET}"            # print it in the terminal
  qrencode -o "${QR_PNG}" -s 10 -m 2 "${TARGET}"
else
  ENC=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "${TARGET}")
  curl -s "https://api.qrserver.com/v1/create-qr-code/?size=400x400&margin=10&data=${ENC}" -o "${QR_PNG}"
fi

echo "📱 Scan the QR (now open in Preview) with your phone camera, then tap the Safari banner."
echo "   First load shows ngrok's 'Visit Site' interstitial — tap through it."
echo "   Tunnel is running in the background; stop it with: ./bin/stop-ngrok-server.sh"
