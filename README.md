# tmux-session-manager

A simple tmux session manager

- **Create** sessions rooted at directories, git worktrees, or defined by configuration scripts
- **Switch** between active sessions
- **Kill** sessions with optional cleanup scripts

## Dependencies

- `fzf`
- `zoxide` (optional)

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

4. (Optional) Install shell completions:

   Completions provide:
   - Active session names for `tsm` and `tsm -k`
   - Directory completion for `tsm -d`
   - Configured session names for `tsm -c` and `tsm -l`

   <details>
   <summary><strong>Bash</strong></summary>

   Add to your <code>~/.bashrc</code>:

   ```bash
   source ~/git/ryanburda/tmux-session-manager/completions/tsm.bash
   ```

   </details>

   <details>
   <summary><strong>Zsh</strong></summary>

   Add to your <code>~/.zshrc</code>:

   ```bash
   fpath=(~/git/ryanburda/tmux-session-manager/completions $fpath)
   autoload -Uz compinit && compinit
   ```
   Or rename `tsm.zsh` to `_tsm` and place in an existing fpath directory.

   </details>

   <details>
   <summary><strong>Fish</strong></summary>

   Symlink to fish completions directory:

   ```bash
   ln -s ~/git/ryanburda/tmux-session-manager/completions/tsm.fish ~/.config/fish/completions/
   ```

   </details>

## Usage

```bash
tsm [session]                  # Browse active sessions with fzf, or switch to session if provided
tsm -c, --configured [session] # Browse configured sessions with fzf, or start session if provided
tsm -d, --dir [path]           # Browse directories with fzf, or start session at path if provided
tsm -h, --help                 # Show help message
tsm -k, --kill [session]       # Kill a session (runs cleanup script if present)
tsm -l, --logs [session]       # Browse all log files, or for named session if provided
tsm -w, --worktree [name]      # Browse worktrees for current git repo with fzf, or start worktree if provided
tsm -z, --zoxide [query]       # Browse zoxide entries with fzf, or start session at best match if provided
```

When session/path arguments are omitted, `tsm` uses fzf for interactive selection.
When creating a new session with `tsm -d`, `tsm -z`, or `tsm -w`, you are prompted
to confirm or override the suggested session name before the session is created.

## tmux Keybindings

`tsm` is best used with tmux keybinds which can be added to your `~/.tmux.conf`:

```bash
bind-key s popup -E "tsm"
bind-key c popup -E "tsm -c"
bind-key d popup -E "tsm -d"
bind-key k popup -E "tsm -k"
bind-key l popup -E "tsm -l"
bind-key w popup -E "tsm -w"
bind-key X run-shell "tsm -k #{session_name}"

# OPTIONAL
bind-key z popup -h 24 -w 80 -E "tsm -z"
```

This maps:
- `prefix + s` - Active session switcher
- `prefix + c` - Configured session launcher
- `prefix + d` - Directory session launcher
- `prefix + k` - Kill session selector
- `prefix + l` - Browse logs
- `prefix + w` - Worktree session launcher
- `prefix + X` - Kill the current session and run kill script

And optionally maps:
- `prefix + z` - Zoxide directory session launcher

Modify these keybindings as needed.

<details>
<summary><strong style="font-size: 1.25em;">Troubleshooting Keybinds</strong></summary>

> tmux's `run-shell` and `popup -E` commands execute in a non-interactive, non-login shell.
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
> 
> **Note:** If you specify a custom `TSM_DIRS_CMD`, add it to the same file where you configure your PATH
> (e.g., `~/.zshenv` for zsh). Otherwise, `tsm -d` will use the default directory list in a tmux popup
> but a different custom list from an interactive shell, leading to inconsistent behavior.

</details>

## Session Launcher Types

Sessions can be launched in three different ways:

