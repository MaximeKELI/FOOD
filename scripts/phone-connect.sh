#!/usr/bin/env bash
# Connect a USB Android phone to the local FOOD backend.
# Usage:
#   ./scripts/phone-connect.sh          # adb reverse (127.0.0.1 on phone)
#   ./scripts/phone-connect.sh --wifi   # show Wi-Fi IP + flutter command
#   ./scripts/phone-connect.sh --run    # launch flutter with auto LAN IP
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIFI=false
RUN_FLUTTER=false

for arg in "$@"; do
  case "$arg" in
    --wifi) WIFI=true ;;
    --run) RUN_FLUTTER=true; WIFI=true ;;
    -h|--help)
      sed -n '2,6p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
  esac
done

LAN_IP="$("$ROOT/scripts/detect-lan-ip.sh" || true)"

echo "==> Checking backend..."
if curl -sf --max-time 3 http://127.0.0.1:8000/health/ >/dev/null; then
  echo "✓ Backend OK at http://127.0.0.1:8000"
else
  echo "✗ Backend not reachable. Start it with:"
  echo "  cd $ROOT && docker compose up -d"
  exit 1
fi

if [[ -n "$LAN_IP" ]]; then
  echo "✓ LAN IP (Wi-Fi): $LAN_IP"
  echo "  API URL for phone: http://${LAN_IP}:8000"
else
  echo "! Could not detect LAN IP (Wi-Fi)"
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "✗ adb not found. Install Android platform-tools."
  exit 1
fi

if ! adb get-state >/dev/null 2>&1; then
  echo "✗ No Android device detected. Plug in your phone and enable USB debugging."
  exit 1
fi

echo "==> Configuring adb reverse (USB fallback)..."
adb reverse tcp:8000 tcp:8000
adb reverse --list

echo ""
if [[ "$RUN_FLUTTER" == true ]]; then
  if [[ -z "$LAN_IP" ]]; then
    echo "✗ No LAN IP — cannot run with --run"
    exit 1
  fi
  exec "$ROOT/scripts/flutter-run-phone.sh"
fi

if [[ "$WIFI" == true ]] && [[ -n "$LAN_IP" ]]; then
  echo "Wi-Fi mode — run on phone (same network as PC):"
  echo "  cd $ROOT/chez_mama"
  echo "  flutter run --dart-define=API_LAN_HOST=$LAN_IP"
  echo ""
  echo "Or use the helper script:"
  echo "  ./scripts/flutter-run-phone.sh"
else
  echo "USB mode — restart app (127.0.0.1 via adb reverse):"
  echo "  Press R in flutter run"
  echo ""
  if [[ -n "$LAN_IP" ]]; then
    echo "For Wi-Fi (recommended if connection fails):"
    echo "  ./scripts/flutter-run-phone.sh"
  fi
fi
