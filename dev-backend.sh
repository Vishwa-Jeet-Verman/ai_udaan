#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${APP_DIR}/backend"

cd "${BACKEND_DIR}"

echo "[dev-backend] starting backend on port ${PORT:-9000}"
node server.js
