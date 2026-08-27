# tmux-session-manager

A simple tmux session manager

- **Create** sessions rooted at directories or defined by configuration scripts
- **Switch** between active sessions
- **Kill** sessions with optional cleanup scripts
- **Find** the AI agent that wants your attention, wherever it is running

## Dependencies

- `fzf`
- `ps` (only for `tsm -a`)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

This clones the repository to `~/.local/share/tmux-session-manager` and symlinks both `tsm` and
`tlm` into `~/.local/bin`. Re-run it at any time to update to the latest revision. Override
`TSM_HOME`, `BIN_DIR` or `TSM_REPO` to change where things land:

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh \
  | BIN_DIR=~/bin sh
```

Shell completions are not installed by the script -- see step 4 below.

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ryanburda/tmux-session-manager.git ~/git/ryanburda/tmux-session-manager
   ```

2. Symlink both scripts to a directory in your PATH. Session configurations
   invoke `tlm` as a command, exactly the way you invoke `tsm` -- see
   [Building Layouts with `tlm`](#building-layouts-with-tlm):
   ```bash
   mkdir -p ~/.local/bin
   ln -s ~/git/ryanburda/tmux-session-manager/tsm ~/.local/bin/tsm
   ln -s ~/git/ryanburda/tmux-session-manager/tlm ~/.local/bin/tlm
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

# Configuration based sessions
tsm -c, --configured [config]             # Create configured session
tsm -l, --logs [session]                  # Browse configured session logs

# AI agent panes
tsm -a, --agents                          # Browse panes running an AI agent
tsm --agent-state [state]                 # Record agent state on the current pane (for agent hooks)

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

<a id="configured-sessions"></a>

## Configured Sessions (`-c`)

Script up the perfect window/pane layout and automate tasks like starting up services when a session starts.
Ideal for projects you work on regularly to keep things consistent and reproducible.

Session configurations are shell scripts stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<config-name>.sh`.
**The file's name is the session's name** -- `myproject.sh` starts a session called `myproject`.

tsm owns the session's lifecycle: it creates the session before your configuration runs, and kills it
when you kill the session. Everything the file defines is therefore optional, and describes what you
want *beyond* a plain session:
  - `ROOT`: The session's root directory, used as the working directory for its windows and panes.
    Defaults to `$HOME`. Export it, so that `tlm` and anything else the configuration runs inherits
    it.
  - `start()`: Customizes the session -- windows, panes, commands. The session already exists by the
    time it runs.
  - `kill()`: Runs asynchronously when the session is killed. Use this for cleanup tasks like stopping services.

`SESSION` is set for you, to the file's name, and exported before the file is sourced -- so top-level
code and `start()` alike can use it. There is nothing to declare and nothing to keep in sync: rename
the file and you have renamed the session.

> **NOTE:** Configuration file names cannot contain `.` or `:`. tmux reads both as the window and
> pane separators of a target, so a session named `my.project` would be created and then be
> unreachable. tsm refuses such a name rather than quietly renaming the session out from under you.

The smallest useful configuration is a single line:

```bash
# ~/.config/tsm/notes.sh  ->  a session named "notes", rooted at ~/notes
export ROOT="$HOME/notes"
```

![Launch Configured Sessions](docs/configured_launcher.gif)

### Building Layouts with `tlm`

Session configurations are plain shell scripts calling `tmux` directly, which is fine for a single
window but repetitive once a config grows panes. `tlm` (tmux layout manager) is an optional command
that ships with this repo and factors out the parts every layout repeats. There is nothing to source
-- it is a command on your PATH, used the same way `tsm` is, with everything it does reached as a
subcommand:

```bash
export ROOT="$HOME/code/myproject"

start() {
  code=$(tlm get-current-pane)
  ai=$(tlm split-pane -h 35% "$code")
}
```

It reads `SESSION` and `ROOT` from the environment, and uses `ROOT` as the working directory for
every window and pane it creates. tsm exports both around `start()` and `kill()`, which is how `tlm`
gets them -- it runs as its own process rather than sharing the configuration's shell. Export `ROOT`
yourself when you set it, for that same reason.

| Command | Description |
| --- | --- |
| `tlm new-window <window> [-c dir]` | Create a window, print its pane id |
| `tlm split-pane -h\|-v <size> <pane> [-c dir]` | Split a pane, print the new pane id |
| `tlm run <pane> <command...>` | Type a command into a pane and press Enter |
| `tlm focus-pane <pane>` | Make a pane active within its window |
| `tlm get-current-pane [target-pane]` | Print the active pane id of a target -- a session or window target resolves to its active pane |
| `tlm focus-window <window>` | Make a window current |

**Pane addressing** is the thing it handles that is easy to get wrong by hand. Every pane-creating
subcommand prints the new pane's id, so layouts are built by capturing ids and splitting off them.
Positional targets like `"$SESSION:code.1"` shift underneath you as soon as a later split renumbers
the window; ids never do.

The session tsm hands you has one window holding one pane, so `tlm get-current-pane` with no argument
is the way in -- it prints that pane's id. Naming its window is one plain `tmux` command, and only
worth doing if you care what the window is called:

```bash
start() {
  code=$(tlm get-current-pane)
  tmux rename-window -t "$code" code
}
```

A pane id is a valid `-t` target for `rename-window`: it names the window that pane is in, which
saves constructing a window target of your own.

> **NOTE:** tmux creates detached sessions at 80x24, so a percentage split made before the client
> attaches would be computed against 80 columns and a `35%` split would visibly drift toward 50/50
> once the real terminal size arrived. tsm sizes the session to the attaching client when it creates
> it, so percentages mean what they say -- in plain `tmux` commands as much as in `tlm` ones.

<details>
<summary><strong style="font-size: 1.25em;">Example: the same configuration with and without <code>tlm</code></strong></summary>

> An editor on the left, an AI agent on the right, focus back on the editor.
>
> ```bash
> export ROOT="$HOME/projects/myproject"
>
> start() {
>   NVIM_PANE=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
>   tmux rename-window -t "$NVIM_PANE" "code"
>   AI_PANE=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$NVIM_PANE" -c "$ROOT")
>   tmux send-keys -t "$NVIM_PANE" 'nvim' Enter
>   tmux send-keys -t "$AI_PANE" 'ai' Enter
>   tmux select-pane -t "$NVIM_PANE"
> }
> ```
>
> becomes:
>
> ```bash
> export ROOT="$HOME/projects/myproject"
>
> start() {
>   code=$(tlm get-current-pane)
>   tmux rename-window -t "$code" code
>   ai=$(tlm split-pane -h 35% "$code")
>   tlm run "$code" nvim
>   tlm run "$ai" ai
>   tlm focus-pane "$code"
> }
> ```

</details>

<details>
<summary><strong style="font-size: 1.25em;">Example: multiple windows</strong></summary>

> ```bash
> export ROOT="$HOME/projects/myproject"
>
> start() {
>   # First window: the one the session starts with. Just an editor.
>   code=$(tlm get-current-pane)
>   tmux rename-window -t "$code" code
>   tlm run "$code" nvim
>
>   # Second window: an editor with an agent to the right and a terminal below.
>   nav=$(tlm new-window nav)
>   nav_ai=$(tlm split-pane -h 30% "$nav")
>   nav_terminal=$(tlm split-pane -v 20% "$nav")
>   tlm run "$nav" nvim lua/init.lua
>   tlm run "$nav_ai" ai
>   tlm run "$nav_terminal" ls
>   tlm focus-pane "$nav"
>
>   # The last window created is the one you would attach to, so pick explicitly.
>   tlm focus-window code
> }
> ```

</details>

#### Failing Fast with `set -e`

Every `tlm` command returns non-zero and writes to stderr when something is wrong, but a session
configuration is a plain shell script: by default `start()` runs to the end regardless, building the
rest of the layout on top of the mistake. Adding `set -e` at the top of the configuration stops it at
the first failure instead.

```bash
set -e

export ROOT="$HOME/code/myproject"
```

That catches the structural errors -- a typo'd subcommand, a stale pane id (`can't find pane: %99`),
a duplicate session name, a bad window target. Adding `-u` is worth it too: a misspelled variable
(`tlm run "$cdoe" nvim`) otherwise expands to an empty target and fails a step later with a vaguer
message.

At the top level it does more than abort the layout: a configuration that fails before tsm has
created the session means there is no session to attach to, and tsm says so rather than dropping you
somewhere confusing.

Two things it does not do, both worth knowing before relying on it:

**It does not check what runs inside the panes.** `tlm run` is `send-keys`, which succeeds as long as
the pane exists. Whether the program you typed exists is never part of its exit status, so a config
launching a tool you have since uninstalled aborts nothing -- the pane simply sits there showing
`command not found`.

**It does not stop tsm from attaching.** tsm does not inspect `start()`'s exit status, so you are
still dropped into the partially built session. What you gain is that the layout stopped growing and
the error is the last thing in `tsm -l` rather than buried mid-log.

One trap, and it applies to the exact idiom every layout uses: `local` is itself a command that
returns 0, so it swallows the status of the substitution it assigns.

```bash
ai=$(tlm split-pane -h 35% "$code")            # aborts on failure
local ai; ai=$(tlm split-pane -h 35% "$code")  # aborts on failure
local ai=$(tlm split-pane -h 35% "$code")      # CONTINUES, with ai empty
```

Top-level assignments in `start()` are unaffected. It only bites in a helper function, where the
empty pane id then surfaces as a confusing `can't find pane` further down. Declare, then assign.

#### Complementary, Not Binding

Most tmux layout managers, like tmuxinator and tmuxp, ask you to describe a layout in a
configuration format they define. That works right up until you want something the format has no
word for, and at that point you are waiting on the maintainer to add it or abandoning the tool
outright. The abstraction is binding: whatever it cannot express, you cannot do.

`tlm` is deliberately not that. It is a handful of subcommands that sit *beside* tmux's commands
rather than in front of them, and it keeps no state of its own. Every one hands back a real pane id, so
anything `tlm` does not cover you do with plain `tmux` -- in the middle of the same `start()`, on the
same panes:

```bash
start() {
  code=$(tlm get-current-pane)
  ai=$(tlm split-pane -h 35% "$code")

  # tlm has no opinion about options, titles or hooks. It does not need one.
  tmux set-option -t "$SESSION" status-style 'bg=colour238'
  tmux select-pane -t "$ai" -T 'agent'
}
```

There is no escape hatch to reach for, because you never left. The ceiling of a `tlm` configuration
is the ceiling of tmux itself.

The tradeoff is that a session configuration is a shell script, which is not the most inviting thing
to write. That is the price of the property worth having: if something cannot be done with native
tmux commands, no configuration format was going to solve it away either -- it would only add a
second place for it to be impossible. Better to keep the full command set within reach and let the
library be a convenience you can put down at any time.

So use `tlm` for the common cases, ignore it for the rest, and mix the two without ceremony. Running
`tlm` with no arguments prints the command reference. Using it at all is optional -- a session configuration
that calls `tmux` directly keeps working unchanged.

### Logging

Output from the `start()` and `kill()` hooks -- and from the session creation around them -- is
redirected to a dedicated log file. Each configured session gets its own log directory.
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
> export ROOT="$HOME/projects/myproject"
> 
> start() {
>   # Take the pane the session starts with and name its window 'code'.
>   # This window will have two vertical splits:
>   #     - nvim on top 80%
>   #     - a terminal at the bottom 20%
>   code=$(tlm get-current-pane)
>   tmux rename-window -t "$code" code
>   tlm split-pane -v 20% "$code" > /dev/null   # a plain shell; discard the pane id
>   tlm run "$code" nvim
> 
>   # Create a second window named 'docker'.
>   # This window will have an even-vertical layout with:
>   #     - a terminal that starts docker compose on top
>   #     - lazydocker on bottom
>   compose=$(tlm new-window docker)
>   lazydocker=$(tlm split-pane -v 50% "$compose")
>   tlm run "$compose" docker compose up --force-recreate --detach
>   tlm run "$lazydocker" lazydocker
>   tmux select-layout -t "$SESSION:docker" even-vertical
> 
>   # Select first window
>   tlm focus-window code
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
> `tlm` is a convenience, not a requirement -- see
> [Building Layouts with `tlm`](#building-layouts-with-tlm). Drop back to plain `tmux` commands for
> anything it does not cover; see `man tmux` for the full list.

</details>

<details>
<summary><strong style="font-size: 1.25em;">Advanced Configuration Examples</strong></summary>

> Since each session file is a full shell script, you're not limited to running commands inside tmux panes and windows.
>
> You can kick off commands in the background with `&` so they don't block session startup. The session attaches
> immediately while the command continues running, and its output is captured in the log file for later review.
> 
> ```bash
> export ROOT="$HOME/projects/webapp"
> 
> start() {
>   code=$(tlm get-current-pane)
>   tlm run "$code" nvim
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
