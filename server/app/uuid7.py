from __future__ import annotations

import os
import time


def uuid7() -> str:
    timestamp_ms = time.time_ns() // 1_000_000
    random_bytes = os.urandom(10)
    value = bytearray(16)
    value[0] = (timestamp_ms >> 40) & 0xFF
    value[1] = (timestamp_ms >> 32) & 0xFF
    value[2] = (timestamp_ms >> 24) & 0xFF
    value[3] = (timestamp_ms >> 16) & 0xFF
    value[4] = (timestamp_ms >> 8) & 0xFF
    value[5] = timestamp_ms & 0xFF
    value[6] = 0x70 | (random_bytes[0] & 0x0F)
    value[7] = random_bytes[1]
    value[8] = 0x80 | (random_bytes[2] & 0x3F)
    value[9:] = random_bytes[3:13]
    hex_value = value.hex()
    return (
        f"{hex_value[:8]}-{hex_value[8:12]}-{hex_value[12:16]}-"
        f"{hex_value[16:20]}-{hex_value[20:]}"
    )
