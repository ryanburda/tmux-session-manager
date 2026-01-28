# tmux-session-manager

A simple tmux session manager that lets you:

- **Switch** between active tmux sessions
- **Create** sessions rooted at a directory
- **Start** configured sessions with custom startup scripts
- **Kill** sessions (with optional cleanup scripts)

## Features

- **Interactive Selection**: Use `fzf` to fuzzy-find and select sessions
- **Configured Sessions**: Define sessions with custom startup and cleanup scripts (Similar to **[tmuxinator](https://github.com/tmuxinator/tmuxinator)**)
- **Directory-based Sessions**: Create sessions rooted at a specific directory (Similar to **[tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer)**)
    - Optional **[Zoxide](https://github.com/ajeetdsouza/zoxide)** support

## Dependencies

- `bash/zsh`
- `tmux`
- `fzf`
- `zoxide` (optional, for `-z` flag)

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
tsm [session]                  # Browse active sessions with fzf, or switch to session if provided
tsm -c, --configured [session] # Browse configured sessions with fzf, or start session if provided
tsm -d, --dir [path]           # Browse directories with fzf, or start session at path if provided
tsm -z, --zoxide [query]       # Browse zoxide entries with fzf, or start session at best match if provided
tsm -k, --kill [session]       # Kill a session (runs cleanup script if present)
tsm -h, --help                 # Show help message
```

When session/path arguments are omitted, `tsm` uses fzf for interactive selection.
When session/path arguments are provided, commands execute directly without prompts.
This makes `tsm` both user-friendly for daily use and suitable for scripting.

### Examples

Interactive use:
```bash
tsm        # Opens fzf → select an active session → attaches
tsm -c     # Opens fzf → select a configured session → starts it
tsm -d     # Opens fzf → select a directory → creates session
tsm -z     # Opens fzf → select from zoxide entries → creates session
tsm -k     # Opens fzf → select a session → kills it
```

Scripted use:
```bash
# Start a configured session
tsm -c myproject

# Switch to an active session
tsm myproject

# Create a session rooted at a specific path
tsm -d ~/projects/webapp

# Create a session using zoxide's best match
tsm -z proj

# Kill a session by name
tsm -k myproject

# Start a set of microservices together
for project in api frontend backend; do
    tsm -d ~/projects/$project
done
```

## tmux Keybindings

The real power of `tsm` is when it's used with tmux keybindings to launch fuzzy finding switchers and launchers.
Add the following to your `~/.tmux.conf`:

```bash
bind-key s popup -h 24 -w 60 -E "tsm"
bind-key c popup -h 24 -w 80 -E "tsm -c"
bind-key d popup -h 24 -w 80 -E "tsm -d"
bind-key k popup -h 24 -w 60 -E "tsm -k"
bind-key X run-shell "tsm -k #{session_name}"

# OPTIONAL
bind-key z popup -h 24 -w 80 -E "tsm -z"
```

This maps:
- `prefix + s` - Active session switcher
- `prefix + c` - Configured session launcher
- `prefix + d` - Directory rooted session launcher
- `prefix + z` - Zoxide directory rooted session launcher (Optional)
- `prefix + k` - Kill session selector
- `prefix + X` - Kill the current session and run kill script

Modify these keybindings as needed.

> **Note:** tmux's `run-shell` and `popup -E` commands execute in a non-interactive, non-login shell.
> For `tsm` to be found, it must be in your PATH when this shell starts.
>
> **For zsh users:** Add your PATH configuration to `~/.zshenv` (not `.zshrc`).
>
> **For bash users:** Set the `BASH_ENV` environment variable to point to a file that configures your PATH,
> or add your PATH to `/etc/environment`.
>
> **Shell startup file precedence:**
>
> | Shell | Login | Interactive | Non-interactive |
> |-------|-------|-------------|-----------------|
> | **zsh** | zshenv → zprofile → zshrc → zlogin | zshenv → zshrc | zshenv only |
> | **bash** | /etc/profile → (~/.bash_profile OR ~/.bash_login OR ~/.profile) | ~/.bashrc | $BASH_ENV only (if set) |
>
> Since tmux runs commands non-interactively, zsh only sources `~/.zshenv` and bash only sources the file
> specified by `$BASH_ENV` (if set). This is why PATH modifications in `.zshrc` or `.bashrc` won't apply.
>
> **Fallback:** If configuring shell startup files isn't working, you can execute `tsm` using its full path
> in your keybindings:
>
> ```bash
> bind-key s popup -h 24 -w 60 -E "~/git/ryanburda/tmux-session-manager/tsm"
> bind-key d popup -h 24 -w 80 -E "~/git/ryanburda/tmux-session-manager/tsm -d"
> bind-key X run-shell "~/git/ryanburda/tmux-session-manager/tsm -k #{session_name}"
> ```
>
> Adjust the path to match where you cloned the repository.

> **Note:** If you specify a custom `TSM_DIRS_CMD`, add it to the same file where you configure your PATH
> (e.g., `~/.zshenv` for zsh). Otherwise, `tsm -d` will use the default directory list in a tmux popup
> but a different custom list from an interactive shell, leading to inconsistent behavior.

## Session Types

tsm supports two types of sessions:

- **Configured Sessions**: Predefined sessions stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/`.
These use startup scripts to create a customized tmux environment with specific windows, panes, and commands.
Ideal for projects you work on regularly that benefit from a consistent workspace setup.

- **Directory Sessions**: Quick, on-the-fly sessions rooted at any directory using the `-d` flag.
These simply open a new tmux session with the working directory set to your selection.
Ideal for quickly jumping into a project without any predefined configuration.

## Configured Sessions

Configured sessions work like [tmuxinator](https://github.com/tmuxinator/tmuxinator) sessions, but use shell scripts
instead of YAML configuration files. This gives you full control over your session setup using familiar bash/zsh commands.

Session configurations are stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<session-name>/`.

Each session directory can contain:

- `start.sh` (required): Script that runs when starting the session
- `kill.sh` (optional): Script that runs asynchronously just before session is killed

### Example Session Configuration

Create a session configuration for a project:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/tsm/myproject"
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

Use the `-d` flag to create a session rooted at a specific directory:

```bash
tsm -d              # Browse directories with fzf and start session from selection
tsm -d ~/projects   # Start a session directly at ~/projects
```

When no path is provided, fzf displays your home directory and any directories that contain git repositories
within 3 levels deep of your $HOME directory.

This can be customized by setting the `TSM_DIRS_CMD` environment variable in your `.bashrc/.zshrc`:

The following is a slight variation the default that returns:
- the $HOME directory
- directories in your `$HOME` directory that contain git repos (1 level deep)
- directories in your `$HOME/projects` directory that contain git repos (up to 3 levels deep)

```bash
export TSM_DIRS_CMD='{
    echo "$HOME"
    find "$HOME" -maxdepth 2 -name .git -type d 2>/dev/null | sed "s|/.git$||"
    find "$HOME/projects" -maxdepth 4 -name .git -type d 2>/dev/null | sed "s|/.git$||"
}'
```
This is a more targeted search which may be slightly faster as a result.

### Zoxide Integration (Optional)

If you have **[zoxide](https://github.com/ajeetdsouza/zoxide)** installed, you can use the `-z` flag to create sessions from your zoxide directory history:

```bash
tsm -z              # Browse zoxide entries interactively and start session from selection
tsm -z proj         # Start a session at the best zoxide match for "proj"
```

Zoxide tracks directories you visit frequently, ranking them by "frecency" (frequency + recency). This makes it easy to jump to projects with just a few characters of the directory name.

When no query is provided, `tsm -z` uses `zoxide query -i` for interactive selection with fzf. When a query is provided, it uses `zoxide query` to find the best match directly.
