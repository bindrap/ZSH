#!/bin/bash

# ============================================================================
# ZSH Custom Terminal Setup - Bulletproof Installation Script
# ============================================================================
# This script installs zsh, Oh My Zsh, and custom configurations
# Supports: Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, macOS, WSL
# Features: Retry logic, rollback, validation, comprehensive error handling
# ============================================================================

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# Global Variables
# ============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation state file for rollback
readonly STATE_FILE="/tmp/zsh_install_state_$$"
readonly LOG_FILE="/tmp/zsh_install_log_$$.log"

# Retry configuration
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5

# Minimum disk space required (in KB)
readonly MIN_DISK_SPACE=524288  # 512MB

# Track what was installed for potential rollback
declare -a INSTALLED_ITEMS=()

# OS detection variables
OS=""
OS_VERSION=""
IS_WSL=false

# ============================================================================
# Cleanup and Error Handling
# ============================================================================

cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        print_error "Installation failed with exit code $exit_code"
        print_info "Log file available at: $LOG_FILE"

        if [ -f "$STATE_FILE" ]; then
            print_warning "Installation was interrupted. State file: $STATE_FILE"
        fi

        if [ ${#INSTALLED_ITEMS[@]} -gt 0 ]; then
            print_info "Items installed before failure:"
            printf '%s\n' "${INSTALLED_ITEMS[@]}" | sed 's/^/  - /'
        fi
    else
        # Clean up on success
        rm -f "$STATE_FILE"
    fi
}

trap cleanup EXIT
trap 'exit 130' INT  # Handle Ctrl+C gracefully
trap 'exit 143' TERM # Handle termination gracefully

# ============================================================================
# Logging Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" >/dev/null
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >/dev/null
}

# ============================================================================
# Output Functions
# ============================================================================

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "HEADER: $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
    log_error "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
    log "INFO: $1"
}

# ============================================================================
# Validation Functions
# ============================================================================

check_internet() {
    print_info "Checking internet connectivity..."

    local test_urls=(
        "https://www.google.com"
        "https://github.com"
        "https://raw.githubusercontent.com"
    )

    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 --max-time 10 "$url" >/dev/null 2>&1; then
            print_success "Internet connection verified"
            return 0
        fi
    done

    print_error "No internet connection detected"
    print_info "Please check your network connection and try again"
    return 1
}

check_disk_space() {
    print_info "Checking available disk space..."

    local available_space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')

    if [ "$available_space" -lt "$MIN_DISK_SPACE" ]; then
        print_error "Insufficient disk space. Required: ${MIN_DISK_SPACE}KB, Available: ${available_space}KB"
        return 1
    fi

    print_success "Sufficient disk space available (${available_space}KB)"
    return 0
}

check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root is not recommended"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check for required commands
    local required_cmds=("curl" "sed" "awk" "grep")
    local missing_cmds=()

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_cmds+=("$cmd")
        fi
    done

    if [ ${#missing_cmds[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_cmds[*]}"
        print_info "These will be installed automatically"
    fi

    print_success "Prerequisites check completed"
}

validate_installation() {
    local component=$1
    local validation_command=$2

    if eval "$validation_command" &>/dev/null; then
        print_success "$component validated successfully"
        return 0
    else
        print_error "$component validation failed"
        return 1
    fi
}

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    print_info "Detecting operating system..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            # shellcheck disable=SC1091
            . /etc/os-release
            OS=$ID
            OS_VERSION=${VERSION_ID:-"unknown"}
        elif [ -f /etc/lsb-release ]; then
            # shellcheck disable=SC1091
            . /etc/lsb-release
            OS=$DISTRIB_ID
            OS_VERSION=$DISTRIB_RELEASE
        else
            OS=$(uname -s | tr '[:upper:]' '[:lower:]')
            OS_VERSION="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        OS_VERSION="unknown"
    fi

    # Check if running in WSL
    if [ -f /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
    fi

    print_success "Detected OS: $OS $OS_VERSION"
    [[ "$IS_WSL" == true ]] && print_info "Running in WSL"

    # Verify OS is supported
    case $OS in
        ubuntu|debian|pop|fedora|centos|rhel|arch|manjaro|macos)
            return 0
            ;;
        *)
            print_warning "OS '$OS' may not be fully supported. Proceeding with caution..."
            return 0
            ;;
    esac
}

# ============================================================================
# Retry Logic
# ============================================================================

