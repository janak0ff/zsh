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

[Automate Your Zsh Setup- Scripted Installation of Oh My Zsh, Auto-Suggestions & Syntax Highlighting](https://blogs.janakkumarshrestha0.com.np/posts/linux/zsh-setup-with-auto-suggestions--themes/)

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

### 2. Automate using `cron` or shell alias
Set up a cron job to periodically run the `rsync` command in either direction to keep the files updated regularly.

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

