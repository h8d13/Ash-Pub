#!/bin/sh
## /* SPDX-FileCopyrightText: 2025 
# (O) Eihdran L. <hadean-eon-dev@proton.me>
# (C) Lagan S. <sarbjitsinghsandhu509@gmail.com>
# Adapted for Artix OpenRC - Combined Installation & Configuration
# Desc: Automated Artix OpenRC Installation & Extended Configuration
##  SPDX-License-Identifier: MIT */
set -e  # Exit on error

# Configuration variables
TARGET_DISK="/dev/sdb" ### VERY CAREFULLY LSBLK TO CHECK 
TARGET_TIMEZONE="Europe/Paris" 
ROOT_PASSWORD="Everest" ### PLEASE CHANGE ME 
KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||' || echo "us") 
TARGET_HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "artix-k2")
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
SWAP_SIZE="4G" 

# Confirm before proceeding
echo "!!!! WARNING !!!!"
echo "This script will ERASE ALL DATA on $TARGET_DISK"
echo "Current configuration:"
echo "Target disk: $TARGET_DISK"
echo "Timezone: $TARGET_TIMEZONE"
echo "Hostname: $TARGET_HOSTNAME"
echo "User to be created: $TARGET_USER"
echo "Keyboard layout: $KB_LAYOUT"
echo ""
echo "Press ENTER to continue or CTRL+C to abort..."
read confirmation

