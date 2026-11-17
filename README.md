# Meshtastic 2.8.2 for RAK11200 with MQTT

- `firmware/`: meshtastic/firmware at tag **v2.8.2.d5f1619** (newest release, an Alpha), with submodules
- `rak11200-enable-mqtt.patch`: the only change, which removes `-DMESHTASTIC_EXCLUDE_MQTT=1`
  from `variants/esp32/rak11200/platformio.ini`
- `build.sh`: builds the `rak11200` env and copies the images to `output/`

## Build
    cd ~/Claude_Cowork/meshtastic_rak11200 && ./build.sh
The first run downloads the ESP32 toolchain and libraries (around 1 GB, several minutes).

## Flash
Use `output/firmware-rak11200-*.factory.bin` for a full install (this erases settings):
- https://flasher.meshtastic.org → "Open custom .bin", or
- `esptool --port /dev/cu.usbserial-XXXX write-flash 0x0 output/firmware-rak11200-*.factory.bin`

Optional, after the factory image: `esptool --port ... write-flash 0x300000 output/littlefs-rak11200-*.bin`.
This is only the web UI files (the web server is excluded on this board); if you skip it, the node formats an empty filesystem on first boot.
For BLE/WiFi OTA updates later, also flash `mt-esp32-ota.bin` (from the official 2.8.2 release zip) at `0x260000`.

Use the plain (non-factory) `.bin` to update a node that already runs Meshtastic, for example over WiFi OTA.

## If the link step overflows memory (IRAM / dram0 / flash)
Add any of these lines under `build_flags` in `firmware/variants/esp32/rak11200/platformio.ini`, then rebuild:

    -DMESHTASTIC_EXCLUDE_STOREFORWARD=1
    -DMESHTASTIC_EXCLUDE_AUDIO=1
    -DMESHTASTIC_EXCLUDE_REMOTEHARDWARE=1
    -DMESHTASTIC_EXCLUDE_CANNEDMESSAGES=1
    -DMESHTASTIC_EXCLUDE_BLUETOOTH=1   ; frees the most, but you then configure over WiFi/serial

## Enable MQTT on the node
Connect the node to WiFi (Network config), then turn on the MQTT module and set server, user and password.
Enable "uplink" / "downlink" on each channel you want bridged.

## Background
MQTT was excluded from RAK11200 in March 2026 (PR #9874) to fix an IRAM overflow on the old Arduino 2.x core.
Since 2.8.x the ESP32 builds use Arduino 3.x with IRAM-saving sdkconfig options, and every other
classic-ESP32 board (T-Beam, Heltec V2, T-LoRa V2) builds with MQTT enabled.
Note: 2.7.26 (the last stable "Beta") is still on Arduino 2.x, so this change is unlikely to fit there.

## Runtime notes (classic ESP32 without PSRAM)
- Build result for 2.8.2 + MQTT: IRAM 55 % (77 KB free), static DRAM 71 % (35.7 KB free), app flash 85 %.
- On ESP32, Meshtastic turns Bluetooth off when WiFi is enabled, so configure the node over WiFi/serial while MQTT is active.
- Prefer MQTT without TLS (or a local broker); TLS needs about 40 KB of heap, which is tight on this board.
  Watch free heap in the device metrics after enabling MQTT.

## Full install incl. OTA loader (no web UI files)
`output/mt-esp32-ota.bin` comes unchanged from the official release zip firmware-esp32-2.8.2.d5f1619.zip
(sha256 1a6f9592019a5401e68e50c5941c600af0467ca4b313ecce4f9a4d584d4db881). It's the same for all classic ESP32 boards.

    cd ~/Claude_Cowork/meshtastic_rak11200/output
    PORT=/dev/cu.usbserial-XXXX
    esptool --port $PORT erase-flash
    esptool --port $PORT write-flash 0x0      firmware-rak11200-2.8.2.d5f1619.factory.bin
    esptool --port $PORT write-flash 0x260000 mt-esp32-ota.bin

Later updates over WiFi/BLE only need `firmware-rak11200-*.bin` (non-factory). The OTA loader stays in place.

## Web flasher (flasher.meshtastic.org)
- Updates: pick "RAK WisBlock 11200", use "Open custom file" with `firmware-rak11200-*.bin` (NOT .factory.bin),
  keep "Full Erase and Install" OFF. It writes the file at 0x10000; settings and the OTA loader are kept.
- Do NOT do a Full Erase and Install with a single custom .factory.bin. For a custom single file, the flasher
  writes that same file at 0x0, 0x260000 (OTA) and 0x300000 (filesystem), which overruns the 4 MB flash.
  Use the esptool commands above for the first install.
- RAK11200 download mode: bridge BOOT0 to GND on the base board while resetting.
