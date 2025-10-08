#!/bin/bash

set -e

echo "Downloading setup_zsh.sh and .zsh_history to home directory..."
wget -O ~/setup_zsh.sh https://raw.githubusercontent.com/janak0ff/zsh/main/setup_zsh.sh
wget -O ~/.zsh_history https://raw.githubusercontent.com/janak0ff/zsh/main/.zsh_history

echo "Making setup_zsh.sh executable and running it..."
chmod +x ~/setup_zsh.sh
~/setup_zsh.sh

echo "Starting Zsh shell..."
zsh -c 'source ~/.zshrc && echo "Zsh config sourced successfully."'
