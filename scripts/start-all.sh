#!/usr/bin/env bash
# Start the full FOOD / Chez Mama local stack and optionally the Flutter app.
#
# Usage:
#   ./scripts/start-all.sh              Start Docker stack + print URLs
#   ./scripts/start-all.sh --flutter    Also run `flutter run`
#   ./scripts/start-all.sh --smoke      Start + run health checks
#   ./scripts/start-all.sh --stop       Stop containers
#   ./scripts/start-all.sh --logs       Tail all service logs
#   ./scripts/start-all.sh --help

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

RUN_FLUTTER=false
RUN_SMOKE=false
STOP_STACK=false
FOLLOW_LOGS=false
FLUTTER_DEVICE=""
FLUTTER_ARGS=()

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \?//'
  echo ""
  echo "Options:"
  echo "  --flutter          Launch Flutter after stack is healthy"
  echo "  -d, --device DEV   Flutter device id (e.g. linux, chrome, emulator-5554)"
  echo "  --smoke            Run health checks after start"
  echo "  --stop             Stop docker compose stack"
  echo "  --logs             Follow docker compose logs"
  echo "  --help             Show this help"
}

log()  { echo -e "${CYAN}==>${NC} $*"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing command: $1"
    exit 1
  fi
}

wait_for_url() {
  local url="$1"
  local label="$2"
  local max="${3:-60}"
  local i
  for i in $(seq 1 "$max"); do
    if curl -sf "$url" >/dev/null 2>&1; then
      ok "$label"
      return 0
    fi
    sleep 2
  done
  err "$label failed (timeout)"
  return 1
}

print_urls() {
  echo ""
  echo -e "${GREEN}Stack is ready.${NC}"
  echo ""
  echo "  API          http://127.0.0.1:8000/"
  echo "  Health       http://127.0.0.1:8000/health/"
  echo "  Swagger      http://127.0.0.1:8000/api/docs/"
  echo "  ReDoc        http://127.0.0.1:8000/api/redoc/"
  echo "  Admin        http://127.0.0.1:8000/admin/"
  echo "  MinIO UI     http://127.0.0.1:9001/  (minioadmin / minioadmin123)"
  echo "  Socket       http://127.0.0.1:3001/health"
  echo ""
  echo "Flutter (from chez_mama/):"
  echo "  flutter run                         # auto API URL per platform"
  echo "  flutter run -d linux                # Linux desktop"
  echo "  flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000  # physical phone"
  echo ""
  echo "Docs: docs/GETTING_STARTED.md"
  echo ""
}

start_stack() {
  require_cmd docker
  if ! docker compose version >/dev/null 2>&1; then
    err "Docker Compose v2 required (docker compose)"
    exit 1
  fi

  log "Starting Docker stack (Postgres, Redis, MinIO, Django, Socket)..."
  docker compose up -d --build --wait

  log "Waiting for Django health..."
  wait_for_url "http://127.0.0.1:8000/health/" "Django API" 45

  log "Waiting for Socket gateway..."
  wait_for_url "http://127.0.0.1:3001/health" "Socket gateway" 30

  print_urls
}

run_smoke() {
  require_cmd curl
  log "Running smoke checks..."
  curl -sf "http://127.0.0.1:8000/health/" | grep -q '"status": "ok"' && ok "Health JSON"
  curl -sf "http://127.0.0.1:8000/api/schema/" -o /dev/null && ok "OpenAPI schema"
  curl -sf "http://127.0.0.1:3001/health" | grep -q '"status":"ok"' && ok "Socket health"
  ok "All smoke checks passed"
}

run_flutter() {
  require_cmd flutter
  local lan_ip=""
  if [[ -x "$ROOT/scripts/detect-lan-ip.sh" ]]; then
    lan_ip="$("$ROOT/scripts/detect-lan-ip.sh" 2>/dev/null || true)"
  fi
  if command -v adb >/dev/null 2>&1; then
    if adb get-state >/dev/null 2>&1; then
      log "Configuring adb reverse for API (port 8000)..."
      adb reverse tcp:8000 tcp:8000 || true
      if [[ -n "$lan_ip" ]]; then
        log "Physical phone: using LAN API http://${lan_ip}:8000"
      fi
    fi
  fi
  log "Launching Flutter app..."
  cd "$ROOT/chez_mama"
  flutter pub get
  local cmd=(flutter run)
  if [[ -n "$FLUTTER_DEVICE" ]]; then
    cmd+=(-d "$FLUTTER_DEVICE")
  fi
  if [[ -n "$lan_ip" ]] && adb get-state >/dev/null 2>&1; then
    cmd+=(--dart-define=API_LAN_HOST="$lan_ip")
  fi
  if ((${#FLUTTER_ARGS[@]})); then
    cmd+=("${FLUTTER_ARGS[@]}")
  fi
  "${cmd[@]}"
}

stop_stack() {
  require_cmd docker
  log "Stopping Docker stack..."
  docker compose down
  ok "Stopped"
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --flutter) RUN_FLUTTER=true; shift ;;
    --smoke)   RUN_SMOKE=true; shift ;;
    --stop)    STOP_STACK=true; shift ;;
    --logs)    FOLLOW_LOGS=true; shift ;;
    -d|--device)
      FLUTTER_DEVICE="${2:-}"
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    --dart-define)
      FLUTTER_ARGS+=("$1" "${2:-}")
      shift 2
      ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if $STOP_STACK; then
  stop_stack
  exit 0
fi

if $FOLLOW_LOGS; then
  require_cmd docker
  docker compose logs -f
  exit 0
fi

start_stack
$RUN_SMOKE && run_smoke
$RUN_FLUTTER && run_flutter
