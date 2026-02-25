# Fish completion for tsm (Tmux Session Manager)
# Copy to ~/.config/fish/completions/tsm.fish
# Or symlink: ln -s /path/to/tsm.fish ~/.config/fish/completions/

# Helper function: get active tmux sessions
function __tsm_active_sessions
    tmux ls 2>/dev/null | awk -F: '{print $1}'
end

# Helper function: get configured session names
function __tsm_configured_sessions
    set -l config_dir "$XDG_CONFIG_HOME"
    if test -z "$config_dir"
        set config_dir "$HOME/.config"
    end
    set config_dir "$config_dir/tsm"

    if test -d "$config_dir"
        for dir in $config_dir/*/
            if test -d "$dir"
                basename "$dir"
            end
        end
    end
end

# Helper function: get session names with log files
function __tsm_log_sessions
    set -l state_dir "$XDG_STATE_HOME"
    if test -z "$state_dir"
        set state_dir "$HOME/.local/state"
    end
    set -l log_dir "$state_dir/tsm/logs"

    if test -d "$log_dir"
        for f in $log_dir/*.log
            if test -f "$f"
                basename "$f" .log
            end
        end
    end
end

# Disable file completion by default
complete -c tsm -f

# Options
complete -c tsm -s c -l configured -d 'Browse/start configured sessions' -xa '(__tsm_configured_sessions)'
complete -c tsm -s k -l kill -d 'Kill a session' -xa '(__tsm_active_sessions)'
complete -c tsm -s l -l logs -d 'Tail session logs' -xa '(__tsm_log_sessions)'
complete -c tsm -s d -l dir -d 'Browse/start session at directory' -ra '(__fish_complete_directories)'
complete -c tsm -s z -l zoxide -d 'Browse/start session via zoxide'
complete -c tsm -s h -l help -d 'Show help message'

# Default (no flag): complete with active sessions
complete -c tsm -n '__fish_is_first_arg' -xa '(__tsm_active_sessions)'
