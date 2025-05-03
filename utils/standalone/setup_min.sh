#!/bin/sh

# Script to install a minimal KDE Plasma desktop on Alpine Linux
# Run as root (e.g., with doas)
# Exit on any error
set -e

TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||') 
ALPINE_VERSION=$(cat /etc/alpine-release)

# Enable community repository for KDE packages
echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
# Update package index
apk update
# Install essential KDE Plasma packages and SDDM display manager
apk add \
    plasma-desktop \
    sddm \
    xorg-server \
    xf86-video-vesa \
    mesa-dri-gallium \
    font-noto \
    ttf-dejavu \
    pipewire \
    pipewire-pulse \
    sof-firmware \
    wireplumber \
    elogind \
    polkit-elogind \
    ufw \
    dbus

# Enable required services
rc-update add sddm
rc-update add dbus
rc-update add elogind

# Set up PipeWire for audio
rc-update add pipewire
rc-update add pipewire-pulse
rc-update add wireplumber
addgroup $TARGET_USER audio
addgroup $TARGET_USER video
# Optional: Install a minimal terminal and file manager
apk add konsole dolphin

ufw default deny incoming
ufw allow out 443/tcp  

## Examples stolen from the internet # uncomment if using these
#ufw limit SSH         # open SSH port and protect against brute-force login attacks
#ufw allow out DNS     # allow outgoing DNS
#ufw allow out 80/tcp  # allow outgoing HTTP/HTTPS traffic
ufw allow 3389        # remote desktop on xorg
#ufw allow 21          # ftp
#ufw allow 22	       # sftp
#ufw allow 51820/udp   # wireguard
#ufw allow 1194/udp    # openvpn
ufw enable

########################################## FIX LOGIN KB
echo "Setting up Keyboard..." 
mkdir -p "/usr/share/sddm/scripts/"
cat >> /usr/share/sddm/scripts/Xsetup << EOF
setxkbmap "$KB_LAYOUT"
EOF
chmod +x /usr/share/sddm/scripts/Xsetup
########################################## FIX GLOBAL KB
mkdir -p "/home/$TARGET_USER/.config"
cat > "/home/$TARGET_USER/.config/kxkbrc" << EOF
[Layout]
LayoutList=$KB_LAYOUT
Use=True
EOF

# Optional: Clean up APK cache to save space
rm -rf /var/cache/apk/*

# Notify user
echo "Minimal KDE Plasma desktop installed!"
echo "Reboot and select 'plasma' session in SDDM to start."
