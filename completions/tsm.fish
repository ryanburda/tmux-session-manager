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
    set -l state_dir "$XDG_STATE_HOME"
    if test -z "$state_dir"
        set state_dir "$HOME/.local/state"
    end

    # Only asked for when there is something to list: with no bookmarks set,
    # tsm says so, and inside tmux it says so in the status line.
    if test -s "$state_dir/tsm/bookmarks.json"
        tsm bookmark-list 2>/dev/null | awk 'length($1) == 1 { c = $1; sub(/^.[[:space:]]+/, ""); print c "\t" $0 }'
    end
end

# Disable file completion by default
complete -c tsm -f

# Subcommands
complete -c tsm -n '__fish_use_subcommand' -a active -d 'Switch to session'
complete -c tsm -n '__fish_use_subcommand' -a last -d 'Switch to the most recent session that is still open'
complete -c tsm -n '__fish_use_subcommand' -a kill -d 'Kill a session'
complete -c tsm -n '__fish_use_subcommand' -a dir -d 'Browse/start session at directory'
complete -c tsm -n '__fish_use_subcommand' -a git -d 'Browse git repositories with fzf'
complete -c tsm -n '__fish_use_subcommand' -a worktree -d 'Browse worktrees for current git repo session'
complete -c tsm -n '__fish_use_subcommand' -a bookmark -d 'Browse/start session at a bookmarked directory'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-add -d 'Bookmark a directory at a character'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-remove -d 'Remove a bookmark'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-list -d 'List all bookmarks, or browse them with fzf'
complete -c tsm -n '__fish_use_subcommand' -a bookmark-status -d 'The open sessions bookmarks, for a tmux status line'
complete -c tsm -n '__fish_use_subcommand' -a match -d 'Configurations claiming a path, best first'
complete -c tsm -n '__fish_use_subcommand' -a logs -d 'Browse session logs'
complete -c tsm -n '__fish_use_subcommand' -a apply-matching-config -d 'Apply the matching configuration start hook'
complete -c tsm -n '__fish_use_subcommand' -a kill-matching-config -d 'Run the matching configuration kill hook'
complete -c tsm -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
complete -c tsm -n '__fish_seen_subcommand_from active kill' -xa '(__tsm_active_sessions)'
complete -c tsm -n '__fish_seen_subcommand_from dir' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from dir' -xa '-c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from git' -xa '-b --brief -f --fetch -c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from worktree' -xa '(__tsm_worktrees)'
complete -c tsm -n '__fish_seen_subcommand_from worktree' -xa '-c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from bookmark' -xa '(__tsm_bookmarks)'
complete -c tsm -n '__fish_seen_subcommand_from bookmark' -xa '-c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-remove' -xa '(__tsm_bookmarks)'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-list' -xa '-f --fzf'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-status' -xa '-s --style -c --current-style'
complete -c tsm -n '__fish_seen_subcommand_from bookmark-add' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from match' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from logs' -xa '(__tsm_log_sessions)'
