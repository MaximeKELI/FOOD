#!/usr/bin/env bash
# Free disk space for Flutter/Android builds (safe caches only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Disk before:"
df -h / | tail -1

echo "==> Flutter clean (chez_mama)..."
if command -v flutter >/dev/null 2>&1; then
  (cd "$ROOT/chez_mama" && flutter clean) || true
fi
rm -rf "$ROOT/chez_mama/build" \
       "$ROOT/chez_mama/android/.gradle" \
       "$ROOT/chez_mama/android/app/build" 2>/dev/null || true

echo "==> Gradle caches (keeps current 8.11.1, removes other versions)..."
if [[ -d "$HOME/.gradle/caches" ]]; then
  for ver in 8.7 8.8 8.9 8.10.2 8.12 8.12.1 8.13; do
    rm -rf "$HOME/.gradle/caches/$ver" 2>/dev/null || true
  done
  rm -rf "$HOME/.gradle/daemon" 2>/dev/null || true
fi

echo "==> Disk after:"
df -h / | tail -1
echo ""
echo "If still low on space, also try:"
echo "  docker system prune -a          # if Docker installed"
echo "  rm -rf ~/.cache/pip"
echo "  conda clean -a                  # if using conda"
