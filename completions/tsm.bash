# Bash completion for tsm (Tmux Session Manager)
# Source this file in your .bashrc:
#   source /path/to/tsm.bash
# Or copy to /etc/bash_completion.d/tsm

_tsm_completions() {
    local cur prev cmd subcmds
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd="${COMP_WORDS[1]}"

    # Available subcommands
    subcmds="active kill dir git worktree zoxide configured logs start-default agents agent-state help"

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
        dir)
            COMPREPLY=($(compgen -d -W "--start-default --use-default-name" -- "$cur"))
            return 0
            ;;
        git)
            COMPREPLY=($(compgen -W "--hide-brief --no-fetch --start-default --use-default-name" -- "$cur"))
            return 0
            ;;
        worktree)
            local worktrees=$(git worktree list --porcelain 2>/dev/null | awk '
                /^worktree / { path = substr($0, 10) }
                /^bare$/ { path = "" }
                /^$/ { if (path != "") { n = split(path, a, "/"); print a[n]; path = "" } }
                END { if (path != "") { n = split(path, a, "/"); print a[n] } }
            ')
            COMPREPLY=($(compgen -W "$worktrees --start-default --use-default-name" -- "$cur"))
            return 0
            ;;
        zoxide)
            COMPREPLY=($(compgen -W "--start-default --use-default-name" -- "$cur"))
            return 0
            ;;
        configured)
            local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsm"
            if [ -d "$config_dir" ]; then
                local sessions=$(for f in "$config_dir"/*.sh; do [ -f "$f" ] && basename "$f" .sh; done 2>/dev/null)
                COMPREPLY=($(compgen -W "$sessions" -- "$cur"))
            fi
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
        agent-state)
            COMPREPLY=($(compgen -W "working blocked done idle clear" -- "$cur"))
            return 0
            ;;
    esac
}

complete -F _tsm_completions tsm
