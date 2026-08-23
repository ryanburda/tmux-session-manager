# tmux-session-manager

A simple tmux session manager

- **Create** sessions rooted at directories or defined by configuration scripts
- **Switch** between active sessions
- **Kill** sessions with optional cleanup scripts

## Dependencies

- `fzf`
- `ps` (only for `tsm -a`)

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
   - Config names for `tsm -c`
   - Session names with logs for `tsm -l`

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
tsm [session]                             # Switch to session
tsm -k, --kill [session]                  # Kill session (run cleanup script if present)

# Directory based sessions
tsm -d, --dir [path]                      # Create session at path
tsm -g, --git [--hide-brief] [--no-fetch] # Browse git repositories with fzf, creates session at path
tsm -w, --worktree [name]                 # Create session at git worktree path
tsm -z, --zoxide [query]                  # Create session for zoxide match path

# AI agent sessions
tsm -a, --agents                          # Browse panes running an AI agent
tsm --agent-state [state]                 # Record agent state on the current pane (for agent hooks)

# Configuration based sessions
tsm -c, --configured [config]             # Create configured session
tsm -l, --logs [session]                  # Browse configured session logs

tsm -h, --help                            # Show help message
```

When session/path arguments are omitted, `tsm` uses fzf for interactive selection.
When creating a new directory based session you are prompted to confirm or override
the suggested session name before the session is created.

## tmux Keybindings

`tsm` is best used with tmux keybinds which can be added to your `~/.tmux.conf`:

```bash
bind-key s popup -E "tsm"
bind-key k popup -E "tsm -k"
bind-key X run-shell "tsm -k #{session_name}"

# Directory based sessions
bind-key d popup -E "tsm -d"
bind-key g popup -E "tsm -g"
bind-key w popup -E "tsm -w"
bind-key z popup -E "tsm -z"

# AI agent sessions
bind-key a popup -E "tsm -a"

