# tmux-session-manager

A simple tmux session manager

- **Create** sessions rooted at directories or defined by configuration scripts
- **Switch** between active sessions
- **Kill** sessions with optional cleanup scripts
- **Find** the AI agent that wants your attention, wherever it is running

## Dependencies

- `fzf`
- `ps` (only for `tsm agents`)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

This clones the repository to `~/.local/share/tmux-session-manager` and symlinks `tsm` into
`~/.local/bin`. Re-run it at any time to update to the latest revision. Override
`TSM_HOME`, `BIN_DIR` or `TSM_REPO` to change where things land:

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh \
  | BIN_DIR=~/bin sh
```

Shell completions are not installed by the script -- see the last step under Manual
Installation below.

<details>
<summary><strong style="font-size: 1.25em;">Manual Installation</strong></summary>

1. Clone the repository:
   ```bash
   git clone https://github.com/ryanburda/tmux-session-manager.git ~/git/ryanburda/tmux-session-manager
   ```

2. Symlink the script to a directory in your PATH:
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
   - Active session names for `tsm active` and `tsm kill`
   - Directory completion for `tsm dir`
   - Config names for `tsm configured`
   - Session names with logs for `tsm logs`

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

</details>

## Usage

```bash
tsm                                # Switch to session
tsm active [session]               # Switch to session
tsm kill [session]                 # Kill session (run cleanup script if present)

# Directory based sessions
tsm dir [path] [-c] [-d] [-p]      # Create session at path
tsm git [-b] [-f] [-c] [-d] [-p]   # Browse git repositories with fzf, creates session at path
tsm worktree [name] [-c] [-d] [-p] # Create session at git worktree path
tsm zoxide [query] [-c] [-d] [-p]  # Create session for zoxide match path

  -c, --no-custom-config           # Ignore a custom configuration rooted at the selected path
  -d, --no-default-config          # Skip the shared default configuration
  -p, --prompt-name                # Prompt for the session name instead of using the default
  -b, --brief                      # (git) Show git status information in the picker
  -f, --fetch                      # (git) Fetch before showing the brief; implies -b

# Configuration based sessions
tsm configured [config]            # Create configured session
tsm logs [session]                 # Browse configured session logs
tsm apply-default-config           # Apply the shared default configuration (inside a configuration's start())

# AI agent panes
tsm agents                         # Browse panes running an AI agent
tsm agent-state [state]            # Record agent state on the current pane (for agent hooks)

tsm help                           # Show help message
```

When session/path arguments are omitted, `tsm` uses fzf for interactive selection.

## tmux Keybindings

`tsm` is best used with tmux keybinds which can be added to your `~/.tmux.conf`:

```bash
bind-key s popup -E "tsm active"
bind-key k popup -E "tsm kill"
bind-key X run-shell "tsm kill #{session_name}"

# Directory based sessions
bind-key d popup -E "tsm dir"
bind-key g popup -E "tsm git"
bind-key G popup -E "tsm git -bf"
bind-key w popup -E "tsm worktree"
bind-key z popup -E "tsm zoxide"

# AI agent sessions
bind-key a popup -E "tsm agents"

# Configuration based sessions
bind-key c popup -E "tsm configured"
bind-key l popup -E "tsm logs"
```

This maps:
- `prefix + s` - Active session switcher
- `prefix + k` - Kill session selector
- `prefix + X` - Kill the current session and run kill script
- `prefix + d` - Directory session launcher
- `prefix + g` - Git repository session launcher
- `prefix + G` - Git repository session launcher (with git brief)
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
> bind-key d popup -h 24 -w 80 -E "~/git/ryanburda/tmux-session-manager/tsm dir"
> bind-key X run-shell "~/git/ryanburda/tmux-session-manager/tsm kill #{session_name}"
> ```
> 
> Adjust the path to match where you cloned the repository.
> 
> **Note:** If you specify a custom `TSM_DIRS_CMD`, add it to the same file where you configure your PATH
> (e.g., `~/.zshenv` for zsh). Otherwise, `tsm dir` will use the default directory list in a tmux popup
> but a different custom list from an interactive shell, leading to inconsistent behavior.

</details>

# Command Overview

## Active Session Switcher

```bash
tsm active         # Browse active sessions with fzf and switch to selection
tsm session-name   # Switch to 'session-name'
```

