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

_tsm_configured_sessions() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsm"
    local sessions
    if [[ -d "$config_dir" ]]; then
        sessions=(${(f)"$(for f in "$config_dir"/*.sh; do [[ -f "$f" ]] && basename "$f" .sh; done 2>/dev/null)"})
        _describe 'configured session' sessions
    fi
}

_tsm_commands() {
    local commands=(
        'active:Switch to session'
        'kill:Kill a session'
        'dir:Browse/start session at directory'
        'git:Browse git repositories with fzf'
        'worktree:Browse worktrees for current git repo session'
        'zoxide:Browse/start session via zoxide'
        'configured:Browse/start configured sessions'
        'logs:Browse session logs'
        'apply-default-config:Apply the shared default configuration'
        'agents:Browse panes running an AI agent'
        'agent-state:Record agent state on the current pane'
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
                'options:option:(-c --no-custom-config -d --no-default-config -p --prompt-name)'
            ;;
        git)
            _values -s ' ' 'git options' '-b' '--brief' '-f' '--fetch' '-c' '--no-custom-config' '-d' '--no-default-config' '-p' '--prompt-name'
            ;;
        worktree)
            _alternative \
                'worktrees:worktree:_tsm_worktrees' \
                'options:option:(-c --no-custom-config -d --no-default-config -p --prompt-name)'
            ;;
        zoxide)
            _values 'zoxide options' '-c' '--no-custom-config' '-d' '--no-default-config' '-p' '--prompt-name'
            ;;
        configured)
            _tsm_configured_sessions
            ;;
        logs)
            _tsm_log_sessions
            ;;
        agent-state)
            _values 'state' working blocked done idle clear
            ;;
    esac
}

_tsm "$@"
