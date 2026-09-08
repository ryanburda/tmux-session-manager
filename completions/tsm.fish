# Fish completion for tsm (Tmux Session Manager)
# Copy to ~/.config/fish/completions/tsm.fish
# Or symlink: ln -s /path/to/tsm.fish ~/.config/fish/completions/

# Helper function: get active tmux sessions
function __tsm_active_sessions
    tmux ls 2>/dev/null | awk -F: '{print $1}'
end

# Helper function: get session names with log directories
function __tsm_log_sessions
    set -l state_dir "$XDG_STATE_HOME"
    if test -z "$state_dir"
        set state_dir "$HOME/.local/state"
    end
    set -l log_dir "$state_dir/tsm/logs"

    if test -d "$log_dir"
        for dir in $log_dir/*/
            if test -d "$dir"
                basename "$dir"
            end
        end
    end
end

# Disable file completion by default
complete -c tsm -f

# Subcommands
complete -c tsm -n '__fish_use_subcommand' -a active -d 'Switch to session'
complete -c tsm -n '__fish_use_subcommand' -a last -d 'Switch to the most recent session that is still open'
complete -c tsm -n '__fish_use_subcommand' -a kill -d 'Kill a session'
complete -c tsm -n '__fish_use_subcommand' -a at -d 'Start a session at a directory'
complete -c tsm -n '__fish_use_subcommand' -a match -d 'Configurations claiming a path, best first'
complete -c tsm -n '__fish_use_subcommand' -a logs -d 'Browse session logs'
complete -c tsm -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
complete -c tsm -n '__fish_seen_subcommand_from active kill' -xa '(__tsm_active_sessions)'
# `tsm at` takes a directory and the session flags
complete -c tsm -n '__fish_seen_subcommand_from at' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from at' -xa '-c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from match' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from logs' -xa '(__tsm_log_sessions)'