# Check if running as root
if [ "$(whoami)" != "root" ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Exit if no TARGET_USER found
if [ -z "$TARGET_USER" ]; then
    echo "ERROR: No user with /home directory found."
    echo "Please enter a username to create:"
    read TARGET_USER
    if [ -z "$TARGET_USER" ]; then
        echo "No username provided. Exiting."
        exit 1
    fi
fi

echo "User set to: $TARGET_USER"

# Make sure nothing is mounted from the target disk
echo "Unmounting any existing mounts..."
for mnt in $(mount | grep ${TARGET_DISK} | awk '{print $1}' 2>/dev/null || true); do
  echo "Unmounting $mnt"
  umount -f "$mnt" 2>/dev/null || true
done

# Partitioning with three partitions: EFI, swap, and root
echo "Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$TARGET_DISK" set 1 esp on
parted -s "$TARGET_DISK" mkpart primary linux-swap 512MiB 4.5GiB
parted -s "$TARGET_DISK" mkpart primary ext4 4.5GiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${TARGET_DISK}1"  # EFI partition
mkswap "${TARGET_DISK}2"        # Swap partition
swapon "${TARGET_DISK}2"        # Enable swap
mkfs.ext4 -F "${TARGET_DISK}3"  # Root partition

# Mount filesystems
echo "Mounting filesystems..."
TARGET_MOUNT="/mnt"
mount "${TARGET_DISK}3" "$TARGET_MOUNT"       # Mount root
mkdir -p "$TARGET_MOUNT/boot/efi"
mount "${TARGET_DISK}1" "$TARGET_MOUNT/boot/efi"  # Mount EFI

# Installing base Artix system with OpenRC
echo "Installing base Artix system with OpenRC..."
basestrap "$TARGET_MOUNT" base base-devel openrc elogind-openrc linux linux-firmware linux-headers

# Installing essential packages
echo "Installing essential packages..."
basestrap "$TARGET_MOUNT" dhcpcd-openrc networkmanager-openrc wpa_supplicant-openrc grub os-prober efibootmgr cryptsetup lvm2 vi nano

# Generate fstab
echo "Generating fstab..."
fstabgen -U "$TARGET_MOUNT" > "$TARGET_MOUNT/etc/fstab"

# Basic system configuration
echo "Creating configuration script..."
cat > "$TARGET_MOUNT/configure.sh" << EOF
#!/bin/bash
# Basic configuration
ln -sf /usr/share/zoneinfo/$TARGET_TIMEZONE /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$TARGET_HOSTNAME" > /etc/hostname
# For OpenRC
echo "hostname=\"$TARGET_HOSTNAME\"" > /etc/conf.d/hostname

# Configure hosts file
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $TARGET_HOSTNAME.localdomain $TARGET_HOSTNAME" >> /etc/hosts

# Set up root password
echo "Setting root password..."
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel,audio,video,optical,storage,input -s /bin/bash "$TARGET_USER"
echo "$TARGET_USER:$ROOT_PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" | EDITOR='tee -a' visudo

# Configure keymap
echo "KEYMAP=$KB_LAYOUT" > /etc/vconsole.conf

# Set up GRUB
echo "Installing and configuring GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARTIX
grub-mkconfig -o /boot/grub/grub.cfg

# Set up network
echo "Configuring network..."
rc-update add NetworkManager default

# Enable other basic services
rc-update add elogind default
rc-update add local default
EOF

chmod +x "$TARGET_MOUNT/configure.sh"

# Chroot into the new system and run the configuration script
echo "Chrooting into the new system and running configuration..."
artix-chroot "$TARGET_MOUNT" /configure.sh

# Create the post-installation configuration script
cat > "$TARGET_MOUNT/post_install.sh" << 'EOF'
#!/bin/bash

TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
KB_LAYOUT=$(setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}' || echo "us")
ARTIX_VERSION=$(grep VERSION /etc/os-release | head -1 | cut -d'"' -f2)

# Exit if no TARGET_USER found
if [ -z "$TARGET_USER" ]; then
    echo "ERROR: No user with /home directory found. Exiting."
    exit 1
fi

echo "Detected ARTIX v: $ARTIX_VERSION TARGET_USER set to:$TARGET_USER : KB_LAYOUT set to:$KB_LAYOUT"

################################################ PREPARE
pacman -Syu --noconfirm

################################# VIDEO DRIVERS
echo "Setting up video/drivers..." 
pacman -S --noconfirm xf86-video-vesa 
pacman -S --noconfirm mesa mesa-demos libva-mesa-driver mesa-vdpau
pacman -S --noconfirm intel-ucode #amd-ucode for AMD systems
pacman -S --noconfirm libva-intel-driver intel-media-driver vulkan-intel
# xf86-video-intel 

################################# DISPLAY SERVERS
pacman -S --noconfirm xorg xorg-server xorg-xinit
pacman -S --noconfirm wayland wayland-protocols xorg-xwayland

################################# PLASMA DESKTOP
pacman -S --noconfirm plasma-meta plasma-wayland-session kde-applications elogind-openrc
# Setup OpenRC services for display manager
rc-update add elogind default
rc-update add sddm default

################################# ESSENTIALS
echo "Setting up drivers and essential packages..."
pacman -S --noconfirm pciutils
pacman -S --noconfirm wpa_supplicant wpa_supplicant-openrc
pacman -S --noconfirm dbus dbus-openrc
pacman -S --noconfirm busybox
pacman -S --noconfirm ufw ufw-openrc
pacman -S --noconfirm iptables-nft iptables-nft-openrc
   
pacman -S --noconfirm util-linux dolphin wget tar zstd hwinfo lshw usbutils git micro bash

################################# SOUND
echo "Setting up sound..."
pacman -S --noconfirm alsa-utils alsa-plugins alsa-firmware
pacman -S --noconfirm sof-firmware pulseaudio-alsa
usermod -aG audio $TARGET_USER
usermod -aG video $TARGET_USER

################################# SECURITY
echo "Setting up UFW & Iptables..." 
ufw default deny incoming
ufw allow out 443/tcp
# Example rules (uncomment as needed)
#ufw limit SSH
#ufw allow out DNS
#ufw allow out 80/tcp
ufw enable

################################# RUNLEVEL SERVICES
echo "Setting services..."
rc-update add ufw default
rc-update add alsa default
rc-update add dbus default
rc-update add elogind default
rc-update add sddm default
rc-update add NetworkManager default

################################# KDE KEYBOARD SETUP
echo "Setting up Keyboard..." 
mkdir -p "/usr/share/sddm/scripts/"
cat >> /usr/share/sddm/scripts/Xsetup << EOF
setxkbmap "$KB_LAYOUT"
EOF
chmod +x /usr/share/sddm/scripts/Xsetup

mkdir -p "/home/$TARGET_USER/.config"
cat > "/home/$TARGET_USER/.config/kxkbrc" << EOF
[Layout]
LayoutList=$KB_LAYOUT
Use=True
EOF

################################# KDE CUSTOMIZATION
echo "Setting up KDE customization..." 
mkdir -p "/home/$TARGET_USER/Desktop/k2-os/etc"
cat > /home/$TARGET_USER/Desktop/k2-os/etc/kpost.sh << EOF
#!/bin/sh
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 5 --group Configuration --group General --key launchers "applications:org.kde.konsole.desktop"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image "/usr/share/wallpapers/Mountain/contents/images_dark/5120x2880.png"
# Set dark theme for menu and taskbar
plasma-apply-desktoptheme breeze-dark
# Set dark theme for window styles
plasma-apply-colorscheme BreezeDark
doas reboot
EOF
chmod +x /home/$TARGET_USER/Desktop/k2-os/etc/kpost.sh
cat > /home/$TARGET_USER/Desktop/k2-os/runme_once.sh << EOF
#!/bin/sh
konsole --builtin-profile -e "/home/$TARGET_USER/Desktop/k2-os/etc/kpost.sh"
EOF
chmod +x /home/$TARGET_USER/Desktop/k2-os/runme_once.sh

################################# KDE SESSION CONFIG
echo "Setting up KDE Config..." 
CONFIG_FILE2="/home/$TARGET_USER/.config/ksmserverrc"
TMP_FILE="$(mktemp)"
echo -e "[General]\nloginMode=emptySession" > "$TMP_FILE"
cat "$CONFIG_FILE2" >> "$TMP_FILE" 2>/dev/null # ignore not exist error
mv "$TMP_FILE" "$CONFIG_FILE2"

CONFIG_FILE3="/home/$TARGET_USER/.config/kscreenlockerrc"
cat <<EOFL > $CONFIG_FILE3
[Daemon]
LockGrace=300
Timeout=30
EOFL

################################# ADDITIONAL FONTS AND SHELLS
echo "Setting up additional packages..." 
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra ttf-dejavu zsh

################################# DIRECTORY SETUP
echo "Setting up directories..." 
# Admin directories
mkdir -p "/root/.config"
mkdir -p "/root/.config/ash"
mkdir -p "/root/.config/zsh"
mkdir -p "/root/.config/micro/"
mkdir -p "/root/.local/bin"
mkdir -p "/root/.zsh/plugins"
# User directories
mkdir -p "/home/$TARGET_USER/.config/micro/"
mkdir -p "/home/$TARGET_USER/.local/share/konsole"
mkdir -p "/home/$TARGET_USER/.local/bin"
mkdir -p "/home/$TARGET_USER/.config/zsh"
mkdir -p "/home/$TARGET_USER/.zsh/plugins"

################################# MICRO EDITOR CONFIG
echo "Setting up Micro editor..." 
cat > "/root/.config/micro/settings.json" << EOFM
{
    "sucmd": "doas",
    "clipboard": "external"
}
EOFM
cat > "/home/$TARGET_USER/.config/micro/settings.json" << EOFM
{
    "sucmd": "doas", 
    "clipboard": "external"
}
EOFM

################################# KONSOLE PROFILE
echo "Setting up Konsole..." 
cat > "/home/$TARGET_USER/.config/konsolerc" << EOFK
[Desktop Entry]
DefaultProfile=$TARGET_USER.profile
EOFK
cat > "/home/$TARGET_USER/.local/share/konsole/$TARGET_USER.profile" << EOFK
[General]
Command=su -l
Name=$TARGET_USER
Parent=FALLBACK/
EOFK

################################# DESKTOP SHORTCUTS
mkdir -p "/home/$TARGET_USER/Desktop/k2-os"
cat > /home/$TARGET_USER/Desktop/k2-os/wikik2.desktop << 'EOFD'
[Desktop Entry]
Icon=alienarena
Name=wikik2
Type=Link
URL[$e]=https://github.com/h8d13/k2-alpine/wiki
EOFD

cat > /home/$TARGET_USER/Desktop/k2-os/usershell.desktop << 'EOFD'
[Desktop Entry]
Comment=Open a usershell quickly
Exec=konsole --builtin-profile
GenericName=UserShell
Icon=amarok_scripts
MimeType=
Name=UserShell
Path=
StartupNotify=false
Terminal=false
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=false
X-KDE-Username=
EOFD

################################# CLONE UTILS
echo "Setting up GitHub/K2..." 
git clone https://github.com/h8d13/k2-alpine /tmp/k2-alpine
mkdir -p /home/$TARGET_USER/Desktop/k2-os/
mv /tmp/k2-alpine/utils /home/$TARGET_USER/Desktop/k2-os/
rm -rf /tmp/k2-alpine

################################# LOCAL BIN PATH SETUP
echo "Setting up local bin path..." 
cat > "/root/.config/environment" << 'EOFE'
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOFE

cat > "/home/$TARGET_USER/.config/environment" << 'EOFE'
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOFE

################################# PACKAGE SEARCH SCRIPT
cat > /root/.local/bin/iapps << 'EOFA'
#!/bin/sh
# this script lets you search your installed packages easily
if [ -z "$1" ]; then
	echo "Missing search term"
	exit 1
fi
pacman -Qs "$1"
EOFA
chmod +x /root/.local/bin/iapps

cat > /home/$TARGET_USER/.local/bin/iapps << 'EOFA'
#!/bin/sh
# this script lets you search your installed packages easily
if [ -z "$1" ]; then
	echo "Missing search term"
	exit 1
fi
pacman -Qs "$1"
EOFA
chmod +x /home/$TARGET_USER/.local/bin/iapps

################################# SHELL ALIASES
echo "Setting up aliases..." 
cat > "/root/.config/aliases" << EOFA
alias comms="cat ~/.config/aliases | sed 's/alias//g'"
# Base alias
alias cdu="cd /home/$TARGET_USER/"
alias aus="su $TARGET_USER -c" 
alias clr="clear"
alias cls="clr"
alias sudo="doas"
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
# Utils alias
alias wztree="du -h / | sort -rh | head -n 30 | less"
alias wzhere="du -h . | sort -rh | head -n 30 | less"
alias genpw="head /dev/urandom | tr -dc A-Za-z0-9 | head -c 21; echo"
alias logd="tail -f /var/log/syslog"
alias logds="dmesg -r"
# Pacman alias
alias updapc="pacman -Syu"
alias paclean="pacman -Sc"
alias paci="pacman -S"
alias pacr="pacman -R"
alias pacs="pacman -Ss"
EOFA

cat > "/home/$TARGET_USER/.config/aliases" << EOFA
alias comms="cat ~/.config/aliases | sed 's/alias//g'"
# Base alias
alias cdu="cd /home/$TARGET_USER/"
alias clr="clear"
alias cls="clr"
alias sudo="doas"
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
# Utils alias
alias wztree="du -h / | sort -rh | head -n 30 | less"
alias wzhere="du -h . | sort -rh | head -n 30 | less"
alias genpw="head /dev/urandom | tr -dc A-Za-z0-9 | head -c 21; echo"
alias logd="tail -f /var/log/syslog"
alias logds="dmesg -r"
# Pacman alias
alias updapc="pacman -Syu"
alias paclean="pacman -Sc"
alias paci="pacman -S"
alias pacr="pacman -R"
alias pacs="pacman -Ss"
EOFA

################################# PROFILE SETUP
echo "Setting up profile..." 
cat > /etc/profile.d/profile.sh << 'EOFP'
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
EOFP
chmod +x /etc/profile.d/profile.sh

################################# ASH SHELL CONFIG
echo "Setting up ASH..." 
echo 'export ENV="$HOME/.config/ash/ashrc"' > "/root/.config/ash/profile"
cat > "/root/.config/ash/ashrc" << 'EOFA'
# Style
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
## Source aliases
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOFA

mkdir -p "/home/$TARGET_USER/.config/ash"
echo 'export ENV="$HOME/.config/ash/ashrc"' > "/home/$TARGET_USER/.config/ash/profile"
cat > "/home/$TARGET_USER/.config/ash/ashrc" << 'EOFA'
# Style
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
## Source aliases
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOFA

################################# ZSH SHELL SETUP
echo "Setting up ZSH..." 
pacman -S --noconfirm zsh-autosuggestions \
      zsh-history-substring-search \
      zsh-completions \
      zsh-syntax-highlighting

cat > "/root/.config/zsh/zshrc" << 'EOFZ'
# === Load Extra Completions ===
if [ -d "/usr/share/zsh/plugins/zsh-completions" ]; then
    fpath+=("/usr/share/zsh/plugins/zsh-completions")
fi

# === History Configuration ===
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# === Source Zsh Plugins (with error checking) ===
plugin_locations=(
    "/usr/share/zsh/plugins"
    "/usr/share"
)

# Load autosuggestions and history-substring-search first
for plugin in "zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-history-substring-search/zsh-history-substring-search.zsh"; do
    found=0
    for location in "${plugin_locations[@]}"; do
        if [ -f "$location/$plugin" ]; then
            . "$location/$plugin"
            found=1
            break
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "Warning: Plugin not found: $plugin"
    fi
done

# === History Substring Search with Arrow Keys ===
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Load syntax-highlighting last as recommended
for location in "${plugin_locations[@]}"; do
    if [ -f "$location/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
        . "$location/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        break
    fi
done
# === Custom Zsh Prompt Red ===
export PROMPT='%F{red}┌──[%F{cyan}%D{%H:%M}%F{red}]─[%F{default}%n%F{red}@%F{cyan}%m%F{red}]─[%F{green}%~%F{red}]
%F{red}└──╼ %F{cyan}$ %f'

# === Source common aliases ===
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOFZ

cat > "/home/$TARGET_USER/.config/zsh/zshrc" << 'EOFZ'
# === Load Extra Completions ===
if [ -d "/usr/share/zsh/plugins/zsh-completions" ]; then
    fpath+=("/usr/share/zsh/plugins/zsh-completions")
fi

# === History Configuration ===
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# === Source Zsh Plugins (with error checking) ===
plugin_locations=(
    "/usr/share/zsh/plugins"
    "/usr/share"
)

# Load autosuggestions and history-substring-search first
for plugin in "zsh-autosuggestions/zsh-autosuggestions.zsh" "zsh-history-substring-search/zsh-history-substring-search.zsh"; do
    found=0
    for location in "${plugin_locations[@]}"; do
        if [ -f "$location/$plugin" ]; then
            . "$location/$plugin"
            found=1
            break
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "Warning: Plugin not found: $plugin"
    fi
done

# === History Substring Search with Arrow Keys ===
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Load syntax-highlighting last as recommended
for location in "${plugin_locations[@]}"; do
    if [ -f "$location/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
        . "$location/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        break
    fi
done
# === Custom Zsh Prompt Red ===
export PROMPT='%F{red}┌──[%F{cyan}%D{%H:%M}%F{red}]─[%F{default}%n%F{red}@%F{cyan}%m%F{red}]─[%F{green}%~%F{red}]
%F{red}└──╼ %F{cyan}$ %f'

# === Source common aliases ===
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOFZ

# Source environment file in both shells for both users
for user in "root" "$TARGET_USER"; do
  for config in "/home/$user/.config/ash/ashrc" "/home/$user/.config/zsh/zshrc"; do
    mkdir -p "$(dirname "$config")"
    touch "$config"
    echo 'if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi' >> "$config"
  done
done

for user in "root" "$TARGET_USER"; do
  touch "/home/$user/.zshrc"
  grep -q "HOME/.config/zsh/zshrc" "/home/$user/.zshrc" || echo '. "$HOME/.config/zsh/zshrc"' >> "/home/$user/.zshrc"
done

# === Add zsh to /etc/shells if missing ===
grep -qxF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells

################################# SYSTEM HARDENING
echo "Setting up system hardening..." 
cat > /etc/sysctl.conf << 'EOFS'
# Network performance and security
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1

# Security settings
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Enable IPv6 privacy extensions
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
EOFS

sysctl -p >/dev/null 2>&1

pacman -Sc --noconfirm

################################# MOTD AND WELCOME MESSAGES
cat > /etc/motd << 'EOFM'
Package manager: pacman -S (install), -Rs (remove), -Syu (update)
Change this message by editing /etc/motd
Change the pre-login message /etc/issue
Change default shells /etc/passwd

Find shared aliases ~/.config/aliases
Use . ~/.config/aliases if you added something

Post login scripts can be added to /etc/profile.d
Personal bin scripts in ~/.local/bin
EOFM

## Pre login splash art ## That i stole from the internet. And edit sometimes for fun :D
cat > /etc/issue << 'EOF'
##################################################################################################################################################
                                                                                                                                                  
                                                       ▒▒▒▓▓▒░░                                                                                    
                                                      ▓▓  ░░  ░░                                                                                  
                                                  ▒▒▓▓▓▓    ░░  ▒▒                           #########                                                     
                                              ░░▓▓▓▓▓▓░░    ░░    ▒▒                         # 8611m #                                                 
                                           ▓▓█▓▓▓▓▓     ░    ░░    ░░▓▓▒▒█                   #########                                                     
                                        ▒▒▓▓▓█▓▓█▓▒▒          ▒▒      ▓▓▓█▓▓▒▒               # 1.0.3 #                                                    
                                        ▓▓▓█▓▓▒▒▓█▓▓          ░░▒▒    ░░▓▓▓▓▓▓░░             #########                                                    
                                      ░░▓█▓▓▒▒▒▓▓▓▓█▒▒       ░  ▒▒░░    ░░▓▓█▓                                          ▒█▒▓▒▒                    
                                     █▓█▓▓▓▓▒▒▓▓▓▓█▓▓▓▓▓        ▒▒░░      ▒▒▓▓░░▒▒                                    ▓▓▓▓    ▒▒                  
                                ▒▒▓▓▓▓▓▓█▓▒▒▒▒▒▓▓▓▓█▓▓▓▓░░    ░░▒▒▒▒   ░    ▓█▓▓  ▒                                 ▓▓▓█▓▓  ░   ░                  
                          ░░▒▒▓▓▓▓█▓▓█▓▓▒▒▒▒▒░▓▓▓▓█▓▓▓▓▓▒▒    ░░▒▒▒▒░░      ▒▒█▓░░░░ ▒                            ▒▒▓▓▓▓▒▓░░  ░░▒▒                
                      ▓▓▓▓█▓▓▓▓▓▓▓▓█▒▒▒▒▒▒░▓▓▓▓▓██▓▓▓▓▓▓▓      ▒▒░░▒▒░░      ▓▓█▓▒▒    ░░                      ▓▓▓▓▓▓▓▒▓▓▓▓  ░░  ░░░░            
                  ▓▓▓▓▓█▓▓▒▒▓█▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓██▓█▓▓▓▓▓▓▓▓▓   ░  ░░▒▒▒▒▒▒   ░  ▒▒█▓▓▓      ▒▒                  ▓▓▓▓▓▓▒▒▓▓▓▓▓▓    ░░  ░ ▓▓          
                  ▓▓▓▓█▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓█▓▓█▓▓▓▓▓▓▓▓▓▓▒▒      ░░▒▒▒▒      ░░▓▓█▓░░   ▒  ░░            ░░▓▓▓█▓▓▒▓▓▓▓▓▓▓▓█    ▒▒    ░  ░         
                ▓▓█▓█▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▓██▓▓█░▒▓▓▓▓▓▓▓▓▓▓▒▒      ▒▒▒▒     ░  ▓▓█▓▒▒  ░   ░░░░        ▒▒▓▓▓█▓▓▓▓▒▒▓▓▓▓▒█▓▓░   ░░ ░    ▒▒        
            ▓▓████████▓▓▒▒▓▓▓▓▓▓▓▓▓▓█░███▓████▓░████▓▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒      ░░██▓▓       ▒  ░░▒▒▒▒▓▓▓▓▓█▓▓▓▓▒▒▓▓▓▓▓▒█▓▓▓      ▒▒░░    ░░      
          ████████████▓▓▓▓▓▓▓▓▓▓█▓░███▓▓████░▓████████▓▓▓▓▓▓▓▓░░▒▒▓▓▒▒▒▒▒▒░░      ▓▓██▒▒░░░░    ░░▒▒▓▓▓████▓▓▓▓▓▓▓▒▒▓▒▓▓████▓▓░░  ▒▒▓▓▒▒░░  ░░▓▓    
        ▓▓████████▓▓▓▓▓▓▓▓▓▓██▓▓░░██████████████████▓▓▓█▓▒▒▒▓▓▓▓▓▓░▓▓▓▓░▓▓▓▒▒░░░░  ██▓▓▓▓▓▓▓▓▓░▓▓▓▓███▓█████▓▓▒▒▒▒▓▓██▒███████▓▓░░▓▓░▓▓▓▓░▓░▓▓▓▓░░  
  ▒▒████████████▓▓▓▓██▓▓██████████████▓████████████▓▒▒▓▓███▓▓▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓░░▓▓░▓▓▓▓░▓▓▓▓░▓▓▓▓▓████▓▓███▓▓▓▓█████████▒███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▓
███▓██████████▓▓██████████████████████████████████▓█▓▓▓▓██▓▓▓▓▓▓▓▓▓░░▓▓▓▓░▓▓▓▓░▓▓▓▓▓▓▓▓▓▓░▓▓▓▓▓▓████▓███▓▓▓▓▓▓███████████▒██████░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
█▓████████▓▓██████████████████████████████████████████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░░▓▓▓▓▓▓▓▓░▓▓▓███▓████▓▓▓▓▓▓█████████████▓▒███████░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓███████▓▓███████████████████████████████████████▓████▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░░▓▓▓░▓▓▓▓█▓██████▓▓▓▓▓▓▓▓█████████████████▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████▓▓███████████████████████▓████████████████████████▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓▓▓█████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
█████████████████████████████████████████████▓██████████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████████████████████████████████████████▓█████████████▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓██▓▓██████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓
████████████████████████████▓█████████████████████████████▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓██████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓
████████▓█████████▓▓████████████████████████████████████▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓██████████████████████▓███████████████████▓▓▓▓▓▓
█████▓████████████▓▓▓▓██████████████████████████████████▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓███████████▓████████████████████████████████████▓▓▓▓
███▓▓█████████████▓▓▓▓██████████████████████████████████▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓██▓▓██████████████████████████████████████████▓▓▓▓▓▓▓▓
█▓████████████████▓▓▓▓▓▓▓▓██████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓██████████████████████████████████████████████████▓▓▓▓▓▓
▓██████████████▓▓██▓▓▓▓▓▓▓▓▓▓██▓▓▓▓███████████████▓██▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████▓▓█████████▓████████████████████████████████████████████▓▓▓▓
██████████████▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████▓██████████████▓██████████████████████████▓██████████████████▓▓
██████████▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████▓█████████████████████████████████▓▓███████████
##################################################################################################################################################
# Kernel \r on \m #

EOF
cat > /etc/profile.d/welcome.sh << EOF
echo -e '\e[1;31mWelcome to Alpine $ALPINE_VERSION K2.\e[0m'
echo -e '\e[1;31mZsh will be red. \e[1;34m Ash shell will blue.\e[0m'
EOF
chmod +x /etc/profile.d/welcome.sh
################################################################################################################################################### 
# Source the environment file in the current shell to make commands available
. "$HOME/.config/environment" 
echo "All set." 
echo "K2 SETUP. DONE. Reboot"
