cd ~/Claude_Cowork/meshtastic_rak11200/output
PORT=/dev/cu.usbserial-XXXX
esptool --port $PORT erase-flash
esptool --port $PORT write-flash 0x0      firmware-rak11200-2.8.2.d5f1619.factory.bin
esptool --port $PORT write-flash 0x260000 mt-esp32-ota.bin