retry_command() {
    local max_attempts=$1
    shift
    local delay=$1
    shift
    local command=("$@")
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if "${command[@]}" 2>&1 | tee -a "$LOG_FILE"; then
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                print_warning "Attempt $attempt failed. Retrying in ${delay}s..."
                sleep "$delay"
                ((attempt++))
            else
                print_error "All $max_attempts attempts failed"
                return 1
            fi
        fi
    done
}

download_with_retry() {
    local url=$1
    local output=$2
    local max_attempts=${3:-$MAX_RETRIES}

    print_info "Downloading from $url..."

    for ((i=1; i<=max_attempts; i++)); do
        if curl -fsSL --connect-timeout 10 --max-time 300 -o "$output" "$url" 2>&1 | tee -a "$LOG_FILE"; then
            if [ -s "$output" ]; then
                print_success "Download completed"
                return 0
            else
                print_error "Downloaded file is empty"
                rm -f "$output"
            fi
        fi

        if [ $i -lt $max_attempts ]; then
            print_warning "Download attempt $i failed. Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
    done

    print_error "Failed to download after $max_attempts attempts"
    return 1
}

git_clone_with_retry() {
    local repo_url=$1
    local target_dir=$2
    local depth=${3:-1}
    local max_attempts=${4:-$MAX_RETRIES}

    print_info "Cloning repository: $repo_url"

    for ((i=1; i<=max_attempts; i++)); do
        if git clone --depth="$depth" "$repo_url" "$target_dir" 2>&1 | tee -a "$LOG_FILE"; then
            if [ -d "$target_dir/.git" ]; then
                print_success "Repository cloned successfully"
                return 0
            else
                print_error "Clone succeeded but directory is invalid"
                rm -rf "$target_dir"
            fi
        fi

        if [ $i -lt $max_attempts ]; then
            print_warning "Clone attempt $i failed. Retrying in ${RETRY_DELAY}s..."
            rm -rf "$target_dir"
            sleep "$RETRY_DELAY"
        fi
    done

    print_error "Failed to clone repository after $max_attempts attempts"
    return 1
}

# ============================================================================
# Package Manager Functions
# ============================================================================

wait_for_package_manager() {
    local max_wait=300  # 5 minutes
    local waited=0
    local lock_files=()

    case $OS in
        ubuntu|debian|pop)
            lock_files=("/var/lib/dpkg/lock" "/var/lib/dpkg/lock-frontend" "/var/lib/apt/lists/lock")
            ;;
        fedora)
            lock_files=("/var/run/dnf.pid" "/var/run/yum.pid")
            ;;
        centos|rhel)
            lock_files=("/var/run/yum.pid")
            ;;
    esac

    if [ ${#lock_files[@]} -eq 0 ]; then
        return 0
    fi

    while [ $waited -lt $max_wait ]; do
        local locked=false

        for lock_file in "${lock_files[@]}"; do
            if sudo fuser "$lock_file" 2>/dev/null; then
                locked=true
                break
            fi
        done

        if [ "$locked" = false ]; then
            return 0
        fi

        if [ $waited -eq 0 ]; then
            print_info "Package manager is locked. Waiting..."
        fi

        sleep 5
        waited=$((waited + 5))

        if [ $((waited % 30)) -eq 0 ]; then
            print_info "Still waiting for package manager... (${waited}s)"
        fi
    done

    print_warning "Package manager lock timeout after ${max_wait}s"
    return 1
}

update_package_cache() {
    print_info "Updating package cache..."

    wait_for_package_manager || return 1

    case $OS in
        ubuntu|debian|pop)
            retry_command 3 5 sudo apt-get update -qq
            ;;
        fedora)
            retry_command 3 5 sudo dnf check-update || true
            ;;
        centos|rhel)
            retry_command 3 5 sudo yum check-update || true
            ;;
        arch|manjaro)
            retry_command 3 5 sudo pacman -Sy
            ;;
        macos)
            if command -v brew &>/dev/null; then
                retry_command 3 5 brew update
            fi
            ;;
    esac

    print_success "Package cache updated"
}

