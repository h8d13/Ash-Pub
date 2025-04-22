#!/bin/sh
#### ARCH CONFIG - AUTOMATED SETUP
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
KB_LAYOUT=$(localectl list-x11-keymap-layouts | grep "^$(setxkbmap -query | grep layout | cut -d: -f2 | xargs)" | head -1)
#### Should return "us" "fr" "de" "it" "es" etc 

# Exit if no TARGET_USER found
if [ -z "$TARGET_USER" ]; then
    echo "ERROR: No user with /home directory found. Exiting."
    exit 1
fi

username=$(whoami)
echo "Hi $username : TARGET_USER set to:$TARGET_USER : KB_LAYOUT set to:$KB_LAYOUT"

########################################## SYSTEM PACKAGES
# Update system and install Plasma + tools
pacman -Syu --noconfirm
pacman -S --noconfirm plasma-meta kde-applications sddm plasma-wayland-session zsh micro ufw ttf-noto-emoji fontconfig konsole dolphin noto-fonts git

# Enable services
systemctl enable sddm.service
systemctl enable NetworkManager
systemctl enable ufw

########################################## FIX LOGIN KB
mkdir -p /etc/X11/xorg.conf.d/
cat > /etc/X11/xorg.conf.d/00-keyboard.conf << EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "$KB_LAYOUT"
EndSection
EOF

########################################## FIX GLOBAL KB
mkdir -p "/home/$TARGET_USER/.config"
cat > "/home/$TARGET_USER/.config/kxkbrc" << EOF
[Layout]
LayoutList=$KB_LAYOUT
Use=True
EOF

########################################## DIRS
## Admin
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/bash"
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/micro/"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.zsh/plugins"

## User
mkdir -p "/home/$TARGET_USER/.config/micro/"
mkdir -p "/home/$TARGET_USER/.local/share/konsole"

########################################## FRIENDLY EDITOR
cat > "$HOME/.config/micro/settings.json" << 'EOF'
{
    "sucmd": "sudo"
}
EOF

cat > "/home/$TARGET_USER/.config/micro/settings.json" << 'EOF'
{
    "sucmd": "sudo"
}
EOF

########################################## CREATE THE KONSOLE PROFILE 
cat > "/home/$TARGET_USER/.config/konsolerc" << EOF
[Desktop Entry]
DefaultProfile=$TARGET_USER.profile
EOF

cat > "/home/$TARGET_USER/.local/share/konsole/$TARGET_USER.profile" << EOF
[General]
Command=su -l
Name=$TARGET_USER
Parent=FALLBACK/
EOF

########################################## KPost script fix KDE Quirks. 
mkdir -p "/home/$TARGET_USER/Desktop/k2-os"
cat > /home/$TARGET_USER/Desktop/k2-os/kpost.sh << 'EOF'
#!/bin/sh
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
TMP_FILE="$(mktemp)"

awk '
BEGIN { state = 0 }
/^\[Containments\]\[2\]\[Applets\]\[5\]$/ { state = 1; print; next }
state == 1 && /^immutability=1$/ { state = 2; print; next }
state == 2 && /^plugin=org\.kde\.plasma\.icontasks$/ {
    print
    print ""
    print "[Containments][2][Applets][5][Configuration][General]"
    print "launchers=preferred://filemanager,applications:org.kde.konsole.desktop"
    state = 0
    next
}
{ print }
' "$CONFIG_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$CONFIG_FILE"

plasma-apply-desktoptheme breeze-dark > /dev/null 2>&1
plasma-apply-colorscheme BreezeDark > /dev/null 2>&1
killall plasmashell > /dev/null 2>&1 && kstart5 plasmashell > /dev/null 2>&1
EOF
chmod +x /home/$TARGET_USER/Desktop/k2-os/kpost.sh

########################################## K2 Wiki and Repo
cat > /home/$TARGET_USER/Desktop/k2-os/wiki-k2.desktop << 'EOF'
[Desktop Entry]
Icon=alienarena
Name=wiki-k2
Type=Link
URL[$e]=https://github.com/h8d13/k2-alpine/wiki
EOF

git clone https://github.com/h8d13/k2-alpine.git /tmp/k2-alpine-temp
mv /tmp/k2-alpine-temp/* /home/$TARGET_USER/Desktop/k2-os/
mv /tmp/k2-alpine-temp/.* /home/$TARGET_USER/Desktop/k2-os/ 2>/dev/null || true
rm -rf /tmp/k2-alpine-temp

########################################## Give everything back to user
chown -R $TARGET_USER:$TARGET_USER /home/$TARGET_USER/

########################################## LOCAL BIN
cat > "$HOME/.config/environment" << 'EOF'
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOF

########################################## SHARED ALIASES
cat > "$HOME/.config/aliases" << 'EOF'
# Main alias
alias mc="micro"
alias startde="systemctl start sddm"
alias stoptde="systemctl stop sddm"
# Base alias
alias clr="clear"
alias cls="clr"
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
# Utils alias
alias comms="cat ~/.config/aliases | sed 's/alias//g'"
alias wztree="du -h / | sort -rh | head -n 30 | less"
alias wzhere="du -h . | sort -rh | head -n 30 | less"
alias genpw="head /dev/urandom | tr -dc A-Za-z0-9 | head -c 21; echo"
alias logd="journalctl -f"
alias logds="dmesg -r"
# Pacman alias
alias updapc="sudo pacman -Syu"
alias paclean="sudo pacman -Sc"
alias pacin="sudo pacman -S"
alias pacrm="sudo pacman -R"
alias pacs="pacman -Ss"
EOF

########################################## BASH/ZSH Setup
# Bash config
cat > "$HOME/.bashrc" << 'EOF'
# Style
export PS1='\[\033[0;34m\]┌──[\[\033[0;36m\]\t\[\033[0;34m\]]─[\[\033[0;39m\]\u\[\033[0;34m\]@\[\033[0;36m\]\h\[\033[0;34m\]]─[\[\033[0;32m\]\w\[\033[0;34m\]]\n\[\033[0;34m\]└──╼ \[\033[0;36m\]$ \[\033[0m\]'

if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi

if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi
EOF

# ZSH Setup
sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search

cat > "$HOME/.config/zsh/zshrc" << 'EOF'
# Load plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Prompt
export PROMPT='%F{red}┌──[%F{cyan}%D{%H:%M}%F{red}]─[%F{default}%n%F{red}@%F{cyan}%m%F{red}]─[%F{green}%~%F{red}]
%F{red}└──╼ %F{cyan}$ %f'

if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi

if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi
EOF

########################################## UFW Setup
ufw default deny incoming
ufw enable

########################################## System Info
cat > /etc/motd << 'EOF'
Arch Linux - K2 Customized

Pacman commands aliased:
updapc - System update
pacin - Install package  
pacrm - Remove package
pacs - Search package

Use 'startde/stoptde' for Desktop Environment
'mc' for micro editor

Custom with <3 by H8D13.
EOF

# Set ZSH as default shell for target user
chsh -s /bin/zsh $TARGET_USER

echo "Arch K2 setup complete!"
