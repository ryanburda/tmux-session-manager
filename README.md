# tmux-session-manager

A simple tmux session manager that combines the best of [tmuxinator](https://github.com/tmuxinator/tmuxinator) and
[tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer).

Manage your tmux sessions with configuration scripts or create quick sessions from any directory.

## Features

- **Configured Sessions**: Define sessions with custom startup and cleanup scripts
- **Interactive Selection**: Use fzf to fuzzy-find and select sessions
- **Directory-based Sessions**: Create on-the-fly sessions from any directory
- **Smart Attachment**: Automatically attaches to existing sessions or switches clients when inside tmux
- **Session Lifecycle**: Run initialization scripts on start and cleanup scripts on kill

## Dependencies

- `bash/zsh`
- `tmux`
- `fzf`

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ryanburda/tmux-session-manager.git ~/git/ryanburda/tmux-session-manager
   ```

2. Symlink the `tsm` script to a directory in your PATH:
   ```bash
   mkdir -p ~/.local/bin
   ln -s ~/git/ryanburda/tmux-session-manager/tsm ~/.local/bin/tsm
   ```

3. Ensure `~/.local/bin` is in your PATH. Add this to your `.bashrc` or `.zshrc` if needed:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

## Usage

```bash
tsm                     # Interactive configured/active session selection with fzf
tsm <session-name>      # Start or attach to a specific configured/active session
tsm -l, --list          # List configured sessions
tsm -k, --kill [name]   # Kill a session (runs cleanup script if present)
tsm -d, --dir [path]    # Browse directories with fzf, or start session at path if provided
tsm -h, --help          # Show help message
```

When arguments are omitted, `tsm` uses fzf for interactive selection.
When arguments are provided, commands execute directly without prompts.
This makes `tsm` both user-friendly for daily use and suitable for scripting.

| Command | Interactive (no argument) | Scripted (with argument) |
|---------|---------------------------|--------------------------|
| `tsm` | fzf picker for configured sessions | `tsm myproject` - starts/attaches directly |
| `tsm -d` | fzf picker for directories | `tsm -d ~/code/app` - starts session at path |
| `tsm -k` | fzf picker for running sessions | `tsm -k myproject` - kills session directly |

### Examples

Interactive use:
```bash
tsm        # Opens fzf → select a session → attaches
tsm -d     # Opens fzf → select a directory → creates session
tsm -k     # Opens fzf → select a session → kills it
```

Scripted use:
```bash
# Start a specific session
tsm myproject

# Create a session at a known path
tsm -d ~/projects/webapp

# Kill a session by name
tsm -k myproject

# Start a set of microservices together
for project in api frontend backend; do
    tsm -d ~/projects/$project
done
```

## Optional tmux Keybindings

Add these to your `~/.tmux.conf` to access tsm directly from within tmux using popup windows:

```bash
bind-key s popup -h 16 -w 40 -E "tsm"
bind-key d popup -h 24 -w 80 -E "tsm -d"
bind-key X run-shell "tsm -k #{session_name}"
```

This maps:
- `prefix + s` - Open configured/active session selector
- `prefix + d` - Create a directory session
- `prefix + X` - Kill the current session and run kill script

Modify these keybindings as needed.

## Session Types

tsm supports two types of sessions:

- **Configured Sessions**: Predefined sessions stored in `~/.config/tsm/`.
These use startup scripts to create a customized tmux environment with specific windows, panes, and commands.
Ideal for projects you work on regularly that benefit from a consistent workspace setup.

- **Directory Sessions**: Quick, on-the-fly sessions created from any directory using the `-d` flag.
These simply open a new tmux session with the working directory set to your selection.
Ideal for quickly jumping into a project without any predefined configuration.

## Configured Sessions

Configured sessions work like tmuxinator sessions, but use shell scripts instead of YAML configuration files.
This gives you full control over your session setup using familiar bash/zsh commands.

Session configurations are stored in `~/.config/tsm/<session-name>/`.

Each session directory can contain:

- `start.sh` (required): Script that runs when starting the session
- `kill.sh` (optional): Script that runs asynchronously just before session is killed

### Example Session Configuration

Create a session configuration for a project:

```bash
mkdir -p ~/.config/tsm/myproject
```

Create `~/.config/tsm/myproject/start.sh`:

```bash
#!/bin/bash
SESSION="myproject"
ROOT="$HOME/projects/myproject"

# Create new session with first window named 'code'.
# This window will have two vertical splits:
#     - nvim on top 80%
#     - a terminal at the bottom 20% that runs the `ls` command
CODE_WINDOW="code"
tmux new-session -d -s "$SESSION" -n "$CODE_WINDOW" -c "$ROOT"
tmux send-keys -t "$SESSION:$CODE_WINDOW" 'nvim' Enter
tmux split-window -v -l 20% -t "$SESSION:$CODE_WINDOW" -c "$ROOT"
tmux send-keys -t "$SESSION:$CODE_WINDOW" 'ls' Enter

# Create a second window named 'docker'.
# This window will have an even-vertical layout with:
#     - a terminal that starts docker compose on top
#     - lazydocker on bottom
DOCKER_WINDOW="docker"
tmux new-window -t "$SESSION" -n $DOCKER_WINDOW -c "$ROOT"
tmux send-keys -t "$SESSION:$DOCKER_WINDOW" 'docker compose up --force-recreate --detach' Enter
tmux split-window -t "$SESSION:$DOCKER_WINDOW" -v -c "$ROOT"
tmux send-keys -t "$SESSION:$DOCKER_WINDOW" 'lazydocker' Enter
tmux select-layout -t "$SESSION:$DOCKER_WINDOW" even-vertical

# Select first window
tmux select-window -t "$SESSION:$CODE_WINDOW"

# Attach or switch to session
if [ -n "$TMUX" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
```

Optionally create `~/.config/tsm/myproject/kill.sh` for cleanup:

> **Note:** The `kill.sh` script runs in the background, allowing the tmux session to be killed immediately
without waiting for cleanup tasks to complete. This provides a snappier user experience, especially when
cleanup involves slow operations like stopping services or terminating remote connections.

```bash
#!/bin/bash
# Stop the docker compose service that was started earlier.
ROOT="$HOME/projects/myproject"
docker compose --project-directory "$ROOT" down
```

This scripting approach is slightly more verbose than tmuxinator's YAML configuration,
but offers greater control and flexibility since you can use any shell commands, conditionals, or logic you need.

See `man tmux` for a full list of available tmux commands.

## Directory Sessions

Use the `-d` flag to create a quick session from a directory:

```bash
tsm -d              # Browse directories with fzf and start session from selection
tsm -d ~/projects   # Start a session directly at ~/projects
```

When no path is provided, fzf displays your home directory and git repositories within 3 levels.
Customize this by setting the `TSM_DIRS_CMD` environment variable in your `.bashrc/.zshrc`:

```bash
export TSM_DIRS_CMD="find ~/projects -maxdepth 2 -type d"
```