install_package() {
    local package=$1
    print_info "Installing $package..."

    # Check if already installed
    if command -v "$package" &>/dev/null; then
        print_success "$package is already available"
        return 0
    fi

    wait_for_package_manager || return 1

    case $OS in
        ubuntu|debian|pop)
            if retry_command $MAX_RETRIES $RETRY_DELAY sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$package"; then
                INSTALLED_ITEMS+=("package:$package")
                return 0
            fi
            ;;
        fedora)
            if retry_command $MAX_RETRIES $RETRY_DELAY sudo dnf install -y -q "$package"; then
                INSTALLED_ITEMS+=("package:$package")
                return 0
            fi
            ;;
        centos|rhel)
            if retry_command $MAX_RETRIES $RETRY_DELAY sudo yum install -y -q "$package"; then
                INSTALLED_ITEMS+=("package:$package")
                return 0
            fi
            ;;
        arch|manjaro)
            if retry_command $MAX_RETRIES $RETRY_DELAY sudo pacman -S --noconfirm "$package"; then
                INSTALLED_ITEMS+=("package:$package")
                return 0
            fi
            ;;
        macos)
            if ! command -v brew &>/dev/null; then
                print_info "Homebrew not found. Installing..."
                if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                    print_error "Failed to install Homebrew"
                    return 1
                fi
                INSTALLED_ITEMS+=("homebrew")
            fi

            if retry_command $MAX_RETRIES $RETRY_DELAY brew install "$package"; then
                INSTALLED_ITEMS+=("package:$package")
                return 0
            fi
            ;;
        *)
            print_error "Unsupported OS: $OS"
            return 1
            ;;
    esac

    print_error "Failed to install $package"
    return 1
}

# ============================================================================
# Installation Functions
# ============================================================================

install_zsh() {
    print_header "Installing ZSH"

    if command -v zsh &>/dev/null; then
        local version
        version=$(zsh --version 2>/dev/null || echo "unknown")
        print_success "ZSH is already installed: $version"
        INSTALLED_ITEMS+=("zsh:existing")
        return 0
    fi

    if ! install_package zsh; then
        print_error "Failed to install ZSH"
        return 1
    fi

    if ! validate_installation "ZSH" "command -v zsh"; then
        return 1
    fi

    local version
    version=$(zsh --version 2>/dev/null || echo "unknown")
    print_success "ZSH installed successfully: $version"
    echo "zsh" >> "$STATE_FILE"

    return 0
}

install_dependencies() {
    print_header "Installing Dependencies"

    # Essential packages
    local packages=("git" "curl" "wget")

    for package in "${packages[@]}"; do
        if command -v "$package" &>/dev/null; then
            print_success "$package is already installed"
        else
            if ! install_package "$package"; then
                print_error "Failed to install $package"
                return 1
            fi
            print_success "$package installed successfully"
        fi
    done

    # Install fonts for powerline/powerlevel10k
    print_info "Installing Nerd Fonts for Powerlevel10k..."

    if [[ "$OS" == "macos" ]]; then
        if command -v brew &>/dev/null; then
            brew tap homebrew/cask-fonts 2>/dev/null || true
            brew install --cask font-meslo-lg-nerd-font 2>/dev/null || {
                print_warning "Font installation failed or already installed"
            }
        fi
    else
        # Install fonts on Linux
        local font_dir="$HOME/.local/share/fonts"

        if ! mkdir -p "$font_dir" 2>/dev/null; then
            print_warning "Failed to create font directory"
            return 0  # Non-critical failure
        fi

        if [ ! -f "$font_dir/MesloLGS NF Regular.ttf" ]; then
            local fonts=(
                "MesloLGS%20NF%20Regular.ttf:MesloLGS NF Regular.ttf"
                "MesloLGS%20NF%20Bold.ttf:MesloLGS NF Bold.ttf"
                "MesloLGS%20NF%20Italic.ttf:MesloLGS NF Italic.ttf"
                "MesloLGS%20NF%20Bold%20Italic.ttf:MesloLGS NF Bold Italic.ttf"
            )

            local font_base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
            local all_fonts_installed=true

            for font in "${fonts[@]}"; do
                IFS=':' read -r url_name file_name <<< "$font"
                local temp_file="/tmp/${file_name// /_}"

                if download_with_retry "$font_base_url/$url_name" "$temp_file"; then
                    if mv "$temp_file" "$font_dir/$file_name" 2>/dev/null; then
                        print_success "Installed: $file_name"
                    else
                        print_warning "Failed to move font: $file_name"
                        all_fonts_installed=false
                    fi
                else
                    print_warning "Failed to download font: $file_name"
                    all_fonts_installed=false
                fi
            done

            if [ "$all_fonts_installed" = true ]; then
                # Refresh font cache
                if command -v fc-cache &>/dev/null; then
                    fc-cache -fv &>/dev/null || print_warning "Failed to refresh font cache"
                fi
                print_success "Fonts installed successfully"
                INSTALLED_ITEMS+=("fonts:meslo")
            else
                print_warning "Some fonts failed to install (non-critical)"
            fi
        else
            print_success "Fonts already installed"
        fi
    fi

    echo "dependencies" >> "$STATE_FILE"
    return 0
}

