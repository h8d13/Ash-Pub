#!/bin/sh
# First, as root, extract the cookie from the user's session
XCOOKIE=$(doas -u hadeaneon xauth list | grep :0 | cut -d' ' -f3)

# Then use it in your su command
doas su - hadeaneon -c "export DISPLAY=:0; xauth add :0 MIT-MAGIC-COOKIE-1 $XCOOKIE; export XDG_RUNTIME_DIR=/run/user/\$(id -u); export DBUS_SESSION_BUS_ADDRESS=\$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/\$(pgrep plasmashell)/environ 2>/dev/null | cut -d= -f2-); konsole"
