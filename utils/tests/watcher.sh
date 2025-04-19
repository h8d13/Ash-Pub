#!/bin/bash

# Directories to exclude
EXCLUDE_DIRS="/proc /sys /dev /tmp /run /var/log /var/cache"

# Function to create exclude parameters for find command
create_exclude_params() {
    local exclude_params=""
    for dir in $EXCLUDE_DIRS; do
        exclude_params="$exclude_params -not -path \"$dir/*\""
    done
    echo "$exclude_params"
}

# File to store the previous state
PREV_STATE="/tmp/prev_state.txt"

# Create initial empty file
touch "$PREV_STATE"

echo "Watching system for file changes. Press Ctrl+C to stop."
echo "Make your KDE keyboard layout changes now..."

while true; do
    # Create a temporary file for current state
    CURR_STATE="/tmp/curr_state.txt"
    
    # Find all files, excluding specified directories
    eval "find / -type f $(create_exclude_params) 2>/dev/null -exec stat -c '%n %Y' {} \;" | sort > "$CURR_STATE"
    
    # Compare with previous state and show differences
    if [ -s "$PREV_STATE" ]; then
        echo "Changes at $(date):"
        diff "$PREV_STATE" "$CURR_STATE" | grep '^[<>]' | sed 's/^< /REMOVED: /;s/^> /ADDED or MODIFIED: /'
    fi
    
    # Current becomes previous for next iteration
    mv "$CURR_STATE" "$PREV_STATE"
    
    # Wait before checking again
    sleep 5
done
