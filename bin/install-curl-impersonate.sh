#!/bin/bash
#
# install-curl-impersonate.sh
#
# Downloads the curl-impersonate binary for this machine into bin/curl-impersonate/
# (gitignored). The crawler shells out to it for venues behind a Cloudflare
# challenge that rejects the BEAM's TLS fingerprint - currently Massey Hall,
# Roy Thomson Hall and TD Music Hall (see MusicListings.HttpClient.CurlImpersonate).
# Without it those venues report "No events found" when crawled locally.
#
# Keep the version/checksums in step with the Dockerfile, which installs the
# same release for the nightly crawl on Render.
#
# Usage:
#   ./bin/install-curl-impersonate.sh

set -euo pipefail

VERSION="2.2.2"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)
    ASSET="arm64-macos"
    SHA256="22924f1463f7daab8cdc28d12304a39f2292232529683598f47d2c32866b964f"
    ;;
  Linux-x86_64)
    ASSET="x86_64-linux-gnu"
    SHA256="94f036c2fd18d1201fae73e3bc24332f3dff7c62bb4888afeaa744fd50dd998f"
    ;;
  Linux-aarch64)
    ASSET="aarch64-linux-gnu"
    SHA256="30d48cd8cb6a0652555192b4214ea26448905f02d00b2b27c82dcb4d131f2c58"
    ;;
  *)
    echo "Error: no known curl-impersonate build for $(uname -s)-$(uname -m)."
    echo "See https://github.com/lexiforest/curl-impersonate/releases/tag/v${VERSION}"
    exit 1
    ;;
esac

TARBALL="curl-impersonate-v${VERSION}.${ASSET}.tar.gz"
URL="https://github.com/lexiforest/curl-impersonate/releases/download/v${VERSION}/${TARBALL}"
DEST_DIR="$(cd "$(dirname "$0")" && pwd)/curl-impersonate"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading ${URL}"
curl -fsSL -o "${TMP_DIR}/${TARBALL}" "$URL"
echo "${SHA256}  ${TMP_DIR}/${TARBALL}" | shasum -a 256 -c -

mkdir -p "$DEST_DIR"
tar -xzf "${TMP_DIR}/${TARBALL}" -C "$DEST_DIR" curl-impersonate
chmod +x "${DEST_DIR}/curl-impersonate"

echo "Installed ${DEST_DIR}/curl-impersonate"
"${DEST_DIR}/curl-impersonate" --version | head -1
