#!/bin/bash
## Script made for Rasp4+ (preferably on NVMe SSD if you want a responsive system) 
# Or really any deb base using bash shell?
# Get image from Raspi imager, Pick Armbian64 > Kde neon
# Make sure you created a user, pws, etc
# Update upgrade > Then run this script as root "su" to get to root. 
TARGET_USER=hadean

echo "Checking user..." 
## Check the target user is correct
if [ ! -d "/home/$TARGET_USER" ]; then
    echo "ERROR: Home directory for user '$TARGET_USER' does not exist. Exiting."
    exit 1
fi
########################################## FIX SESSIONS
echo "Setting up KDE Config..." 
## Cool prepend move totally useless file doesnt exist yet but it's cool ya know
CONFIG_FILE2="/home/$TARGET_USER/.config/ksmserverrc"
TMP_FILE="$(mktemp)"
echo -e "[General]\nloginMode=emptySession" > "$TMP_FILE"
cat "$CONFIG_FILE2" >> "$TMP_FILE" 2>/dev/null # ignore not exist error idk 
mv "$TMP_FILE" "$CONFIG_FILE2"
# Basically just makes it so that new sessions are fresh
# Simple override the whole file for 15 min lockout and 5 min password grace. 
CONFIG_FILE3="/home/$TARGET_USER/.config/kscreenlockerrc"
cat <<EOF > $CONFIG_FILE3
[Daemon]
LockGrace=300
Timeout=30
EOF

########################################## MORE Nice to haves
echo "Setting up Bonuses..." 
## Update package list first
if ! apt update; then
    echo "ERROR: Failed to update package databases"
    exit 1
fi
## Initial zsh (thank me later ;)
apt install -y zsh ufw vim
########################################## DIRS
echo "Setting up Directories..." 
## Admin
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/bash"
mkdir -p "$HOME/.local/bin"
## User
mkdir -p "/home/$TARGET_USER/.local/share/konsole"
mkdir -p "/home/$TARGET_USER/.config/zsh"
mkdir -p "/home/$TARGET_USER/.config/bash"
########################################## CREATE THE KONSOLE PROFILE 
echo "Setting up Konsole..." 
cat > "/home/$TARGET_USER/.config/konsolerc" << EOF
[Desktop Entry]
DefaultProfile=$TARGET_USER.profile
EOF
# Create the profile file with a .profile extension can also use "bash" instead of "zsh" 
cat > "/home/$TARGET_USER/.local/share/konsole/$TARGET_USER.profile" << EOF
[General]
Command=zsh
Name=$TARGET_USER
Parent=FALLBACK/
EOF

## Root shell profile
cat > "/home/$TARGET_USER/.local/share/konsole/root.profile" << EOF
[General]
Command=su -l -c 'zsh'  
Name=root
Parent=FALLBACK/
EOF

#### Give everything back to user. IMPORTANT: BELOW NO MORE USER CHANGES. ##### IMPORTANT IMPORTANT IMPORTANT #######
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
# Create the script file - using dpkg instead of apk for apt-based systems
cat > ~/.local/bin/iapps << 'EOF'
#!/bin/sh
# this script lets you search your installed packages easily
if [ -z "$1" ]; then
    echo "Missing search term"
    exit 1
fi
dpkg -l | grep "$1"
EOF
# Make it executable ### Can now be called simply as iapps git
chmod +x ~/.local/bin/iapps

########################################## SHARED (BASH & ZSH) ALIASES
echo "Setting up aliases..." 
cat > "$HOME/.config/aliases" << EOF
alias comms="cat ~/.config/aliases | sed 's/alias//g'"
alias ecomms="vim ~/.config/aliases"
alias syncusr="cp ~/.config/aliases /home/$TARGET_USER/.config/aliases"
alias srcall=". ~/.config/aliases"
# Base alias
alias cdu="cd /home/$TARGET_USER/"
alias aus="su $TARGET_USER" 
alias clr="clear"
alias cls="clr"
alias ls='ls --color=auto'
alias ll='ls --color=auto -la'
alias la='ls --color=auto -a'
alias l='ls --color=auto -CF'
# Utils alias
alias wztree="du -h / | sort -rh | head -n 30 | less"
alias wzhere="du -h . | sort -rh | head -n 30 | less"
alias genpw="head /dev/urandom | tr -dc A-Za-z0-9 | head -c 21; echo"
alias logd="tail -f /var/log/syslog"  # Changed from /var/log/messages to syslog for Debian-based
alias logds="dmesg -r"
alias birth="stat /"
# APT aliases 
alias updapc="apt update && apt upgrade"
alias apklean="apt autoremove --purge"
alias apka="apt install"
alias apkd="apt remove"
alias apks="apt search"
# Practical alias
alias sudo='sudo ' # crucial
EOF

