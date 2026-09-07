# Bash completion for tsm (Tmux Session Manager)
# Source this file in your .bashrc:
#   source /path/to/tsm.bash
# Or copy to /etc/bash_completion.d/tsm

_tsm_worktree_names() {
    git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { path = substr($0, 10) }
        /^bare$/ { path = "" }
        /^$/ { if (path != "") { n = split(path, a, "/"); print a[n]; path = "" } }
        END { if (path != "") { n = split(path, a, "/"); print a[n] } }
    '
}

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

    # Available subcommands, plus whatever tsm-* programs are on PATH: tsm
    # runs `tsm <name>` as `tsm-<name>` when <name> is not one of its own.
    subcmds="active last kill create-or-switch bookmark-add bookmark-remove bookmark-status match logs help"
    subcmds="$subcmds $(tsm _external-commands 2>/dev/null)"

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
            # The picker comes first; everything after it is the session
            # flags, plus whatever argument that picker takes.
            if [ "$COMP_CWORD" -eq 2 ]; then
                COMPREPLY=($(compgen -W "$(tsm _pickers 2>/dev/null)" -- "$cur"))
                return 0
            fi

            flags="-c --no-config -p --prompt-name"
            case "${COMP_WORDS[2]}" in
                dir)
                    COMPREPLY=($(compgen -d -W "$flags" -- "$cur"))
                    ;;
                worktree)
                    COMPREPLY=($(compgen -W "$(_tsm_worktree_names) $flags" -- "$cur"))
                    ;;
                bookmark)
                    COMPREPLY=($(compgen -W "$(_tsm_bookmark_chars) $flags" -- "$cur"))
                    ;;
                *)
                    COMPREPLY=($(compgen -W "$flags" -- "$cur"))
                    ;;
            esac
            return 0
            ;;
        bookmark-remove)
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
