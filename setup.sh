#!/bin/sh
## /* SPDX-FileCopyrightText: 2025 
# (O) Eihdran L. <hadean-eon-dev@proton.me>
# (C) Lagan S. <sarbjitsinghsandhu509@gmail.com>
# Desc: Extended Install Intel.
##  SPDX-License-Identifier: MIT */
#set -e
#set -x
#### NO MORE CONFIG ALL AUTOMATED.
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||') 
ALPINE_VERSION=$(cat /etc/alpine-release)
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
echo "Detected ALPINE v: $ALPINE_VERSION TARGET_USER set to:$TARGET_USER : KB_LAYOUT set to:$KB_LAYOUT"
# Community & main & Testing ############### vX.xX/Branch
# Check if running on edge
if echo "$ALPINE_VERSION" | grep -q "alpha"; then
    echo "Detected EDGE expect bugs."
    cp /etc/apk/repositories /etc/apk/repositories.bak
    echo "Original repositories backed up to /etc/apk/repositories.bak"
	# Clear the current repositories file
    echo "Clearing current repositories..."
    > /etc/apk/repositories
    echo "Setting up repositories for Alpine edge..."
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
else
    # Extract major.minor version (e.g., "3.21")
    VERSION_NUM=$(echo "$ALPINE_VERSION" | cut -d '.' -f 1,2)
    cp /etc/apk/repositories /etc/apk/repositories.bak
    echo "Original repositories backed up to /etc/apk/repositories.bak"
    # Clear the current repositories file
    echo "Clearing current repositories..."
    > /etc/apk/repositories
    echo "Setting up repositories for Alpine..."
    echo "https://dl-cdn.alpinelinux.org/alpine/v$VERSION_NUM/main" >> /etc/apk/repositories
    echo "https://dl-cdn.alpinelinux.org/alpine/v$VERSION_NUM/community" >> /etc/apk/repositories
fi
echo "Repositories added successfully! Ready?"
apk update && apk upgrade
########################################## VIDEO
echo "Setting up video/drivers..." 
apk add xf86-video-vesa 
apk add mesa mesa-gl mesa-va-gallium mesa-dri-gallium
#mesa-dri-vmwgfx ## # mesa-vulkan-layers vulkan-tools
apk add intel-ucode #amd-ucode
apk add linux-firmware-intel #-amd
apk add intel-gmmlib intel-media-driver libva-intel-driver mesa-vulkan-intel
# xf86-video-intel 
## Check the wiki if using older hardware/AMD :3 
# xf86-video-amdgpu # mesa-vulkan-radeon ...
########################################## DISPLAY SERVERS
#setup-xorg-base
#apk add kbd xorg-server xrandr inxi xf86-input-evdev xf86-input-libinput
setup-wayland-base
setup-desktop plasma
########################################## REMOVE STUFF
apk del kate kate-common
########################################## ESSENTIALS
echo "Setting up drivers..."
apk add linux-firmware-other \
 	linux-firmware \
	linux-lts \
  	pciutils \
	wpa_supplicant \
  	dbus-openrc \
     	busybox-extras \
 	ufw \
  	ip6tables 
   
apk add util-linux dolphin wget tar zstd hwinfo lshw usbutils micro
########################################## OPTIONAL SYSTEM TWEAKS (ADVANCED)
#apk add gtkmm3 glibmm gcompat
#apk add fuse libstdc++ dbus-x11 ##  modprobe fuse ### addgroup $USER fuse
#rc-update del sddm default
#apk add bash fish nix
#chsh -s /bin/zsh root
## Parralel boot 
#sed -i 's/^rc_parallel="NO"/rc_parallel="YES"/' /etc/rc.conf
## CPU Freq
#apk add cpufrequtils
########################################## EXTRA SERVICES (OPTIONAL)
#apk add docker docker-compose podman ## Ideally create a user for said service
#apk add flatpak
#flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
########################################## OTHERS SOUND (Thnx to Klagan)
echo "Setting up sound..."
apk add pulseaudio-alsa alsa-plugins-pulse alsa-utils sof-firmware
# use alsamixer > f6 select card and M to unmute devices
addgroup $TARGET_USER audio
addgroup $TARGET_USER video
########################################## Security
echo "Setting up UFW & Ip6Tables..." 
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
rc-update add ufw
rc-update add alsa
########################################## COUNTDOWN Bellow more specifics.
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
########################################## Kdepost 3rd reboot but helps do quick setup. Can add more kwrites as desired.
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
# Basiclally just makes it so that new sessions are fresh (something that I always thought was a stupid default value... 
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
apk add tzdata font-noto-emoji fontconfig musl-locales font-noto ttf-dejavu zsh
########################################## DIRS
echo "Setting up Directories..." 
## Admin
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/ash"
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/micro/"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.zsh/plugins"
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
apk list --installed | grep "$1"
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
alias logd="tail -f /var/log/messages"
alias logds="dmesg -r"
# Apk alias
alias updapc="apk update && doas apk upgrade"
alias apklean="apk clean cache"
alias apka="apk add"
alias apkd="apk del"
alias apks="apk search"
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
# Install ZSH plugins via package manager instead of git
apk add zsh-autosuggestions \
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

echo "Setting up edge repos..." 
echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update

echo "Cleaning cache..." 
rm -rf /var/cache/apk/*

########################################## INFO STUFF
cat > /etc/motd << 'EOF'
Apk sources /etc/apk/repositories
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
                                        ▒▒▓▓▓█▓▓█▓▒▒          ▒▒      ▓▓▓█▓▓▒▒               # 1.3.1 #                                                    
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

#PLASMA_VERSION=$(apk search plasma-welcome-lang | grep -o "plasma[^[:space:]]*-[0-9][0-9\.]*-r[0-9]*" | sed -E 's/.*-([0-9][0-9\.]*-r[0-9]*)/\1/')
#echo "KDE Plasma Version: $PLASMA_VERSION"
