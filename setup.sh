#!/bin/sh

# System tweaks
sed -i 's/^rc_parallel="no"/rc_parallel="yes"/' /etc/rc.conf

# Community & main ######################### vX.xX/Branch
echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" >> /etc/apk/repositories
apk update

## Extended ascii support for later :)
apk add --no-cache tzdata font-noto-emoji fontconfig musl-locales

# Create /etc/profile.d/profile.sh to source user profile if it exists & Make exec
cat > /etc/profile.d/profile.sh << 'EOF'
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
EOF

chmod +x /etc/profile.d/profile.sh
# Create ~/.config/ash directory if it doesn't exist
mkdir -p "$HOME/.config/ash"
# Create ~/.config/ash/profile and add basic style 
echo 'export ENV="$HOME/.config/ash/ashrc"' > "$HOME/.config/ash/profile"

cat > "$HOME/.config/ash/ashrc" << 'EOF'
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
# Aliases base:
alias cls="clr"
alias sudo="doas"
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
EOF


# === Install required packages ===
apk update
apk add zsh git curl wget unzip

# === Install Zsh plugins: Autosuggestions, Syntax Highlighting, and Fuzzy History Search ===
mkdir -p "$HOME/.zsh/plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-history-substring-search "$HOME/.zsh/plugins/zsh-history-substring-search"

# === Create ~/.config/zsh directory if it doesn't exist ===
mkdir -p "$HOME/.config/zsh"

# === Create ~/.config/zsh/zshrc ===
cat > "$HOME/.config/zsh/zshrc" << 'EOF'
# === Source Zsh Plugins ===
source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"

# === Custom Prompt ===
export PROMPT='%F{blue}┌──[%F{cyan}%*%F{blue}]─[%F{default}%n%F{blue}@%F{cyan}%m%F{blue}]─[%F{green}%~%F{blue}]
%F{blue}└──╼ %F{cyan}$ %f'
EOF

# Ensure zsh configuration is sourced
echo 'source "$HOME/.config/zsh/zshrc"' >> "$HOME/.zshrc"
echo "Configured zsh to source $HOME/.config/zsh/zshrc."

# Check install
which zsh
# Add it to login shells
grep -qxF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells
# Change default shells to zsh
sed -i 's|/bin/sh|/bin/zsh|g' /etc/passwd


cat > /etc/motd << 'EOF'
See <https://wiki.alpinelinux.org> for more info.
For keyboard layouts: setup-keymap
Set up the system with: setup-alpine

Apk sources /etc/apk/repositories
Change this message by editing /etc/motd
Change the pre-login message /etc/issue
ZSH & SH Pre-Installed.
Custom with <3 by H8D13. 
EOF

cat > /etc/issue << 'EOF'

                                                                                                                                                  
                                                      ▒▒▒▒░░░░                                                                                    
                                                      ▓▓  ░░  ░░                                                                                  
                                                  ▒▒▓▓▓▓    ░░  ▒▒                           ########                                                     
                                              ░░▓▓▓▓▓▓░░    ░░    ▒▒                         # 8611 #                                                 
                                          ▓▓▓▓▓▓▓▓▓▓          ░░    ░░▓▓▒▒▓▓▓▓               ########                                                     
                                        ▒▒▓▓▓▓▓▓▓▓▒▒          ▒▒      ▓▓▓▓▓▓▒▒▒▒             # V1.3 #                                                    
                                        ▓▓▓▓▓▓▒▒▓▓▓▓          ░░▒▒    ░░▓▓▓▓▓▓░░             ########                                                     
                                      ░░▓▓▓▓▒▒▒▓▓▓▓█▒▒          ▒▒░░    ░░▓▓▓▓                                          ▒▒▓█▒▒                    
                                      ▓▓▓▓▓▓▒▒▓▓▓▓█▓▓▓▓▓        ▒▒░░      ▒▒▓▓░░▒▒                                    ▓▓▓▓    ▒▒                  
                                ▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▓▓▓▓█▓▓▓▓░░    ░░▒▒▒▒        ▓▓▓▓                                    ▓▓▓█▓▓                        
                          ░░▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓█▓▓▓▓▓▒▒    ░░▒▒▒▒░░      ▒▒▓▓░░░░                              ▒▒▓▓▓▓▓▓░░  ░░▒▒                
                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▓▓▓▓▓█▓▓▓▓▓▓▓▓      ▒▒░░▒▒░░      ▓▓▓▓▒▒    ░░                      ▓▓▓▓▓▓▓▓▓▓▓▓  ░░  ░░░░            
                  ▓▓▓▓▓▓▓▓▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒▒▒      ▒▒▓▓▓▓      ▒▒                  ▓▓▓▓▓▓▒▒▓▓▓▓▓▓    ░░    ▓▓          
                  ▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▒▒      ░░▒▒▒▒      ░░▓▓▓▓░░      ░░            ░░▓▓▓█▓▓▓▓▓▓▓▓▓▓▓█    ▒▒                
                ▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓██▒▓▓▓▓▓▓▓▓▓▓▒▒      ▒▒▒▒        ▓▓▓▓▒▒      ░░░░        ▒▒▓▓▓█▓▓▓▓▒▒▓▓▓▓▓█▓▓    ░░      ▒▒        
            ▓▓████████▓▓▒▒▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒      ░░██▓▓          ░░▒▒▒▒▓▓▓▓▓█▓▓▓▓▒▒▓▓▓▓▓▓█▓▓▓      ▒▒░░    ░░      
          ████████████▓▓▓▓▓▓▓▓▓▓█▓████████████████████▓▓▓▓▓▓▓▓░░▒▒▓▓▒▒▒▒▒▒░░      ▓▓██▒▒░░░░    ░░▒▒▓▓▓████▓▓▓▓▓▓▓▒▒▓▓▓▓████▓▓░░  ▒▒▓▓▒▒░░  ░░▓▓    
        ▓▓████████▓▓▓▓▓▓▓▓▓▓██▓▓████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░  ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████▓▓▒▒▒▒▓▓██████████▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░  
  ▒▒████████████▓▓▓▓██▓▓███████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▓▓█████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████████████▓▓████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████████▓▓██████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▓▓▓▓██████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
████████▓▓████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████▓▓████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓▓█████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓██▓▓██████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓██████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓
██████████████████▓▓████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓██████████████████████████████████████████▓▓▓▓▓▓
██████████████████▓▓▓▓██████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓████████████████████████████████████████████████▓▓▓▓
██████████████████▓▓▓▓██████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓██▓▓██████████████████████████████████████████▓▓▓▓▓▓▓▓
██████████████████▓▓▓▓▓▓▓▓██████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓██████████████████████████████████████████████████▓▓▓▓▓▓
██████████████▓▓██▓▓▓▓▓▓▓▓▓▓██▓▓▓▓██████████████████▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓██████████████████████████████████████████████████████▓▓▓▓
██████████████▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████████████████████████████████████████████▓▓
██████████▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████████████████████████████████████████████████

Welcome to Alpine K2. 
Kernel \r on \m
EOF

################################################################################################################################################### 



