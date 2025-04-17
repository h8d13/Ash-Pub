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
