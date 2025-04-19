#!/bin/sh

## Hacky way to get the username auto
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
# Print the result
echo "TARGET_USER=$TARGET_USER"

# Pass :)
