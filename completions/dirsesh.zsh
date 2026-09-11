#compdef dirsesh
# Zsh completion for dirsesh (one tmux session per directory)
#
# Installation options:
# 1. Add to fpath and autoload:
#      fpath=(/path/to/completions $fpath)
#      autoload -Uz compinit && compinit
# 2. Or source directly in .zshrc:
#      source /path/to/dirsesh.zsh

_dirsesh_commands() {
    local commands=(
        'at:Start a session at a directory'
        'match:Configurations claiming a path, best first'
        'init:Install the tmux session-closed hook'
        'help:Show help message'
    )

    _describe 'command' commands
}

_dirsesh() {
    local context state state_descr line
    typeset -A opt_args

    _arguments -C \
        '1:command:_dirsesh_commands' \
        '*::arg:->args' \
        && return 0

    case "$line[1]" in
        at)
            _alternative \
                'directories:directory:_files -/' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        match)
            _files -/
            ;;
    esac
}

_dirsesh "$@"
