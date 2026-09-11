# Fish completion for dirsesh (one tmux session per directory)
# Copy to ~/.config/fish/completions/dirsesh.fish
# Or symlink: ln -s /path/to/dirsesh.fish ~/.config/fish/completions/

# Disable file completion by default
complete -c dirsesh -f

# Subcommands
complete -c dirsesh -n '__fish_use_subcommand' -a at -d 'Start a session at a directory'
complete -c dirsesh -n '__fish_use_subcommand' -a match -d 'Configurations claiming a path, best first'
complete -c dirsesh -n '__fish_use_subcommand' -a init -d 'Install the tmux session-closed hook'
complete -c dirsesh -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
# `dirsesh at` takes a directory and the session flags
complete -c dirsesh -n '__fish_seen_subcommand_from at' -ra '(__fish_complete_directories)'
complete -c dirsesh -n '__fish_seen_subcommand_from at' -xa '-c --no-config -p --prompt-name'
complete -c dirsesh -n '__fish_seen_subcommand_from match' -ra '(__fish_complete_directories)'
