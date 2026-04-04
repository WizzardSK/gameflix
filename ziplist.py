#!/usr/bin/env python3
"""List files inside a remote zip archive by reading only the central directory via rclone."""
import sys, subprocess, json

path = sys.argv[1]
tail_size = 131072  # 128KB should cover most zip central directories

# Get zip size
result = subprocess.run(["rclone", "size", path, "--json"], capture_output=True, text=True)
size = json.loads(result.stdout)["bytes"]
offset = max(size - tail_size, 0)

# Read central directory from end of zip
result = subprocess.run(["rclone", "cat", path, "--offset", str(offset)], capture_output=True)
data = result.stdout

i = 0
while i < len(data) - 46:
    if data[i:i+4] == b'\x50\x4b\x01\x02':
        fname_len = int.from_bytes(data[i+28:i+30], 'little')
        extra_len = int.from_bytes(data[i+30:i+32], 'little')
        comment_len = int.from_bytes(data[i+32:i+34], 'little')
        fname = data[i+46:i+46+fname_len].decode('utf-8', errors='replace')
        print(fname)
        i += 46 + fname_len + extra_len + comment_len
    else:
        i += 1