########################################## BASH CONFIGURATION
echo "Setting up Bash..." 
# === Create ~/.config/bash/bashrc ===
cat > "$HOME/.config/bash/bashrc" << 'EOF'
# === Custom Bash Prompt Blue ===
export PS1='\[\033[1;34m\]┌──[\[\033[0;36m\]\A\[\033[1;34m\]]─[\[\033[0m\]\u\[\033[1;34m\]@\[\033[0;36m\]\h\[\033[1;34m\]]─[\[\033[0;32m\]\w\[\033[1;34m\]]\n\[\033[1;34m\]└──╼ \[\033[0;36m\]$ \[\033[0m\]'

# === Source common aliases ===
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi

# === Source environment file ===
if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi
EOF

# === Ensure ~/.bashrc Sources the New Config ===
# Create ~/.bashrc if it doesn't exist
touch "$HOME/.bashrc"
# Add source line if not already present
grep -q "HOME/.config/bash/bashrc" "$HOME/.bashrc" || echo '. "$HOME/.config/bash/bashrc"' >> "$HOME/.bashrc"

########################################## ZSH 
echo "Setting up ZSH..." 
apt install -y zsh-autosuggestions \
              zsh-syntax-highlighting

# === Create ~/.config/zsh/zshrc ===
cat > "$HOME/.config/zsh/zshrc" << 'EOF'
# === Load Extra Completions ===
if [ -d "/usr/share/zsh/vendor-completions" ]; then
    fpath+=("/usr/share/zsh/vendor-completions")
fi

# === History Configuration ===
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# === Source Zsh Plugins (with error checking) ===
# Load autosuggestions and history-substring-search first
if [ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    . "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
    echo "Warning: zsh-autosuggestions plugin not found"
fi

# Load syntax-highlighting last as recommended
if [ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    . "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
    echo "Warning: zsh-syntax-highlighting plugin not found"
fi

# === Custom Zsh Prompt Red ===
export PROMPT='%F{red}┌──[%F{cyan}%D{%H:%M}%F{red}]─[%F{default}%n%F{red}@%F{cyan}%m%F{red}]─[%F{green}%~%F{red}]
%F{red}└──╼ %F{cyan}$ %f'

# === Source common aliases ===
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi

# === Source environment file ===
if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi
EOF

# === Ensure ~/.zshrc Sources the New Config ===
# Create ~/.zshrc if it doesn't exist
touch "$HOME/.zshrc"
# Add source line if not already present
grep -q "HOME/.config/zsh/zshrc" "$HOME/.zshrc" || echo '. "$HOME/.config/zsh/zshrc"' >> "$HOME/.zshrc"
# === Add zsh to /etc/shells if missing ===
grep -qxF '/usr/bin/zsh' /etc/shells || echo '/usr/bin/zsh' >> /etc/shells

########################################## USER SHELL SETUP
echo "Setting up user shell configurations..."

# Copy shell configs to user
cp "$HOME/.config/zsh/zshrc" "/home/$TARGET_USER/.config/zsh/zshrc"
cp "$HOME/.config/bash/bashrc" "/home/$TARGET_USER/.config/bash/bashrc"
cp "$HOME/.config/aliases" "/home/$TARGET_USER/.config/aliases"
cp "$HOME/.config/environment" "/home/$TARGET_USER/.config/environment"

# Create user's shell rc files
touch "/home/$TARGET_USER/.zshrc"
echo '. "$HOME/.config/zsh/zshrc"' >> "/home/$TARGET_USER/.zshrc"

touch "/home/$TARGET_USER/.bashrc"
echo '. "$HOME/.config/bash/bashrc"' >> "/home/$TARGET_USER/.bashrc"

# Set user's default shell to zsh
chsh -s /usr/bin/zsh $TARGET_USER

# Fix ownership after copying
chown -R $TARGET_USER:$TARGET_USER /home/$TARGET_USER/

########################################## SYSTEM HARDENING
echo "Setting up Security fixes..." 
## Enhanced firewall
ufw default deny incoming
ufw enable

## Enhanced system hardening - using sysctl.d for better organization
cat > /etc/sysctl.d/99-custom-harden.conf << 'EOF'
# Network performance and security
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1

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

# Performance tweaks
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

# Apply settings
sysctl --system >/dev/null 2>&1
