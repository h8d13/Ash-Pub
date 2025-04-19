#!/bin/bash

# Monitor whole system for file changes (with exceptions)
echo "Watching system for file changes."

inotifywait -m -r -e modify,create,delete \
  --exclude '/proc/|/sys/|/dev/|/tmp/|/run/|/var/log/|/var/cache/' \
  / 2>/dev/null |
while read path action file; do
  echo "[$(date +%T)] $action: $path$file"
done
