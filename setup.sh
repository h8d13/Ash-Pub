#!/bin/sh
#set -e
#### NO MORE CONFIG ALL AUTOMATED.
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||') 
ALPINE_VERSION=$(cat /etc/alpine-release)
#### Should return "us" "fr" "de" "it" "es" etc 
# Exit if no TARGET_USER found
if [ -z "$TARGET_USER" ]; then
    echo "ERROR: No user with /home directory found. Exiting."
    exit 1
fi
username=$(whoami)
echo "Hi $username : TARGET_USER set to:$TARGET_USER : KB_LAYOUT set to:$KB_LAYOUT"
# Will be root ^^
# Community & main & Testing ############### vX.xX/Branch
# Get Alpine version
echo "Detected Alpine version: $ALPINE_VERSION"
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
apk update
apk upgrade

echo "Setting up drivers..." 
apk add mesa-dri-gallium #mesa-va-gallium 

echo "Starting setup..."
echo "3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1
echo "Go!"
setup-desktop plasma
## Debloating
echo "..." 
apk del kate kate-common
########################################## AUDIO
echo "Setting up audio/video/drivers..." 
# thnx to lagan 
apk add elogind polkit polkit-elogind
apk add pipewire wireplumber pipewire-pulse pipewire-jack 
#apk add pipewire-alsa
apk add linux-firmware-i915 \
	linux-firmware-other \
	linux-lts \
	wpa_supplicant \
 	doas \
 	dbus 
########################################## NECESSARY RUNLEVEL
echo "Setting services..."
rc-update add dbus 
rc-update add elogind 
rc-update add sddm
rc-update add pipewire
rc-update add pipewire-pulse
rc-update add wireplumber 
########################################## OTHERS
#rc-update del sddm default
########################################## OPTIONAL SYSTEM TWEAKS
#apk add gcompat flatpak
##chsh -s /bin/zsh root
#apk add bash fish
## Parralel boot 
#sed -i 's/^rc_parallel="NO"/rc_parallel="YES"/' /etc/rc.conf
## OPTIONAL: Switch default login shell to zsh globally
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
######################################### FIX SESSIONS
echo "Setting up KDE Config..." 
## Cool prepend move totally useless file doesnt exist yet but it's cool ya know
CONFIG_FILE2="/home/$TARGET_USER/.config/ksmserverrc"
TMP_FILE="$(mktemp)"
echo -e "[General]\nloginMode=emptySession" > "$TMP_FILE"
cat "$CONFIG_FILE2" >> "$TMP_FILE" 2>/dev/null # ignore not exist error idk 
mv "$TMP_FILE" "$CONFIG_FILE2"
# Basiclally just makes it so that new sessions are fresh. 
# Simple override the whole file for 15 min lockout and 5 min password grace. 
CONFIG_FILE3="/home/$TARGET_USER/.config/kscreenlockerrc"
cat <<EOF > $CONFIG_FILE3
[Daemon]
LockGrace=300
Timeout=15
EOF
#echo "Setting up KDE Shortcuts..."
# Setup Konsole shortcut for usershell DOESNT WORK YET
#CONFIG_FILE4="/home/$TARGET_USER/.config/kglobalshortcutsrc"
#cat >> "$CONFIG_FILE4" << EOF
#[services][net.local.konsole.desktop]
#_launch=Ctrl+Alt+Y
#EOF
########################################## MORE SYSTEM TWEAKS
# remove sddm login default  (Shell already does this.) # in case user prefers shell manual start
########################################## MORE Noice to haves
echo "Setting up Bonuses..." 
## Extended ascii support + Inital zsh (thank me later ;)
apk add --no-cache tzdata font-noto-emoji fontconfig musl-locales zsh micro ufw util-linux dolphin wget tar
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
########################################## KPost script fix KDE Quirks. We assume total generation of files takes about 30 seconds.
echo "Setting up KDE..." 
mkdir -p "/home/$TARGET_USER/Desktop/k2-os/etc"
cat > /home/$TARGET_USER/Desktop/k2-os/etc/kpost.sh << EOF
#!/bin/sh
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 5 --group Configuration --group General --key launchers "applications:org.kde.konsole.desktop"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image "/usr/share/wallpapers/Mountain/contents/images_dark/5120x2880.png"
# Set dark theme for menu and taskbar
plasma-apply-desktoptheme breeze-dark
# Set dark theme for window styles
plasma-apply-colorscheme BreezeDark
# Restart Plasma to apply changes
killall plasmashell
EOF
chmod +x /home/$TARGET_USER/Desktop/k2-os/etc/kpost.sh
cat > /home/$TARGET_USER/Desktop/k2-os/runme.sh << EOF
#!/bin/sh
konsole --builtin-profile -e "/home/$TARGET_USER/Desktop/k2-os/etc/kpost.sh" && service sddm restart
EOF
chmod +x /home/$TARGET_USER/Desktop/k2-os/runme.sh
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
########################################## Firefox profile
#TODO
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
alias startde="rc-service sddm start"
alias stopde="rc-service sddm stop"
alias resde="rc-service sddm restart"
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

echo "Setting up UFW & Ip6Tables..." 
apk add --no-cache ip6tables
ufw default deny incoming

## Examples stolen from the internet # uncomment if using these
#ufw limit SSH         # open SSH port and protect against brute-force login attacks
#ufw allow out 123/udp # allow outgoing NTP (Network Time Protocol)
#ufw allow out DNS     # allow outgoing DNS
#ufw allow out 80/tcp  # allow outgoing HTTP/HTTPS traffic
ufw allow out 443/tcp 
#ufw allow 51820/udp
ufw enable
rc-update add ufw   

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
