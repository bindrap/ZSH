# Custom ZSH Terminal Setup

A beautiful and inspirational ZSH terminal configuration with philosophy quotes, rotating ASCII art, and a modern theme.

## Features

- **147 Philosophy Quotes** from diverse thinkers:
  - Stoic philosophers: Marcus Aurelius, Seneca, Epictetus
  - Greek philosophers: Socrates, Plato, Aristotle
  - Existentialists: Nietzsche, Kierkegaard, Sartre, Camus
  - Eastern wisdom: Buddha, Confucius, Rumi
  - Modern thinkers: Carl Jung, Joseph Campbell, Oscar Wilde, and more

- **20 Unique ASCII Art Styles** for your name display
  - Rotates through different designs on each terminal startup
  - Various fonts and styles (Block, Unicode, Retro, Decorative)

- **Powerlevel10k Theme**
  - Fast, customizable, and beautiful prompt
  - Git integration, command execution time, and more

- **Custom Startup Display**
  - Time-based greetings (Morning, Afternoon, Evening, Night)
  - System information (OS, kernel, uptime, memory, disk usage)
  - Daily philosophy quote (cached for performance)
  - Colorful ASCII art

- **Useful Plugins**
  - `zsh-autosuggestions` - Fish-like autosuggestions
  - `zsh-syntax-highlighting` - Syntax highlighting in the terminal
  - `git` - Git aliases and functions

## Preview

Every time you open your terminal, you'll be greeted with:
- A personalized greeting based on time of day
- System information dashboard
- A random philosophy quote to inspire your day
- Beautiful ASCII art of your name

## Quick Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/bindrap/ZSH/main/install.sh | bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/bindrap/ZSH/main/install.sh | bash
```

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bindrap/ZSH.git
   cd ZSH
   ```

2. **Make the install script executable:**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installation:**
   ```bash
   ./install.sh
   ```

4. **Log out and log back in** (or restart your terminal)

## What Gets Installed

The installation script will:

1. ✅ Install ZSH (if not already installed)
2. ✅ Install Oh My Zsh framework
3. ✅ Install Powerlevel10k theme
4. ✅ Install required plugins (autosuggestions, syntax-highlighting)
5. ✅ Install Nerd Fonts (MesloLGS NF) for proper icon display
6. ✅ Install NVM (Node Version Manager)
7. ✅ Copy custom configuration files:
   - `.zshrc` - Main ZSH configuration
   - `startup.sh` - Custom startup script
   - `quotes.txt` - Philosophy quotes database
   - `ascii_art.txt` - ASCII art designs
8. ✅ Set ZSH as your default shell

## Supported Operating Systems

- ✅ Ubuntu / Debian / Pop!_OS
- ✅ Fedora
- ✅ CentOS / RHEL
- ✅ Arch Linux / Manjaro
- ✅ macOS
- ✅ WSL (Windows Subsystem for Linux)

## Customization

### Personalize Your Name

To display your own name instead of "PARTEEK":

1. Edit `startup.sh` and change line 64-70 (greeting messages)
2. Generate new ASCII art for your name at:
   - [patorjk.com/software/taag](https://patorjk.com/software/taag/)
   - [ASCII Art Generator](https://www.ascii-art-generator.org/)
3. Add your custom ASCII art to `ascii_art.txt` following the format:
   ```
   ===ARTXX===
   [your ASCII art here]
   ```
4. Update the rotation count in `startup.sh` line 48 if you add/remove art

### Add Your Own Quotes

Edit `~/.config/zsh/quotes.txt` and add quotes in this format:
```
Your quote here. - Author Name
```

### Customize Colors and Display

Edit `~/.config/zsh/startup.sh` to modify:
- Color schemes (RGB color codes)
- Greeting messages
- System information displayed
- Layout and spacing

### Customize Powerlevel10k Theme

Run the configuration wizard anytime:
```bash
p10k configure
```

### Add Custom Aliases

Add your personal aliases to `~/.zshrc` at the bottom of the file.

## Configuration Files

```
~/.zshrc                     # Main ZSH configuration
~/.p10k.zsh                  # Powerlevel10k theme config
~/.config/zsh/
├── startup.sh               # Custom startup display script
├── quotes.txt               # Philosophy quotes database
└── ascii_art.txt            # ASCII art designs
```

## Uninstallation

To uninstall and restore your previous shell:

1. **Remove Oh My Zsh:**
   ```bash
   uninstall_oh_my_zsh
   ```

2. **Change back to bash (or previous shell):**
   ```bash
   chsh -s $(which bash)
   ```

3. **Remove configuration files:**
   ```bash
   rm -rf ~/.oh-my-zsh ~/.zshrc ~/.p10k.zsh ~/.config/zsh
   ```

4. **Restore backup** (if you had a previous .zshrc):
   ```bash
   mv ~/.zshrc.backup.[timestamp] ~/.zshrc
   ```

## Troubleshooting

### Icons/Symbols Not Displaying Correctly

**Problem:** You see question marks or boxes instead of icons.

**Solution:** Install and configure the MesloLGS NF font:

1. Download the fonts from [Powerlevel10k repository](https://github.com/romkatv/powerlevel10k#fonts)
2. Install the fonts on your system
3. Set your terminal font to "MesloLGS NF"

**For WSL/Windows Terminal:**
- Settings → Profiles → Ubuntu → Appearance → Font face → "MesloLGS NF"

**For iTerm2 (macOS):**
- Preferences → Profiles → Text → Font → "MesloLGS NF"

### Startup Display Not Showing

**Problem:** The custom startup display doesn't appear.

**Solution:**
```bash
# Check if files exist
ls -la ~/.config/zsh/

# Manually source the startup script
source ~/.config/zsh/startup.sh

# Check if STARTUP_DISPLAYED is set
echo $STARTUP_DISPLAYED
```

### Plugins Not Working

**Problem:** Autosuggestions or syntax highlighting not working.

**Solution:**
```bash
# Reinstall plugins manually
cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins

git clone https://github.com/zsh-users/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting

# Restart terminal
```

### Permission Denied on install.sh

**Problem:** Cannot execute install.sh

**Solution:**
```bash
chmod +x install.sh
./install.sh
```

## Contributing

Feel free to submit issues or pull requests if you have:
- Additional philosophy quotes
- New ASCII art designs
- Bug fixes or improvements
- Feature suggestions

## Philosophy Quote Sources

The quotes database includes wisdom from:
- **Stoicism:** Marcus Aurelius, Seneca, Epictetus
- **Ancient Greece:** Socrates, Plato, Aristotle, Heraclitus
- **Existentialism:** Nietzsche, Kierkegaard, Sartre, Camus
- **Eastern Philosophy:** Buddha, Confucius, Rumi
- **Modern Thinkers:** Carl Jung, Joseph Campbell, Immanuel Kant
- **Contemporary:** Dalai Lama, Oscar Wilde, Christopher Hitchens

## License

MIT License - Feel free to use and modify as you wish.

## Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Framework for managing ZSH configuration
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - ZSH theme
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting

## Author

Created with wisdom and code.

---

**Enjoy your beautiful and inspirational terminal! 🚀✨**
