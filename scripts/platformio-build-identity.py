"""Set the firmware variant and OTA layout IDs for PlatformIO builds."""

Import("env")

import csv
from pathlib import Path


variant = env.get("PIOENV", "custom")
partition_file = Path(env.subst("$PROJECT_DIR")) / env.GetProjectOption(
    "board_build.partitions", "components/boards/partitions.csv"
)
ota_sizes = []
with partition_file.open(newline="", encoding="utf-8") as csv_file:
    for row in csv.reader(line for line in csv_file if not line.lstrip().startswith("#")):
        if len(row) >= 5 and row[1].strip() == "app" and row[2].strip().startswith("ota_"):
            ota_sizes.append(int(row[4].strip(), 0))

if not ota_sizes or len(set(ota_sizes)) != 1:
    raise RuntimeError("OTA app partitions must exist and have matching sizes")

size = ota_sizes[0]
layout = {
    0x300000: "ota-3m-v1",
    0x1E0000: "ota-1875k-v1",
    0x600000: "ota-6m-v1",
}.get(size)
if layout is None:
    raise RuntimeError("Unknown OTA partition size; assign and document a layout ID")

env.Append(CPPDEFINES=[
    ("FIRMWARE_BUILD_VARIANT", '"%s"' % variant),
    ("FIRMWARE_UPDATE_LAYOUT", '"%s"' % layout),
])
