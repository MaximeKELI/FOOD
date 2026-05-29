#!/usr/bin/env bash
# Démarre le serveur backend Food.
# Usage : ./run.sh
set -e
cd "$(dirname "$0")"

PY="./venv/bin/python"
if [ ! -x "$PY" ]; then
  echo "Environnement virtuel introuvable (venv/). Crée-le avec : python3 -m venv venv && ./venv/bin/pip install -r requirements.txt"
  exit 1
fi

# 0.0.0.0 => accessible depuis un téléphone sur le même Wi-Fi (http://<IP_PC>:8000)
exec "$PY" manage.py runserver 0.0.0.0:8000
