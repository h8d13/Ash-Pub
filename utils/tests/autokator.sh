#!/bin/sh

## Hacky way to get the username auto
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)

KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||')

# Print the result
echo "TARGET_USER=$TARGET_USER"

# Pass :)
