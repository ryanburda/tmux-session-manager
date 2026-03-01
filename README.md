# tmux-session-manager

A simple tmux session manager that lets you:

- **Switch** between active tmux sessions
- **Create** sessions rooted at a directory
    - Similar to **[tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer)**
    - Optional **[Zoxide](https://github.com/ajeetdsouza/zoxide)** support
- **Start** configured sessions with custom startup scripts
    - Similar to **[tmuxinator](https://github.com/tmuxinator/tmuxinator)**
- **Kill** sessions (with optional cleanup scripts)

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
   - Directory completion for `tsm -d` and `tsm -z`
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
tsm -z, --zoxide [query]       # Browse zoxide entries with fzf, or start session at best match if provided
tsm -k, --kill [session]       # Kill a session (runs cleanup script if present)
tsm -l, --logs [session]       # Browse all log files, or for named session if provided
tsm -h, --help                 # Show help message
```

When session/path arguments are omitted, `tsm` uses fzf for interactive selection.
When session/path arguments are provided, commands execute directly without prompts.
This makes `tsm` both user-friendly for daily use and suitable for scripting.

## tmux Keybindings

`tsm` is best used with tmux keybinds which can be added to your `~/.tmux.conf`:

```bash
bind-key s popup -E "tsm"
bind-key c popup -E "tsm -c"
bind-key d popup -E "tsm -d"
bind-key k popup -E "tsm -k"
bind-key k popup -E "tsm -l"
bind-key X run-shell "tsm -k #{session_name}"

# OPTIONAL
bind-key z popup -h 24 -w 80 -E "tsm -z"
```

This maps:
- `prefix + s` - Active session switcher
- `prefix + c` - Configured session launcher
- `prefix + d` - Directory rooted session launcher
- `prefix + k` - Kill session selector
- `prefix + l` - Browse logs
- `prefix + X` - Kill the current session and run kill script

And optionally maps:
- `prefix + z` - Zoxide directory rooted session launcher

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

`tsm` allows you to launch sessions in two different ways:

- **[Directory Sessions](#directory-sessions)**: Open a new tmux session rooted at a specific directory.
Ideal for quickly jumping into a project without any predefined configuration.

- **[Configured Sessions](#configured-sessions)**: Ideal for projects you work on regularly that benefit from
a consistent tmux window/pane layout. These use a script stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/` that
control how the session is created and killed.

## Directory Sessions

Use the `-d` flag to create a session rooted at a specific directory:

```bash
tsm -d              # Browse directories with fzf and start session from selection
tsm -d ~/projects   # Start a session directly at ~/projects
```

When no path is provided, fzf by default displays your `$HOME` directory and any directories that contain git
repositories within 4 levels deep of your `$HOME` directory. This can be changed by setting the `TSM_DIRS_CMD`
environment variable in your `.bashrc/.zshrc`. You likely only need to change this if `tsm -d` lags on start
or specific directories are missing in the result.

<details>
<summary><strong style="font-size: 1.25em;">Overriding <code>TSM_DIRS_CMD</code></strong></summary>

> The following is a slight variation the default that returns:
> - the `$HOME` directory
> - directories in your `$HOME` directory that contain git repos (1 level deep)
> - directories in your `$HOME/projects` directory that contain git repos (up to 3 levels deep)
> 
> ```bash
> export TSM_DIRS_CMD='{
>     echo "$HOME"
>     find "$HOME/projects" -maxdepth 3 -name .git -type d 2>/dev/null | sed "s|/.git$||"
>     find "$HOME/projects" -maxdepth 3 -name .bare -type d 2>/dev/null | sed "s|/.bare$||"
>     find "$HOME/projects" -maxdepth 3 -name HEAD -not -path "*/.git/*" 2>/dev/null | while read -r f; do
>         d=$(dirname "$f")
>         if [ -d "$d/objects" ] && [ -d "$d/refs" ]; then
>             case "$(basename "$d")" in .bare) dirname "$d" ;; *) echo "$d" ;; esac
>         fi
>     done
> }'
> ```
> This is a more targeted search rooted at `$HOME/projects` which may be slightly faster as a result.
> 
> The following lists all directories in your `$HOME` directory:
> 
> ```bash
> export TSM_DIRS_CMD='find "$HOME" -type d 2>/dev/null'
> ```
> 
> **Note:** This will likely be slow to produce the full result since it recursively walks every
> directory under `$HOME`. However, fzf will begin displaying results as they stream in so you
> can start searching before the full list is ready.

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

## Configured Sessions

Configured sessions provide more control when starting a session. Session configurations are shell scripts
stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<session-name>/`.

Each session directory is required to have a `main.sh` script that defines:
  - `ROOT` (required): Path to the project root directory. tsm auto-detects git type from ROOT to enable worktree support.
  - `start()` (required): Customizes the tmux session. tsm creates the session before calling `start()`, which receives `$1`=session name, `$2`=working directory, `$3`=log directory.
  - `kill()` (optional): Runs asynchronously when the session is killed. Receives the same arguments as `start()`.

### Example Session Configuration

Create a session configuration for a project:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/tsm/myproject"
```

Create `~/.config/tsm/myproject/main.sh`:

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
  local session="$1"
  local root="$2"
  local log_dir="$3"

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

> NOTE: The `tsm -l` `ctrl-o` keybind opens the selected log file in `$EDITOR` (falls back to `vi` if not set)

<details>
<summary><strong style="font-size: 1.25em;">Advanced Configuration Examples</strong></summary>

Since `main.sh` is a full shell script, you're not limited to running commands inside tmux panes and windows.
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

## Optional Features

### Worktree Sessions

A worktree session is a tmux session dedicated to a git worktree, where the session's working directory is the worktree directory itself.

Git worktrees allow you to have multiple branches checked out at the same time in separate working directories. `tsm` piggybacks off this to seamlessly launch dedicated tmux sessions for your worktrees as needed, using `/` as a session name delimiter (e.g., `myproject/main`, `myproject/feature`).

This works with both bare repositories and regular git repos.

#### Why Worktree Sessions?

`cd`ing in and out of worktree folders is not difficult. The problem comes when you want to do work in two different worktrees in parallel.

<details>
<summary><strong style="font-size: 1.25em;">Workflow 1: Windows and Splits (Good)</strong></summary>

> If you're using `tsm` then you are likely already familiar with tmux's pane splitting and windowing commands.
> Your current workflow probably looks something like:
>
> 1. `cd <repo>/<worktree1>`
> 2. Do work...
> 3. Realize you need to do something else in a different branch
> 4. Create a new window or split
> 5. In the new window/split run `cd ../worktree2`
> 6. Do more work...
>
> In this workflow your layer of isolation between worktrees is the dedicated window or split you created. You can
> jump between these two locations to parallelize your work. This is fine, but it can be made better.

</details>

<details>
<summary><strong style="font-size: 1.25em;">Workflow 2: Manual Sessions (Better)</strong></summary>

> A better workflow is to create a dedicated tmux session when you want to do work in a different worktree. This is
> similar to Workflow 1, but instead of creating a split or window for the worktree, you create a new tmux session.
>
> Now your layer of isolation between worktrees is a tmux session. This is significantly better since you're less
> likely to mistake which worktree you're operating on, especially if you give your sessions distinct names.

</details>

<details open>
<summary><strong style="font-size: 1.25em;">Workflow 3: tsm (Best)</strong></summary>

> The `tsm` workflow is an automated version of Workflow 2 via `tsm -w`. This pulls up a worktree picker for the
> current session and automatically creates a new tmux session with its working directory set to the chosen worktree.
> The session name is set to `<repo>/<worktree>` to clearly distinguish active sessions based in different worktrees.
>
> This is especially helpful for agentic workflows. Tmux sessions provide a layer of isolation between different
> worktrees of the same project. Combined with [configured sessions](#configured-sessions), this allows you to
> effortlessly duplicate your preferred tmux window/split setup as many times as you want — parallelizing distinct
> tasks in a familiar, custom-tailored environment with zero setup cost.
>
> For example, you can create a worktree session for a large refactor ticket and delegate that work to an AI agent
> to get things started. Meanwhile, in another worktree session, you can continue coding by hand.

</details>

> **Note:** `tsm -w` only works from inside an existing tmux session that contains a repo with worktrees.
> You cannot call `tsm -w` outside of tmux.

> **Note:** `tsm` does not manage your git worktrees — it only creates tmux sessions for them. Creating,
> deleting, and otherwise managing worktrees is done with `git worktree` directly or with other tools.

#### Default Worktree

The worktree workflow in `tsm` relies on a default worktree. When `tsm -d` or `tsm -c` detects a bare repo, it
will always drop you into the default worktree. This means you don't have to think about worktrees until you
choose to start a new session for a different one.

The default worktree name is `main` but can be changed with the `TSM_DEFAULT_WORKTREE_NAME` environment variable.

#### Setup

Create a bare repo and add a worktree:

```bash
git clone --bare git@github.com:user/myproject.git myproject
cd myproject
git worktree add main main
```

<details>
<summary><strong style="font-size: 1.25em;">Alternative: <code>.bare</code> convention</strong></summary>

> Some people prefer cloning into a `.bare` subdirectory to keep git internals separate from worktrees:
>
> ```bash
> git clone --bare git@github.com:user/myproject.git myproject/.bare
> cd myproject
> git --git-dir=.bare worktree add main main
> ```
>
> This produces a cleaner layout:
>
> ```
> myproject/
> ├── .bare/       ← git internals hidden here
> ├── main/        ← worktrees are clean siblings
> └── feature/
> ```
>
> vs the standard layout where git internals and worktrees are mixed together:
>
> ```
> myproject/
> ├── HEAD
> ├── config
> ├── objects/
> ├── refs/
> ├── main/
> └── feature/
> ```
>
> `tsm` supports both conventions automatically.

</details>

When you run `tsm -d` and select a bare repo directory, `tsm` will automatically:
1. Use an existing worktree if one exists, or create the default worktree
2. Name the session `repo/worktree` (e.g., `myproject/main`)
3. Set `TSM_REPO_ROOT` on the session for worktree commands

When you run `tsm -d` and select a regular git repo directory, `tsm` will set `TSM_REPO_ROOT` so that `tsm -w` works from the session.

#### Switching Worktrees

From inside a git repo session, switch between worktrees:

```bash
tsm -w              # Browse existing worktrees with fzf and switch to selection
```

Suggested tmux keybinding:

```bash
bind-key w popup -E "tsm -w"
```

#### Configured Sessions with Worktrees

Worktree support is automatically enabled when `ROOT` points to a bare git repository. When this is detected, `tsm` will:
- Use an existing worktree or create the default worktree if needed
- Name the session `config/worktree` (e.g., `myproject/main`)
- Pass the worktree path as `$2` (working directory) to `start()` and `kill()`

When `ROOT` points to a regular git repo, `tsm` sets `TSM_REPO_ROOT` so that `tsm -w` works from the session.

No special handling is needed in `start()` or `kill()` — tsm resolves the working directory automatically:

```bash
ROOT="$HOME/projects/myproject"

start() {
  local session="$1"      # e.g. "myproject" or "myproject/feature"
  local root="$2"         # ROOT, or worktree path if worktree session
  local log_dir="$3"

  # Session already created by tsm with cwd=$root
  tmux rename-window -t "$session" "code"
  tmux send-keys -t "$session:code" 'nvim' Enter
}

kill() {
  local session="$1"
  local root="$2"
  local log_dir="$3"
  # cleanup tasks...
}
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
