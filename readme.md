[Automate Your Zsh Setup- Scripted Installation of Oh My Zsh, Auto-Suggestions & Syntax Highlighting](https://blogs.janakkumarshrestha0.com.np/posts/linux/zsh-setup-with-auto-suggestions--themes/)

---

Here's a complete `setup_zsh.sh` bash script that you can `curl` to any (deb and rpm) based Linux server to perform the full install process:

Run this single curl command in bash shell:

```sh
curl -sL setzsh.vercel.app | bash
```
- or

```sh
curl -fsSL https://raw.githubusercontent.com/janak0ff/zsh/main/setup_zsh.sh | bash
```

---

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
   This avoids Bash-only errors and applies Zsh-specific changes right away.

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

