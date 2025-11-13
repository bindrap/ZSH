#!/usr/bin/env zsh

# ============================================================================
# WSL Startup Script - Parteek's Custom Terminal Greeting
# ============================================================================

# Only run in interactive shells, not in scripts or subshells
[[ $- != *i* ]] && return
[[ -z "$PS1" ]] && return

# Respect Powerlevel10k instant prompt - print after prompt is ready
(( ${+p10k_instant_prompt_active} )) && p10k finalize

# Cache directory for performance
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-startup"
mkdir -p "$CACHE_DIR"

# ============================================================================
# Color Definitions - Vibrant Color Scheme
# ============================================================================

# ANSI color codes
RESET="\033[0m"
BOLD="\033[1m"

# Vibrant color palette
C_PRIMARY="\033[38;2;137;180;250m"    # Bright Blue
C_ACCENT="\033[38;2;255;121;198m"     # Hot Pink/Magenta
C_GREEN="\033[38;2;80;250;123m"       # Neon Green
C_YELLOW="\033[38;2;255;184;108m"     # Bright Orange-Yellow
C_CYAN="\033[38;2;139;233;253m"       # Electric Cyan
C_PURPLE="\033[38;2;189;147;249m"     # Vibrant Purple
C_RED="\033[38;2;255;85;85m"          # Bright Red
C_ORANGE="\033[38;2;255;158;100m"     # Bright Orange
C_WHITE="\033[38;2;248;248;242m"      # Bright white

# ============================================================================
# Functions
# ============================================================================

get_ascii_art() {
    local art_file=~/.config/zsh/ascii_art.txt
    local art_index_file="$CACHE_DIR/art_index"

    local current_index=1
    [[ -f "$art_index_file" ]] && current_index=$(cat "$art_index_file")

    local next_index=$(( (current_index % 20) + 1 ))
    echo "$next_index" > "$art_index_file"

    awk -v idx="$current_index" '
        /===ART/ { count++; if (count == idx) { printing=1; next } else { printing=0 } }
        printing && !/===ART/ { print }
    ' "$art_file"
}

# ============================================================================
# Main Display
# ============================================================================

# Get time-based greeting
hour=$(date +%H)
if [[ $hour -ge 5 && $hour -lt 12 ]]; then
    greeting="${C_YELLOW}${BOLD}☀️  Good Morning, ${C_ORANGE}Parteek${RESET}"
elif [[ $hour -ge 12 && $hour -lt 17 ]]; then
    greeting="${C_ORANGE}${BOLD}🌤️  Good Afternoon, ${C_ACCENT}Parteek${RESET}"
elif [[ $hour -ge 17 && $hour -lt 21 ]]; then
    greeting="${C_PURPLE}${BOLD}🌆 Good Evening, ${C_CYAN}Parteek${RESET}"
else
    greeting="${C_CYAN}${BOLD}🌙 Good Night, ${C_PURPLE}Parteek${RESET}"
fi

# System info
os_info=$(grep -oP '(?<=PRETTY_NAME=").*(?=")' /etc/os-release 2>/dev/null || echo "Unknown")
kernel=$(uname -r)

# Uptime
uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
uptime_days=$((uptime_seconds / 86400))
uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
uptime_mins=$(( (uptime_seconds % 3600) / 60 ))
uptime_str=""
[[ $uptime_days -gt 0 ]] && uptime_str="${uptime_days}d "
[[ $uptime_hours -gt 0 ]] && uptime_str="${uptime_str}${uptime_hours}h "
uptime_str="${uptime_str}${uptime_mins}m"

# Memory
mem_info=$(free -m | awk 'NR==2{printf "%s/%sMB (%.0f%%)", $3, $2, $3*100/$2}')
mem_percent=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
mem_color=$C_GREEN
[[ $mem_percent -gt 70 ]] && mem_color=$C_YELLOW
[[ $mem_percent -gt 85 ]] && mem_color=$C_ACCENT

# Disk
disk_info=$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')
disk_percent=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
disk_color=$C_GREEN
[[ $disk_percent -gt 70 ]] && disk_color=$C_YELLOW
[[ $disk_percent -gt 85 ]] && disk_color=$C_ACCENT

# IP
ip_cache="$CACHE_DIR/ip_address"
if [[ ! -f "$ip_cache" ]] || [[ $(find "$ip_cache" -mmin +5 2>/dev/null) ]]; then
    ip_addr=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    [[ -z "$ip_addr" ]] && ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
    [[ -z "$ip_addr" ]] && ip_addr="Not connected"
    echo "$ip_addr" > "$ip_cache"
else
    ip_addr=$(cat "$ip_cache")
fi

# Quote
quote_cache="$CACHE_DIR/daily_quote"
quote=""
if [[ -f "$quote_cache" ]]; then
    cache_date=$(stat -c %Y "$quote_cache" 2>/dev/null)
    today=$(date +%s)
    day_diff=$(( (today - cache_date) / 86400 ))
    [[ $day_diff -eq 0 ]] && quote=$(cat "$quote_cache")
fi

if [[ -z "$quote" ]]; then
    [[ -f ~/.config/zsh/quotes.txt ]] && quote=$(shuf -n 1 ~/.config/zsh/quotes.txt)
    [[ -z "$quote" ]] && quote="You have power over your mind - not outside events. Realize this, and you will find strength."
    echo "$quote" > "$quote_cache"
