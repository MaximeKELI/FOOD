#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export LD_LIBRARY_PATH="$ROOT/.local-libs/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
cd "$(dirname "$0")"
exec flutter run -d linux "$@"
