#!/bin/bash

LOCAL_REPO_PATH="$HOME/Documents/zsh"
LOCAL_HISTORY="$HOME/.zsh_history"

cd "$LOCAL_REPO_PATH" || { echo "Local repo path not found."; exit 1; }

cp "$LOCAL_HISTORY" "$LOCAL_REPO_PATH/.zsh_history"

if git diff --quiet .zsh_history; then
    echo "$(date): No changes in .zsh_history to commit." >> "$HOME/update_history.log"
else
    git add .zsh_history
    git commit -m "Auto-update .zsh_history"
    git push origin main
    echo "$(date): .zsh_history updated and pushed to GitHub." >> "$HOME/update_history.log"
fi
