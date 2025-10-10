[Automate Your Zsh Setup- Scripted Installation of Oh My Zsh, Auto-Suggestions & Syntax Highlighting](https://blogs.janakkumarshrestha0.com.np/posts/linux/zsh-setup-with-auto-suggestions--themes/)

---

Here's a complete `setup_zsh.sh` bash script that you can `curl` to any (deb and rpm) based Linux server to perform the full install process:

Run this single curl command in bash shell:

```sh
curl -sL setzsh.vercel.app | bash
```
- OR 

```sh
curl -fsSL https://raw.githubusercontent.com/janak0ff/zsh/main/setup_zsh.sh | bash
```

---
<!-- 
1. Download my `setup_zsh.sh and .zsh_history` files in home dir:
    ```sh
    wget https://raw.githubusercontent.com/janak0ff/zsh/main/setup_zsh.sh https://raw.githubusercontent.com/janak0ff/zsh/main/.zsh_history
    ```

2. Make the script executable and run it:
    ```sh
    chmod +x setup_zsh.sh
    ./setup_zsh.sh
    ```

3. **Start Zsh Shell**  
   ```sh
   zsh
   ```
   This opens a Zsh session, where `.zshrc` syntax (including `autoload`) will work correctly.

2. **Source the Config Properly**  
   Inside Zsh, reload your config with:
   ```sh
   source ~/.zshrc
   ```
   This avoids Bash-only errors and applies Zsh-specific changes right away. -->

---

To keep your `.zsh_history` file synchronized between your local Linux machine and your cloud Linux server, you can use these approaches:

### 1. Use `rsync` for manual sync
Run from your local machine to sync history file to server:
```sh
rsync -avz ~/.zsh_history ubuntu@202.51.74.32:/home/ubuntu/
```
And from the server to sync to local:
```sh
rsync -avz ubuntu@202.51.74.32:/home/ubuntu/.zsh_history ~/
```
This copies your history file both ways when needed.

---

### 2. Automate using `cron job`

To create a cron job that automatically updates your `.zsh_history` in your local Git repo and pushes to GitHub, follow these steps:

### a. Create a script file (if not created yet)

Save the script `update_history_repo.sh` 

```bash
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
```

Make it executable:

```sh
chmod +x ~/update_history_repo.sh
```

***

### b. Add a cron job

Edit your cron jobs by running:

```sh
crontab -e
```

Add this line to run the script daily at 12:00 PM: (adjust timing as desired):

```cron
0 12 * * * /bin/bash $HOME/update_history_repo.sh
```

***

### c. Save and exit the editor

Cron will auto-load the job.  
The script logs output to `update_history.log` inside your home directory for your reference.

***

### Notes:

- Make sure your Git environment (keys, credentials) work non-interactively for pushing.
- Adjust the cron frequency (`0 12 * * *`) as needed to run more or less often.

This will automate pushing your updated `.zsh_history` from your local repo to GitHub regularly.

---

### 3. Use a cloud sync tool
Services like Dropbox, Syncthing, or Nextcloud can sync specific files across machines continuously if installed.

### 4. Append rather than overwrite
To avoid losing any history entries, you can manually merge the files, or use commands like:
```sh
cat ~/.zsh_history >> /path/to/server/.zsh_history
```
and vice versa, then reload history in your shell:
```sh
fc -R ~/.zsh_history
```

---
Here's the improved bash script `sync.sh` with variables for better flexibility:

```bash
#!/bin/bash

# Sync and Merge ZSH History
# This script downloads server history, merges with local history, and reloads

set -e  # Exit on any error

# Configuration variables
SERVER_USER="ubuntu"
SERVER_IP="202.51.74.32"
SERVER_HISTORY_PATH="/home/ubuntu/.zsh_history"
LOCAL_SERVER_HISTORY="$HOME/server_zsh_history"
LOCAL_HISTORY="$HOME/.zsh_history"
MERGED_HISTORY="$HOME/.zsh_history_merged"
BACKUP_REPO_PATH="$HOME/Documents/zsh/.zsh_history"

echo "Starting ZSH history sync..."

# Download the server history file to your local machine
echo "Downloading server history from ${SERVER_USER}@${SERVER_IP}..."
rsync -avz "${SERVER_USER}@${SERVER_IP}:${SERVER_HISTORY_PATH}" "$LOCAL_SERVER_HISTORY"

# Merge multiline commands and remove duplicates while preserving order
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

# Replace local history with merged version
echo "Updating local history..."
mv "$MERGED_HISTORY" "$LOCAL_HISTORY"

# Copy history to local repo
echo "Backing up to local repo..."
cp "$LOCAL_HISTORY" "$BACKUP_REPO_PATH"

# Reload history in current Zsh session
echo "Reloading history in current session..."
fc -R "$LOCAL_HISTORY"

echo "ZSH history sync completed successfully!"
```

## Even more flexible version with command-line options:

```bash
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
```

## Usage examples:

**Basic usage:**
```bash
./sync.sh
```

**With custom server:**
```bash
./sync.sh -u myuser -i 192.168.1.100 -p /home/myuser/.zsh_history
```

**With backup:**
```bash
./sync.sh -b
```

**Using environment variables:**
```bash
export SERVER_USER="deploy"
export SERVER_IP="10.0.1.50"
./sync.sh
```

**Custom backup location:**
```bash
./sync.sh -l "/path/to/my/backup/.zsh_history"
```

## Make it executable:
```bash
chmod +x sync.sh
```

This version is much more flexible and can be easily configured for different servers and environments without modifying the script itself!