fi

# Random art color
colors=($C_CYAN $C_PURPLE $C_ACCENT $C_YELLOW $C_GREEN)
art_color=${colors[$((RANDOM % 5 + 1))]}

# Create temp files
left_tmp=$(mktemp)
right_tmp=$(mktemp)

# Custom rainbow colors for PARTEEK banner (each line = letter color)
C_P="\033[38;2;0;255;255m"      # P = Teal (bright cyan)
C_A="\033[38;2;255;50;50m"      # A = Bright Red
C_R="\033[38;2;255;255;0m"      # R = Bright Yellow
C_T="\033[38;2;0;255;255m"      # T = Cyan
C_E="\033[38;2;255;165;0m"      # E = Bright Orange
C_E2="\033[38;2;0;150;255m"     # E = Bright Blue
C_K="\033[38;2;200;100;255m"    # K = Bright Purple

# Build left column content (P-A-R-T-E-E-K rainbow)
{
    echo -e "${C_P}${BOLD}    ____             __            __${RESET}"
    echo -e "${C_A}${BOLD}   / __ \\____ ______/ /____  ___  / /__${RESET}"
    echo -e "${C_R}${BOLD}  / /_/ / __ \`/ ___/ __/ _ \\/ _ \\/ //_/${RESET}"
    echo -e "${C_T}${BOLD} / ____/ /_/ / /  / /_/  __/  __/ ,<${RESET}"
    echo -e "${C_E}${BOLD}/_/${RESET}${C_E2}${BOLD}    \\__,_/_/   \\__/${C_K}${BOLD}\\___/\\___/_/|_|${RESET}"
    echo ""
    echo -e "$greeting"
    echo ""
    echo -e "${C_PURPLE}${BOLD}┌─────────────────────────────────────────────────┐${RESET}"
    echo -e "${C_CYAN}${BOLD}  💻 OS:${RESET}       ${C_WHITE}${os_info}${RESET}"
    echo -e "${C_CYAN}${BOLD}  🔧 Kernel:${RESET}   ${C_WHITE}${kernel}${RESET}"
    echo -e "${C_CYAN}${BOLD}  ⏱️  Uptime:${RESET}   ${C_GREEN}${uptime_str}${RESET}"
    echo -e "${C_CYAN}${BOLD}  🧠 Memory:${RESET}   ${mem_color}${BOLD}${mem_info}${RESET}"
    echo -e "${C_CYAN}${BOLD}  💾 Disk:${RESET}     ${disk_color}${BOLD}${disk_info}${RESET}"
    echo -e "${C_CYAN}${BOLD}  👤 User:${RESET}     ${C_PURPLE}${USER}@$(hostname)${RESET}"
    echo -e "${C_CYAN}${BOLD}  🌐 IP:${RESET}       ${C_ORANGE}${ip_addr}${RESET}"
    echo -e "${C_PURPLE}${BOLD}└─────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "${C_ACCENT}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${C_YELLOW}${BOLD}💭 Thought for the day:${RESET}"
    echo ""
    # Split quote and author, color them differently
    if [[ "$quote" == *" - Marcus Aurelius"* ]]; then
        quote_text="${quote% - Marcus Aurelius}"
        # Wrap and color each line
        while IFS= read -r line; do
            echo -e "   ${C_YELLOW}${BOLD}${line}${RESET}"
        done <<< "$(echo "$quote_text" | fold -s -w 49)"
        echo -e "   ${C_PURPLE}${BOLD}- Marcus Aurelius${RESET}"
    else
        # Wrap and color each line
        while IFS= read -r line; do
            echo -e "   ${C_YELLOW}${BOLD}${line}${RESET}"
        done <<< "$(echo "$quote" | fold -s -w 49)"
    fi
    echo -e "${C_ACCENT}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
} > "$left_tmp"

# Build right column content (colored ASCII art)
get_ascii_art | while IFS= read -r line; do
    echo -e "${art_color}${line}${RESET}"
done > "$right_tmp"

# Merge columns using awk with proper ANSI handling
awk -v left="$left_tmp" -v right="$right_tmp" '
BEGIN {
    # Read left column
    while ((getline line < left) > 0) {
        left_lines[++left_count] = line
    }
    close(left)

    # Read right column
    while ((getline line < right) > 0) {
        right_lines[++right_count] = line
    }
    close(right)

    # Get max lines
    max_lines = (left_count > right_count) ? left_count : right_count

    # Print side by side
    for (i = 1; i <= max_lines; i++) {
        left_line = (i <= left_count) ? left_lines[i] : ""
        right_line = (i <= right_count) ? right_lines[i] : ""

        # Strip ANSI codes to measure visible length
        visible = left_line
        gsub(/\x1b\[[0-9;]*m/, "", visible)
        visible_len = length(visible)

        # Pad to 65 characters
        padding = 65 - visible_len
        if (padding < 0) padding = 0

        # Print line with padding
        printf "%s", left_line
        for (j = 0; j < padding; j++) printf " "
        printf "  %s\n", right_line
    }
}
'

echo ""

# Cleanup
rm -f "$left_tmp" "$right_tmp"
