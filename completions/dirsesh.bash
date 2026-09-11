# Bash completion for dirsesh (one tmux session per directory)
# Source this file in your .bashrc:
#   source /path/to/dirsesh.bash
# Or copy to /etc/bash_completion.d/dirsesh

_dirsesh_completions() {
    local cur prev cmd subcmds flags
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd="${COMP_WORDS[1]}"

    subcmds="at match init help"

    # Completing the subcommand itself
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$subcmds" -- "$cur"))
        return 0
    fi

    # Completing an argument to a subcommand
    case "$cmd" in
        at)
            # A directory and the session flags, in either order.
            flags="-noconfig -name"
            COMPREPLY=($(compgen -d -W "$flags" -- "$cur"))
            return 0
            ;;
        match)
            COMPREPLY=($(compgen -d -- "$cur"))
            return 0
            ;;
    esac
}

complete -F _dirsesh_completions dirsesh
