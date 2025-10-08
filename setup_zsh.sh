#!/bin/bash

# Lightweight Zsh + Plugins + Git Prompt Setup Script
# Supports both Debian/Ubuntu and RHEL/CentOS/Fedora systems

set -e

# === Functions ===
info() {
    echo -e "\n\033[1;32m==> $1\033[0m"
}

warn() {
    echo -e "\n\033[1;33m==> $1\033[0m"
}

error() {
    echo -e "\n\033[1;31m==> ERROR: $1\033[0m" >&2
}

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        error "Could not detect package manager"
        exit 1
    fi
}

install_packages() {
    local pkg_manager="$1"
    shift
    local packages=("$@")
    
    case "$pkg_manager" in
        apt)
            sudo apt update && sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        zypper)
            sudo zypper refresh && sudo zypper install -y "${packages[@]}"
            ;;
    esac
}

check_sudo() {
    if ! command -v sudo &>/dev/null; then
        error "sudo not found. Please install sudo or run as root."
        exit 1
    fi
    
    if ! sudo -v &>/dev/null; then
        error "Sudo access required."
        exit 1
    fi
}

download_zsh_history() {
    info "Downloading .zsh_history to home directory..."
    
    # Check if wget or curl is available
    if command -v wget &>/dev/null; then
        if wget -q -O ~/.zsh_history "https://raw.githubusercontent.com/janak0ff/zsh/main/.zsh_history"; then
            info "✅ Successfully downloaded .zsh_history using wget"
        else
            warn "❌ Failed to download .zsh_history using wget"
        fi
    elif command -v curl &>/dev/null; then
        if curl -s -o ~/.zsh_history "https://raw.githubusercontent.com/janak0ff/zsh/main/.zsh_history"; then
            info "✅ Successfully downloaded .zsh_history using curl"
        else
            warn "❌ Failed to download .zsh_history using curl"
        fi
    else
        warn "❌ Neither wget nor curl available. Skipping .zsh_history download."
        # Install curl for future use
        return 1
    fi
    
    # Set appropriate permissions
    if [ -f ~/.zsh_history ]; then
        chmod 600 ~/.zsh_history
        info "✅ Set secure permissions on .zsh_history"
    fi
}

setup_zsh_shell() {
    local current_shell="$SHELL"
    local zsh_path="$(command -v zsh)"
    
    if [[ "$current_shell" != *zsh ]]; then
        if [ -n "$zsh_path" ]; then
            warn "To set zsh as your default shell, run: chsh -s $zsh_path"
        else
            error "zsh not found in PATH"
            exit 1
        fi
    else
        info "Zsh is already the default shell."
    fi
}

setup_auto_start() {
    local shell_rc=""
    
    case "$SHELL" in
        *bash) shell_rc="$HOME/.bashrc" ;;
        *zsh) shell_rc="$HOME/.zshrc" ;;
        *) return ;;
    esac
    
    if [ -n "$shell_rc" ] && [ -f "$shell_rc" ]; then
        if ! grep -qxF '[ -x "$(command -v zsh)" ] && exec zsh' "$shell_rc"; then
            echo '[ -x "$(command -v zsh)" ] && exec zsh' >> "$shell_rc"
            info "Added auto-start of zsh to $shell_rc"
        fi
    fi
}

install_plugin() {
    local plugin_dir="$1"
    local repo_url="$2"
    local plugin_name="$3"
    
    if [ ! -d "$plugin_dir/$plugin_name" ]; then
        git clone --depth 1 "$repo_url" "$plugin_dir/$plugin_name"
    else
        info "$plugin_name already installed."
    fi
}

generate_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    info "Generating ~/.zshrc..."
    
    cat > "$zshrc" <<'EOF'
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
zstyle ':vcs_info:git:*' formats '(%b%u%c)'

# Show current dir and git info
PROMPT='%~ ${vcs_info_msg_0_}> '

# === Shell options ===
setopt autocd
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt hist_verify
setopt appendhistory
setopt sharehistory

HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

# === Autosuggestions ===
if [ -f $HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source $HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999999"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# === Syntax Highlighting ===
if [ -f $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
fi

# === Environment ===
export EDITOR="${EDITOR:-vim}"
export PATH="$HOME/.local/bin:$PATH"

# === Aliases ===
alias ll='ls -lAh'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
EOF
}

# === Main Script ===
main() {
    info "Starting Zsh setup..."
    
    # Download zsh history first (before installing zsh)
    download_zsh_history
    
    # Detect package manager
    info "Detecting package manager..."
    PKG_MANAGER=$(detect_pkg_manager)
    info "Detected package manager: $PKG_MANAGER"
    
    # Check sudo access
    info "Checking sudo access..."
    check_sudo
    
    # Install packages
    info "Installing zsh, git, curl..."
    case "$PKG_MANAGER" in
        apt) install_packages "$PKG_MANAGER" zsh git curl ;;
        dnf|yum) install_packages "$PKG_MANAGER" zsh git curl ;;
        zypper) install_packages "$PKG_MANAGER" zsh git curl ;;
    esac
    
    # Setup shell
    setup_zsh_shell
    
    # Setup auto-start
    info "Configuring auto-start of zsh..."
    setup_auto_start
    
    # Plugin setup
    info "Setting up plugins..."
    ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
    mkdir -p "$ZSH_PLUGIN_DIR"
    
    install_plugin "$ZSH_PLUGIN_DIR" \
        "https://github.com/zsh-users/zsh-autosuggestions" \
        "zsh-autosuggestions"
    
    install_plugin "$ZSH_PLUGIN_DIR" \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "zsh-syntax-highlighting"
    
    # Generate .zshrc
    generate_zshrc
    
    # Completion message
    info "✅ Zsh minimal setup complete!"
    echo
    echo "🎯 Next steps:"
    echo "   - Run 'zsh' to start using Zsh"
    echo "   - Run 'chsh -s $(command -v zsh)' to make it your default shell"
    echo "   - Restart your terminal for all changes to take effect"
    echo "   - Your command history has been pre-loaded from the downloaded .zsh_history"
}

# Run main function
main "$@"