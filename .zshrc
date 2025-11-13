# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ============================================================================
# User Configuration
# ============================================================================

# History configuration
HISTSIZE=1000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS
setopt APPEND_HISTORY

# Color support for ls and grep
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Common ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/nvm_completion" ] && \. "$NVM_DIR/nvm_completion"  # This loads nvm completion

# ============================================================================
# Custom Startup Display
# ============================================================================
# Only show on interactive login shells, not in subshells or scripts
if [[ -o interactive ]] && [[ -z "$STARTUP_DISPLAYED" ]]; then
    export STARTUP_DISPLAYED=1
    [[ -f ~/.config/zsh/startup.sh ]] && source ~/.config/zsh/startup.sh
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
# Additional Custom Aliases (Add your own below)
# ============================================================================
# Example:
# alias notes='cd ~/notes && nvim'
# alias push='your-push-command'
# alias pull='your-pull-command'
