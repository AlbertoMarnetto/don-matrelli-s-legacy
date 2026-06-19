#! env python3

import re
from sys import argv

input_file = argv[1]

numbers = []

with open(input_file, "r") as f:
    for line in f:
        match = re.search(r'END', line)
        if match:
            break

        match = re.search(r'\((\d+),\s*(\d+)\)', line)
        if match:
            x, y = int(match.group(1)), int(match.group(2))
            numbers.append((x, y))

hex_pairs = []
for x, y in numbers:
    hex_pairs.append((f"{x:#X}", f"{y:#X}"))

print(f"Processed {len(numbers)} coordinate pairs\n")

for i in range(0, len(hex_pairs), 8):
    chunk = hex_pairs[i:i+8]
    hex_vals = ", ".join(f"{x[2:]:0>2}h, {y[2:]:0>2}h" for x, y in chunk)
    print(f"    db {hex_vals}")

