#!/usr/bin/env bash
# Production entrypoint — Gunicorn + collectstatic.
set -e
cd "$(dirname "$0")"

PY="./venv/bin/python"
GUNICORN="./venv/bin/gunicorn"

if [ ! -x "$PY" ]; then
  echo "venv introuvable. Lance: python3 -m venv venv && ./venv/bin/pip install -r requirements.txt"
  exit 1
fi

"$PY" manage.py migrate --noinput
"$PY" manage.py collectstatic --noinput

exec "$GUNICORN" food_api.wsgi:application -c gunicorn.conf.py
