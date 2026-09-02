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
    subcmds="active last kill dir git worktree bookmark bookmark-add bookmark-remove bookmark-list bookmark-status configured logs apply-matching-config kill-matching-config help"

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
            COMPREPLY=($(compgen -d -W "-c --no-config -p --prompt-name" -- "$cur"))
            return 0
            ;;
        git)
            COMPREPLY=($(compgen -W "-b --brief -f --fetch -c --no-config -p --prompt-name" -- "$cur"))
            return 0
            ;;
        worktree)
            local worktrees=$(git worktree list --porcelain 2>/dev/null | awk '
                /^worktree / { path = substr($0, 10) }
                /^bare$/ { path = "" }
                /^$/ { if (path != "") { n = split(path, a, "/"); print a[n]; path = "" } }
                END { if (path != "") { n = split(path, a, "/"); print a[n] } }
            ')
            COMPREPLY=($(compgen -W "$worktrees -c --no-config -p --prompt-name" -- "$cur"))
            return 0
            ;;
        bookmark|bookmark-remove)
            # Only asked for when there is something to list: with no bookmarks
            # set, tsm says so, and inside tmux it says so in the status line.
            local bookmarks_file="${XDG_STATE_HOME:-$HOME/.local/state}/tsm/bookmarks.json"
            local bookmarks=""
            if [ -s "$bookmarks_file" ]; then
                bookmarks=$(tsm bookmark-list 2>/dev/null | awk 'length($1) == 1 { print $1 }')
            fi
            if [ "$cmd" = "bookmark" ]; then
                COMPREPLY=($(compgen -W "$bookmarks -c --no-config -p --prompt-name" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$bookmarks" -- "$cur"))
            fi
            return 0
            ;;
        bookmark-list)
            COMPREPLY=($(compgen -W "-f --fzf" -- "$cur"))
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
    esac
}

complete -F _tsm_completions tsm