install_oh_my_zsh() {
    print_header "Installing Oh My Zsh"

    local omz_dir="$HOME/.oh-my-zsh"

    if [ -d "$omz_dir" ]; then
        if [ -d "$omz_dir/.git" ]; then
            print_success "Oh My Zsh is already installed"
            INSTALLED_ITEMS+=("oh-my-zsh:existing")
            return 0
        else
            print_warning "Oh My Zsh directory exists but appears corrupted"
            local backup_dir="${omz_dir}.backup.$(date +%s)"
            if mv "$omz_dir" "$backup_dir" 2>/dev/null; then
                print_info "Moved corrupted installation to $backup_dir"
            else
                print_error "Failed to backup corrupted installation"
                return 1
            fi
        fi
    fi

    # Download Oh My Zsh installer
    local installer="/tmp/omz_install_$$.sh"

    if ! download_with_retry "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$installer"; then
        print_error "Failed to download Oh My Zsh installer"
        return 1
    fi

    # Make installer executable
    chmod +x "$installer" || {
        print_error "Failed to make installer executable"
        rm -f "$installer"
        return 1
    }

    # Install Oh My Zsh (unattended)
    if RUNZSH=no CHSH=no sh "$installer" 2>&1 | tee -a "$LOG_FILE"; then
        rm -f "$installer"
    else
        local exit_code=$?
        rm -f "$installer"
        print_error "Oh My Zsh installer failed with exit code $exit_code"
        return 1
    fi

    # Validate installation
    if ! validate_installation "Oh My Zsh" "[ -d '$omz_dir/.git' ]"; then
        return 1
    fi

    print_success "Oh My Zsh installed successfully"
    INSTALLED_ITEMS+=("oh-my-zsh")
    echo "oh-my-zsh" >> "$STATE_FILE"

    return 0
}

install_powerlevel10k() {
    print_header "Installing Powerlevel10k Theme"

    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$p10k_dir" ]; then
        if [ -d "$p10k_dir/.git" ]; then
            print_success "Powerlevel10k is already installed"
            INSTALLED_ITEMS+=("powerlevel10k:existing")
            return 0
        else
            print_warning "Powerlevel10k directory exists but appears corrupted"
            rm -rf "$p10k_dir" 2>/dev/null || {
                print_error "Failed to remove corrupted Powerlevel10k directory"
                return 1
            }
        fi
    fi

    # Ensure parent directory exists
    local parent_dir
    parent_dir=$(dirname "$p10k_dir")
    if ! mkdir -p "$parent_dir" 2>/dev/null; then
        print_error "Failed to create themes directory"
        return 1
    fi

    # Clone repository
    if ! git_clone_with_retry "https://github.com/romkatv/powerlevel10k.git" "$p10k_dir" 1; then
        print_error "Failed to clone Powerlevel10k repository"
        return 1
    fi

    # Validate installation
    if ! validate_installation "Powerlevel10k" "[ -d '$p10k_dir/.git' ]"; then
        return 1
    fi

    print_success "Powerlevel10k installed successfully"
    INSTALLED_ITEMS+=("powerlevel10k")
    echo "powerlevel10k" >> "$STATE_FILE"

    return 0
}