# Configuration based sessions
bind-key c popup -E "tsm -c"
bind-key l popup -E "tsm -l"
```

This maps:
- `prefix + s` - Active session switcher
- `prefix + k` - Kill session selector
- `prefix + X` - Kill the current session and run kill script
- `prefix + d` - Directory session launcher
- `prefix + g` - Git repository session launcher
- `prefix + w` - Worktree session launcher
- `prefix + z` - Zoxide directory session launcher
- `prefix + a` - AI agent picker
- `prefix + c` - Configured session launcher
- `prefix + l` - Browse configured session logs

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

# Command Overview

## Session Switcher

```bash
tsm                # Browse active sessions with fzf and switch to selection
tsm session-name   # Switch to 'session-name'
```

![Session Switcher](docs/session_switcher.gif)

## Directory Sessions

Directory sessions allow you to open a new tmux session rooted at a specific directory.
All directory sessions work the same way: pick a directory, name the session, and go.
There are several options that offer different ways to pick the directory.

### Direct Path (`-d`)

> ```bash
> tsm -d                   # Browse directories with fzf and start session from selection
> tsm -d ~/code/projectA   # Start a session directly at ~/code/projectA
> ```
> 
> When no path is provided, fzf by default displays all non-hidden directories within 4 levels deep of your
> `$HOME` directory. This can be changed by setting the `TSM_DIRS_CMD` environment variable in your `.bashrc/.zshenv`.
> 
> <details>
> <summary><strong style="font-size: 1.25em;">Modifying <code>TSM_DIRS_CMD</code></strong></summary>
> 
> > `TSM_DIRS_CMD` can be set to any command that returns directories.
> >
> > The following example shows:
> > - directories 1 level deep in the `$HOME` directory
> > - directories 4 levels deep in `$HOME/code` while also pruning the search once it finds the root of a git repo
> >
> > ```bash
> > export TSM_DIRS_CMD='{
> >   find "$HOME" -maxdepth 1 -name ".*" -prune -o -type d -print;
> >   find "$HOME/code" -maxdepth 4 -name ".*" -prune -o -type d \( -exec test -e {}/.git \; -print -prune -o -print \);
> > }'
> > ```
> </details>
>
> ![Launch Directory Sessions](docs/directory_launcher.gif)

### Git Repositories (`-g`)

> ```bash
> tsm -g   # Browse git repositories with fzf and start session from selection
> ```
> 
> Works like `-d` but is tailored to git repositories by displaying a brief git status summary showing:
> - the current branch
> - ahead/behind counts
> - unstaged changes
>
> By default, `tsm -g` finds all directories containing `.git` within 4 levels of `$HOME`. This can be
> changed by setting the `TSM_GIT_DIRS_CMD` environment variable in your `.bashrc/.zshenv`.
> 
> Optional flags:
> - `--hide-brief` — Skip displaying git status information in the picker.
> - `--no-fetch` — Skip running `git fetch` before displaying status. Useful for faster startup when
>   you don't need the latest remote tracking info.
>
> The fetches run in parallel, 8 repositories at a time. `TSM_GIT_FETCH_JOBS` raises or lowers that
> cap:
>
> ```bash
> export TSM_GIT_FETCH_JOBS=4
> ```
>
> The cap matters because every fetch also opens a connection to a remote. Lower it if a wide
> `TSM_GIT_DIRS_CMD` makes the picker slow to appear or your connection is metered, and use
> `--no-fetch` to skip fetching altogether.
> 
> <details>
> <summary><strong style="font-size: 1.25em;">Modifying <code>TSM_GIT_DIRS_CMD</code></strong></summary>
> 
> > `TSM_GIT_DIRS_CMD` can be set to any command that returns directories of git repositories.
> >
> > It is a good idea to limit this search to a directory where you keep your projects:
> > ```bash
> > export TSM_GIT_DIRS_CMD='find "$HOME/code" -maxdepth 4 -name ".git" 2>/dev/null | sed "s/\/\.git$//"'
> > ```
> >
> > Or you could get the `$ROOT` paths of all of your [configured sessions](#configured-sessions):
> > ```bash
> > export TSM_GIT_DIRS_CMD='for f in "$HOME/.config/tsm/"*.sh; do ROOT=""; source "$f"; [ -n "$ROOT" ] && echo "$ROOT"; done'
> > ```
> 
> </details>
>
> ![Launch Git Sessions](docs/git_launcher.gif)

### Git Worktrees (`-w`)

> ```bash
> tsm -w         # Browse worktrees for current git repo with fzf
> tsm -w other   # Start session for worktree named 'other'
> ```
> 
> Browse git worktrees for the current repository and create a session rooted at the selected worktree directory.
>
> > **NOTE:** Can only be run when the current working directory is inside a git repo
> 
> ![Launch Worktree Sessions](docs/worktree_launcher.gif)

### Zoxide (`-z`, Optional)

> ```bash
> tsm -z              # Browse zoxide entries interactively and start session from selection
> tsm -z proj         # Start a session at the best zoxide match for "proj"
> ```
> Requires **[zoxide](https://github.com/ajeetdsouza/zoxide)**.
> 
> Zoxide tracks directories you visit frequently, ranking them by "frecency" (frequency + recency). This makes
> it easy to jump to projects with just a few characters of the directory name.
> 
> When no query is provided, `tsm -z` uses `zoxide query -i` for interactive selection with fzf. When a query is
> provided, it uses `zoxide query` to find the best match directly.
> 
> ![Zoxide Session Launcher](docs/zoxide_launcher.gif)

## AI Agents (`-a`)

```bash
tsm -a   # Browse panes running an AI agent with fzf and jump to the selection
```

Long running agents scatter across sessions and windows, and the one you need is usually the one
that finished or is waiting on you. `tsm -a` gives you a flat, cross-session list of every pane
running an agent, ordered by session, window, and pane. Selecting an entry switches session,
window, and pane in one step.

```
  state    session:window:pane  agent
