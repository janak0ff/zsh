#!/bin/bash

# =============================================================================
# Enhanced Zsh + Plugins + Git Prompt Setup Script
# Supports Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux, and openSUSE systems
# =============================================================================

set -e  # Exit on any error

# === COLOR FUNCTIONS ===
info() {
    echo -e "\n\033[1;32m==> $1\033[0m"
}

warn() {
    echo -e "\n\033[1;33m==> $1\033[0m"
}

error() {
    echo -e "\n\033[1;31m==> ERROR: $1\033[0m" >&2
}

# === PACKAGE MANAGEMENT ===
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        error "Could not detect package manager"
        exit 1
    fi
}

install_packages() {
    local pkg_manager="$1"
    shift
    local packages=("$@")

    info "Installing packages: ${packages[*]}"

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
        pacman)
            sudo pacman -Sy --noconfirm "${packages[@]}"
            ;;
    esac
}

# === SYSTEM CHECKS ===
check_sudo() {
    if ! command -v sudo &>/dev/null; then
        error "sudo not found. Please install sudo or run as root."
        exit 1
    fi

    if ! sudo -v &>/dev/null; then
        error "Sudo access required. Please run with sudo privileges."
        exit 1
    fi
}

# === ZSH HISTORY DOWNLOAD ===
download_zsh_history() {
    info "Downloading .zsh_history to home directory..."

    local history_url="https://raw.githubusercontent.com/janak0ff/zsh/main/.zsh_history"
    local history_file="$HOME/.zsh_history"

    # Check if wget or curl is available
    if command -v wget &>/dev/null; then
        if wget -q -O "$history_file" "$history_url"; then
            info "✅ Successfully downloaded .zsh_history using wget"
        else
            warn "❌ Failed to download .zsh_history using wget"
            return 1
        fi
    elif command -v curl &>/dev/null; then
        if curl -s -o "$history_file" "$history_url"; then
            info "✅ Successfully downloaded .zsh_history using curl"
        else
            warn "❌ Failed to download .zsh_history using curl"
            return 1
        fi
    else
        warn "❌ Neither wget nor curl available. Skipping .zsh_history download."
        return 1
    fi

    # Set appropriate permissions
    if [ -f "$history_file" ]; then
        chmod 600 "$history_file"
        info "✅ Set secure permissions on .zsh_history"
        return 0
    else
        warn "❌ Downloaded .zsh_history file not found"
        return 1
    fi
}

# === SHELL SETUP ===
setup_zsh_shell() {
    local current_shell="$SHELL"
    local zsh_path="$(command -v zsh)"

    if [ -z "$zsh_path" ]; then
        error "zsh not found in PATH. Please install zsh first."
        exit 1
    fi

    if [[ "$current_shell" != *zsh ]]; then
        warn "To set zsh as your default shell, run: chsh -s $zsh_path"
        info "You can also start zsh temporarily by typing 'zsh'"
    else
        info "Zsh is already the default shell."
    fi
}

setup_auto_start() {
    local shell_rc=""

    # Determine which shell config file to use
    case "$SHELL" in
        *bash) shell_rc="$HOME/.bashrc" ;;
        *zsh) shell_rc="$HOME/.zshrc" ;;
        *) 
            warn "Unknown shell: $SHELL. Cannot setup auto-start."
            return
            ;;
    esac

    # Create shell rc if it doesn't exist
    if [ ! -f "$shell_rc" ]; then
        touch "$shell_rc"
        info "Created $shell_rc"
    fi

    # Add auto-start if not already present
    if ! grep -qxF '[ -x "$(command -v zsh)" ] && exec zsh' "$shell_rc"; then
        echo '# Auto-start zsh if available' >> "$shell_rc"
        echo '[ -x "$(command -v zsh)" ] && exec zsh' >> "$shell_rc"
        info "✅ Added auto-start of zsh to $shell_rc"
    else
        info "✅ Auto-start already configured in $shell_rc"
    fi
}

# === PLUGIN MANAGEMENT ===
install_plugin() {
    local plugin_dir="$1"
    local repo_url="$2"
    local plugin_name="$3"

    if [ ! -d "$plugin_dir/$plugin_name" ]; then
        info "Installing $plugin_name..."
        if git clone --depth 1 "$repo_url" "$plugin_dir/$plugin_name" 2>/dev/null; then
            info "✅ Successfully installed $plugin_name"
        else
            warn "❌ Failed to install $plugin_name"
            return 1
        fi
    else
        info "✅ $plugin_name already installed."
    fi
    return 0
}

