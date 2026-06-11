#!/usr/bin/env bash
# Run Flutter against local Docker backend (port 8000).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

resolve_flutter() {
  if [[ -n "${FLUTTER_ROOT:-}" && -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
    echo "${FLUTTER_ROOT}/bin/flutter"
    return 0
  fi
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return 0
  fi
  if [[ -x "$HOME/flutter/bin/flutter" ]]; then
    echo "$HOME/flutter/bin/flutter"
    return 0
  fi
  return 1
}

FLUTTER="$(resolve_flutter)" || {
  echo "✗ Flutter not found"
  exit 1
}

echo "==> Checking local backend..."
if ! curl -sf --max-time 3 http://127.0.0.1:8000/health/ >/dev/null; then
  echo "✗ Start backend first: cd $ROOT && docker compose up -d"
  exit 1
fi

cd "$ROOT/chez_mama"
exec "$FLUTTER" run --dart-define=USE_LOCAL_API=true "$@"
