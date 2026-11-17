#!/usr/bin/env bash
# Build Meshtastic 2.8.2 for RAK11200 with MQTT enabled.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"

# Find PlatformIO (VS Code extension install or Homebrew/pip)
PIO="$(command -v pio || true)"
[ -z "$PIO" ] && [ -x "$HOME/.platformio/penv/bin/pio" ] && PIO="$HOME/.platformio/penv/bin/pio"
if [ -z "$PIO" ]; then
  echo "PlatformIO not found. Install with: brew install platformio   (or: pip3 install platformio)"; exit 1
fi
echo "Using $PIO"

# Meshtastic 2.8.x (pioarduino espressif32 55.x) needs PlatformIO Core >= 6.2.0
VER="$("$PIO" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+[^ ]*' | head -1)"
# dev/post builds like 6.2.0-post.1 count as *older* than 6.2.0 for the platform check
if [[ "$VER" == *-* ]] || [ "$(printf '%s\n' 6.2.0 "$VER" | sort -V | head -1)" != "6.2.0" ]; then
  echo "PlatformIO Core $VER is too old (need >= 6.2.0). Upgrade with:"
  case "$PIO" in
    */.platformio/penv/*) echo "  $HOME/.platformio/penv/bin/python -m pip install --force-reinstall 'platformio==6.2.0'" ;;
    /opt/homebrew/*|/usr/local/*) echo "  brew upgrade platformio   (or: $PIO upgrade)" ;;
    *) echo "  $PIO upgrade   (or: pip3 install -U platformio)" ;;
  esac
  exit 1
fi

cd firmware
grep -q "MESHTASTIC_EXCLUDE_MQTT" variants/esp32/rak11200/platformio.ini \
  && { echo "MQTT exclusion is still present - patch not applied?"; exit 1; }

if ! "$PIO" run -e rak11200 2>&1 | tee "$ROOT/build.log"; then
  echo
  if grep -q "overflowed" "$ROOT/build.log"; then
    grep "overflowed" "$ROOT/build.log"
    echo "Memory overflow. Add more -DMESHTASTIC_EXCLUDE_...=1 flags to"
    echo "firmware/variants/esp32/rak11200/platformio.ini (see README.md) and rerun."
  fi
  exit 1
fi

mkdir -p "$ROOT/output"
cp .pio/build/rak11200/firmware-rak11200-*.bin .pio/build/rak11200/littlefs-rak11200-*.bin "$ROOT/output/"
echo; grep -E "^(RAM|Flash):" "$ROOT/build.log" || true
echo; echo "Done. Firmware images in: $ROOT/output"; ls -1 "$ROOT/output"