● done     dotfiles:1:0         claude
● idle     tsm/base:1:0         claude
● blocked  work/api:2:1         claude
● working  work/webapp:3:0      codex
```

A pane shows up in the picker if either of the following is true:

1. It has a recorded agent state (see [Agent State Hooks](#agent-state-hooks) below).
2. A known agent command is running anywhere in the pane's process tree. These panes are listed
   with the state `unknown` — the agent is running, but nothing has told `tsm` what it is doing.

The commands recognized in step 2 default to:

```
claude codex aider cursor-agent opencode goose gemini amp crush copilot droid
```

Override the list with the `TSM_AGENT_CMDS` environment variable (whitespace separated):

```bash
export TSM_AGENT_CMDS="claude codex my-agent"
```

<a id="agent-state-hooks"></a>

### Agent State Hooks

Process detection tells you an agent is *running*; it can't tell you whether it is churning through
a task, waiting on a permission prompt, or done. Agents that support notification hooks can report
that themselves.

`tsm --agent-state <state>` records a state on the pane it is called from, as the pane-scoped tmux
option `@tsm_agent_state`. Valid states, in the order they sort in the picker:

| State | Meaning |
|-------|---------|
| `blocked` | The agent needs input — a permission prompt or a question |
| `done` | The agent finished its turn and its response is waiting |
| `idle` | The agent is running but has nothing in flight |
| `working` | The agent is busy |
| `clear` | Not a state — removes the option, dropping the pane back to process detection |

Plus one pseudo-state:

| Argument | Meaning |
|----------|---------|
| `notification` | Derive the state from an agent notification payload on stdin (see below) |

The command is safe to call from anywhere: it does nothing outside of tmux, ignores unknown states,
and always exits `0` so a misconfiguration never surfaces as an error inside the agent.

<details>
<summary><strong>Claude Code</strong></summary>

> Add to `~/.claude/settings.json`:
>
> ```json
> {
>   "hooks": {
>     "SessionStart": [
>       { "hooks": [{ "type": "command", "command": "tsm --agent-state idle" }] }
>     ],
>     "UserPromptSubmit": [
>       { "hooks": [{ "type": "command", "command": "tsm --agent-state working" }] }
>     ],
>     "Notification": [
>       { "hooks": [{ "type": "command", "command": "tsm --agent-state notification" }] }
>     ],
>     "Stop": [
>       { "hooks": [{ "type": "command", "command": "tsm --agent-state done" }] }
>     ],
>     "SessionEnd": [
>       { "hooks": [{ "type": "command", "command": "tsm --agent-state clear" }] }
>     ]
>   }
> }
> ```
>
> **NOTE:** Hooks run in a non-interactive shell, so `tsm` must be on the PATH that shell starts with
> — the same requirement as the tmux keybindings above. Use the absolute path to the script
> (`$HOME/.local/bin/tsm --agent-state idle`) if that is inconvenient.

</details>

#### Why `Notification` is not just `blocked`

Claude Code's `Notification` event is not only "the agent needs you". It also fires once the
session has been sitting at the prompt for `messageIdleNotifThresholdMs` (60 seconds by default),
and again for auth and usage-limit chatter. Wiring the whole event to `blocked` means every agent
you don't return to within a minute eventually claims to be blocked, and `idle` never appears at
all — the two most useful states collapse into one.

`tsm --agent-state notification` reads the hook's JSON payload from stdin and maps its
`notification_type` field instead:

| `notification_type` | State |
|---------------------|-------|
| `permission_prompt`, `worker_permission_prompt`, `agent_needs_input` | `blocked` |
| `idle_prompt` | `idle` |
| `agent_completed` | `done` |
| anything else (`auth_success`, `quota_*`, …) | *unchanged* |

Payloads it doesn't recognize leave the pane's current state alone rather than overwriting it. If
the payload has no `notification_type` — older releases didn't send one — it falls back to matching
the `message` text.

Any agent with an equivalent hook system works the same way — point its lifecycle events at
`tsm --agent-state <state>`, and anything notification-shaped at `tsm --agent-state notification`.

<a id="configured-sessions"></a>

## Configured Sessions (`-c`)

Script up the perfect window/pane layout and automate tasks like starting up services when a session starts.
Ideal for projects you work on regularly to keep things consistent and reproducible.

Session configurations are shell scripts stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<config-name>.sh`.

Each session file defines:
  - `SESSION` (required): The tmux session name.
  - `start()` (required): Creates and customizes the tmux session.
  - `kill()` (optional): Runs asynchronously when the session is killed. Use this for cleanup tasks like stopping services.

![Launch Configured Sessions](docs/configured_launcher.gif)

### Logging

