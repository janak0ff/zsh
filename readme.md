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