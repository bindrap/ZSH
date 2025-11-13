# Testing the ZSH Installation Script

This guide will help you safely test the installation script on your WSL terminal.

## Quick Test (Safest)

Run the pre-check script to see what will happen without making any changes:

```bash
cd /path/to/ZSH
chmod +x test-install.sh
./test-install.sh
```

This will show you:
- Current system status
- What's already installed
- What will be installed
- Any potential issues
- **NO CHANGES WILL BE MADE**

## Testing Methods

### Method 1: Pre-Check Only (Recommended First)

```bash
# Navigate to the ZSH directory
cd ~/ZSH  # or wherever you cloned it

# Run the test script
chmod +x test-install.sh
./test-install.sh
```

This gives you a complete report without modifying anything.

### Method 2: Syntax Check

Verify the script has no syntax errors:

```bash
# Check syntax without executing
bash -n install.sh

# If no output, syntax is valid!
```

### Method 3: Manual Step-by-Step Test

Test each component individually:

```bash
# 1. Check if you can install packages (won't actually install)
sudo apt-get update --dry-run

# 2. Check if ZSH is available
apt-cache policy zsh

# 3. Verify files exist
ls -la startup.sh quotes.txt ascii_art.txt .zshrc

# 4. Check current shell
echo $SHELL

# 5. Check if you have Oh My Zsh
ls -la ~/.oh-my-zsh

# 6. Check available disk space
df -h ~
```

### Method 4: Docker Test (Safest - Completely Isolated)

Test in a completely isolated Ubuntu container:

```bash
# Pull Ubuntu image
docker pull ubuntu:22.04

# Run container with your ZSH directory mounted
docker run -it -v "$(pwd)":/zsh ubuntu:22.04 bash

# Inside the container:
cd /zsh
apt-get update && apt-get install -y sudo
./install.sh

# Test it out, then exit and container is destroyed
exit
```

### Method 5: WSL Test Instance (Safe)

Create a test WSL instance (WSL2 only):

```bash
# Export your current WSL (from Windows PowerShell)
wsl --export Ubuntu ubuntu-backup.tar

# Import as test instance
wsl --import UbuntuTest C:\WSL\UbuntuTest ubuntu-backup.tar

# Enter test instance
wsl -d UbuntuTest

# Run installation in test instance
cd /mnt/c/path/to/ZSH
./install.sh

# If satisfied, delete test instance (from PowerShell)
wsl --unregister UbuntuTest
```

### Method 6: Dry Run Features

The install script is designed to be safe:

```bash
# The script will:
# 1. Ask for confirmation before starting
# 2. Check if things are already installed (won't reinstall)
# 3. Backup your existing .zshrc
# 4. Only install what's missing
# 5. Show clear progress messages

./install.sh
```

## What to Check After Installation

If you decide to run the actual installation, verify these:

### 1. Check ZSH Installed

```bash
zsh --version
# Should show: zsh 5.x.x or higher
```

### 2. Check Oh My Zsh

```bash
ls -la ~/.oh-my-zsh
# Should show Oh My Zsh directory structure
```

### 3. Check Custom Files

```bash
ls -la ~/.config/zsh/
# Should show: startup.sh, quotes.txt, ascii_art.txt

cat ~/.config/zsh/quotes.txt | wc -l
# Should show: 147 (number of quotes)

grep -c "===ART" ~/.config/zsh/ascii_art.txt
# Should show: 20 (number of ASCII art styles)
```

### 4. Check .zshrc Configuration

```bash
cat ~/.zshrc | grep -i powerlevel10k
# Should find the theme configuration

cat ~/.zshrc | grep -i plugins
# Should show: zsh-autosuggestions and zsh-syntax-highlighting
```

### 5. Test Startup Script

```bash
# Manually test the startup display
source ~/.config/zsh/startup.sh

# You should see:
# - Greeting with your name
# - System information
# - Random quote
# - ASCII art
```

### 6. Check Default Shell

```bash
echo $SHELL
# Should show: /usr/bin/zsh or /bin/zsh

# Or check user database
grep $USER /etc/passwd
# Should end with: /usr/bin/zsh
```

