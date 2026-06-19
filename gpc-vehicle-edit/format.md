| Field | Offset (in Settings) | Offset (in Vehicle) | Size | Value Range |
|-------|---------------------|---------------------|------|-------------|
| gearsCount | 0 | 0 | 2 bytes | 0-0xFFFF |
| rpmRedline | 2 | 2 | 2 bytes | 0-0xFFFF |
| rpmLimit | 4 | 4 | 2 bytes | 0-0xFFFF |
| overrevTolerance | 6 | 6 | 2 bytes | 0-0xFFFF |
| grip | 8 | 8 | 2 bytes | 0-0xFFFF |
| grip0 | 10 | 10 | 2 bytes | 0-0xFFFF |
| brakingSpeed | 12 | 12 | 2 bytes | 0-0xFFFF |
| brakingSpeed0 | 14 | 14 | 2 bytes | 0-0xFFFF |
| spinThreshold | 16 | 16 | 2 bytes | 0-0xFFFF |
| spinThreshold0 | 18 | 18 | 2 bytes | 0-0xFFFF |
| rpmDownshift | 20 | 20 | 2 bytes | 0-0xFFFF |

---

## Gearbox Fields (20 bytes, offsets 22-41)

| Gear | Offset (in Vehicle) | Size | Description |
|------|---------------------|------|-------------|
| N (neutral) | 22 | 2 bytes | 16-bit little-endian |
| 1 | 24 | 2 bytes | 16-bit little-endian |
| 2 | 26 | 2 bytes | 16-bit little-endian |
| 3 | 28 | 2 bytes | 16-bit little-endian |
| 4 | 30 | 2 bytes | 16-bit little-endian |
| 5 | 32 | 2 bytes | 16-bit little-endian |
| 6 | 34 | 2 bytes | 16-bit little-endian |
| 7 | 36 | 2 bytes | 16-bit little-endian |
| 8 | 38 | 2 bytes | 16-bit little-endian |
| 9 | 40 | 2 bytes | 16-bit little-endian |

---

## Power Curve (106 bytes, offsets 42-147)

| Description | Offset (in Vehicle) | Size | Details |
|-------------|---------------------|------|---------|
| Power values | 42 - 147 | 106 bytes | 106 × 8-bit values (0-255) |
| RPM range | - | - | 768 - 14335 RPM |
| RPM per point | - | - | 128 RPM |

The power curve covers RPM range 768-14335, with each byte representing power at `768 + (index × 128)` RPM.