install_zsh_plugins() {
    print_header "Installing ZSH Plugins"

    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins_installed=0
    local plugins_failed=0

    # Ensure plugins directory exists
    if ! mkdir -p "$custom_dir/plugins" 2>/dev/null; then
        print_error "Failed to create plugins directory"
        return 1
    fi

    # Install zsh-autosuggestions
    local autosugg_dir="$custom_dir/plugins/zsh-autosuggestions"
    if [ -d "$autosugg_dir/.git" ]; then
        print_success "zsh-autosuggestions already installed"
        ((plugins_installed++))
    else
        print_info "Installing zsh-autosuggestions..."
        rm -rf "$autosugg_dir" 2>/dev/null

        if git_clone_with_retry "https://github.com/zsh-users/zsh-autosuggestions" "$autosugg_dir" 1; then
            if validate_installation "zsh-autosuggestions" "[ -d '$autosugg_dir/.git' ]"; then
                print_success "zsh-autosuggestions installed"
                INSTALLED_ITEMS+=("plugin:zsh-autosuggestions")
                ((plugins_installed++))
            else
                ((plugins_failed++))
            fi
        else
            print_error "Failed to install zsh-autosuggestions"
            ((plugins_failed++))
        fi
    fi

    # Install zsh-syntax-highlighting
    local syntax_dir="$custom_dir/plugins/zsh-syntax-highlighting"
    if [ -d "$syntax_dir/.git" ]; then
        print_success "zsh-syntax-highlighting already installed"
        ((plugins_installed++))
    else
        print_info "Installing zsh-syntax-highlighting..."
        rm -rf "$syntax_dir" 2>/dev/null

        if git_clone_with_retry "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$syntax_dir" 1; then
            if validate_installation "zsh-syntax-highlighting" "[ -d '$syntax_dir/.git' ]"; then
                print_success "zsh-syntax-highlighting installed"
                INSTALLED_ITEMS+=("plugin:zsh-syntax-highlighting")
                ((plugins_installed++))
            else
                ((plugins_failed++))
            fi
        else
            print_error "Failed to install zsh-syntax-highlighting"
            ((plugins_failed++))
        fi
    fi

    if [ $plugins_failed -gt 0 ]; then
        print_warning "$plugins_failed plugin(s) failed to install"
    fi

    if [ $plugins_installed -eq 0 ] && [ $plugins_failed -gt 0 ]; then
        print_error "No plugins were installed successfully"
        return 1
    fi

    echo "zsh-plugins" >> "$STATE_FILE"
    return 0
}

setup_custom_config() {
    print_header "Setting Up Custom Configuration"

    local config_dir="$HOME/.config/zsh"

    # Create config directory
    if ! mkdir -p "$config_dir" 2>/dev/null; then
        print_error "Failed to create config directory: $config_dir"
        return 1
    fi

    print_success "Config directory created: $config_dir"

    # Copy custom startup script
    if [ -f "$SCRIPT_DIR/startup.sh" ]; then
        if cp "$SCRIPT_DIR/startup.sh" "$config_dir/startup.sh" 2>/dev/null; then
            chmod +x "$config_dir/startup.sh" || print_warning "Failed to make startup.sh executable"
            print_success "Startup script installed"
            INSTALLED_ITEMS+=("config:startup.sh")
        else
            print_warning "Failed to copy startup.sh"
        fi
    else
        print_warning "startup.sh not found in $SCRIPT_DIR"
    fi

    # Copy quotes file
    if [ -f "$SCRIPT_DIR/quotes.txt" ]; then
        if cp "$SCRIPT_DIR/quotes.txt" "$config_dir/quotes.txt" 2>/dev/null; then
            print_success "Philosophy quotes installed"
            INSTALLED_ITEMS+=("config:quotes.txt")
        else
            print_warning "Failed to copy quotes.txt"
        fi
    else
        print_warning "quotes.txt not found in $SCRIPT_DIR"
    fi

    # Copy ASCII art file
    if [ -f "$SCRIPT_DIR/ascii_art.txt" ]; then
        if cp "$SCRIPT_DIR/ascii_art.txt" "$config_dir/ascii_art.txt" 2>/dev/null; then
            print_success "ASCII art designs installed"
            INSTALLED_ITEMS+=("config:ascii_art.txt")
        else
            print_warning "Failed to copy ascii_art.txt"
        fi
    else
        print_warning "ascii_art.txt not found in $SCRIPT_DIR"
    fi

    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        local backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        if cp "$HOME/.zshrc" "$backup_file" 2>/dev/null; then
            print_info "Existing .zshrc backed up to $backup_file"
            INSTALLED_ITEMS+=("backup:.zshrc")
        else
            print_warning "Failed to backup existing .zshrc"
        fi
    fi

    # Copy new .zshrc (if exists in script directory)
    if [ -f "$SCRIPT_DIR/.zshrc" ]; then
        if cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc" 2>/dev/null; then
            print_success "Custom .zshrc installed"
            INSTALLED_ITEMS+=("config:.zshrc")
        else
            print_error "Failed to copy .zshrc"
            return 1
        fi
    else
        print_warning ".zshrc not found in $SCRIPT_DIR, keeping existing configuration"
    fi

    # Copy .p10k.zsh if it exists
    if [ -f "$SCRIPT_DIR/.p10k.zsh" ]; then
        # Backup existing .p10k.zsh if present
        if [ -f "$HOME/.p10k.zsh" ]; then
            local p10k_backup="$HOME/.p10k.zsh.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$HOME/.p10k.zsh" "$p10k_backup" 2>/dev/null && \
                print_info "Existing .p10k.zsh backed up to $p10k_backup"
        fi

        if cp "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh" 2>/dev/null; then
            print_success "Powerlevel10k configuration installed"
            INSTALLED_ITEMS+=("config:.p10k.zsh")
        else
            print_warning "Failed to copy .p10k.zsh"
        fi
    else
        print_info "No .p10k.zsh found. You can customize it later with: p10k configure"
    fi

    echo "custom-config" >> "$STATE_FILE"
    return 0
}

