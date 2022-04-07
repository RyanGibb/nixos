
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000

setopt autocd nomatch notify interactive_comments
unsetopt beep extendedglob

autoload -Uz compinit
compinit

# https://superuser.com/questions/476532/how-can-i-make-zshs-vi-mode-behave-more-like-bashs-vi-mode
vi-search-fix() {
	zle vi-cmd-mode
	zle .vi-history-search-backward
}
autoload vi-search-fix
zle -N vi-search-fix
bindkey -M viins '\e/' vi-search-fix

bindkey -v
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd V edit-command-line

alias ls='ls -p --color=auto'
alias pls='sudo $(fc -ln -1)'
alias o='xdg-open'
alias se='sudoedit'
alias su='su -p'
alias ssh='TERM=xterm ssh'

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)

autoload zmv

# fix right prompt indent
ZLE_RPROMPT_INDENT=0


# load version control information
autoload -Uz vcs_info
precmd() { vcs_info }

setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '!'
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
zstyle ':vcs_info:git*' formats $' %F{green}%.32b%m%u%c%f'

+vi-git-untracked() {
	if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
		git status --porcelain | grep -m 1 '^??' &>/dev/null
	then
		hook_com[misc]='?'
	fi
}


PROMPT='%(?..%F{red}%3?%f )%D{%I:%M:%S%p} %F{blue}%n@%m%f:%F{cyan}%~%f%<<${vcs_info_msg_0_}'$'\n'' %# '
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=5


# set window title
# https://wiki.archlinux.org/title/zsh#xterm_title
autoload -Uz add-zsh-hook

function xterm_title_precmd () {
	print -Pn -- '\e]2;zsh %n@%m:%~\a'
}

function xterm_title_preexec () {
	print -Pn -- '\e]2;zsh %n@%m:%~ %# ' && print -n -- "${(q)1}\a"
}

if [[ "$TERM" != "linux" ]]; then
	add-zsh-hook -Uz precmd xterm_title_precmd
	add-zsh-hook -Uz preexec xterm_title_preexec
fi


autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

typeset -g -A key

bindkey "${key[Up]}"                up-line-or-beginning-search
bindkey "${key[Down]}"              down-line-or-beginning-search

key[Shift-Tab]="${terminfo[kcbt]}"
key[Control-Left]="^[[1;5D"
key[Control-Right]="^[[1;5C"
key[Control-Backspace]="^H"
key[Control-Delete]="^[[3;5~"
key[Control-R]="^R"

bindkey "${key[Shift-Tab]}"         reverse-menu-complete
bindkey "${key[Control-Left]}"      backward-word
bindkey "${key[Control-Right]}"     forward-word
bindkey "${key[Control-Backspace]}" backward-kill-word
bindkey "${key[Control-Delete]}"    kill-word
bindkey "${key[Control-R]}"         history-incremental-search-backward



# https://unix.stackexchange.com/questions/258656/how-can-i-have-two-keystrokes-to-delete-to-either-a-slash-or-a-word-in-zsh

# Alt+Backspace
backward-kill-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle backward-kill-word
	# Ensure Ctrl+Y will restore repeated applications
    zle -f kill
}
zle -N backward-kill-dir
bindkey '^[^?' backward-kill-dir

# Alt+Delete
forward-kill-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle kill-word
	# Ensure Ctrl+Y will restore repeated applications
    zle -f kill
}
zle -N forward-kill-dir
bindkey '^[[3;3~' forward-kill-dir

# Alt+Left
backward-word-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle backward-word
}
zle -N backward-word-dir
bindkey "^[[1;3D" backward-word-dir

# Alt+Right
forward-word-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle forward-word
}
zle -N forward-word-dir
bindkey "^[[1;3C" forward-word-dir
