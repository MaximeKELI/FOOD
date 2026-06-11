#!/usr/bin/env bash
set -e
cd /app

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  python manage.py migrate --noinput
fi

if [ "${SEED_CATEGORIES:-false}" = "true" ]; then
  python manage.py seed_categories || true
fi

if [ "$#" -eq 0 ]; then
  exec gunicorn food_api.wsgi:application \
    --bind "0.0.0.0:${PORT:-8000}" \
    --workers 3 \
    --timeout 120
fi

exec "$@"
