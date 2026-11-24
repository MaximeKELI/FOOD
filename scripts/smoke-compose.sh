#!/usr/bin/env bash
# Smoke test for local docker-compose stack.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Starting compose stack..."
docker compose up -d --build --wait

echo "==> Health check (Django)..."
for i in $(seq 1 40); do
  body="$(curl -sf http://127.0.0.1:8000/health/ || true)"
  if echo "$body" | grep -q '"status": "ok"'; then
    echo "Django OK: $body"
    break
  fi
  sleep 2
  if [ "$i" -eq 40 ]; then
    echo "Django health failed: $body"
    docker compose logs --tail=80 django
    exit 1
  fi
done

echo "==> OpenAPI schema..."
curl -sf http://127.0.0.1:8000/api/schema/ -o /dev/null
echo "Schema OK"

echo "==> Socket authorize rejects bad secret..."
code="$(curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:8000/api/internal/socket-authorize/ \
  -H 'Content-Type: application/json' \
  -H 'X-Internal-Secret: wrong' \
  -d '{"user_id":1,"rooms":["user:1"]}')"
if [ "$code" != "403" ]; then
  echo "Expected 403 from socket-authorize, got $code"
  exit 1
fi
echo "Socket authorize ACL OK"

echo "==> Socket gateway health..."
curl -sf http://127.0.0.1:3001/health | grep -q '"status":"ok"'
echo "Socket OK"

echo "==> All smoke checks passed."
