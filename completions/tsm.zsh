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

_tsm_configured_sessions() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsm"
    local sessions
    if [[ -d "$config_dir" ]]; then
        sessions=(${(f)"$(for dir in "$config_dir"/*/; do [[ -d "$dir" ]] && basename "$dir"; done 2>/dev/null)"})
        _describe 'configured session' sessions
    fi
}

_tsm() {
    local context state state_descr line
    typeset -A opt_args

    _arguments -s \
        '(-c --configured -k --kill -d --dir -z --zoxide -h --help)'{-c,--configured}'[Browse/start configured sessions]:configured session:_tsm_configured_sessions' \
        '(-c --configured -k --kill -d --dir -z --zoxide -h --help)'{-k,--kill}'[Kill a session]:active session:_tsm_active_sessions' \
        '(-c --configured -k --kill -d --dir -z --zoxide -h --help)'{-d,--dir}'[Browse/start session at directory]:directory:_files -/' \
        '(-c --configured -k --kill -d --dir -z --zoxide -h --help)'{-z,--zoxide}'[Browse/start session via zoxide]:zoxide query:' \
        '(-c --configured -k --kill -d --dir -z --zoxide -h --help)'{-h,--help}'[Show help message]' \
        '1:active session:_tsm_active_sessions'
}

_tsm "$@"
