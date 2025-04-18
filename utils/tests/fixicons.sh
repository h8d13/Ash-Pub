#!/bin/sh
TARGET_USER=hill
sed -i '/\[Containments\]\[2\]\[Applets\]\[5\]\[Configuration\]\[General\]/,/^\[/ s/launchers=.*/launchers=applications:org.kde.konsole.desktop/' "/home/$TARGET_USER/.config/plasma-org.kde.plasma.desktop-appletsrc"
