#!/bin/sh

# Exit on any error
set -e

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

USER_NAME="$(logname)"
USER_HOME="/home/$USER_NAME"

# Install necessary packages
apk update
apk add zsh git curl wget unzip fontconfig

# Install Oh My Zsh
sudo -u "$USER_NAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"

# Set ZSH_THEME in .zshrc
ZSHRC="$USER_HOME/.zshrc"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# Enable plugins in .zshrc
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"

# Set up font (JetBrainsMono Nerd Font)
FONT_DIR="/usr/share/fonts/nerd-fonts"
mkdir -p "$FONT_DIR"
TMP_ZIP="/tmp/JetBrainsMono.zip"
wget -O "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o "$TMP_ZIP" -d "$FONT_DIR"
fc-cache -fv
rm "$TMP_ZIP"

# Set ownership
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh"
chown "$USER_NAME:$USER_NAME" "$ZSHRC"

echo "Zsh with Oh My Zsh + Powerlevel10k + Nerd Font installed!"
echo "Run 'zsh' to enjoy!"
