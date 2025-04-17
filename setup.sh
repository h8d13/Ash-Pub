#!/bin/sh
# Community & main ######################### vX.xX/Branch
echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories
echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" >> /etc/apk/repositories
apk update

## Extended ascii support for later :)
apk add --no-cache tzdata font-noto-emoji fontconfig musl-locales

# Create /etc/profile.d/profile.sh to source user profile if it exists
cat > /etc/profile.d/profile.sh << 'EOF'
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
EOF

# Make it executable
chmod +x /etc/profile.d/profile.sh
echo "Created and made /etc/profile.d/profile.sh executable."

# Create ~/.config/ash directory if it doesn't exist
mkdir -p "$HOME/.config/ash"

# Create ~/.config/ash/profile
echo 'export ENV="$HOME/.config/ash/ashrc"' > "$HOME/.config/ash/profile"
echo "Created $HOME/.config/ash/profile."

cat > "$HOME/.config/ash/ashrc" << 'EOF'
# Custom prompt with time display in blue color scheme
export PS1='\033[0;34m┌──[\033[0;36m\t\033[0;34m]─[\033[0;39m\u\033[0;34m@\033[0;36m\h\033[0;34m]─[\033[0;32m\w\033[0;34m]\n\033[0;34m└──╼ \033[0;36m$ \033[0m'
EOF


cat > /etc/motd << 'EOF'
See <https://wiki.alpinelinux.org> for more info.
For keyboard layouts: setup-keymap
Set up the system with: setup-alpine

Apk sources /etc/apk/repositories
Change this message by editing /etc/motd
Change the pre-login message /etc/issue
Made with <3 by H8D13. 
EOF

cat > /etc/issue << 'EOF'
                                                                                                                                                  
                                                      ▒▒▒▒░░░░                                                                                    
                                                      ▓▓  ░░  ░░                                                                                  
                                                  ▒▒▓▓▓▓    ░░  ▒▒                                                                                
                                              ░░▓▓▓▓▓▓░░    ░░    ▒▒                                                                              
                                          ▓▓▓▓▓▓▓▓▓▓          ░░    ░░▓▓▒▒▓▓▓▓                                                                    
                                        ▒▒▓▓▓▓▓▓▓▓▒▒          ▒▒      ▓▓▓▓▓▓▒▒▒▒                                                                  
                                        ▓▓▓▓▓▓▒▒▓▓▓▓          ░░▒▒    ░░▓▓▓▓▓▓░░                                                                  
                                      ░░▓▓▓▓▒▒▓▓▓▓▓▓▒▒          ▒▒░░    ░░▓▓▓▓                                          ▒▒▓▓▒▒                    
                                      ▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓        ▒▒░░      ▒▒▓▓░░▒▒                                    ▓▓▓▓    ▒▒                  
                                ▒▒▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓░░    ░░▒▒▒▒        ▓▓▓▓                                    ▓▓▓▓▓▓                        
                          ░░▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒    ░░▒▒▒▒░░      ▒▒▓▓░░░░                              ▒▒▓▓▓▓▓▓░░  ░░▒▒                
                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ▒▒░░▒▒░░      ▓▓▓▓▒▒    ░░                      ▓▓▓▓▓▓▓▓▓▓▓▓  ░░  ░░░░            
                  ▓▓▓▓▓▓▓▓▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ░░▒▒▒▒▒▒      ▒▒▓▓▓▓      ▒▒                  ▓▓▓▓▓▓▒▒▓▓▓▓▓▓    ░░    ▓▓          
                  ▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒      ░░▒▒▒▒      ░░▓▓▓▓░░      ░░            ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▒▒                
                ▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒      ▒▒▒▒        ▓▓▓▓▒▒      ░░░░        ▒▒▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓    ░░      ▒▒        
            ▓▓████████▓▓▒▒▓▓▓▓▓▓▓▓▓▓██████████████████▓▓▓▓▓▓▓▓      ░░▒▒▒▒      ░░██▓▓          ░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓      ▒▒░░    ░░      
          ████████████▓▓▓▓▓▓▓▓▓▓██████████████████████▓▓▓▓▓▓▓▓░░▒▒▓▓▒▒▒▒▒▒░░      ▓▓██▒▒░░░░    ░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓████▓▓░░  ▒▒▓▓▒▒░░  ░░▓▓    
        ▓▓████████▓▓▓▓▓▓▓▓▓▓██▓▓████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░  ██▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▒▒▒▒▓▓██████████▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░  
  ▒▒████████████▓▓▓▓██▓▓████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▓▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████████████▓▓████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████████▓▓██████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▓▓▓▓██████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
████████▓▓████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓██████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
██████▓▓████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓██████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
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
