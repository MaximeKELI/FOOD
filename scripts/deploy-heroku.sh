#!/usr/bin/env bash
# Deploy backend to Heroku (Docker container stack).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${HEROKU_APP:-allcoders}"

cd "$ROOT/backend"

echo "==> Stack container + déploiement Docker sur Heroku ($APP)"
heroku stack:set container -a "$APP"

echo "==> git push heroku master"
git push heroku master

echo "==> Scale web dyno"
heroku ps:scale web=1 -a "$APP"

echo "==> Health check"
sleep 8
curl -sf "https://${APP}-5eced76bab42.herokuapp.com/health/" || \
  curl -sf "https://${APP}.herokuapp.com/health/" || \
  heroku open -a "$APP"

heroku ps -a "$APP"
echo "✓ Déployé sur Heroku"