# === ZSH CONFIGURATION ===
generate_zshrc() {
    local zshrc="$HOME/.zshrc"

    # Backup existing zshrc if it exists
    if [ -f "$zshrc" ]; then
        local backup="$zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$zshrc" "$backup"
        info "✅ Backed up existing .zshrc to $backup"
    fi

    info "Generating enhanced ~/.zshrc..."

    cat > "$zshrc" <<'EOF'
# =============================================================================
# ENHANCED ZSH CONFIGURATION
# Generated by automated setup script
# =============================================================================

# === GIT BRANCH/STATUS IN PROMPT ===
autoload -Uz vcs_info
precmd() { vcs_info }
setopt prompt_subst

# Git status configuration
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '✔'
zstyle ':vcs_info:git:*' unstagedstr '✚'
zstyle ':vcs_info:git:*' untrackedstr '?'  # Changed from emoji for better compatibility
zstyle ':vcs_info:git:*' formats ' (%b%u%c)'

# Prompt: current directory + git status
PROMPT='%~${vcs_info_msg_0_} > '

# === SHELL OPTIONS ===
setopt auto_cd                    # Change to directory by typing its name
setopt hist_expire_dups_first     # Remove duplicates first when history fills up
setopt hist_ignore_space          # Don't save commands starting with space
setopt hist_verify                # Show history expansion before executing
setopt append_history             # Append to history file
setopt share_history              # Share history between sessions

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000

# === AUTOSUGGESTIONS ===
if [ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999999"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
else
    echo "⚠️  zsh-autosuggestions not found. Run setup script to install."
fi

# === SYNTAX HIGHLIGHTING ===
if [ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
else
    echo "⚠️  zsh-syntax-highlighting not found. Run setup script to install."
fi

# === ENVIRONMENT VARIABLES ===
export EDITOR="${EDITOR:-vim}"           # Default editor
export VISUAL="${VISUAL:-$EDITOR}"       # Visual editor
export PATH="$HOME/.local/bin:$PATH"     # Add local bin to PATH

# === ALIASES ===
# File listing
alias ll='ls -lAh'               # Long list with almost all files, human readable
alias la='ls -A'                 # List all including hidden
alias l='ls -CF'                 # Column format with file type indicators

# Grep with colors
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety (interactive mode)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# === COMPLETION SYSTEM ===
# Initialize and configure completions
autoload -Uz compinit
compinit

# Completion settings
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true

# === NODE VERSION MANAGER (NVM) ===
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    \. "$NVM_DIR/bash_completion"
fi

# === LS COLORS ===
# Enable colors for ls if available
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi
EOF

    info "✅ Generated enhanced .zshrc configuration"
}

# === USER PROMPT ===
prompt_for_history() {
    while true; do
        read -r -p "Do you want to download zsh history? [Y/n] " response
        case "$response" in
            [yY]|[yY][eE][sS]|"")
                return 0
                ;;
            [nN]|[nN][oO])
                return 1
                ;;
            *)
                echo "❌ Invalid input. Please answer 'y' or 'n'."
                ;;
        esac
    done
}

# === MAIN SCRIPT ===
main() {
    info "🚀 Starting Enhanced Zsh Setup..."

    # Prompt for history download
    if prompt_for_history; then
        download_zsh_history
    else
        info "Skipping history download."
    fi

    # Detect package manager
    info "Detecting package manager..."
    PKG_MANAGER=$(detect_pkg_manager)
    info "Detected package manager: $PKG_MANAGER"

    # Check sudo access
    info "Checking sudo access..."
    check_sudo

    # Install required packages
    info "Installing zsh, git, curl, and wget..."
    case "$PKG_MANAGER" in
        apt) 
            install_packages "$PKG_MANAGER" zsh git curl wget
            ;;
        dnf|yum) 
            install_packages "$PKG_MANAGER" zsh git curl wget
            ;;
        zypper) 
            install_packages "$PKG_MANAGER" zsh git curl wget
            ;;
        pacman)
            install_packages "$PKG_MANAGER" zsh git curl wget
            ;;
    esac

    # Setup shell configuration
    setup_zsh_shell

    # Setup auto-start
    info "Configuring auto-start of zsh..."
    setup_auto_start

    # Plugin setup
    info "Setting up Zsh plugins..."
    ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
    mkdir -p "$ZSH_PLUGIN_DIR"

    install_plugin "$ZSH_PLUGIN_DIR" \
        "https://github.com/zsh-users/zsh-autosuggestions" \
        "zsh-autosuggestions"

    install_plugin "$ZSH_PLUGIN_DIR" \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "zsh-syntax-highlighting"

    # Generate enhanced .zshrc
    generate_zshrc

    # Completion message
    info "✅ Zsh setup completed successfully!"
    echo
    echo "🎯 NEXT STEPS:"
    echo "   - Run 'zsh' to start using Zsh immediately"
    echo "   - Run 'chsh -s $(command -v zsh)' to make Zsh your default shell"
    echo "   - Restart your terminal for all changes to take effect"
    echo "   - Your configuration includes:"
    echo "     ✓ Git-aware prompt"
    echo "     ✓ Syntax highlighting"
    echo "     ✓ Autosuggestions"
    echo "     ✓ Enhanced completions"
    echo "     ✓ Useful aliases"
    echo
    echo "🔧 To customize further, edit: ~/.zshrc"
}

# Handle script interruption
trap 'error "Script interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"