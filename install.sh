#!/bin/bash

# ============================================================================
# ZSH Custom Terminal Setup - Installation Script
# ============================================================================
# This script installs zsh, Oh My Zsh, and custom configurations
# Supports: Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, macOS, WSL
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS=$DISTRIB_ID
            OS_VERSION=$DISTRIB_RELEASE
        else
            OS=$(uname -s)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS=$(uname -s)
    fi

    # Check if running in WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
    else
        IS_WSL=false
    fi

    print_info "Detected OS: $OS"
    [[ "$IS_WSL" == true ]] && print_info "Running in WSL"
}

# ============================================================================
# Package Manager Functions
# ============================================================================

install_package() {
    local package=$1
    print_info "Installing $package..."

    case $OS in
        ubuntu|debian|pop)
            sudo apt-get update -qq
            sudo apt-get install -y "$package"
            ;;
        fedora)
            sudo dnf install -y "$package"
            ;;
        centos|rhel)
            sudo yum install -y "$package"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm "$package"
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                print_error "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install "$package"
            ;;
        *)
            print_error "Unsupported OS: $OS"
            return 1
            ;;
    esac
}

# ============================================================================
# Installation Functions
# ============================================================================

install_zsh() {
    print_header "Installing ZSH"

    if command -v zsh &> /dev/null; then
        print_success "ZSH is already installed: $(zsh --version)"
        return 0
    fi

    install_package zsh

    if command -v zsh &> /dev/null; then
        print_success "ZSH installed successfully: $(zsh --version)"
    else
        print_error "Failed to install ZSH"
        exit 1
    fi
}

install_dependencies() {
    print_header "Installing Dependencies"

    # Install required packages
    local packages=("git" "curl" "wget")

    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            install_package "$package"
        else
            print_success "$package is already installed"
        fi
    done

    # Install fonts for powerline/powerlevel10k
    print_info "Installing Nerd Fonts for Powerlevel10k..."

    if [[ "$OS" == "macos" ]]; then
        brew tap homebrew/cask-fonts
        brew install --cask font-meslo-lg-nerd-font 2>/dev/null || print_warning "Font may already be installed"
    else
        # Install fonts on Linux
        local font_dir="$HOME/.local/share/fonts"
        mkdir -p "$font_dir"

        if [ ! -f "$font_dir/MesloLGS NF Regular.ttf" ]; then
            cd "$font_dir"
            curl -fLo "MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
            curl -fLo "MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
            curl -fLo "MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
            curl -fLo "MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

            # Refresh font cache
            fc-cache -fv &>/dev/null
            cd - > /dev/null

            print_success "Fonts installed"
        else
            print_success "Fonts already installed"
        fi
    fi
}

install_oh_my_zsh() {
    print_header "Installing Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh is already installed"
        return 0
    fi

    # Install Oh My Zsh (unattended)
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh installed successfully"
    else
        print_error "Failed to install Oh My Zsh"
        exit 1
    fi
}

install_powerlevel10k() {
    print_header "Installing Powerlevel10k Theme"

    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$p10k_dir" ]; then
        print_success "Powerlevel10k is already installed"
        return 0
    fi

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"

    if [ -d "$p10k_dir" ]; then
        print_success "Powerlevel10k installed successfully"
    else
        print_error "Failed to install Powerlevel10k"
        exit 1
    fi
}

install_zsh_plugins() {
    print_header "Installing ZSH Plugins"

    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Install zsh-autosuggestions
    if [ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]; then
        print_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_success "zsh-autosuggestions already installed"
    fi

    # Install zsh-syntax-highlighting
    if [ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]; then
        print_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        print_success "zsh-syntax-highlighting already installed"
    fi
}

