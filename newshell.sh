#!/bin/sh
set -e

# === Install required packages ===
apk update
apk add zsh git curl wget unzip

# === Install Zsh plugins: Autosuggestions & Syntax Highlighting ===
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting

# === Update .zshrc to enable plugins ===
echo 'source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
echo 'source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc
echo 'export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=10"' >> ~/.zshrc

# === Set Zsh as default shell ===
chsh -s /bin/zsh

echo "Zsh setup complete with syntax highlighting and autosuggestions."
echo "Restart your terminal or run 'zsh' to start using it."
