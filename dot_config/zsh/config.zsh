# ~/.zshrc - A Modern Zsh Configuration

# ============================================================================
# ZSH OPTIONS
# ============================================================================

# Navigation
setopt AUTO_CD                  # Auto cd to directory without typing cd
setopt AUTO_PUSHD               # Push the old directory onto the stack on cd
setopt PUSHD_IGNORE_DUPS        # Do not store duplicates in the stack
setopt PUSHD_SILENT             # Do not print the directory stack after pushd or popd

# History
setopt EXTENDED_HISTORY         # Write the history file in the ':start:elapsed;command' format
setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS         # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS        # Do not display a line previously found
setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS        # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks before recording entry
setopt HIST_VERIFY              # Don't execute immediately upon history expansion
setopt SHARE_HISTORY            # Share history between all sessions

# Completion
setopt COMPLETE_ALIASES         # Complete aliases
setopt AUTO_MENU                # Show completion menu on second consecutive tab
setopt ALWAYS_TO_END            # When completing, move cursor to the end of the word
setopt AUTO_LIST                # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH         # If completed parameter is a directory, add a trailing slash
setopt COMPLETE_IN_WORD         # Allow completion from within a word/phrase

# Correction
setopt CORRECT                  # Spelling correction for commands
setopt CORRECT_ALL              # Spelling correction for arguments

# Prompt
setopt PROMPT_SUBST             # Enable parameter expansion, command substitution, and arithmetic expansion in prompts

# Globbing
setopt EXTENDED_GLOB            # Use extended globbing syntax
setopt GLOB_DOTS               # Include dotfiles in globbing

# Job Control
setopt LONG_LIST_JOBS          # List jobs in the long format by default
setopt AUTO_RESUME             # Attempt to resume existing job before creating a new process

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================

HISTFILE=~/.local/share/zsh/zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ============================================================================
# COMPLETION SYSTEM
# ============================================================================

# Initialize completion system
autoload -Uz compinit
compinit

# Load additional completions
fpath=(/usr/share/zsh/site-functions $fpath)

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path ~/.zsh/cache

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Colors for completion
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Process completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:processes' command 'ps -xuf'
zstyle ':completion:*:processes' sort false
zstyle ':completion:*:processes-names' command 'ps xho command'

# Directory completion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# SSH/SCP/RSYNC completion
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr

# Auto rehash when new executables are added
zstyle ':completion:*' rehash true

# Ignore certain files in completion
zstyle ':completion:*:*:vim:*:*files' ignored-patterns '*~' '*.o' '*.pyc'

# ============================================================================
# KEY BINDINGS
# ============================================================================

# Use vi key bindings
bindkey -v

# Reduce ESC delay (faster mode switching)
export KEYTIMEOUT=1

# Better history search (works in both insert and normal mode)
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Edit command line in editor (vim-like)
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Search in normal mode
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# ============================================================================
# PLUGINS
# ============================================================================

# History substring search
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Fast Syntax Highlighting (faster than zsh-syntax-highlighting)
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true

# You Should Use (suggests aliases)
source /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh

# ============================================================================
# EXTERNAL TOOLS
# ============================================================================

# Starship prompt
eval "$(starship init zsh)"

# Zoxide (better cd)
eval "$(zoxide init zsh)"

# FZF integration
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Direnv (automatic environment loading)
eval "$(direnv hook zsh)"

# TheFuck (command correction)
eval $(thefuck --alias)

# ============================================================================
# ALIASES
# ============================================================================

# File operations
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza --tree --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first --all'

# Editors
alias nv='neovide'
alias nvim='command nvim'
alias vim='command nvim'
alias vi='command nvim'

# Git
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias lg='lazygit'

# System
alias grep='rg'
alias cat='bat'
alias du='dust'
alias df='df -h'
alias free='free -h'
alias ps='ps auxf'
alias mount='mount | column -t'

# Network
alias ping='ping -c 5'
alias ports='netstat -tulanp'

# Directory navigation
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Quick access
alias h='history'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================================================
# FUNCTIONS
# ============================================================================

# Extract various archive formats
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find file by name
ff() {
    fd -H -I "$1"
}

# Find and execute
fex() {
    local file
    file=$(fd -H -I | fzf --preview 'bat --color=always {}') && ${EDITOR:-vim} "$file"
}

# CD to directory selected with fzf
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git | fzf) && cd "$dir"
}

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# Pager
export PAGER='less'
export LESS='-R'

# Colors
export TERM='xterm-256color'

# Path additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/env:$PATH"

# Wayland
# Wayland for Qt apps
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Wayland for Electron apps (e.g., VSCode)
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# Wayland for SDL apps (e.g., games)
export SDL_VIDEODRIVER=wayland

# GTK
export GDK_BACKEND=wayland

# For Browsers
export MOZ_ENABLE_WAYLAND=1
export XDG_SESSION_TYPE=wayland
export CLUTTER_BACKEND=wayland

# Chromium/Electron
export OZONE_PLATFORM=wayland
export GTK_USE_PORTAL=1
