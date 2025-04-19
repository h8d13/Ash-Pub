# Some things i'd like to do PROGRAMATICALLY 
# Modify default theme to dark
# Modify icons in taskbar to be empty (feel like a fresh install) 
# Modify default Konsole profile to use su -l directly. 
# Modify default bg & start icon 

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
