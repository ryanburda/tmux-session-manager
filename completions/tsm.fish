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

# Helper function: get worktree names
function __tsm_worktrees
    git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { path = substr($0, 10) }
        /^bare$/ { path = "" }
        /^$/ { if (path != "") { n = split(path, a, "/"); print a[n]; path = "" } }
        END { if (path != "") { n = split(path, a, "/"); print a[n] } }
    '
end

# Helper function: get bookmark characters and their directories
function __tsm_bookmarks
    # The bookmark picker's own rows: character, directory, then the column
    # it displays -- which makes a fine completion description.
    tsm _bookmark-entries 2>/dev/null | awk -F'\t' '{ d = $3; sub(/^[^ ]+ +/, "", d); print $1 "\t" d }'
end

# Helper function: get the tsm-* programs on PATH, which tsm runs as
# `tsm <name>` when <name> is not one of its own commands
function __tsm_external_commands
    tsm _external-commands 2>/dev/null
end

# Helper function: the picker names create-or-switch takes
function __tsm_pickers
    tsm _pickers 2>/dev/null
end

# Disable file completion by default
complete -c tsm -f

# Subcommands
complete -c tsm -n '__fish_use_subcommand' -a active -d 'Switch to session'
complete -c tsm -n '__fish_use_subcommand' -a last -d 'Switch to the most recent session that is still open'
complete -c tsm -n '__fish_use_subcommand' -a kill -d 'Kill a session'
complete -c tsm -n '__fish_use_subcommand' -a create-or-switch -d 'Start a session at the directory a picker names'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-add -d 'Bookmark a directory at a character'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-remove -d 'Remove a bookmark'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-status -d 'The open sessions bookmarks, for a tmux status line'
complete -c tsm -n '__fish_use_subcommand' -a match -d 'Configurations claiming a path, best first'
complete -c tsm -n '__fish_use_subcommand' -a logs -d 'Browse session logs'
complete -c tsm -n '__fish_use_subcommand' -a help -d 'Show help message'
complete -c tsm -n '__fish_use_subcommand' -a '(__tsm_external_commands)' -d 'External command'

# Subcommand arguments
complete -c tsm -n '__fish_seen_subcommand_from active kill' -xa '(__tsm_active_sessions)'
# create-or-switch takes a picker first, then the session flags and whatever
# argument that picker takes
complete -c tsm -n '__fish_seen_subcommand_from create-or-switch; and not __fish_seen_subcommand_from (__tsm_pickers)' -xa '(__tsm_pickers)'
complete -c tsm -n '__fish_seen_subcommand_from create-or-switch; and __fish_seen_subcommand_from dir git' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from create-or-switch; and __fish_seen_subcommand_from worktree' -xa '(__tsm_worktrees)'
complete -c tsm -n '__fish_seen_subcommand_from create-or-switch; and __fish_seen_subcommand_from bookmark' -xa '(__tsm_bookmarks)'
complete -c tsm -n '__fish_seen_subcommand_from create-or-switch' -xa '-c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-remove' -xa '(__tsm_bookmarks)'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-status' -xa '-s --style -c --current-style'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-add' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from match' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from logs' -xa '(__tsm_log_sessions)'
