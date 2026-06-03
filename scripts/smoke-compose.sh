#!/usr/bin/env bash
# Smoke test for local docker-compose stack.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Starting compose stack..."
docker compose up -d --build --wait

echo "==> Health check (Django)..."
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8000/health/ | grep -q '"status": "ok"'; then
    echo "Django OK"
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "Django health failed"
    docker compose logs django
    exit 1
  fi
done

echo "==> OpenAPI schema..."
curl -sf http://127.0.0.1:8000/api/schema/ -o /dev/null
echo "Schema OK"

echo "==> Socket gateway health..."
curl -sf http://127.0.0.1:3001/health | grep -q '"status":"ok"'
echo "Socket OK"

echo "==> All smoke checks passed."
