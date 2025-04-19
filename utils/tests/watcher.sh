#!/bin/sh

# Take a snapshot before changes
echo "Taking initial snapshot..."
find / -type f -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" \
  -not -path "/run/*" -not -path "/tmp/*" -mmin -60 2>/dev/null > /tmp/files_before.txt

echo "Please make your KDE keyboard layout changes now."
echo "Press Enter when done..."
read

# Take a snapshot after changes
echo "Taking final snapshot..."
find / -type f -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" \
  -not -path "/run/*" -not -path "/tmp/*" -mmin -60 2>/dev/null > /tmp/files_after.txt

# Show differences
echo "Files that changed:"
diff /tmp/files_before.txt /tmp/files_after.txt | grep "^>" | cut -c 3-
