# Seeed Studio XIAO ESP32S3 + PCM5102A

This setup uses the standard **Seeed Studio XIAO ESP32S3** with **8 MB flash and 8 MB octal PSRAM**, an external **PCM5102A DAC**, and USB-C power. Audio is received over WiFi via AirPlay and sent to an amplifier or powered speakers through the DAC's analog output. Bluetooth A2DP is only available on the classic ESP32 targets, not this S3 setup.

| Component | Purpose |
| --- | --- |
| Seeed Studio XIAO ESP32S3 + external WiFi antenna | AirPlay receiver |
| PCM5102A I2S DAC module with 5V VIN and analog output | Digital-to-analog conversion |
| Short jumper wires / soldered wires and suitable headers | Power and I2S connections |
| USB-C data cable and USB power source | Flashing and power |
| Amplifier or powered speakers + audio cable | Playback from the DAC's line output |

See the [official Seeed hardware overview and pinout](https://wiki.seeedstudio.com/xiao_esp32s3_getting_started/) for board orientation and header labels.

### Wiring

Disconnect USB power before wiring. Connect the DAC to the XIAO as follows; **D labels and GPIO numbers are different**:

| XIAO header label | ESP32-S3 GPIO | PCM5102A pin | Function |
| --- | --- | --- | --- |
| **5V** | — | **VIN** | DAC module power (USB-powered setup) |
| **GND** | — | **GND** | Common ground |
| **D8** | **GPIO7** | **BCK** / BCLK | I2S bit clock |
| **D9** | **GPIO8** | **DIN** | I2S audio data from the XIAO |
| **D10** | **GPIO9** | **LCK** / LRCK / WS | I2S word select |

Use the actual **GND** pin: software ground and GPIO power are disabled in this target. MCLK output is also disabled (`CONFIG_I2S_SCK_IO=-1`). For the PCM5102A module, configure its solder bridges for I2S operation without an external master clock; check the reference photo against your module's pin labels and bridge layout.

<div align="center">
<img src="../assets/PCM5102A.png" alt="PCM5102A DAC module solder-bridge reference" width="500">
</div>

The pin assignments match [`config/sdkconfig.defaults.seeed-xiao-esp32s3`](../../config/sdkconfig.defaults.seeed-xiao-esp32s3):

```ini
CONFIG_I2S_SCK_IO=-1
CONFIG_I2S_BCK_IO=7
CONFIG_I2S_WS_IO=9
CONFIG_I2S_DO_IO=8
CONFIG_I2S_GND_IO=-1
CONFIG_I2S_VCC_IO=-1
```

Attach the external WiFi antenna, connect the DAC's analog output to your amplifier or powered speakers, then power the XIAO through USB-C. The DAC provides a line-level signal; passive speakers need an amplifier.

The target configures the onboard user LED on GPIO21. An external RGB LED, display, buttons, DAC I2C control, and battery monitoring are not enabled by this setup.

## Printable XIAO / PCM5102A Case

[`docs/case_esp32s3zero_pcm5102a.scad`](../case_esp32s3zero_pcm5102a.scad) now targets the standard **XIAO ESP32S3**; its historical filename is retained. The XIAO uses Seeed's 21 × 17.8 mm outline, and the DAC retains the original measured 32 × 17 mm outline and jack position. The **XIAO mounts component-side down, with its solder side accessible from above**; the DAC remains component-side up. Both connectors face forward, both PCB seating surfaces sit at the same height, and the **3 mm edge-to-edge board gap is unchanged**.

The model includes four XIAO corner clips, two DAC front retaining toes and two rear clips, ventilation through the floor, lower side walls and lid, and matching lid snap recesses. Both PCB supports are 7 mm above the inner floor, leaving **3 mm of free air below the XIAO's downward-facing component envelope**. The USB opening and its lid tongue follow the connector below the PCB. With default parameters, the closed case measures **61.2 × 44 × 25.2 mm**.

The rear antenna compartment reserves **50 × 12 × 10 mm**, with two cable-tie saddles and a rear coax exit. This is a provisional space allowance, not a measurement of your antenna. Adjust `antenna_length`, `antenna_depth` and `antenna_height` to the actual antenna; for the [Seeed FPC A-02](https://www.seeedstudio.com/2-4GHz-FPC-Antenna-1-16dBi-for-XIAO-ESP32S3-p-6440.html), allow at least 19 mm depth. The orange preview volume shows the reserved space. Connect the antenna before seating the XIAO: its flipped U.FL socket is **underneath at the rear-right**. Route the coax below the rear edge and up into the antenna compartment, with slack at the connector. The rear stops leave this route open, and the preview includes its cable envelope.

Print in PETG with a 0.4 mm nozzle, 0.2 mm layers and three perimeters. `PART="base"` and `PART="lid"` place each part directly on the bed; the lid is inverted automatically. `PART="print"` places both beside each other, and `PART="assembled"` previews the closed case. Board outlines are preview-only and are excluded from STL exports.

```sh
openscad -D 'PART="base"' -o docs/case_xiao_esp32s3_pcm5102a_base.stl docs/case_esp32s3zero_pcm5102a.scad
openscad -D 'PART="lid"' -o docs/case_xiao_esp32s3_pcm5102a_lid.stl docs/case_esp32s3zero_pcm5102a.scad
```

The defaults allow directly soldered wiring. Check actual PCB thicknesses (`esp_pcb_t`, `dac_pcb_t`), solder near the clip positions, connector size and under-board clearance before printing; downward headers may need a larger `ledge_h`. Insert the connectors into the front openings, slide the DAC under its front toes, then seat the boards in their clips. Secure the antenna with small cable ties and close the lid. CAD clearance checks do not replace a physical fit check or a temperature check during sustained playback.

## Flash the Firmware

For the XIAO, build this checkout using the **`seeed-xiao-esp32s3`** target described below. The plain `esp32s3` target uses a different pin mapping and 16 MB flash settings. `platformio.ini` still defaults to `esp32s3`, so always specify `-e seeed-xiao-esp32s3`.

## Build with PlatformIO

[PlatformIO](https://platformio.org/) handles all the toolchain setup for you.

```bash
# 1. Install PlatformIO CLI
pip install platformio

# 2. Clone this project (with submodules)
git clone --recursive https://github.com/lebck/airplay-esp32
cd airplay-esp32

# 3. Connect the XIAO via USB-C and flash firmware + web files
pio run -e seeed-xiao-esp32s3 -t upload
pio run -e seeed-xiao-esp32s3 -t uploadfs

# 4. (Optional) Watch serial output for debugging
pio run -e seeed-xiao-esp32s3 -t monitor
```

If you previously built this target, check the generated `sdkconfig.seeed-xiao-esp32s3`: older builds may still have `CONFIG_I2S_WS_IO=8` and `CONFIG_I2S_DO_IO=9`. Update these to **WS=9 / DO=8** using `pio run -e seeed-xiao-esp32s3 -t menuconfig` under **Board Configuration → Pin Configuration → I2S and S/PDIF Pin Configuration**, or back up and remove that generated sdkconfig so the next build uses the current defaults. Changing a defaults file alone does not overwrite cached values.

If the board does not appear for flashing, hold **BOOT** while connecting USB, then release it and retry. Press **RESET** after flashing if needed.

## Build with ESP-IDF

```bash
# 1. Install ESP-IDF v5.5 or newer following:
#    https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/

# 2. Clone and enter the project (with submodules)
git clone --recursive https://github.com/lebck/airplay-esp32
cd airplay-esp32

# 3. Activate ESP-IDF environment
source /path/to/esp-idf/export.sh

# 4. Use a separate build directory and sdkconfig for the XIAO
idf.py -B build-xiao -DIDF_TARGET=esp32s3 \
  -DSDKCONFIG=sdkconfig.xiao-idf \
  -DSDKCONFIG_DEFAULTS="config/sdkconfig.defaults;config/sdkconfig.defaults.seeed-xiao-esp32s3" build

# 5. Flash firmware + SPIFFS "storage" partition from data/
# Replace <serial-port> with your XIAO port (e.g. /dev/cu.usbmodem… on macOS)
idf.py -B build-xiao -p "<serial-port>" flash

# 6. (Optional) Monitor serial output
idf.py -B build-xiao -p "<serial-port>" monitor
```

---

## Updating the Firmware (OTA)

Once the device is connected to your WiFi, you can update the firmware wirelessly without unplugging anything:

1. Build the XIAO firmware with `pio run -e seeed-xiao-esp32s3` (or `idf.py -B build-xiao build` after the ESP-IDF setup above)
2. Open the device's web interface (find its IP in your router's connected devices list)
3. Use the firmware upload page to flash `.pio/build/seeed-xiao-esp32s3/firmware.bin` (or `build-xiao/airplay2-receiver.bin` with ESP-IDF)

---
