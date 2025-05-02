#!/bin/sh
## /* SPDX-FileCopyrightText: 2025 
# (O) Eihdran L. <hadean-eon-dev@proton.me>
# (C) Lagan S. <sarbjitsinghsandhu509@gmail.com>
# Adapted for Artix OpenRC by Eihdran
# Desc: Extended Install Artix / Wayland (+Optionals).
##  SPDX-License-Identifier: MIT */
#set -e+
#set -x
#### NO MORE CONFIG ALL AUTOMATED.
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
KB_LAYOUT=$(setxkbmap -query | grep layout | awk '{print $2}')
ARTIX_VERSION=$(grep VERSION /etc/os-release | head -1 | cut -d'"' -f2)
# Exit if not root
if [ "$(whoami)" != "root" ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi
#### Should return "us" "fr" "de" "it" "es" etc 
# Exit if no TARGET_USER found
if [ -z "$TARGET_USER" ]; then
    echo "ERROR: No user with /home directory found. Exiting."
    exit 1
fi
echo "Detected ARTIX v: $ARTIX_VERSION TARGET_USER set to:$TARGET_USER : KB_LAYOUT set to:$KB_LAYOUT"

echo "Repositories added successfully! Ready?"
pacman -Syu

########################################## VIDEO
echo "Setting up video/drivers..." 
pacman -S --noconfirm xf86-video-vesa 
pacman -S --noconfirm mesa mesa-demos libva-mesa-driver mesa-vdpau
pacman -S --noconfirm intel-ucode #amd-ucode for AMD systems
pacman -S --noconfirm libva-intel-driver intel-media-driver vulkan-intel
# xf86-video-intel 
## Check the wiki if using older hardware/AMD :3 
# xf86-video-amdgpu vulkan-radeon ...

########################################## DISPLAY SERVERS
pacman -S --noconfirm xorg xorg-server xorg-xinit
pacman -S --noconfirm wayland wayland-protocols xorg-xwayland

########################################## PLASMA DESKTOP
pacman -S --noconfirm plasma-meta plasma-wayland-session kde-applications elogind-openrc
# Setup OpenRC services for display manager
rc-update add elogind default
rc-update add sddm default

########################################## ESSENTIALS
echo "Setting up drivers..."
pacman -S --noconfirm linux-lts 
pacman -S --noconfirm linux-firmware
pacman -S --noconfirm pciutils
pacman -S --noconfirm wpa_supplicant wpa_supplicant-openrc
pacman -S --noconfirm dbus dbus-openrc
pacman -S --noconfirm busybox
pacman -S --noconfirm ufw ufw-openrc
pacman -S --noconfirm iptables-nft iptables-nft-openrc
   
pacman -S --noconfirm util-linux dolphin wget tar zstd hwinfo lshw usbutils micro bash

########################################## OPTIONAL SYSTEM TWEAKS (ADVANCED)
## Packages
#pacman -S --noconfirm gtkmm3 glibmm gcompat
#pacman -S --noconfirm fuse libstdc++ dbus-x11

## Shells
#pacman -S --noconfirm fish
#chsh -s /bin/zsh root

########################################## EXTRA SERVICES (OPTIONAL)
#pacman -S --noconfirm docker docker-compose docker-openrc
#pacman -S --noconfirm flatpak
#flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

########################################## OTHERS SOUND
echo "Setting up sound..."
pacman -S --noconfirm alsa-utils alsa-plugins alsa-firmware
pacman -S --noconfirm sof-firmware
# use alsamixer > f6 select card and M to unmute devices
usermod -aG audio $TARGET_USER
usermod -aG video $TARGET_USER

########################################## Security
echo "Setting up UFW & Iptables..." 
ufw default deny incoming
ufw allow out 443/tcp  
## Examples stolen from the internet # uncomment if using these
#ufw limit SSH         # open SSH port and protect against brute-force login attacks
#ufw allow out DNS     # allow outgoing DNS
#ufw allow out 80/tcp  # allow outgoing HTTP/HTTPS traffic
#ufw allow 3389        # remote desktop on xorg
#ufw allow 21          # ftp
#ufw allow 22	       # sftp
#ufw allow 51820/udp   # wireguard
#ufw allow 1194/udp    # openvpn
ufw enable

########################################## NECESSARY RUNLEVEL
echo "Setting services..."
# Add necessary services here
rc-update add ufw default
rc-update add alsa default
rc-update add dbus default
rc-update add elogind default
rc-update add sddm default

########################################## COUNTDOWN
echo "Starting setup..."
echo "3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1
echo "Go!"

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

########################################## Kdepost 3rd reboot but helps do quick setup
# Mine is black theme, only konsole in taskbar and ofc mountain bg. 
echo "Setting up KdePost..." 
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

######################################### FIX SESSIONS
echo "Setting up KDE Config..." 
## Cool prepend move totally useless file doesnt exist yet but it's cool ya know
CONFIG_FILE2="/home/$TARGET_USER/.config/ksmserverrc"
TMP_FILE="$(mktemp)"
echo -e "[General]\nloginMode=emptySession" > "$TMP_FILE"
cat "$CONFIG_FILE2" >> "$TMP_FILE" 2>/dev/null # ignore not exist error idk 
mv "$TMP_FILE" "$CONFIG_FILE2"

# Simple override the whole file for 15 min lockout and 5 min password grace. 
CONFIG_FILE3="/home/$TARGET_USER/.config/kscreenlockerrc"
cat <<EOF > $CONFIG_FILE3
[Daemon]
LockGrace=300
Timeout=30
EOF

########################################## MORE Noice to haves
echo "Setting up Bonuses..." 
## Extended ascii support + Inital zsh (thank me later ;)
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra ttf-dejavu zsh

########################################## DIRS
echo "Setting up Directories..." 
## Admin
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/ash"
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/micro/"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.zsh/plugins"
## User
mkdir -p "/home/$TARGET_USER/.config/micro/"
mkdir -p "/home/$TARGET_USER/.local/share/konsole"

########################################## FRIENDLY EDITOR NEEDS EDITING :D + Alias mc + fixed create config
echo "Setting up Micro..." 
cat > "$HOME/.config/micro/settings.json" << EOF
{
    "sucmd": "doas",
    "clipboard": "external"
}
EOF
## Do the same for the user.
cat > "/home/$TARGET_USER/.config/micro/settings.json" << EOF
{
    "sucmd": "doas", 
    "clipboard": "external"
}
EOF

########################################## CREATE THE KONSOLE PROFILE 
echo "Setting up Konsole..." 
cat > "/home/$TARGET_USER/.config/konsolerc" << EOF
[Desktop Entry]
DefaultProfile=$TARGET_USER.profile
EOF
# Create the profile file with a .profile extension
cat > "/home/$TARGET_USER/.local/share/konsole/$TARGET_USER.profile" << EOF
[General]
Command=su -l
Name=$TARGET_USER
Parent=FALLBACK/
EOF

########################################## Show K2-Wiki Entry
cat > /home/$TARGET_USER/Desktop/k2-os/wikik2.desktop << 'EOF'
[Desktop Entry]
Icon=alienarena
Name=wikik2
Type=Link
URL[$e]=https://github.com/h8d13/k2-alpine/wiki
EOF

########################################## Show UserShell
cat > /home/$TARGET_USER/Desktop/k2-os/usershell.desktop << 'EOF'
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
EOF

########################################## Clone utils only
echo "Setting up Github/K2..." 
git clone https://github.com/h8d13/k2-alpine /tmp/k2-alpine
mkdir -p /home/$TARGET_USER/Desktop/k2-os/
mv /tmp/k2-alpine/utils /home/$TARGET_USER/Desktop/k2-os/
rm -rf /tmp/k2-alpine

#### Give everything back to user. IMPORTANT: BELLOW NO MORE USER CHANGES. ##### IMPORTANT IMPORTANT IMPORTANT #######
echo "Setting up permissions..." 
chown -R $TARGET_USER:$TARGET_USER /home/$TARGET_USER/

########################################## LOCAL BIN THE GOAT <3
echo "Setting up Localbin..." 
# Add local bin to PATH if it exists
cat > "$HOME/.config/environment" << 'EOF'
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOF

########################################## Example Script: Called "iapps" To search in installed packages. 
# Create the script file
cat > ~/.local/bin/iapps << 'EOF'
#!/bin/sh
# this script lets you search your installed packages easily
if [ -z "$1" ]; then
	echo "Missing search term"
	exit 1
fi
pacman -Qs "$1"
EOF

# Make it executable ### Can now be called simply as iapps git
chmod +x ~/.local/bin/iapps

########################################## SHARED (ASH & ZSH) ALIASES
echo "Setting up aliases..." 
cat > "$HOME/.config/aliases" << EOF
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
EOF

########################################## Auto source
echo "Setting up Profile..." 
# Create /etc/profile.d/profile.sh to source user profile if it exists & Make exec
cat > /etc/profile.d/profile.sh << 'EOF'
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
EOF

########################################## ASH
echo "Setting up ASH..." 
chmod +x /etc/profile.d/profile.sh
# Create ~/.config/ash/profile and add basic style 
echo 'export ENV="$HOME/.config/ash/ashrc"' > "$HOME/.config/ash/profile"

# Custom Ash blue
cat > "$HOME/.config/ash/ashrc" << 'EOF'
# Style
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
## Source aliases
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOF

########################################## ZSH 
echo "Setting up ZSH..." 
# Install ZSH plugins from Pacman
pacman -S --noconfirm zsh-autosuggestions \
      zsh-history-substring-search \
      zsh-completions \
      zsh-syntax-highlighting

# === Create ~/.config/zsh/zshrc ===
cat > "$HOME/.config/zsh/zshrc" << 'EOF'
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
EOF

# Source environment file in both shells
for config in "$HOME/.config/ash/ashrc" "$HOME/.config/zsh/zshrc"; do
    mkdir -p "$(dirname "$config")"
    touch "$config"
    echo 'if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi' >> "$config"
done

# === Ensure ~/.zshrc Sources the New Config ===
# Create ~/.zshrc if it doesn't exist
touch "$HOME/.zshrc"
# Add source line if not already present ## Symlink ciz we dont like cluttering our home
grep -q "HOME/.config/zsh/zshrc" "$HOME/.zshrc" || echo '. "$HOME/.config/zsh/zshrc"' >> "$HOME/.zshrc"

# === Add zsh to /etc/shells if missing ===
grep -qxF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells

########################################## SYSTEM HARDENING
echo "Setting up Security fixes..." 
## Not a router stuff
cat > /etc/sysctl.conf << 'EOF'
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
EOF

# Apply settings
sysctl -p >/dev/null 2>&1

echo "Cleaning cache..." 
pacman -Sc --noconfirm

########################################## INFO STUFF
cat > /etc/motd << 'EOF'
Package manager: pacman -S (install), -Rs (remove), -Syu (update)
Change this message by editing /etc/motd
Change the pre-login message /etc/issue
Change default shells /etc/passwd

Find shared aliases ~/.config/aliases
Use . ~/.config/aliases if you added something

Post login scripts can be added to /etc/profile.d
Personal bin scripts in ~/.local/bin
EOF

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
            ▓▓████████▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓█░███▓████▓░████▓▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒      ░░██▓▓       ▒  ░░▒▒▒▒▓▓▓▓▓█▓▓▓▓▒▒▓▓▓▓▓▒█▓▓▓      ▒▒░░    ░░      
          ████████████▓▓▓▓▓▓▓▓▓▓█▓░███▓▓████░▓████████▓▓▓▓▓▓▓▓░░▒▒▓▓▒▒▒▒▒▒░░      ▓▓██▒▒░░░░    ░░▒▒▓▓▓████▓▓▓▓▓▓▓▒▒▓▒▓▓████▓▓░░  ▒▒▓▓▒▒░░  ░░▓▓    
        ▓▓████████▓▓▓▓▓▓▓▓▓▓██▓▓░░██████████████████▓▓▓█▓▒▒▒▓▓▓▓▓▓░▓▓▓▓░▓▓▓▒▒░░░░  ██▓▓▓▓▓▓▓▓▓░▓▓▓▓███▓█████▓▓▒▒▒▒▓▓██▒███████▓▓░░▓▓░▓▓▓▓░▓░▓▓▓▓░░  
  ▒▒████████████▓▓▓▓██▓▓██████████████▓████████████▓▒▒▓▓███▓▓▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓░░▓▓░▓▓▓▓░▓▓▓▓░▓▓▓▓▓████▓▓███▓▓▓▓█████████▒███████▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▓
███▓██████████▓▓██████████████████████████████████▓█▓▓▓▓██▓▓▓▓▓▓▓▓▓░░▓▓▓▓░▓▓▓▓░▓▓▓▓▓▓▓▓▓▓░▓▓▓▓▓▓████▓███▓▓▓▓▓▓███████████▒██████░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
█▓████████▓▓██████████████████████████████████████████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░░▓▓▓▓▓▓▓▓░▓▓▓███▓████▓▓▓▓▓▓█████████████▓▒███████░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓███████▓▓███████████████████████████████████████▓████▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░░▓▓▓░▓▓▓▓█▓██████▓▓▓▓▓▓▓▓█████████████████▒
