#!/usr/bin/env python3
import sys
import os


def value_to_rgb(value):
    """Convert a value (0-255) to an RGB triple.

    0   → None (terminator, no box drawn)
    1-100 → blue
    101-229 → jet colormap (blue → cyan → green → yellow → red)
    230 → red

    Edit this function freely to change color mapping.
    """
    if value == 0:
        return None
    if 1 <= value <= 100:
        return (0, 0, 255)
    if value >= 230:
        return (255, 0, 0)

    t = (value - 101) / (229 - 101)

    if t < 0.25:
        r, g, b = 0.0, t * 4.0, 1.0
    elif t < 0.5:
        r, g, b = 0.0, 1.0, 1.0 - (t - 0.25) * 4.0
    elif t < 0.75:
        r, g, b = (t - 0.5) * 4.0, 1.0, 0.0
    else:
        r, g, b = 1.0, 1.0 - (t - 0.75) * 4.0, 0.0

    return (int(r * 255), int(g * 255), int(b * 255))


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <o1_hex> <o2_hex>")
        sys.exit(1)

    o1 = int(sys.argv[1], 16)
    o2 = int(sys.argv[2], 16)

    filename = "memdump-2--ds-only.bin"
    if not os.path.exists(filename):
        print(f"Error: {filename} not found")
        sys.exit(1)

    entries = []

    with open(filename, "rb") as f:
        while True:
            f.seek(o1)
            d = f.read(2)
            if len(d) < 2:
                break
            x, y = d[0], d[1]

            f.seek(o2)
            d = f.read(1)
            if not d:
                break
            value = d[0]

            if value < 10:
                break

            entries.append((x, y, value))

            o1 += 2
            o2 += 1

    if not entries:
        print("No entries (first value < 20).")
        return

    max_y = max(e[1] for e in entries)
    max_x = max(e[0] for e in entries)

    buf = [" " * 90 * 3] * (max_y + 1)

    for x, y, v in entries:
    #    print(f"{x} {y} {v}")
        if x > 89:
            continue
        col = x * 3
        s = f"{v:>3}"
        row = buf[y]
        buf[y] = row[:col] + s + row[col + 3:]

    #print(f"n={len(entries)}  x 0-{max_x}  y 0-{max_y}")
    for line in buf:
        print(line)


if __name__ == "__main__":
    main()
