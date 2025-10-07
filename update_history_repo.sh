#!/bin/bash

# Path to your local git repo where .zsh_history is tracked
LOCAL_REPO_PATH="$HOME/Documents/zsh"  # Replace with your actual path

# Path to your local .zsh_history file
LOCAL_HISTORY="$HOME/.zsh_history"

echo "Updating .zsh_history in Git repo..."

cd "$LOCAL_REPO_PATH" || { echo "Local repo path not found."; exit 1; }

# Copy the current .zsh_history into the repo directory
cp "$LOCAL_HISTORY" "$LOCAL_REPO_PATH/.zsh_history"

# Stage, commit, and push changes if any
if git diff --quiet .zsh_history; then
    echo "No changes in .zsh_history to commit."
else
    git add .zsh_history
    git commit -m "Auto-update .zsh_history"
    git push origin main
    echo ".zsh_history updated and pushed to GitHub."
fi
