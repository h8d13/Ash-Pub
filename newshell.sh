#!/bin/sh
set -e

# === User and paths ===
TARGET_USER="$USER"
USER_HOME="/home/$TARGET_USER"
ZSHRC="$USER_HOME/.zshrc"

if [ ! -d "$USER_HOME" ]; then
  echo "Home directory for user '$TARGET_USER' not found at $USER_HOME"
  echo "If you're running this as root for another user, set TARGET_USER manually."
  exit 1
fi

# === Install required packages ===
apk update
apk add zsh git curl wget unzip fontconfig

# === Install Oh My Zsh ===
su - "$TARGET_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'

# === Install Powerlevel10k ===
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

# === Install plugins ===
git clone https://github.com/zsh-users/zsh-autosuggestions "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"

# === Install JetBrainsMono Nerd Font ===
FONT_DIR="/usr/share/fonts/nerd-fonts"
mkdir -p "$FONT_DIR"
TMP_ZIP="/tmp/JetBrainsMono.zip"
wget -O "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o "$TMP_ZIP" -d "$FONT_DIR"
fc-cache -fv
rm "$TMP_ZIP"

# === Permissions ===
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.oh-my-zsh"
chown "$TARGET_USER:$TARGET_USER" "$ZSHRC"

echo "Zsh with Oh My Zsh, Powerlevel10k, and plugins installed for user: $TARGET_USER"