Output from `start()` and `kill()` functions is redirected to a dedicated log file.
Each configured session gets its own log directory.
Logs can be found in `${XDG_STATE_HOME:-~/.local/state}/tsm/logs/<session-name>/tsm.log`. 

Use `tsm -l` to browse all log files across sessions with fzf. The fzf preview pane shows the
tail of the currently highlighted file.

> **NOTE:** Each configured session's specific `tsm.log` file is wiped on each call to `start()` or `kill()`,
> so it only contains output from the most recent invocation. This prevents log files from growing unbounded.

<details>
<summary><strong style="font-size: 1.25em;">Example Session Configuration</strong></summary>

> Create a session configuration for a project at `~/.config/tsm/myproject.sh`:
> 
> ```bash
> SESSION="myproject"
> ROOT="$HOME/projects/myproject"
> 
> start() {
>   # Create the session rooted at the project directory.
>   tmux new-session -d -s "$SESSION" -c "$ROOT"
> 
>   # Rename the first window to 'code'.
>   # This window will have two vertical splits:
>   #     - nvim on top 80%
>   #     - a terminal at the bottom 20%
>   tmux rename-window -t "$SESSION" "code"
>   tmux send-keys -t "$SESSION:code" 'nvim' Enter
>   tmux split-window -v -l 20% -t "$SESSION:code" -c "$ROOT"
> 
>   # Create a second window named 'docker'.
>   # This window will have an even-vertical layout with:
>   #     - a terminal that starts docker compose on top
>   #     - lazydocker on bottom
>   tmux new-window -t "$SESSION" -n "docker" -c "$ROOT"
>   tmux send-keys -t "$SESSION:docker" 'docker compose up --force-recreate --detach' Enter
>   tmux split-window -t "$SESSION:docker" -v -c "$ROOT"
>   tmux send-keys -t "$SESSION:docker" 'lazydocker' Enter
>   tmux select-layout -t "$SESSION:docker" even-vertical
> 
>   # Select first window
>   tmux select-window -t "$SESSION:code"
> }
> 
> # Optional: cleanup function runs in background when session is killed.
> # This allows the tmux session to be killed immediately without waiting for
> # cleanup tasks to complete, providing a snappier user experience especially
> # when cleanup involves slow operations like stopping services.
> kill() {
>   # Stop the docker compose service that was started earlier.
>   docker compose --project-directory "$ROOT" down
> }
> ```
> 
> See `man tmux` for a full list of available tmux specific commands.

</details>

<details>
<summary><strong style="font-size: 1.25em;">Advanced Configuration Examples</strong></summary>

> Since each session file is a full shell script, you're not limited to running commands inside tmux panes and windows.
>
> You can kick off commands in the background with `&` so they don't block session startup. The session attaches
> immediately while the command continues running, and its output is captured in the log file for later review.
> 
> ```bash
> SESSION="webapp"
> ROOT="$HOME/projects/webapp"
> 
> start() {
>   tmux new-session -d -s "$SESSION" -c "$ROOT"
> 
>   tmux rename-window -t "$SESSION" "code"
>   tmux send-keys -t "$SESSION:code" 'nvim' Enter
> 
>   # Start a service in the background so it doesn't block session startup.
>   # Build output and errors are captured in the tsm log file.
>   echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting my webapp"
>   docker compose --project-directory "$ROOT" up --build --force-recreate --detach &
> }
> 
> kill() {
>   echo "$(date '+%Y-%m-%d %H:%M:%S'): Stopping my webapp"
>   docker compose --project-directory "$ROOT" down
> }
> ```
> 
> **NOTE:** Background cleanup tasks in `kill()` with `&` so they run in parallel. Although `kill()`
> itself runs asynchronously, commands within it still run sequentially — if one hangs or is slow, it
> will block the rest.
>
> **NOTE:** When backgrounding multiple processes, their output may interleave in the tsm log file.
> To avoid this, redirect each process to its own log file in the session's log directory:
> ```bash
> docker compose up --detach > "$HOME/.local/state/tsm/logs/$SESSION/docker.log" 2>&1 &
> pg_ctl start -l "$HOME/.local/state/tsm/logs/$SESSION/postgres.log" &
> ```
> These files will be browsable with `tsm -l`.

</details>


## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
