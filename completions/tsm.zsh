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

_tsm_worktrees() {
    local worktrees
    worktrees=(${(f)"$(git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { path = substr($0, 10) }
        /^bare$/ { path = "" }
        /^$/ { if (path != "") { n = split(path, a, "/"); print a[n]; path = "" } }
        END { if (path != "") { n = split(path, a, "/"); print a[n] } }
    ')"})
    _describe 'worktree' worktrees
}

_tsm_bookmarks() {
    # Only asked for when there is something to list: with no bookmarks set,
    # tsm says so, and inside tmux it says so in the status line.
    local bookmarks_file="${XDG_STATE_HOME:-$HOME/.local/state}/tsm/bookmarks.json"
    local bookmarks
    if [[ -s "$bookmarks_file" ]]; then
        bookmarks=(${(f)"$(tsm bookmark-list 2>/dev/null | awk 'length($1) == 1 { c = $1; sub(/^.[[:space:]]+/, ""); print c ":" $0 }')"})
        _describe 'bookmark' bookmarks
    fi
}

_tsm_commands() {
    local commands=(
        'active:Switch to session'
        'last:Switch to the most recent session that is still open'
        'kill:Kill a session'
        'dir:Browse/start session at directory'
        'git:Browse git repositories with fzf'
        'worktree:Browse worktrees for current git repo session'
        'bookmark:Browse/start session at a bookmarked directory'
        'bookmark-add:Bookmark a directory at a character'
        'bookmark-remove:Remove a bookmark'
        'bookmark-list:List all bookmarks, or browse them with fzf'
        'bookmark-status:The open sessions bookmarks, for a tmux status line'
        'logs:Browse session logs'
        'apply-matching-config:Apply the matching configuration start hook'
        'kill-matching-config:Run the matching configuration kill hook'
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
        dir)
            _alternative \
                'directories:directory:_files -/' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        git)
            _values -s ' ' 'git options' '-b' '--brief' '-f' '--fetch' '-c' '--no-config' '-p' '--prompt-name'
            ;;
        worktree)
            _alternative \
                'worktrees:worktree:_tsm_worktrees' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        bookmark)
            _alternative \
                'bookmarks:bookmark:_tsm_bookmarks' \
                'options:option:(-c --no-config -p --prompt-name)'
            ;;
        bookmark-remove)
            _tsm_bookmarks
            ;;
        bookmark-list)
            _values -s ' ' 'bookmark-list options' '-f' '--fzf'
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
        logs)
            _tsm_log_sessions
            ;;
    esac
}

_tsm "$@"
