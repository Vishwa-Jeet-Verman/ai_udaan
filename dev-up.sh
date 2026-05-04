#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKEND_PORT="${BACKEND_PORT:-9000}"
WEB_PORT="${WEB_PORT:-54205}"
API_BASE_URL="${API_BASE_URL:-http://localhost:${BACKEND_PORT}/api}"

LOG_DIR="${APP_DIR}/.dev-logs"
BACKEND_LOG="${LOG_DIR}/backend.log"

mkdir -p "${LOG_DIR}"

echo "[dev-up] booting backend on ${BACKEND_PORT}"
PORT="${BACKEND_PORT}" "${APP_DIR}/dev-backend.sh" >"${BACKEND_LOG}" 2>&1 &
BACKEND_PID=$!

cleanup() {
  if kill -0 "${BACKEND_PID}" >/dev/null 2>&1; then
    echo "[dev-up] stopping backend (${BACKEND_PID})"
    kill "${BACKEND_PID}" >/dev/null 2>&1 || true
    wait "${BACKEND_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

echo "[dev-up] waiting for backend health"
READY=0
for _ in {1..30}; do
  if curl -fsS "http://localhost:${BACKEND_PORT}/api/health" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done

if [[ "${READY}" -ne 1 ]]; then
  echo "[dev-up] backend did not become healthy"
  echo "[dev-up] backend log: ${BACKEND_LOG}"
  tail -n 80 "${BACKEND_LOG}" || true
  exit 1
fi

echo "[dev-up] backend ready"
BACKEND_PORT="${BACKEND_PORT}" WEB_PORT="${WEB_PORT}" API_BASE_URL="${API_BASE_URL}" "${APP_DIR}/dev-frontend.sh"
