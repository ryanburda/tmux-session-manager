# Bash completion for tsm (Tmux Session Manager)
# Source this file in your .bashrc:
#   source /path/to/tsm.bash
# Or copy to /etc/bash_completion.d/tsm

_tsm_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Available options
    opts="-c --configured -k --kill -l --logs -d --dir -z --zoxide -h --help"

    # Complete based on previous word
    case "$prev" in
        -c|--configured)
            # Complete with configured session names
            local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsm"
            if [ -d "$config_dir" ]; then
                local sessions=$(for dir in "$config_dir"/*/; do [ -d "$dir" ] && basename "$dir"; done 2>/dev/null)
                COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
            fi
            return 0
            ;;
        -k|--kill)
            # Complete with active sessions
            local active=$(tmux ls 2>/dev/null | awk -F: '{print $1}')
            COMPREPLY=($(compgen -W "$active" -- "$cur"))
            return 0
            ;;
        -l|--logs)
            # Complete with session names that have log files
            local log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tsm/logs"
            if [ -d "$log_dir" ]; then
                local sessions=$(for f in "$log_dir"/*.log; do [ -f "$f" ] && basename "$f" .log; done 2>/dev/null)
                COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
            fi
            return 0
            ;;
        -d|--dir)
            # Complete with directories
            COMPREPLY=($(compgen -d -- "$cur"))
            return 0
            ;;
        -z|--zoxide)
            # No completion for zoxide queries
            return 0
            ;;
        tsm)
            # First argument: complete with options or active sessions
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$opts" -- "$cur"))
            else
                local active=$(tmux ls 2>/dev/null | awk -F: '{print $1}')
                COMPREPLY=($(compgen -W "$active $opts" -- "$cur"))
            fi
            return 0
            ;;
    esac

    # Default: complete with options or active sessions
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    else
        local active=$(tmux ls 2>/dev/null | awk -F: '{print $1}')
        COMPREPLY=($(compgen -W "$active" -- "$cur"))
    fi
}

complete -F _tsm_completions tsm
