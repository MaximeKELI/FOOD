#!/usr/bin/env bash
set -e
cd /app

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  python manage.py migrate --noinput
fi

if [ "${SEED_CATEGORIES:-false}" = "true" ]; then
  python manage.py seed_categories || true
fi

exec "$@"
