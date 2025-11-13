#!/bin/bash

# ============================================================================
# ZSH Installation Test Script
# ============================================================================
# This script tests the installation without making any changes
# Safe to run - won't modify your system
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================================================
# System Checks
# ============================================================================

clear
print_header "ZSH Installation Pre-Check Test"
echo ""

# OS Detection
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
else
    IS_WSL=false
fi

print_header "System Information"
echo "OS: $OS"
echo "OS Version: $OS_VERSION"
echo "WSL: $IS_WSL"
echo "User: $USER"
echo "Home: $HOME"
echo ""

# ============================================================================
# Check Current State
# ============================================================================

print_header "Current Installation Status"
echo ""

# Check ZSH
if command -v zsh &> /dev/null; then
    print_check 0 "ZSH: Installed ($(zsh --version))"
    ZSH_INSTALLED=true
else
    print_check 1 "ZSH: Not installed"
    ZSH_INSTALLED=false
fi

# Check current shell
if [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
    print_check 0 "Default Shell: ZSH"
else
    print_check 1 "Default Shell: $SHELL"
fi

# Check Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_check 0 "Oh My Zsh: Installed"
    OMZ_INSTALLED=true
else
    print_check 1 "Oh My Zsh: Not installed"
    OMZ_INSTALLED=false
fi

# Check Powerlevel10k
if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    print_check 0 "Powerlevel10k: Installed"
    P10K_INSTALLED=true
else
    print_check 1 "Powerlevel10k: Not installed"
    P10K_INSTALLED=false
fi

# Check plugins
if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    print_check 0 "zsh-autosuggestions: Installed"
else
    print_check 1 "zsh-autosuggestions: Not installed"
fi

if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    print_check 0 "zsh-syntax-highlighting: Installed"
else
    print_check 1 "zsh-syntax-highlighting: Not installed"
fi

echo ""

# ============================================================================
# Check Dependencies
# ============================================================================

print_header "Required Dependencies"
echo ""

command -v git &> /dev/null && print_check 0 "git: Installed" || print_check 1 "git: Not installed"
command -v curl &> /dev/null && print_check 0 "curl: Installed" || print_check 1 "curl: Not installed"
command -v wget &> /dev/null && print_check 0 "wget: Installed" || print_check 1 "wget: Not installed"

echo ""

# ============================================================================
# Check Custom Config Files
# ============================================================================

print_header "Custom Configuration Files"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/startup.sh" ]; then
    print_check 0 "startup.sh: Found in $SCRIPT_DIR"
else
    print_check 1 "startup.sh: Not found"
fi

if [ -f "$SCRIPT_DIR/quotes.txt" ]; then
    QUOTE_COUNT=$(wc -l < "$SCRIPT_DIR/quotes.txt")
    print_check 0 "quotes.txt: Found ($QUOTE_COUNT quotes)"
else
    print_check 1 "quotes.txt: Not found"
fi

if [ -f "$SCRIPT_DIR/ascii_art.txt" ]; then
    ART_COUNT=$(grep -c "===ART" "$SCRIPT_DIR/ascii_art.txt")
    print_check 0 "ascii_art.txt: Found ($ART_COUNT art styles)"
else
    print_check 1 "ascii_art.txt: Not found"
fi

if [ -f "$SCRIPT_DIR/.zshrc" ]; then
    print_check 0 ".zshrc: Found"
else
    print_check 1 ".zshrc: Not found"
fi

echo ""

# ============================================================================
# Check Existing Files
# ============================================================================

print_header "Existing Configuration Files (Will be backed up)"
echo ""

if [ -f "$HOME/.zshrc" ]; then
    print_warning ".zshrc exists - will be backed up"
    echo "   Location: $HOME/.zshrc"
    echo "   Size: $(stat -f%z "$HOME/.zshrc" 2>/dev/null || stat -c%s "$HOME/.zshrc") bytes"
    echo "   Last modified: $(stat -f%Sm "$HOME/.zshrc" 2>/dev/null || stat -c%y "$HOME/.zshrc")"
else
    print_check 1 ".zshrc: Does not exist (new install)"
fi

if [ -f "$HOME/.p10k.zsh" ]; then
    print_warning ".p10k.zsh exists - will be backed up if new one provided"
else
    print_check 1 ".p10k.zsh: Does not exist"
fi

if [ -d "$HOME/.config/zsh" ]; then
    print_warning ".config/zsh directory exists"
    ls -la "$HOME/.config/zsh" 2>/dev/null
else
    print_check 1 ".config/zsh: Does not exist (will be created)"
fi

echo ""

# ============================================================================
# Check Fonts
# ============================================================================

print_header "Font Installation"
echo ""

if [[ "$OS" == "macos" ]]; then
    if [ -d "$HOME/Library/Fonts" ]; then
        FONT_COUNT=$(ls "$HOME/Library/Fonts" | grep -i meslo | wc -l)
        if [ $FONT_COUNT -gt 0 ]; then
            print_check 0 "MesloLGS NF fonts: Found ($FONT_COUNT files)"
        else
            print_check 1 "MesloLGS NF fonts: Not found"
        fi
    fi
else
    if [ -d "$HOME/.local/share/fonts" ]; then
        FONT_COUNT=$(ls "$HOME/.local/share/fonts" 2>/dev/null | grep -i meslo | wc -l)
        if [ $FONT_COUNT -gt 0 ]; then
            print_check 0 "MesloLGS NF fonts: Found ($FONT_COUNT files)"
        else
            print_check 1 "MesloLGS NF fonts: Not found"
        fi
    else
        print_check 1 "Font directory does not exist"
    fi
fi

echo ""

# ============================================================================
# Check NVM
# ============================================================================

print_header "Optional Components"
echo ""

if [ -d "$HOME/.nvm" ]; then
    print_check 0 "NVM: Installed"
else
    print_check 1 "NVM: Not installed (will be installed)"
fi

echo ""

# ============================================================================
# What Will Happen
# ============================================================================

print_header "Installation Summary"
echo ""

echo "The installation script will:"
echo ""

if [ "$ZSH_INSTALLED" = false ]; then
    echo "  1. Install ZSH shell"
else
    echo "  1. Skip ZSH installation (already installed)"
fi

if [ "$OMZ_INSTALLED" = false ]; then
    echo "  2. Install Oh My Zsh framework"
else
    echo "  2. Skip Oh My Zsh installation (already installed)"
fi

if [ "$P10K_INSTALLED" = false ]; then
    echo "  3. Install Powerlevel10k theme"
else
    echo "  3. Skip Powerlevel10k installation (already installed)"
fi

echo "  4. Install/update ZSH plugins"
echo "  5. Install Nerd Fonts"
echo "  6. Copy custom configuration files to ~/.config/zsh/"
echo "  7. Install/update .zshrc (backing up existing)"
echo "  8. Install NVM if not present"
echo "  9. Set ZSH as default shell"

echo ""

# ============================================================================
# Safety Check
# ============================================================================

print_header "Safety Checks"
echo ""

ISSUES=0

if [ -f "$HOME/.zshrc" ] && [ ! -w "$HOME/.zshrc" ]; then
    print_warning "Existing .zshrc is not writable"
    ((ISSUES++))
fi

if [ ! -w "$HOME" ]; then
    print_warning "Home directory is not writable"
    ((ISSUES++))
fi

if ! sudo -n true 2>/dev/null; then
    print_info "Script will request sudo password for package installation"
fi

if [ $ISSUES -eq 0 ]; then
    print_check 0 "No issues detected"
fi

echo ""

# ============================================================================
# Recommendations
# ============================================================================

print_header "Recommendations"
echo ""

if [ "$IS_WSL" = true ]; then
    echo "WSL Detected:"
    echo "  • After installation, configure Windows Terminal:"
    echo "    Settings → Profiles → Ubuntu → Appearance → Font face → 'MesloLGS NF'"
    echo ""
fi

if [ -f "$HOME/.zshrc" ]; then
    echo "Backup Notice:"
    echo "  • Your current .zshrc will be backed up to:"
    echo "    ~/.zshrc.backup.[timestamp]"
    echo ""
fi

if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
    print_warning "install.sh not found in current directory"
    echo "    Expected location: $SCRIPT_DIR/install.sh"
    echo ""
fi

# ============================================================================
# Test Commands
# ============================================================================

print_header "Testing Commands"
echo ""
echo "To test the installation safely:"
echo ""
echo "1. Review the install script:"
echo "   ${CYAN}cat install.sh${NC}"
echo ""
echo "2. Run the actual installation:"
echo "   ${CYAN}./install.sh${NC}"
echo ""
echo "3. Or run in a Docker container first:"
echo "   ${CYAN}docker run -it ubuntu:latest bash${NC}"
echo "   ${CYAN}# Inside container: run the installation${NC}"
echo ""
echo "4. Check script syntax:"
echo "   ${CYAN}bash -n install.sh${NC}"
echo ""

print_header "Pre-Check Complete!"
echo ""
echo "Ready to proceed with installation?"
echo ""
