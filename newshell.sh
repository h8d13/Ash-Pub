#!/bin/sh
set -e

USER_HOME="/home/$USER_NAME"
ZSHRC="$USER_HOME/.zshrc"

echo "Installing for user: $USER_NAME"

# === INSTALL DEPENDENCIES ===
apk update
apk add zsh git curl wget unzip fontconfig

# === INSTALL OH MY ZSH ===
sudo -u "$USER_NAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# === INSTALL POWERLEVEL10K ===
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"

# Update .zshrc to use Powerlevel10k
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

# === INSTALL OPTIONAL PLUGINS ===
git clone https://github.com/zsh-users/zsh-autosuggestions "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# Enable them in .zshrc
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"

# === INSTALL NERD FONTS ===
FONT_DIR="/usr/share/fonts/nerd-fonts"
mkdir -p "$FONT_DIR"
TMP_ZIP="/tmp/JetBrainsMono.zip"
wget -O "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o "$TMP_ZIP" -d "$FONT_DIR"
fc-cache -fv
rm "$TMP_ZIP"

# === SET PERMISSIONS ===
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.oh-my-zsh"
chown "$USER_NAME:$USER_NAME" "$ZSHRC"

echo "Setup complete!"