### 7. Test a New Terminal

```bash
# Open a new terminal window/tab
# You should see:
# 1. Custom startup display (quote + ASCII art)
# 2. Powerlevel10k prompt (if configured)
# 3. Working autosuggestions when you type
```

## Rollback (If Needed)

If something goes wrong, here's how to undo:

### 1. Restore Previous .zshrc

```bash
# Find your backup
ls -la ~/.zshrc.backup.*

# Restore it
cp ~/.zshrc.backup.YYYYMMDD_HHMMSS ~/.zshrc
```

### 2. Change Shell Back to Bash

```bash
chsh -s /bin/bash

# Log out and back in
```

### 3. Remove Oh My Zsh

```bash
uninstall_oh_my_zsh
```

### 4. Remove Custom Configs

```bash
rm -rf ~/.config/zsh
```

### 5. Remove ZSH (if you want to completely uninstall)

```bash
sudo apt-get remove zsh
```

## Common Issues and Solutions

### Issue: "Permission Denied"

```bash
# Solution: Make script executable
chmod +x install.sh
```

### Issue: "sudo password required"

The script needs sudo for:
- Installing packages (zsh, git, curl, wget)
- Installing fonts system-wide (optional)
- Changing default shell

This is normal and safe.

### Issue: "Oh My Zsh already installed"

The script detects this and skips installation. Safe to continue.

### Issue: Icons/symbols not showing

**After installation**, configure your terminal font:

**Windows Terminal (WSL):**
1. Open Windows Terminal settings (Ctrl+,)
2. Navigate to: Profiles → Ubuntu → Appearance
3. Set Font face to: `MesloLGS NF`
4. Save and restart terminal

**VS Code Terminal:**
1. Settings → Terminal → Integrated: Font Family
2. Set to: `'MesloLGS NF'`

### Issue: Startup display not showing

```bash
# Check if file exists
ls -la ~/.config/zsh/startup.sh

# Check if it's sourced in .zshrc
grep startup ~/.zshrc

# Manually source it to test
source ~/.config/zsh/startup.sh
```

### Issue: Plugins not working

```bash
# Check if plugins are installed
ls -la ~/.oh-my-zsh/custom/plugins/

# Should show:
# - zsh-autosuggestions/
# - zsh-syntax-highlighting/

# Check if enabled in .zshrc
grep plugins ~/.zshrc
```

## Testing Checklist

Before running the full installation, check:

- [ ] Run `test-install.sh` to see current status
- [ ] Check you have enough disk space (`df -h`)
- [ ] Verify all required files exist in directory
- [ ] Backup any important shell configurations
- [ ] Have sudo access
- [ ] Read through `install.sh` to understand what it does

After installation, verify:

- [ ] ZSH is installed (`zsh --version`)
- [ ] Oh My Zsh is installed (`ls ~/.oh-my-zsh`)
- [ ] Plugins are installed
- [ ] Custom files are in `~/.config/zsh/`
- [ ] Startup display works (`source ~/.config/zsh/startup.sh`)
- [ ] New terminal shows custom greeting
- [ ] Autosuggestions work when typing
- [ ] Syntax highlighting works
- [ ] Fonts display correctly

## Performance Test

Check startup time after installation:

```bash
# Time ZSH startup
time zsh -i -c exit

# Should be under 1 second for a fast startup
# If slow, you may need to optimize plugins
```

## Getting Help

If you encounter issues:

1. Check the TESTING.md troubleshooting section
2. Review the installation output for errors
3. Check logs: `~/.zshrc`, `~/.oh-my-zsh/`
4. Run `test-install.sh` to see current state
5. Restore from backup if needed

## Safe Testing Recommendation

**Most Conservative Approach:**

1. Run `test-install.sh` first
2. Review the output
3. Test in Docker if unsure
4. Only then run actual `install.sh`
5. Keep your terminal open during installation
6. Test in a new terminal window
7. Keep backup of .zshrc handy

---

**Remember: The installation script is designed to be safe and will backup your existing configuration before making changes!**
