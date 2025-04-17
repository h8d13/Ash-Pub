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

