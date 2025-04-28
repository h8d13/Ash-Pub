# Some things i'd like to do PROGRAMATICALLY 
# Modify default theme to dark
# Modify icons in taskbar to be empty (feel like a fresh install) 
# Modify default Konsole profile to use su -l directly. 
# Modify default bg & start icon 

#!/bin/bash

# Search for plasma package extract version
apk search plasma-welcome-lang | grep -o "plasma[^[:space:]]*-[0-9][0-9\.]*-r[0-9]*" | sed -E 's/.*-([0-9][0-9\.]*-r[0-9]*)/\1/'
doas su - username -c 'export DISPLAY=:0; export XDG_RUNTIME_DIR=/run/user/$(id -u); export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep plasmashell)/environ 2>/dev/null | cut -d= -f2-); command_to_run'
#plasma-apply-desktoptheme breeze-dark
#plasma-apply-colorscheme BreezeDark
#plasma-apply-lookandfeel --apply org.kde.breezedark.desktop

#copy personal image to 
#> /home/$TARGET_USER/Pictures 
#same for a custom icon for start menu

# Remove icons # 

#/usr/share/applications/kde-mimeapps.list 


#!/bin/bash
# Set dark theme for menu and taskbar
plasma-apply-desktoptheme breeze-dark
# Set dark theme for window styles
plasma-apply-colorscheme BreezeDark
# Restart Plasma to apply changes
killall plasmashell && kstart5 plasmashell