- **[Directory Sessions](#directory-sessions)**: Open a new tmux session rooted at a specific directory.
Ideal for quickly jumping into a project.

- **[Worktree Sessions](#worktree-sessions)**: Open a new tmux session rooted at a git worktree directory.
Ideal for parallelizing work across multiple branches of the same project.

- **[Configured Sessions](#configured-sessions)**: Script up your perfect window/pane layout. Great for
automating tasks like starting up services when a session starts. Ideal for projects you work on regularly
to keep things consistent and reproducible.

## Directory Sessions

Use the `-d` flag to create a session rooted at a specific directory:

```bash
tsm -d                   # Browse directories with fzf and start session from selection
tsm -d ~/code/projectA   # Start a session directly at ~/code/projectA
```

When no path is provided, fzf by default displays all non-hidden directories within 4 levels deep of your
`$HOME` directory. This can be changed by setting the `TSM_DIRS_CMD` environment variable in your `.bashrc/.zshenv`.

<details>
<summary><strong style="font-size: 1.25em;">Modifying <code>TSM_DIRS_CMD</code></strong></summary>

> `TSM_DIRS_CMD` can be set to any command that returns directories.
>
> The following example shows:
> - directories 1 level deep in the `$HOME` directory
> - directories 4 levels deep in `$HOME/code` while also pruning the search once it finds the root of a git repo
>
> ```bash
> export TSM_DIRS_CMD='{
>   find "$HOME" -maxdepth 1 -name ".*" -prune -o -type d -print;
>   find "$HOME/code" -maxdepth 4 -name ".*" -prune -o -type d \( -exec test -e {}/.git \; -print -prune -o -print \);
> }'
> ```

</details>

<details><summary><strong style="font-size: 1.25em;">Zoxide Integration (Optional)</strong></summary>

> If you have **[zoxide](https://github.com/ajeetdsouza/zoxide)** installed, you can use the `-z` flag to create
> sessions from your zoxide directory history:
>
> ```bash
> tsm -z              # Browse zoxide entries interactively and start session from selection
> tsm -z proj         # Start a session at the best zoxide match for "proj"
> ```
>
> Zoxide tracks directories you visit frequently, ranking them by "frecency" (frequency + recency). This makes
> it easy to jump to projects with just a few characters of the directory name.
>
> When no query is provided, `tsm -z` uses `zoxide query -i` for interactive selection with fzf. When a query is
> provided, it uses `zoxide query` to find the best match directly.

</details>

## Worktree Sessions

A worktree session is a tmux session dedicated to a git worktree. Run `tsm -w` from within a git repo to
browse its worktrees. On creation the sessions working directory will be set to the worktree directory.

This works with both bare repositories and regular git repos, and worktrees can live anywhere on the filesystem.

> **Note:** `tsm` only creates tmux sessions for your worktrees. It does not contain any functionality related
> to worktree management.

## Configured Sessions

Configured sessions provide more control when starting a session. Session configurations are shell scripts
stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<session-name>.sh`.

Each session file defines:
  - `ROOT` (required): Path to the project root directory.
  - `start()` (required): Customizes the tmux session. tsm creates the session before calling `start()`, which receives:
    - `$1`=session name
    - `$2`=working directory
    - `$3`=log directory
  - `kill()` (optional): Runs asynchronously when the session is killed. Receives the same arguments as `start()`.

### Example Session Configuration

Create a session configuration for a project at `~/.config/tsm/myproject.sh`:

```bash
ROOT="$HOME/projects/myproject"

start() {
  local session="$1"
  local root="$2"
  local log_dir="$3"

  # Rename the first window to 'code'.
  # This window will have two vertical splits:
  #     - nvim on top 80%
  #     - a terminal at the bottom 20% that runs the `ls` command
  tmux rename-window -t "$session" "code"
  tmux send-keys -t "$session:code" 'nvim' Enter
  tmux split-window -v -l 20% -t "$session:code" -c "$root"
  tmux send-keys -t "$session:code" 'ls' Enter

  # Create a second window named 'docker'.
  # This window will have an even-vertical layout with:
  #     - a terminal that starts docker compose on top
  #     - lazydocker on bottom
  tmux new-window -t "$session" -n "docker" -c "$root"
  tmux send-keys -t "$session:docker" 'docker compose up --force-recreate --detach' Enter
  tmux split-window -t "$session:docker" -v -c "$root"
  tmux send-keys -t "$session:docker" 'lazydocker' Enter
  tmux select-layout -t "$session:docker" even-vertical

  # Select first window
  tmux select-window -t "$session:code"
}

# Optional: cleanup function runs in background when session is killed.
# This allows the tmux session to be killed immediately without waiting for
# cleanup tasks to complete, providing a snappier user experience especially
# when cleanup involves slow operations like stopping services.
kill() {
  local root="$2"

  # Stop the docker compose service that was started earlier.
  docker compose --project-directory "$root" down
}
```

> See `man tmux` for a full list of available tmux specific commands.

### Logging

Output from `start()` and `kill()` functions is redirected to a dedicated log file at
`${XDG_STATE_HOME:-~/.local/state}/tsm/logs/<session-name>/tsm.log`. Each configured session
gets its own log directory (e.g. `~/.local/state/tsm/logs/myproject/`). The `tsm.log` file is
wiped on each call to `start()` or `kill()`, so it only contains output from the most recent
invocation. This prevents log files from growing unbounded.

Use `tsm -l` to browse all log files across sessions with fzf. The fzf preview pane shows the
tail of the currently highlighted file. Use `tsm -l <name>` to browse logs for a specific session.

<details>
<summary><strong style="font-size: 1.25em;">Advanced Configuration Examples</strong></summary>

Since each session file is a full shell script, you're not limited to running commands inside tmux panes and windows.
You can kick off commands in the background with `&` so they don't block session startup. The session attaches
immediately while the command continues running, and its output is captured in the log file for later review.

```bash
ROOT="$HOME/projects/webapp"

start() {
  local session="$1"
  local root="$2"
  local log_dir="$3"

  tmux rename-window -t "$session" "code"
  tmux send-keys -t "$session:code" 'nvim' Enter

  # Start a service in the background so it doesn't block session startup.
  # Build output and errors are captured in the tsm log file.
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting my webapp"
  docker compose --project-directory "$root" up --build --force-recreate --detach &
}

kill() {
  local session="$1"
  local root="$2"
  local log_dir="$3"

  echo "$(date '+%Y-%m-%d %H:%M:%S'): Stopping my webapp"
  docker compose --project-directory "$root" down
}
```

This logging approach works well for simple cases, but output from multiple backgrounded processes runs
the risk of being interleaved in the log file since they all write to the same location concurrently.
To get around this, both `start()` and `kill()` receive the session log directory as their third argument (`$3`).
You can use this to write additional log files alongside `tsm.log`, keeping all logs for a session organized in
one place:

```bash
ROOT="$HOME/projects/webapp"

DOCKER_LOG_FILE="docker.log"
POSTGRES_LOG_FILE="postgres.log"

start() {
  local session="$1"
  local root="$2"
  local log_dir="$3"

  tmux rename-window -t "$session" "code"
  tmux send-keys -t "$session:code" 'nvim' Enter

  # Redirect each process to its own log file to avoid interleaving.
  docker compose --project-directory "$root" up --build --force-recreate --detach > "$log_dir/$DOCKER_LOG_FILE" 2>&1 &
  pg_ctl -D "$root/data/postgres" -l "$log_dir/$POSTGRES_LOG_FILE" start
}

kill() {
  local session="$1"
  local root="$2"
  local log_dir="$3"

  # Run cleanup tasks in parallel so one doesn't block the other.
  docker compose --project-directory "$root" down > "$log_dir/$DOCKER_LOG_FILE" 2>&1 &
  pg_ctl -D "$root/data/postgres" -l "$log_dir/$POSTGRES_LOG_FILE" stop &
}
```

This produces the following log structure which will be searchable when using `tsm -l`:

```
~/.local/state/tsm/logs/webapp/
├── docker.log
├── postgres.log
└── tsm.log
```

> **NOTE:** Prefer `>` (overwrite) over `>>` (append) when redirecting to log files. This matches how
> `tsm.log` behaves by only keeping the output from the most recent invocation.

> **NOTE:** Background cleanup tasks in `kill()` with `&` so they run in parallel. Although `kill()`
> itself runs asynchronously, commands within it still run sequentially — if one hangs or is slow, it
> will block the rest.

</details>


## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