![Session Switcher](docs/session_switcher.gif)

## Directory Sessions

Directory sessions allow you to open a new tmux session rooted at a specific directory.
There are several options that offer different ways to pick the directory.

### How the Layout Is Chosen

The goal of `tsm` is create tmux sessions that are always laid the way you want them to be.
Which layout you get is decided by the scripts in your configuration directory,
`${XDG_CONFIG_HOME:-~/.config}/tsm/`.

`dir`, `git`, `worktree` and `zoxide` differ only in how they help you pick a directory.
Once one is picked, all four resolve the layout the same way:

```
      tsm dir  ·  tsm git  ·  tsm worktree  ·  tsm zoxide
                             |
                      picked directory
                             |
         does a ~/.config/tsm/*.sh set a matching $ROOT?
              /                                    \
            yes                                     no
             |                                       |
   start that configuration           does .default_config.sh exist?
   (same session as tsm configured)     /                           \
                                       yes                         no
                                        |                           |
                             create a session at the     create a bare session
                             directory, then apply       at the directory
                             .default_config.sh
```

1. **A custom configuration, if one claims the directory.** Every `<name>.sh` in the configuration
   directory is checked for a `ROOT` equal to the path you picked. The first match starts as a
   [configured session](#configured-sessions) -- the same session `tsm configured <name>` gives you,
   with its own name, `start()` and `kill()`. If that session is already running you are switched to
   it instead.
2. **The shared default configuration, otherwise.** A session is created at the picked directory and
   named after it, and [`.default_config.sh`](#sharing-a-default-configuration) is applied to it --
   the same default a configuration without its own `start()` falls back to. `SESSION` is the
   session name and `ROOT` is the picked directory, exactly as a custom configuration would see
   them.
3. **Nothing, if there is no `.default_config.sh` either.** You get a plain one-window session at the
   picked directory.

So a project with a script of its own gets that script no matter how you arrived at its directory,
and everything else still comes up in your usual layout. A bare `tsm dir` therefore creates and lays
out the session the first time and simply switches you to it on every call after that, since step 1
and step 2 both recognize a session that already exists.

Two flags step out of the chain, allowing you to pick a directory with no session configuration applied after:

- `-c`, `--no-custom-config` — Skip step 1. Ignore any custom configuration rooted at the picked
  path and create an ordinary directory session there, laid out by the default configuration.
- `-d`, `--no-default-config` — Skip step 2. Create a plain session with nothing applied to it.

Passing `-cd` is a convenient way to get a vanilla new tmux session rooted at the picked directory.

A third flag prompts for a session name instead of resolving to a name that is determined for you:

- `-p`, `--prompt-name` — Prompt for the session name instead of using the suggested one.
  In all cases `tsm` will switch to an existing session with the same name if one already exists.

Short flags can be clustered, so `tsm dir -cdp` is a convenient way to get a vanilla new tmux
session rooted at the picked directory with the name you specify.

### Direct Path (`dir`)

> Create a new tmux session rooted at a selected path.
>
> ```bash
> tsm dir                       # Browse directories with fzf, then run the custom/default config
> tsm dir ~/code/projectA       # Start a session directly at ~/code/projectA
> tsm dir -d                    # Browse directories with fzf, skipping the default config
> tsm dir ~/code/projectA -p    # Prompt for the session name instead of using the default
> tsm dir ~/code/projectA -c    # Default config, even if a custom config is rooted there
> ```
>
> Optional flags:
> - `-c`, `--no-custom-config` — Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` — Skip the [shared default configuration](#sharing-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` — Prompt for the session name instead of using the suggested one.
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

### Git Repositories (`git`)

> Create a new tmux session rooted at a git repository.
> 
> ```bash
> tsm git      # Browse git repositories with fzf, then run the custom/default config
> tsm git -bf  # Browse git repositories with fzf, showing a brief summary fetched from origin
> ```
> 
> Optional flags:
> - `-b`, `--brief` — Show git status information in the picker. Off by default so the picker
>   appears immediately.
> - `-f`, `--fetch` — Run `git fetch` before displaying status, so the ahead/behind counts reflect
>   the latest remote tracking info. Implies `-b`.
> - `-c`, `--no-custom-config` — Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` — Skip the [shared default configuration](#sharing-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` — Prompt for the session name instead of using the suggested one.
>
> By default, `tsm git` finds all directories containing `.git` within 4 levels of `$HOME`. This can be
> changed by setting the `TSM_GIT_DIRS_CMD` environment variable in your `.bashrc/.zshenv`.
>
> With `-f`, the fetches run in parallel, 8 repositories at a time. `TSM_GIT_FETCH_JOBS` raises or
> lowers that cap:
> 
> <details>
> <summary><strong style="font-size: 1.25em;">Modifying <code>TSM_GIT_DIRS_CMD/TSM_GIT_FETCH_JOBS</code></strong></summary>
> 
> > `TSM_GIT_DIRS_CMD` can be set to any command that returns directories of git repositories.
> >
> > It is a good idea to limit this search to a directory where you keep your projects:
> > ```bash
> > export TSM_GIT_DIRS_CMD='find "$HOME/code" -maxdepth 4 -name ".git" 2>/dev/null | sed "s/\/\.git$//"'
> > ```
> >
> > The `TSM_GIT_FETCH_JOBS` cap matters because every fetch also opens a connection to a remote. Lower it if a wide
> > `TSM_GIT_DIRS_CMD` makes the picker slow to appear or your connection is metered, or drop `-f`
> > to skip fetching altogether.
> >
> > ```bash
> > export TSM_GIT_FETCH_JOBS=4
> > ```
> </details>
>
> ![Launch Git Sessions](docs/git_launcher.gif)

<a id="git-worktrees"></a>

### Git Worktrees (`worktree`)

> Create a new tmux session rooted at a git worktree.
>
> **NOTE:** Can only be run when the current working directory is inside a git repo
>
> ```bash
> tsm worktree             # Browse worktrees for current git repo with fzf
> tsm worktree other       # Start session for worktree named 'other'
> tsm worktree other -d    # Same, but skip the default config
> tsm worktree other -p    # Prompt for the session name instead of using the default
> ```
> 
> Optional flags:
> - `-c`, `--no-custom-config` — Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` — Skip the [shared default configuration](#sharing-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` — Prompt for the session name instead of using the suggested one.
> 
> ![Launch Worktree Sessions](docs/worktree_launcher.gif)

### Zoxide (`zoxide`, Optional)

> The Zoxide version of `dir`
>
> Requires **[zoxide](https://github.com/ajeetdsouza/zoxide)**.
>
> ```bash
> tsm zoxide            # Browse zoxide entries interactively and start session from selection
> tsm zoxide proj       # Start a session at the best zoxide match for "proj"
> tsm zoxide proj -d    # Same, but skip the default config
> tsm zoxide proj -p    # Prompt for the session name instead of using the default
> ```
> 
> Zoxide tracks directories you visit frequently, ranking them by "frecency" (frequency + recency). This makes
> it easy to jump to projects with just a few characters of the directory name.
> 
> When no query is provided, `tsm zoxide` uses `zoxide query -i` for interactive selection with fzf. When a query is
> provided, it uses `zoxide query` to find the best match directly.
> 
> Optional flags:
> - `-c`, `--no-custom-config` — Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` — Skip the [shared default configuration](#sharing-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` — Prompt for the session name instead of using the suggested one.
> 
> ![Zoxide Session Launcher](docs/zoxide_launcher.gif)

## AI Agents (`agents`)

```bash
tsm agents   # Browse panes running an AI agent with fzf and jump to the selection
```

Long running agents scatter across sessions and windows, and the one you need is usually the one
that finished or is waiting on you. `tsm agents` gives you a flat, cross-session list of every pane
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

`tsm agent-state <state>` records a state on the pane it is called from, as the pane-scoped tmux
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
>       { "hooks": [{ "type": "command", "command": "tsm agent-state idle" }] }
>     ],
>     "UserPromptSubmit": [
>       { "hooks": [{ "type": "command", "command": "tsm agent-state working" }] }
>     ],
>     "Notification": [
>       { "hooks": [{ "type": "command", "command": "tsm agent-state notification" }] }
>     ],
>     "Stop": [
>       { "hooks": [{ "type": "command", "command": "tsm agent-state done" }] }
>     ],
>     "SessionEnd": [
>       { "hooks": [{ "type": "command", "command": "tsm agent-state clear" }] }
>     ]
>   }
> }
> ```
>
> **NOTE:** Hooks run in a non-interactive shell, so `tsm` must be on the PATH that shell starts with
> — the same requirement as the tmux keybindings above. Use the absolute path to the script
> (`$HOME/.local/bin/tsm agent-state idle`) if that is inconvenient.

</details>

<a id="configured-sessions"></a>

## Configured Sessions (`configured`)

Script up the perfect window/pane layout and automate tasks like starting up services when a session starts.
Ideal for projects you work on regularly to keep things consistent and reproducible.

Session configurations are shell scripts stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<config-name>.sh`.
**The file's name is the session's name** -- `myproject.sh` starts a session called `myproject`.