change_default_shell() {
    print_header "Setting ZSH as Default Shell"

    local zsh_path
    zsh_path=$(command -v zsh 2>/dev/null)

    if [ -z "$zsh_path" ]; then
        print_error "ZSH not found in PATH"
        return 1
    fi

    if [ "$SHELL" = "$zsh_path" ]; then
        print_success "ZSH is already the default shell"
        return 0
    fi

    # Check if /etc/shells is writable (or we have sudo)
    if [ ! -w /etc/shells ] && ! sudo -n true 2>/dev/null; then
        print_warning "Cannot modify /etc/shells without sudo privileges"
        print_info "You can manually set ZSH as default later with: chsh -s $zsh_path"
        return 0
    fi

    # Add zsh to /etc/shells if not present
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        print_info "Adding $zsh_path to /etc/shells..."
        if echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1; then
            print_success "ZSH added to /etc/shells"
        else
            print_warning "Failed to add ZSH to /etc/shells"
            print_info "You may need to manually add it before changing shell"
        fi
    fi

    # Change default shell
    print_info "Changing default shell to ZSH..."

    if chsh -s "$zsh_path" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Default shell changed to ZSH"
        print_warning "Please log out and log back in for the change to take effect"
        INSTALLED_ITEMS+=("shell:zsh")
        echo "default-shell" >> "$STATE_FILE"
    else
        print_warning "Failed to change default shell automatically"
        print_info "You can manually change it with: chsh -s $zsh_path"
        print_info "Or contact your system administrator"
    fi

    return 0
}

install_nvm() {
    print_header "Installing NVM (Node Version Manager)"

    local nvm_dir="$HOME/.nvm"

    if [ -d "$nvm_dir" ]; then
        if [ -s "$nvm_dir/nvm.sh" ]; then
            print_success "NVM is already installed"
            INSTALLED_ITEMS+=("nvm:existing")
            return 0
        else
            print_warning "NVM directory exists but appears incomplete"
            local backup_dir="${nvm_dir}.backup.$(date +%s)"
            mv "$nvm_dir" "$backup_dir" 2>/dev/null && \
                print_info "Moved incomplete installation to $backup_dir"
        fi
    fi

    print_info "Installing NVM..."

    # Download and install NVM
    local nvm_installer="/tmp/nvm_install_$$.sh"

    if download_with_retry "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh" "$nvm_installer"; then
        chmod +x "$nvm_installer" || {
            print_warning "Failed to make NVM installer executable"
            rm -f "$nvm_installer"
            return 1
        }

        if bash "$nvm_installer" 2>&1 | tee -a "$LOG_FILE"; then
            rm -f "$nvm_installer"

            # Validate installation
            if [ -s "$nvm_dir/nvm.sh" ]; then
                print_success "NVM installed successfully"
                INSTALLED_ITEMS+=("nvm")
                echo "nvm" >> "$STATE_FILE"
                return 0
            else
                print_warning "NVM installation completed but validation failed"
                return 1
            fi
        else
            rm -f "$nvm_installer"
            print_warning "NVM installation script failed"
            return 1
        fi
    else
        print_warning "Failed to download NVM installer"
        print_info "You can install NVM manually later if needed"
        return 1
    fi
}

# ============================================================================
# Main Installation Flow
# ============================================================================

