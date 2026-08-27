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
        for f in $config_dir/*.sh
            if test -f "$f"
                basename "$f" .sh
            end
        end
    end
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

# Helper function: get worktree names
function __tsm_worktrees
    git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { path = substr($0, 10) }
        /^bare$/ { path = "" }
        /^$/ { if (path != "") { n = split(path, a, "/"); print a[n]; path = "" } }
        END { if (path != "") { n = split(path, a, "/"); print a[n] } }
    '
end

# Disable file completion by default
complete -c tsm -f

# Subcommands
complete -c tsm -n '__fish_use_subcommand' -a active -d 'Switch to session'
complete -c tsm -n '__fish_use_subcommand' -a kill -d 'Kill a session'
complete -c tsm -n '__fish_use_subcommand' -a dir -d 'Browse/start session at directory'
complete -c tsm -n '__fish_use_subcommand' -a git -d 'Browse git repositories with fzf'
complete -c tsm -n '__fish_use_subcommand' -a worktree -d 'Browse worktrees for current git repo session'
complete -c tsm -n '__fish_use_subcommand' -a zoxide -d 'Browse/start session via zoxide'
complete -c tsm -n '__fish_use_subcommand' -a configured -d 'Browse/start configured sessions'
complete -c tsm -n '__fish_use_subcommand' -a logs -d 'Browse session logs'
complete -c tsm -n '__fish_use_subcommand' -a start-default -d 'Run the shared default layout'
complete -c tsm -n '__fish_use_subcommand' -a agents -d 'Browse panes running an AI agent'
complete -c tsm -n '__fish_use_subcommand' -a agent-state -d 'Record agent state on the current pane'
complete -c tsm -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
complete -c tsm -n '__fish_seen_subcommand_from active kill' -xa '(__tsm_active_sessions)'
complete -c tsm -n '__fish_seen_subcommand_from dir' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from dir' -xa '--start-default --use-default-name'
complete -c tsm -n '__fish_seen_subcommand_from git' -xa '--hide-brief --no-fetch --start-default --use-default-name'
complete -c tsm -n '__fish_seen_subcommand_from worktree' -xa '(__tsm_worktrees)'
complete -c tsm -n '__fish_seen_subcommand_from worktree' -xa '--start-default --use-default-name'
complete -c tsm -n '__fish_seen_subcommand_from zoxide' -xa '--start-default --use-default-name'
complete -c tsm -n '__fish_seen_subcommand_from configured' -xa '(__tsm_configured_sessions)'
complete -c tsm -n '__fish_seen_subcommand_from logs' -xa '(__tsm_log_sessions)'
complete -c tsm -n '__fish_seen_subcommand_from agent-state' -xa 'working blocked done idle clear'
