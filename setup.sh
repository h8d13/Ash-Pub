#!/bin/sh
username=$(whoami)
echo "Hi $username"

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

# Custom Ash blue & ALiases
cat > "$HOME/.config/ash/ashrc" << 'EOF'
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
# Aliases base:
alias cls="clr"
alias sudo="doas"
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
EOF


# === Install Required Packages ===
apk update
apk add zsh git curl wget unzip

# === Install Zsh Plugins ===
mkdir -p "$HOME/.zsh/plugins"

# Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/plugins/zsh-autosuggestions"

# Syntax Highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/plugins/zsh-syntax-highlighting"

# History Substring Search
git clone https://github.com/zsh-users/zsh-history-substring-search "$HOME/.zsh/plugins/zsh-history-substring-search"

# zsh-completions (extra completions)
git clone https://github.com/zsh-users/zsh-completions "$HOME/.zsh/plugins/zsh-completions"

# === Create ~/.config/zsh directory if it doesn't exist ===
mkdir -p "$HOME/.config/zsh"

# === Create ~/.config/zsh/zshrc ===
cat > "$HOME/.config/zsh/zshrc" << 'EOF'
# === Load Extra Completions ===
fpath+=("$HOME/.zsh/plugins/zsh-completions/src")

# === Source Zsh Plugins ===
source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"

# === History Substring Search with Arrow Keys ===
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# === Custom Zsh Prompt Red ===
export PROMPT='%F{red}┌──[%F{cyan}%D{%H:%M}%F{red}]─[%F{default}%n%F{red}@%F{cyan}%m%F{red}]─[%F{green}%~%F{red}]
%F{red}└──╼ %F{cyan}$ %f'

EOF

# === Ensure ~/.zshrc Sources the New Config ===
echo 'source "$HOME/.config/zsh/zshrc"' >> "$HOME/.zshrc"
echo "Configured zsh to source $HOME/.config/zsh/zshrc."

# === Add zsh to /etc/shells if missing ===
grep -qxF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells

# === Optional: Switch default login shell to zsh globally ===
#sed -i 's|/bin/sh|/bin/zsh|g' /etc/passwd

# === Optional: Switch shell for current user only ===
#sed -i -E "s|^($username:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:).*|\1/bin/zsh|" /etc/passwd

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

## using agetty escapes
cat > /etc/issue << 'EOF'

                                                                                                                                                  
                                                      ▒▒▒▒░░░░                                                                                    
                                                      ▓▓  ░░  ░░                                                                                  
                                                  ▒▒▓▓▓▓    ░░  ▒▒                           ########                                                     
                                              ░░▓▓▓▓▓▓░░    ░░    ▒▒                         # 8611 #                                                 
                                          ▓▓▓▓█▓▓▓▓▓          ░░    ░░▓▓▒▒█▓▓▓               ########                                                     
                                        ▒▒▓▓▓█▓▓█▓▒▒          ▒▒      ▓▓▓█▓▓▒▒▒▒             # V1.3 #                                                    
                                        ▓▓▓█▓▓▒▒▓█▓▓          ░░▒▒    ░░▓▓▓▓▓▓░░             ########                                                     
                                      ░░▓█▓▓▒▒▒▓▓▓▓█▒▒          ▒▒░░    ░░▓▓█▓                                          ▒▒▓█▒▒                    
                                      ▓█▓▓▓▓▒▒▓▓▓▓█▓▓▓▓▓        ▒▒░░      ▒▒▓▓░░▒▒                                    ▓▓▓▓    ▒▒                  
                                ▒▒▓▓▓▓▓▓█▓▒▒▒▒▒▓▓▓▓█▓▓▓▓░░    ░░▒▒▒▒        ▓█▓▓                                    ▓▓▓█▓▓                        
                          ░░▒▒▓▓▓▓█▓▓█▓▓▒▒▒▒▒░▓▓▓▓█▓▓▓▓▓▒▒    ░░▒▒▒▒░░      ▒▒█▓░░░░                              ▒▒▓▓▓▓▓▓░░  ░░▒▒                
                      ▓▓▓▓█▓▓▓▓▓▓▓▓█▒▒▒▒▒▒░▓▓▓▓▓██▓▓▓▓▓▓▓      ▒▒░░▒▒░░      ▓▓█▓▒▒    ░░                      ▓▓▓▓▓▓▓▓▓▓▓▓  ░░  ░░░░            
                  ▓▓▓▓▓█▓▓▒▒▓█▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓██▓█▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒▒▒      ▒▒█▓▓▓      ▒▒                  ▓▓▓▓▓▓▒▒▓▓▓▓▓▓    ░░    ▓▓          
                  ▓▓▓▓█▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓█▓▓█▓▓▓▓▓▓▓▓▓▓▒▒      ░░▒▒▒▒      ░░▓▓█▓░░      ░░            ░░▓▓▓█▓▓▓▓▓▓▓▓▓▓▓█    ▒▒                
                ▓▓█▓█▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▓██▓▓█░▒▓▓▓▓▓▓▓▓▓▓▒▒      ▒▒▒▒        ▓▓█▓▒▒      ░░░░        ▒▒▓▓▓█▓▓▓▓▒▒▓▓▓▓▓█▓▓    ░░      ▒▒        
            ▓▓████████▓▓▒▒▓▓▓▓▓▓▓▓▓▓█░███▓████▓░████▓▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒      ░░██▓▓          ░░▒▒▒▒▓▓▓▓▓█▓▓▓▓▒▒▓▓▓▓▓▓█▓▓▓      ▒▒░░    ░░      
          ████████████▓▓▓▓▓▓▓▓▓▓█▓░███▓▓████░▓████████▓▓▓▓▓▓▓▓░░▒▒▓▓▒▒▒▒▒▒░░      ▓▓██▒▒░░░░    ░░▒▒▓▓▓████▓▓▓▓▓▓▓▒▒▓▓▓▓████▓▓░░  ▒▒▓▓▒▒░░  ░░▓▓    
        ▓▓████████▓▓▓▓▓▓▓▓▓▓██▓▓░░██████████████████▓▓▓█▓▒▒▒▓▓▓▓▓▓░▓▓▓▓░▓▓▓▒▒░░░░  ██▓▓▓▓▓▓▓▓▓░▓▓▓▓███▓█████▓▓▒▒▒▒▓▓██████████▓▓░░▓▓░▓▓▓▓░▓░▓▓▓▓░░  
  ▒▒████████████▓▓▓▓██▓▓██████████████▓████████████▓▒▒▓▓███▓▓▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓░░▓▓░▓▓▓▓░▓▓▓▓░▓▓▓▓▓████▓▓███▓▓▓▓█████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▓
███▓██████████▓▓██████████████████████████████████▓█▓▓▓▓██▓▓▓▓▓▓▓▓▓░░▓▓▓▓░▓▓▓▓░▓▓▓▓▓▓▓▓▓▓░▓▓▓▓▓▓████▓███▓▓▓▓▓▓██████████████████░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
█▓████████▓▓██████████████████████████████████████████▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░░▓▓▓▓▓▓▓▓░▓▓▓███▓████▓▓▓▓▓▓█████████████▓████████░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓███████▓▓███████████████████████████████████████▓████▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓░░▓▓▓░▓▓▓▓█▓██████▓▓▓▓▓▓▓▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
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


^[[1;34mWelcome to Alpine K2 Linux^[[0m
Kernel \r on \m
EOF

################################################################################################################################################### 



