#!/usr/bin/env bash
# Linux desktop launcher: libmpv for media_kit (video_player_media_kit).
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
LIBROOT="$ROOT/.local-libs"
LIBDIR="$LIBROOT/usr/lib/x86_64-linux-gnu"
PCDIR="$LIBDIR/pkgconfig"

if [[ ! -f "$PCDIR/mpv.pc" || ! -e "$LIBDIR/libmpv.so" ]]; then
  echo "Missing local libmpv under $LIBROOT" >&2
  echo "Install system packages (recommended):" >&2
  echo "  sudo apt install libmpv-dev mpv libmpv2" >&2
  exit 1
fi

# Ensure mpv.pc points at the local tree (deb extract uses prefix=/usr).
cat > "$PCDIR/mpv.pc" <<EOF
prefix=$LIBROOT/usr
exec_prefix=\${prefix}
libdir=\${prefix}/lib/x86_64-linux-gnu
includedir=\${prefix}/include

Name: mpv
Description: mpv media player client library
Version: 2.5.0
Libs: -L\${libdir} -lmpv
Cflags: -I\${includedir}
EOF

export PKG_CONFIG_PATH="$PCDIR:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$LIBDIR:${LD_LIBRARY_PATH:-}"
# Help the linker find libmpv.so at link + runtime
export LIBRARY_PATH="$LIBDIR:${LIBRARY_PATH:-}"
export CPATH="$LIBROOT/usr/include:${CPATH:-}"
export CMAKE_PREFIX_PATH="$LIBROOT/usr:${CMAKE_PREFIX_PATH:-}"

cd "$APP_DIR"
exec flutter run -d linux "$@"
