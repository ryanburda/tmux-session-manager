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

_tsm_bookmarks() {
    # The bookmark picker's own rows: character, directory, then the column
    # it displays -- which makes a fine completion description.
    local bookmarks
    bookmarks=(${(f)"$(tsm _bookmark-entries 2>/dev/null | awk -F'\t' '{ d = $3; sub(/^[^ ]+ +/, "", d); print $1 ":" d }')"})
    _describe 'bookmark' bookmarks
}

_tsm_pickers() {
    # The built-in picker names, then anything else executable: `tsm via`
    # runs whatever it is given that is not a built-in.
    local pickers
    pickers=(${(f)"$(tsm _pickers 2>/dev/null)"})
    _alternative \
        "pickers:built-in picker:($pickers)" \
        'commands:program:_command_names -e'
}

_tsm_commands() {
    local commands=(
        'active:Switch to session'
        'last:Switch to the most recent session that is still open'
        'kill:Kill a session'
        'at:Start a session at a directory'
        'via:Start a session at the directory a picker prints'
        'bookmark-add:Bookmark a directory at a character'
        'bookmark-remove:Remove a bookmark'
        'bookmark-path:Print the directory a bookmark points at'
        'bookmark-status:The open sessions bookmarks, for a tmux status line'
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
            # The session flags come first, then the picker; everything after
            # the picker is the program's own and is left alone.
            local i
            for (( i = 2; i < CURRENT; i++ )); do
                [[ "$line[i]" == -* ]] || return
            done

            _alternative \
                'pickers:picker:_tsm_pickers' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        bookmark-remove|bookmark-path)
            _tsm_bookmarks
            ;;
        bookmark-status)
            _values -s ' ' 'bookmark-status options' '-s' '--style' '-c' '--current-style'
            ;;
        bookmark-add)
            # The character comes first and is the user's to pick; the
            # directory after it is the one being bookmarked.
            if (( CURRENT > 2 )); then
                _files -/
            fi
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
