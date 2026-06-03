#!/usr/bin/env bash
# Run Flutter on a physical phone — auto-detects best API URL (USB adb reverse first).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAN_IP="$("$ROOT/scripts/detect-lan-ip.sh" || true)"

echo "==> Checking backend..."
if curl -sf --max-time 3 http://127.0.0.1:8000/health/ >/dev/null; then
  echo "✓ Backend OK at http://127.0.0.1:8000"
else
  echo "✗ Start backend first: cd $ROOT && docker compose up -d"
  exit 1
fi

if curl -sf --max-time 5 http://127.0.0.1:8000/api/weather/suggestion/ >/dev/null; then
  echo "✓ Weather API OK"
else
  echo "✗ Weather API missing (404) — redémarre Django :"
  echo "  cd $ROOT && docker compose restart django"
  echo "  docker compose exec django python manage.py migrate"
  exit 1
fi

ADB_OK=false
if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
  ADB_OK=true
  echo "==> USB phone detected — configuring adb reverse..."
  adb reverse tcp:8000 tcp:8000
  adb reverse --list
  echo "    App will use http://127.0.0.1:8000 on the phone (most reliable)"
fi

cd "$ROOT/chez_mama"

if [[ "$ADB_OK" == true ]]; then
  echo "==> Launching (USB mode)"
  exec flutter run "$@"
fi

if [[ -z "$LAN_IP" ]]; then
  echo "✗ No LAN IP and no USB device. Plug phone via USB or set:"
  echo "  flutter run --dart-define=API_LAN_HOST=YOUR_PC_IP"
  exit 1
fi

echo "==> No USB — Wi-Fi mode, LAN IP: $LAN_IP"
echo "    Phone and PC must be on the same Wi-Fi"
exec flutter run --dart-define=API_LAN_HOST="$LAN_IP" "$@"
