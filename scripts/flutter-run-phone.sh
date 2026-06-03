#!/usr/bin/env bash
# Run Flutter on a physical phone with auto-detected LAN API URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAN_IP="$("$ROOT/scripts/detect-lan-ip.sh")"

if [[ -z "$LAN_IP" ]]; then
  echo "✗ Could not detect LAN IP. Set manually:"
  echo "  flutter run --dart-define=API_LAN_HOST=YOUR_PC_IP"
  exit 1
fi

echo "==> LAN IP for API: $LAN_IP"
echo "    (Phone and PC must be on the same Wi-Fi)"

if curl -sf --max-time 3 "http://127.0.0.1:8000/health/" >/dev/null; then
  echo "✓ Backend OK"
else
  echo "✗ Start backend first: cd $ROOT && docker compose up -d"
  exit 1
fi

if command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
  adb reverse tcp:8000 tcp:8000 2>/dev/null || true
fi

cd "$ROOT/chez_mama"
exec flutter run --dart-define=API_LAN_HOST="$LAN_IP" "$@"
