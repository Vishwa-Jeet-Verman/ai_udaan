#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="${APP_DIR}/frontend"

BACKEND_PORT="${BACKEND_PORT:-9000}"
WEB_PORT="${WEB_PORT:-54205}"
API_BASE_URL="${API_BASE_URL:-http://localhost:${BACKEND_PORT}/api}"

cd "${FRONTEND_DIR}"

echo "[dev-frontend] starting Flutter web on http://localhost:${WEB_PORT}"
echo "[dev-frontend] using API ${API_BASE_URL}"
flutter run -d chrome --web-port="${WEB_PORT}" --dart-define=API_BASE_URL="${API_BASE_URL}"