tsm owns the session's lifecycle: it creates the session before your configuration runs, and kills it
when you kill the session. Everything the file defines is therefore optional, and describes what you
want *beyond* a plain session:
  - `ROOT`: The session's root directory, used as the working directory for its windows and panes.
    Defaults to `$HOME`.
  - `start()`: Function that defines how the session should be customized. The session already exists
    by the time it runs. This is where you add windows, split panes, run services.
  - `kill()`: Runs asynchronously when the session is killed. Use this for cleanup tasks like stopping services.

`SESSION` is set for you, and exported before the file is sourced so top-level code and `start()`
alike can use it. There is nothing to declare and nothing to keep in sync: rename the file and you
have renamed the session.

> **NOTE:** Configuration file names cannot contain `.` or `:`. tmux reads both as the window and
> pane separators of a target, so a session named `my.project` would be created and then be
> unreachable. tsm refuses such a name rather than quietly renaming the session out from under you.

`tsm configured` is not the only way in. The [directory pickers](#how-the-layout-is-chosen) look for a
configuration whose `ROOT` is the path you picked, and start it when they find one, so `tsm dir`,
`tsm git`, `tsm worktree` and `tsm zoxide` all land on the configured session for a project that
has one. Their `-c`, `--no-custom-config` flag skips that lookup.

Nesting works, and the whole path under the configuration directory is the session name -- so a session can
be called `myrepo/base`, matching the `repo/worktree` names [worktree sessions](#git-worktrees) get, and
sort next to them in the switcher:

```
~/.config/tsm/
  notes.sh                 ->  session "notes"
  myrepo/base.sh           ->  session "myrepo/base"
  myrepo/experiment.sh     ->  session "myrepo/experiment"
```

The smallest useful configuration is a single line:

```bash
# ~/.config/tsm/notes.sh  ->  a session named "notes", rooted at ~/notes
ROOT="$HOME/notes"
```

With no `start()`, the session is plain -- one window, one pane at `ROOT` -- unless
[a default configuration](#sharing-a-default-configuration) is configured, in which case that runs
instead.

![Launch Configured Sessions](docs/configured_launcher.gif)

### Building Layouts

Session configurations are plain shell scripts calling `tmux` directly. The session already exists by
the time `start()` runs -- one window holding one pane, rooted at `ROOT` -- so a layout is built by
splitting off that pane and sending commands into the panes that result:

```bash
ROOT="$HOME/code/myproject"

start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
}
```

**Pane addressing** is the thing that is easy to get wrong. `-P -F '#{pane_id}'` makes
`split-window` and `new-window` print the id of the pane they just created, so layouts are built by
capturing ids and splitting off them. Positional targets like `"$SESSION:code.1"` shift underneath
you as soon as a later split renumbers the window; ids never do.

The session tsm hands you has one window holding one pane, so
`tmux display-message -p -t "$SESSION" '#{pane_id}'` is the way in -- it prints that pane's id.
Naming its window is one more command, and only worth doing if you care what the window is called:

```bash
start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$code" code
}
```

A pane id is a valid `-t` target for `rename-window`: it names the window that pane is in, which
saves constructing a window target of your own.

`-c "$ROOT"` is worth passing to every `split-window` and `new-window`. Without it a new pane
inherits the working directory of the pane it came from, which is only `ROOT` until something in the
layout has `cd`'d somewhere else. `SESSION` and `ROOT` are both exported around `start()` and
`kill()`, so they are in the environment of everything the configuration runs.

<details>
<summary><strong style="font-size: 1.25em;">Example: an editor and an agent</strong></summary>

> An editor on the left, an AI agent on the right, focus back on the editor.
>
> ```bash
> ROOT="$HOME/projects/myproject"
>
> start() {
>   code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
>   tmux rename-window -t "$code" code
>   ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
>   tmux send-keys -t "$code" 'nvim' Enter
>   tmux send-keys -t "$ai" 'ai' Enter
>   tmux select-pane -t "$code"
> }
> ```

</details>

<details>
<summary><strong style="font-size: 1.25em;">Example: multiple windows</strong></summary>

> ```bash
> ROOT="$HOME/projects/myproject"
>
> start() {
>   # First window: the one the session starts with. Just an editor.
>   code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
>   tmux rename-window -t "$code" code
>   tmux send-keys -t "$code" 'nvim' Enter
>
>   # Second window: an editor with an agent to the right and a terminal below.
>   nav=$(tmux new-window -P -F '#{pane_id}' -t "$SESSION" -n nav -c "$ROOT")
>   nav_ai=$(tmux split-window -P -F '#{pane_id}' -h -l 30% -t "$nav" -c "$ROOT")
>   nav_terminal=$(tmux split-window -P -F '#{pane_id}' -v -l 20% -t "$nav" -c "$ROOT")
>   tmux send-keys -t "$nav" 'nvim lua/init.lua' Enter
>   tmux send-keys -t "$nav_ai" 'ai' Enter
>   tmux send-keys -t "$nav_terminal" 'ls' Enter
>   tmux select-pane -t "$nav"
>
>   # The last window created is the one you would attach to, so pick explicitly.
>   tmux select-window -t "$SESSION:code"
> }
> ```

</details>

#### Sharing a Default Configuration

Most configurations end up wanting the same layout. Rather than repeat it in every file, put it once
in `${XDG_CONFIG_HOME:-~/.config}/tsm/.default_config.sh`:

```bash
# ~/.config/tsm/.default_config.sh
code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
tmux rename-window -t "$code" code
ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
tmux send-keys -t "$code" 'nvim' Enter
tmux send-keys -t "$ai" 'ai' Enter
tmux select-pane -t "$code"
```

A configuration that defines no `start()` at all gets it automatically -- tsm falls back to
`tsm apply-default-config` whenever a configuration doesn't define `start()`:

```bash
# ~/.config/tsm/myproject.sh
ROOT="$HOME/code/myproject"
```

Write `start()` yourself only when you want to do more around the default, or something different
entirely:

```bash
# ~/.config/tsm/myproject.sh
ROOT="$HOME/code/myproject"

start() {
  tsm apply-default-config
  make -C "$ROOT" up &
}
```

`tsm apply-default-config` sources `.default_config.sh` at the point it's called, with `SESSION` and
`ROOT` already in the environment -- same as any other command `start()` runs. `.default_config.sh`
itself is excluded from the configured-session list and picker, since it is not a session to start. A
configuration that wants no layout at all -- not even the default -- defines its own empty `start()`
to opt out of the fallback.

#### Failing Fast with `set -e`

`tmux` returns non-zero and writes to stderr when a command fails, but a session
configuration is a plain shell script: by default `start()` runs to the end regardless, building the
rest of the layout on top of the mistake. Adding `set -e` at the top of the configuration stops it at
the first failure instead.

```bash
set -e

ROOT="$HOME/code/myproject"
```

That catches the structural errors -- a typo'd command, a stale pane id (`can't find pane: %99`),
a duplicate session name, a bad window target. Adding `-u` is worth it too: a misspelled variable
(`tmux send-keys -t "$cdoe" 'nvim' Enter`) otherwise expands to an empty target and fails a step
later with a vaguer message.

At the top level it does more than abort the layout: a configuration that fails before tsm has
created the session means there is no session to attach to, and tsm says so rather than dropping you
somewhere confusing.

Two things it does not do, both worth knowing before relying on it:

**It does not check what runs inside the panes.** `send-keys` succeeds as long as
the pane exists. Whether the program you typed exists is never part of its exit status, so a config
launching a tool you have since uninstalled aborts nothing -- the pane simply sits there showing
`command not found`.

**It does not stop tsm from attaching.** tsm does not inspect `start()`'s exit status, so you are
still dropped into the partially built session. What you gain is that the layout stopped growing and
the error is the last thing in `tsm logs` rather than buried mid-log.

One trap, and it applies to the exact idiom every layout uses: `local` is itself a command that
returns 0, so it swallows the status of the substitution it assigns.

```bash
ai=$(tmux split-window -P -F '#{pane_id}' -h -t "$code")            # aborts on failure
local ai; ai=$(tmux split-window -P -F '#{pane_id}' -h -t "$code")  # aborts on failure
local ai=$(tmux split-window -P -F '#{pane_id}' -h -t "$code")      # CONTINUES, with ai empty
```

Top-level assignments in `start()` are unaffected. It only bites in a helper function, where the
empty pane id then surfaces as a confusing `can't find pane` further down. Declare, then assign.

#### Complementary, Not Binding

Most tmux layout managers, like tmuxinator and tmuxp, ask you to describe a layout in a
configuration format they define. That works right up until you want something the format has no
word for, and at that point you are waiting on the maintainer to add it or abandoning the tool
outright. The abstraction is binding: whatever it cannot express, you cannot do.

A session configuration is deliberately not that. tsm creates the session and gets out of the way;
the layout is built with tmux's own commands, so there is nothing tsm needs a word for:

```bash
start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")

  # Options, titles, hooks -- tsm has no opinion about any of it. It does not need one.
  tmux set-option -t "$SESSION" status-style 'bg=colour238'
  tmux select-pane -t "$ai" -T 'agent'
}
```

There is no escape hatch to reach for, because you never left. The ceiling of a session
configuration is the ceiling of tmux itself.

The tradeoff is that a session configuration is a shell script, which is not the most inviting thing
to write. That is the price of the property worth having: if something cannot be done with native
tmux commands, no configuration format was going to solve it away either -- it would only add a
second place for it to be impossible. Better to keep the full command set within reach. `man tmux`
is the reference, and all of it is available.

### Logging

Output from the `start()` and `kill()` hooks -- and from the session creation around them -- is
redirected to a dedicated log file. Each configured session gets its own log directory.
Logs can be found in `${XDG_STATE_HOME:-~/.local/state}/tsm/logs/<session-name>/tsm.log`. 

Use `tsm logs` to browse all log files across sessions with fzf. The fzf preview pane shows the
tail of the currently highlighted file.

> **NOTE:** Each configured session's specific `tsm.log` file is wiped on each call to `start()` or `kill()`,
> so it only contains output from the most recent invocation. This prevents log files from growing unbounded.

<details>
<summary><strong style="font-size: 1.25em;">Example Session Configuration</strong></summary>

> Create a session configuration for a project at `~/.config/tsm/myproject.sh`:
> 
> ```bash
> ROOT="$HOME/projects/myproject"
> 
> start() {
>   # Take the pane the session starts with and name its window 'code'.
>   # This window will have two vertical splits:
>   #     - nvim on top 80%
>   #     - a terminal at the bottom 20%
>   code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
>   tmux rename-window -t "$code" code
>   tmux split-window -v -l 20% -t "$code" -c "$ROOT"   # a plain shell; no pane id needed
>   tmux send-keys -t "$code" 'nvim' Enter
> 
>   # Create a second window named 'docker'.
>   # This window will have an even-vertical layout with:
>   #     - a terminal that starts docker compose on top
>   #     - lazydocker on bottom
>   compose=$(tmux new-window -P -F '#{pane_id}' -t "$SESSION" -n docker -c "$ROOT")
>   lazydocker=$(tmux split-window -P -F '#{pane_id}' -v -l 50% -t "$compose" -c "$ROOT")
>   tmux send-keys -t "$compose" 'docker compose up --force-recreate --detach' Enter
>   tmux send-keys -t "$lazydocker" 'lazydocker' Enter
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
> See [Building Layouts](#building-layouts) for the pane-addressing idiom these examples use, and
> `man tmux` for the full command list.

</details>

<details>
<summary><strong style="font-size: 1.25em;">Advanced Configuration Examples</strong></summary>

> Since each session file is a full shell script, you're not limited to running commands inside tmux panes and windows.
>
> You can kick off commands in the background with `&` so they don't block session startup. The session attaches
> immediately while the command continues running, and its output is captured in the log file for later review.
> 
> ```bash
> ROOT="$HOME/projects/webapp"
> 
> start() {
>   code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
>   tmux send-keys -t "$code" 'nvim' Enter
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
> These files will be browsable with `tsm logs`.

</details>


## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
