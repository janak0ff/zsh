#!/bin/bash

# Sync and Merge ZSH History with configurable variables
set -e

# Default configuration
SERVER_USER="${SERVER_USER:-ubuntu}"
SERVER_IP="${SERVER_IP:-202.51.74.32}"
SERVER_HISTORY_PATH="${SERVER_HISTORY_PATH:-/home/ubuntu/.zsh_history}"
LOCAL_SERVER_HISTORY="${LOCAL_SERVER_HISTORY:-$HOME/server_zsh_history}"
LOCAL_HISTORY="${LOCAL_HISTORY:-$HOME/.zsh_history}"
MERGED_HISTORY="${MERGED_HISTORY:-$HOME/.zsh_history_merged}"
BACKUP_REPO_PATH="${BACKUP_REPO_PATH:-$HOME/Documents/zsh/.zsh_history}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.zsh_history_backups}"

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -u USER    Server username (default: $SERVER_USER)"
    echo "  -i IP      Server IP address (default: $SERVER_IP)"
    echo "  -p PATH    Server history path (default: $SERVER_HISTORY_PATH)"
    echo "  -l PATH    Local backup path (default: $BACKUP_REPO_PATH)"
    echo "  -b         Create backup before merging"
    echo "  -h         Show this help message"
    echo ""
    echo "You can also set these via environment variables:"
    echo "  SERVER_USER, SERVER_IP, SERVER_HISTORY_PATH, etc."
}

# Parse command-line options
while getopts "u:i:p:l:bh" opt; do
    case $opt in
        u) SERVER_USER="$OPTARG" ;;
        i) SERVER_IP="$OPTARG" ;;
        p) SERVER_HISTORY_PATH="$OPTARG" ;;
        l) BACKUP_REPO_PATH="$OPTARG" ;;
        b) CREATE_BACKUP=true ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

echo "Starting ZSH history sync..."
echo "Server: ${SERVER_USER}@${SERVER_IP}:${SERVER_HISTORY_PATH}"

# Create backup if requested
if [ "$CREATE_BACKUP" = true ]; then
    mkdir -p "$BACKUP_DIR"
    backup_file="$BACKUP_DIR/zsh_history_$(date +%Y%m%d_%H%M%S).bak"
    cp "$LOCAL_HISTORY" "$backup_file"
    echo "Backup created: $backup_file"
fi

# Download the server history file
echo "Downloading server history..."
rsync -avz "${SERVER_USER}@${SERVER_IP}:${SERVER_HISTORY_PATH}" "$LOCAL_SERVER_HISTORY"

# Merge multiline commands and remove duplicates
echo "Merging history files..."
{
    cat "$LOCAL_HISTORY" "$LOCAL_SERVER_HISTORY"
} | \
awk '
    /\\$/ {
        sub(/\\$/, "")
        printf "%s", $0
        next
    }
    { print }
' | \
awk '!seen[$0]++' > "$MERGED_HISTORY"

# Update files
mv "$MERGED_HISTORY" "$LOCAL_HISTORY"
cp "$LOCAL_HISTORY" "$BACKUP_REPO_PATH"

# Reload history
fc -R "$LOCAL_HISTORY"

echo "ZSH history sync completed successfully!"