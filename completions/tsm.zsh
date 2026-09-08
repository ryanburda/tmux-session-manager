#compdef tsm
# Zsh completion for tsm (Tmux Session Manager)
#
# Installation options:
# 1. Add to fpath and autoload:
#      fpath=(/path/to/completions $fpath)
#      autoload -Uz compinit && compinit
# 2. Or source directly in .zshrc:
#      source /path/to/tsm.zsh

_tsm_active_sessions() {
    local sessions
    sessions=(${(f)"$(tmux ls 2>/dev/null | awk -F: '{print $1}')"})
    _describe 'active session' sessions
}

_tsm_log_sessions() {
    local log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tsm/logs"
    local sessions
    if [[ -d "$log_dir" ]]; then
        sessions=(${(f)"$(for dir in "$log_dir"/*/; do [[ -d "$dir" ]] && basename "$dir"; done 2>/dev/null)"})
        _describe 'session with logs' sessions
    fi
}

_tsm_commands() {
    local commands=(
        'active:Switch to session'
        'last:Switch to the most recent session that is still open'
        'kill:Kill a session'
        'at:Start a session at a directory'
        'via:Start a session at the directory a program prints'
        'match:Configurations claiming a path, best first'
        'logs:Browse session logs'
        'help:Show help message'
    )

    _describe 'command' commands
}

_tsm() {
    local context state state_descr line
    typeset -A opt_args

    _arguments -C \
        '1:command:_tsm_commands' \
        '*::arg:->args' \
        && return 0

    case "$line[1]" in
        active|kill)
            _tsm_active_sessions
            ;;
        at)
            _alternative \
                'directories:directory:_files -/' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        via)
            # The session flags come first, then the program; everything
            # after it is the program's own and is left alone.
            local i
            for (( i = 2; i < CURRENT; i++ )); do
                [[ "$line[i]" == -* ]] || return
            done

            _alternative \
                'commands:program:_command_names -e' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        match)
            _files -/
            ;;
        logs)
            _tsm_log_sessions
            ;;
    esac
}

_tsm "$@"
