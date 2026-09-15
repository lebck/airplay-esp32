# CPU utilization on the XIAO ESP32S3

The XIAO build enables FreeRTOS runtime statistics with the ESP microsecond
timer and 64-bit counters. Every five seconds, a low-priority task computes
`100 * (1 - idle_time_delta / elapsed_time)` separately for each core.
These are interval averages, not peak utilization or averages since boot.
Idle counters are accounted at task switches, so values have small sampling
boundary errors. Interrupt execution is not measured separately.

Open `/logs` for the `runtime` messages, or GET `/api/system/info`:

- `cpu_stats_ready`: false until the first complete interval is available.
- `cpu_usage_percent`: percentages ordered by core (CPU0, CPU1).
- `cpu_sample_interval_ms`: actual length of the last measurement interval.
- `cpu_sample_age_ms`: age of the latest sample; normally below five seconds.
- `free_internal_heap` and `free_psram`: current free memory in bytes.
- `firmware_build_date` and `firmware_build_time`: identify the installed build.

For a playback measurement, start music, allow buffering to settle, then
record at least one minute of samples. Compare with paused playback and retain
per-core results: a combined average can hide a busy audio core. The monitor
itself adds a small amount of work and uses a 3072-byte task stack.

The existing web files need no update. OTA uploads only `firmware.bin` to
`/api/ota/update`; WiFi settings and SPIFFS files are retained.
