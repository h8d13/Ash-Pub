#!/bin/sh
## For optional change shells LATER IN SCRIPT
username=$(whoami)
echo "Hi $username"

########################################## OPTIONAL SYSTEM TWEAKS
## Parralel boot 
#sed -i 's/^rc_parallel="NO"/rc_parallel="YES"/' /etc/rc.conf

cat > /etc/periodic/daily/clean-tmp << 'EOF'
#!/bin/sh
find /tmp -type f -atime +10 -delete
EOF
chmod +x /etc/periodic/daily/clean-tmp

cat > /etc/security/limits.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 32768
* hard nproc 32768
EOF

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
sysctl -p

# Community & main ######################### vX.xX/Branch
echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" >> /etc/apk/repositories
apk update

## Extended ascii support  (thank me later ;)
apk add --no-cache tzdata font-noto-emoji fontconfig musl-locales

########################################## LOCAL BIN THE GOAT <3
mkdir -p "$HOME/.local/bin"
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

# Source environment file in both shells
for config in "$HOME/.config/ash/ashrc" "$HOME/.config/zsh/zshrc"; do
    echo 'if [ -f "$HOME/.config/environment" ]; then
    . "$HOME/.config/environment"
fi' >> "$config"
done

# Create a simple shell switcher
cat > ~/.local/bin/chsh-local << 'EOF'
#!/bin/sh
# Simple shell toggler between ash and zsh
if [ -n "$(ps -p $$ | grep ash)" ] || [ -n "$(ps -p $$ | grep sh)" ]; then
    exec zsh
else
    exec ash
fi
EOF

# Make it executable
chmod +x ~/.local/bin/chsh-local

########################################## SHARED (ASH & ZSH) ALIASES
cat > "$HOME/.config/aliases" << 'EOF'
# Base aliases
alias clr="clear"
alias cls="clr"
alias sudo="doas"
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
alias wztree="doas du -h / | sort -rh | head -n 30 | less"
alias wzhere="doas du -h . | sort -rh | head -n 30 | less"
alias chsh='~/.local/bin/chsh-local'"
EOF

# Create /etc/profile.d/profile.sh to source user profile if it exists & Make exec
cat > /etc/profile.d/profile.sh << 'EOF'
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
EOF

########################################## ASH
chmod +x /etc/profile.d/profile.sh
# Create ~/.config/ash directory if it doesn't exist
mkdir -p "$HOME/.config/ash"
# Create ~/.config/ash/profile and add basic style 
echo 'export ENV="$HOME/.config/ash/ashrc"' > "$HOME/.config/ash/profile"

# Custom Ash blue
cat > "$HOME/.config/ash/ashrc" << 'EOF'
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOF

########################################## ZSH 
# === Install Essentials ===
apk add zsh git

# === Install Zsh Plugins ===
mkdir -p "$HOME/.zsh/plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-history-substring-search "$HOME/.zsh/plugins/zsh-history-substring-search"
git clone https://github.com/zsh-users/zsh-completions "$HOME/.zsh/plugins/zsh-completions"

# === Create ~/.config/zsh directory if it doesn't exist ===
mkdir -p "$HOME/.config/zsh"

# === Create ~/.config/zsh/zshrc ===
cat > "$HOME/.config/zsh/zshrc" << 'EOF'
# === Load Extra Completions ===
fpath+=("$HOME/.zsh/plugins/zsh-completions/src")

# === Source Zsh Plugins ===
. "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
. "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
. "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"

# === History Substring Search with Arrow Keys ===
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# === Custom Zsh Prompt Red ===
export PROMPT='%F{red}┌──[%F{cyan}%D{%H:%M}%F{red}]─[%F{default}%n%F{red}@%F{cyan}%m%F{red}]─[%F{green}%~%F{red}]
%F{red}└──╼ %F{cyan}$ %f'
# === Source common aliases ===
if [ -f "$HOME/.config/aliases" ]; then
    . "$HOME/.config/aliases"
fi
EOF

# === Ensure ~/.zshrc Sources the New Config ===
echo '. "$HOME/.config/zsh/zshrc"' >> "$HOME/.zshrc"

# === Add zsh to /etc/shells if missing ===
grep -qxF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells

# === OPTIONAL: Switch default login shell to zsh globally ===
#sed -i 's|/bin/sh|/bin/zsh|g' /etc/passwd
# === OR: Switch shell for current user only ===
#sed -i -E "s|^($username:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:).*|\1/bin/zsh|" /etc/passwd


########################################## INFO STUFF
cat > /etc/motd << 'EOF'
See <https://wiki.alpinelinux.org> for more info.
For keyboard layouts: setup-keymap
Set up the system with: setup-alpine

Apk sources /etc/apk/repositories
Change this message by editing /etc/motd
Change the pre-login message /etc/issue
Change shells (zsh installed) /etc/passwd
Custom with <3 by H8D13. 
EOF

## Pre login splash art
cat > /etc/issue << 'EOF'

                                                                                                                                                  
                                                      ▒▒▒▒░░░░                                                                                    
                                                      ▓▓  ░░  ░░                                                                                  
                                                  ▒▒▓▓▓▓    ░░  ▒▒                           ########                                                     
                                              ░░▓▓▓▓▓▓░░    ░░    ▒▒                         # 8611 #                                                 
                                          ▓▓▓▓█▓▓▓▓▓     ░    ░░    ░░▓▓▒▒█▓▓▓               ########                                                     
                                        ▒▒▓▓▓█▓▓█▓▒▒          ▒▒      ▓▓▓█▓▓▒▒▒▒             # v1.3 #                                                    
                                        ▓▓▓█▓▓▒▒▓█▓▓          ░░▒▒    ░░▓▓▓▓▓▓░░             ########                                                     
                                      ░░▓█▓▓▒▒▒▓▓▓▓█▒▒       ░  ▒▒░░    ░░▓▓█▓                                          ▒▒▓█▒▒                    
                                      ▓█▓▓▓▓▒▒▓▓▓▓█▓▓▓▓▓        ▒▒░░      ▒▒▓▓░░▒▒                                    ▓▓▓▓    ▒▒                  
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
# Kernel \r on \m #
EOF

cat > /etc/profile.d/welcome.sh << 'EOF'
echo -e '\e[1;31mWelcome to Alpine K2.\e[0m'
echo -e '\e[1;31mZsh will be red. \e[1;34m Ash shell will blue.\e[0m'
echo "Find shared aliases ~/.config/aliases"
echo "Use . ~/.config/aliases if you added something"
echo "Post login scripts can be added to /etc/profile.d"
echo "Personal bin in ~/.local/bin"
echo "chsh to switch between sh/zsh"

EOF
chmod +x /etc/profile.d/welcome.sh
################################################################################################################################################### 