setup_custom_config() {
    print_header "Setting Up Custom Configuration"

    # Create config directory
    mkdir -p "$HOME/.config/zsh"

    # Copy custom startup script
    if [ -f "$SCRIPT_DIR/startup.sh" ]; then
        cp "$SCRIPT_DIR/startup.sh" "$HOME/.config/zsh/startup.sh"
        chmod +x "$HOME/.config/zsh/startup.sh"
        print_success "Startup script installed"
    else
        print_warning "startup.sh not found in $SCRIPT_DIR"
    fi

    # Copy quotes file
    if [ -f "$SCRIPT_DIR/quotes.txt" ]; then
        cp "$SCRIPT_DIR/quotes.txt" "$HOME/.config/zsh/quotes.txt"
        print_success "Philosophy quotes installed"
    else
        print_warning "quotes.txt not found in $SCRIPT_DIR"
    fi

    # Copy ASCII art file
    if [ -f "$SCRIPT_DIR/ascii_art.txt" ]; then
        cp "$SCRIPT_DIR/ascii_art.txt" "$HOME/.config/zsh/ascii_art.txt"
        print_success "ASCII art designs installed"
    else
        print_warning "ascii_art.txt not found in $SCRIPT_DIR"
    fi

    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc" "$backup_file"
        print_info "Existing .zshrc backed up to $backup_file"
    fi

    # Copy new .zshrc (if exists in script directory)
    if [ -f "$SCRIPT_DIR/.zshrc" ]; then
        cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
        print_success "Custom .zshrc installed"
    else
        print_warning ".zshrc not found in $SCRIPT_DIR, keeping existing configuration"
    fi

    # Copy .p10k.zsh if it exists
    if [ -f "$SCRIPT_DIR/.p10k.zsh" ]; then
        cp "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
        print_success "Powerlevel10k configuration installed"
    else
        print_info "No .p10k.zsh found. You can customize it later with: p10k configure"
    fi
}

change_default_shell() {
    print_header "Setting ZSH as Default Shell"

    local zsh_path=$(which zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        print_success "ZSH is already the default shell"
        return 0
    fi

    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        print_info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi

    # Change default shell
    print_info "Changing default shell to ZSH..."
    if chsh -s "$zsh_path"; then
        print_success "Default shell changed to ZSH"
        print_warning "Please log out and log back in for the change to take effect"
    else
        print_error "Failed to change default shell. You may need to run: chsh -s $zsh_path"
    fi
}

install_nvm() {
    print_header "Installing NVM (Node Version Manager)"

    if [ -d "$HOME/.nvm" ]; then
        print_success "NVM is already installed"
        return 0
    fi

    print_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

    if [ -d "$HOME/.nvm" ]; then
        print_success "NVM installed successfully"
    else
        print_warning "NVM installation may have failed. You can install it manually later."
    fi
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    clear
    print_header "ZSH Custom Terminal Setup - Installation"
    echo ""
    echo "This script will install and configure:"
    echo "  • ZSH shell"
    echo "  • Oh My Zsh framework"
    echo "  • Powerlevel10k theme"
    echo "  • Custom plugins and configurations"
    echo "  • Philosophy quotes and ASCII art"
    echo ""

    # Check for -y or --yes flag, or non-interactive mode
    if [[ "$1" != "-y" ]] && [[ "$1" != "--yes" ]] && [[ -t 0 ]]; then
        read -p "Do you want to continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    else
        print_info "Running in non-interactive mode or with --yes flag, proceeding with installation..."
    fi

    echo ""

    # Detect OS
    detect_os
    echo ""

    # Run installation steps
    install_zsh
    echo ""

    install_dependencies
    echo ""

    install_oh_my_zsh
    echo ""

    install_powerlevel10k
    echo ""

    install_zsh_plugins
    echo ""

    setup_custom_config
    echo ""

    install_nvm
    echo ""

    change_default_shell
    echo ""

    # Final message
    print_header "Installation Complete!"
    echo ""
    print_success "ZSH has been installed and configured successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Log out and log back in (or restart your terminal)"
    echo "  2. Your terminal will now show custom startup with philosophy quotes"
    echo "  3. Run 'p10k configure' to customize the Powerlevel10k theme (optional)"
    echo ""

    if [[ "$IS_WSL" == true ]]; then
        print_warning "WSL Detected: Make sure your terminal font is set to 'MesloLGS NF'"
        print_info "In Windows Terminal: Settings → Profiles → Ubuntu → Appearance → Font face"
    fi

    echo ""
    print_info "To start using ZSH now without logging out, run: zsh"
    echo ""
}

# Run main function
main "$@"