show_summary() {
    print_header "Installation Summary"
    echo ""

    if [ ${#INSTALLED_ITEMS[@]} -gt 0 ]; then
        print_success "Successfully installed/configured:"
        printf '%s\n' "${INSTALLED_ITEMS[@]}" | sed 's/^/  ✓ /'
    fi

    echo ""
    print_info "Log file: $LOG_FILE"

    if [ -f "$STATE_FILE" ]; then
        print_info "State file: $STATE_FILE"
    fi
}

# Show usage information
show_usage() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
  -y, --yes     Run without confirmation prompt
  -h, --help    Show this help message and exit

Notes:
- Non-interactive shells auto-confirm by default
- All actions are logged to a temporary log file shown on failure
EOF
}

main() {
    clear

    # Initialize log file
    echo "=== ZSH Installation Log ===" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "OS: $(uname -a)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    print_header "ZSH Custom Terminal Setup - Bulletproof Installation"
    echo ""
    echo "This script will install and configure:"
    echo "  • ZSH shell"
    echo "  • Oh My Zsh framework"
    echo "  • Powerlevel10k theme"
    echo "  • Custom plugins and configurations"
    echo "  • Philosophy quotes and ASCII art"
    echo "  • NVM (Node Version Manager)"
    echo ""
    echo "Features:"
    echo "  • Automatic retry on network failures"
    echo "  • Comprehensive validation"
    echo "  • Detailed logging"
    echo "  • Graceful error handling"
    echo ""

    # Parse arguments
    local auto_confirm=false
    local args=("$@")

    for arg in "${args[@]}"; do
        case "$arg" in
            -y|--yes)
                auto_confirm=true
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
        esac
    done

    # Non-interactive shells auto-confirm by default
    if [ "$auto_confirm" = false ] && [[ ! -t 0 ]]; then
        auto_confirm=true
        print_info "Running in non-interactive mode"
    fi

    if [ "$auto_confirm" = true ]; then
        print_info "Running in auto-confirm mode"
    fi

    if [ "$auto_confirm" = false ]; then
        read -p "Do you want to continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi

    echo ""

    # Pre-flight checks
    print_header "Pre-flight Checks"

    check_prerequisites || exit 1
    detect_os || exit 1
    check_internet || exit 1
    check_disk_space || exit 1

    echo ""
    print_success "All pre-flight checks passed"
    echo ""

    # Update package cache once at the beginning
    update_package_cache || print_warning "Failed to update package cache (continuing anyway)"
    echo ""

    # Run installation steps
    local failed_steps=()

    install_zsh || failed_steps+=("ZSH")
    echo ""

    install_dependencies || failed_steps+=("Dependencies")
    echo ""

    install_oh_my_zsh || failed_steps+=("Oh My Zsh")
    echo ""

    install_powerlevel10k || failed_steps+=("Powerlevel10k")
    echo ""

    install_zsh_plugins || failed_steps+=("ZSH Plugins")
    echo ""

    setup_custom_config || failed_steps+=("Custom Config")
    echo ""

    install_nvm || print_warning "NVM installation failed (optional component)"
    echo ""

    change_default_shell || print_warning "Failed to change default shell (you can do this manually)"
    echo ""

    # Check if any critical steps failed
    if [ ${#failed_steps[@]} -gt 0 ]; then
        print_error "Installation completed with errors"
        print_error "Failed steps: ${failed_steps[*]}"
        show_summary
        exit 1
    fi

    # Final message
    print_header "Installation Complete!"
    echo ""
    print_success "ZSH has been installed and configured successfully!"
    echo ""

    show_summary
    echo ""

    print_info "Next steps:"
    echo "  1. Log out and log back in (or restart your terminal)"
    echo "  2. Your terminal will now show custom startup with philosophy quotes"
    echo "  3. Run 'p10k configure' to customize the Powerlevel10k theme (optional)"
    echo ""

    if [[ "$IS_WSL" == true ]]; then
        print_warning "WSL Detected: Make sure your terminal font is set to 'MesloLGS NF'"
        print_info "In Windows Terminal: Settings → Profiles → Ubuntu → Appearance → Font face"
        echo ""
    fi

    print_info "To start using ZSH now without logging out, run: exec zsh"
    echo ""

    print_success "Installation log saved to: $LOG_FILE"
    echo ""
}

# Run main function
main "$@"
