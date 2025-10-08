#!/bin/bash

# Lightweight Zsh + Plugins + Git Prompt Setup Script

set -e

# === Functions ===
info() {
  echo -e "\n\033[1;32m==> $1\033[0m"
}

check_sudo() {
  if ! command -v sudo &>/dev/null; then
    echo "❌ sudo not found."
    exit 1
  fi
  if ! sudo -v &>/dev/null; then
    echo "❌ Sudo access required."
    exit 1
  fi
}

# === Begin ===
info "Checking sudo access..."
check_sudo

info "Installing zsh, git, curl..."
sudo apt update
sudo apt install -y zsh git curl

info "Setting zsh as default shell..."
if [[ "$SHELL" != *zsh ]]; then
  echo "⚠️ Skipping automatic shell change due to permission issues."
  echo "Please run 'chsh -s $(which zsh)' manually if you want to change your default shell."
else
  echo "✅ Zsh is already the default shell."
fi

info "Configuring auto-start of zsh on login (via .bashrc)..."
grep -qxF 'exec zsh' ~/.bashrc || echo 'exec zsh' >> ~/.bashrc

# === Plugin Setup ===
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

info "Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already installed."
fi

info "Installing zsh-syntax-highlighting..."
if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting already installed."
fi

# === Generate .zshrc ===
ZSHRC="$HOME/.zshrc"
info "Writing ~/.zshrc..."

cat > "$ZSHRC" <<'EOF'
# === Git branch/status in prompt ===
autoload -Uz vcs_info
precmd() { vcs_info }
setopt prompt_subst

# Git status icons
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '✔'
zstyle ':vcs_info:git:*' unstagedstr '✚'
zstyle ':vcs_info:git:*' untrackedstr '💥'
zstyle ':vcs_info:git:*' formats '(%b %u%c)'

# Show current dir and git info
PROMPT='%~ ${vcs_info_msg_0_}> '

# === Shell options ===
setopt autocd
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt hist_verify

HISTFILE=~/.zsh_history
HISTSIZE=2000
SAVEHIST=4000

# === Autosuggestions ===
source $HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999999"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# === Syntax Highlighting ===
source $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# === Environment ===
export EDITOR="vim"
export PATH="$HOME/.local/bin:$PATH"
EOF

# === Done ===
info "✅ Zsh minimal setup complete."
echo -e "\n🎯 Run \033[1mzsh\033[0m or restart your terminal to start using Zsh."
