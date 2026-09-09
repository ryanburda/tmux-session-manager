# Fish completion for tsm (Tmux Session Manager)
# Copy to ~/.config/fish/completions/tsm.fish
# Or symlink: ln -s /path/to/tsm.fish ~/.config/fish/completions/

# Disable file completion by default
complete -c tsm -f

# Subcommands
complete -c tsm -n '__fish_use_subcommand' -a at -d 'Start a session at a directory'
complete -c tsm -n '__fish_use_subcommand' -a match -d 'Configurations claiming a path, best first'
complete -c tsm -n '__fish_use_subcommand' -a init -d 'Install the tmux session-closed hook'
complete -c tsm -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
# `tsm at` takes a directory and the session flags
complete -c tsm -n '__fish_seen_subcommand_from at' -ra '(__fish_complete_directories)'
complete -c tsm -n '__fish_seen_subcommand_from at' -xa '-c --no-config -p --prompt-name'
complete -c tsm -n '__fish_seen_subcommand_from match' -ra '(__fish_complete_directories)'
