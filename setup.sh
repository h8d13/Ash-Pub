#!/bin/sh

# Create /etc/profile.d/profile.sh
echo 'if [ -f "$HOME/.config/ash/profile" ]; then' > /etc/profile.d/profile.sh
echo '    . "$HOME/.config/ash/profile"' >> /etc/profile.d/profile.sh

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

