# Bash completion for tsm (Tmux Session Manager)
# Source this file in your .bashrc:
#   source /path/to/tsm.bash
# Or copy to /etc/bash_completion.d/tsm

_tsm_bookmark_chars() {
    # The bookmark picker's own rows; the character is their first field.
    tsm _bookmark-entries 2>/dev/null | cut -f1
}

_tsm_completions() {
    local cur prev cmd subcmds flags
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd="${COMP_WORDS[1]}"

    subcmds="active last kill create-or-switch create-or-switch-exec bookmark-add bookmark-remove bookmark-path bookmark-status match logs help"

    # Completing the subcommand itself
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$subcmds" -- "$cur"))
        return 0
    fi

    # Completing an argument to a subcommand
    case "$cmd" in
        active|kill)
            local active=$(tmux ls 2>/dev/null | awk -F: '{print $1}')
            COMPREPLY=($(compgen -W "$active" -- "$cur"))
            return 0
            ;;
        create-or-switch)
            # A directory and the session flags, in either order.
            flags="-c --no-config -p --prompt-name"
            COMPREPLY=($(compgen -d -W "$flags" -- "$cur"))
            return 0
            ;;
        create-or-switch-exec)
            # The session flags come first, then the picker: a built-in name,
            # or any program that prints a path. Everything after the picker
            # is the program's own, so it is left alone.
            flags="-c --no-config -p --prompt-name"
            local i picked=0
            for (( i = 2; i < COMP_CWORD; i++ )); do
                case "${COMP_WORDS[i]}" in
                    -*) ;;
                    *) picked=1; break ;;
                esac
            done
            [ "$picked" -eq 0 ] &&
                COMPREPLY=($(compgen -W "$(tsm _pickers 2>/dev/null) $flags" -c -- "$cur"))
            return 0
            ;;
        bookmark-remove|bookmark-path)
            COMPREPLY=($(compgen -W "$(_tsm_bookmark_chars)" -- "$cur"))
            return 0
            ;;
        bookmark-status)
            COMPREPLY=($(compgen -W "-s --style -c --current-style" -- "$cur"))
            return 0
            ;;
        bookmark-add)
            # The character comes first and is the user's to pick; the
            # directory after it is the one being bookmarked.
            if [ "$COMP_CWORD" -gt 2 ]; then
                COMPREPLY=($(compgen -d -- "$cur"))
            fi
            return 0
            ;;
        match)
            COMPREPLY=($(compgen -d -- "$cur"))
            return 0
            ;;
        logs)
            local log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tsm/logs"
            if [ -d "$log_dir" ]; then
                local sessions=$(for dir in "$log_dir"/*/; do [ -d "$dir" ] && basename "$dir"; done 2>/dev/null)
                COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
            fi
            return 0
            ;;
    esac
}

complete -F _tsm_completions tsm
