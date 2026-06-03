#!/usr/bin/env bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:8000}"
echo "==> GET $BASE/api/weather/suggestion/"
curl -sf "$BASE/api/weather/suggestion/?latitude=14.72&longitude=-17.47" | python3 -m json.tool
echo "OK"
