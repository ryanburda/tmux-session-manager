# tmux-session-manager

Set up your ideal session once, get it in every project

- **Define** how your sessions start up
- **Create** sessions rooted at directories
- **Switch** between sessions
- **Kill** sessions with background cleanup hooks
- **See** what every AI agent is doing, in any session

Session setups are plain shell scripts in `${XDG_CONFIG_HOME:-~/.config}/tsm/`.

No YAML, no DSL, just `tmux` commands.

Write `.default_config.sh` once and every session that doesn't define its own configuration gets it.

Projects that need something different get their own `<session-name>.sh`.

You just define:
- which directory that configuration is associated with
- what to run there
- and what to clean up on the way out

`tsm` finds it automatically whenever you open that directory.

## Dependencies

- `fzf`
- `ps` (only for `tsm agents`)

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

The command above:
- Clones the repository to `${XDG_DATA_HOME:-~/.local/share}/tmux-session-manager`
- symlinks `tsm` into `~/.local/bin`

Re-run it at any time to update to the latest revision.

Two environment variables change where things land:
- `TSM_HOME` is where the repository is cloned
- `BIN_DIR` is where the `tsm` symlink is placed

Set either or both on the `sh` that runs the script:

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh \
  | TSM_HOME=~/src/tsm BIN_DIR=~/bin sh
```

**NOTE:** Shell completions are not installed by the script. See Shell Completions below.

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

</details>

<details>
<summary><strong style="font-size: 1.25em;">Shell Completions</strong></summary>

Completions provide:
- Active session names for `tsm active` and `tsm kill`
- Directory completion for `tsm dir`
- Config names for `tsm configured`
- Session names with logs for `tsm logs`

The paths below are the install script's checkout location. If you overrode `TSM_HOME`, or cloned
manually, substitute that directory instead.

<details>
<summary><strong>Bash</strong></summary>

Add to your <code>~/.bashrc</code>:

```bash
source ~/.local/share/tmux-session-manager/completions/tsm.bash
```

</details>

<details>
<summary><strong>Zsh</strong></summary>

Add to your <code>~/.zshrc</code>:

```bash
fpath=(~/.local/share/tmux-session-manager/completions $fpath)
autoload -Uz compinit && compinit
```
Or rename `tsm.zsh` to `_tsm` and place in an existing fpath directory.

</details>

<details>
<summary><strong>Fish</strong></summary>

Symlink to fish completions directory:

```bash
ln -s ~/.local/share/tmux-session-manager/completions/tsm.fish ~/.config/fish/completions/
```

</details>

</details>

## Usage

```bash
tsm                                  # Show help message
tsm active [session]                 # Switch to session
tsm kill [session]                   # Kill session (runs kill() hook if present)

tsm dir [path] [-c] [-d] [-p]        # Create session at path
tsm git [-b] [-f] [-c] [-d] [-p]     # Browse git repositories with fzf, creates session at path
tsm worktree [name] [-c] [-d] [-p]   # Create session at git worktree path
tsm zoxide [query] [-c] [-d] [-p]    # Create session for zoxide match path

  -c, --no-custom-config             # Ignore a custom configuration rooted at the selected path
  -d, --no-default-config            # Skip the shared default configuration
  -p, --prompt-name                  # Prompt for the session name instead of using the default
  -b, --brief                        # (git) Show git status information in the picker
  -f, --fetch                        # (git) Fetch before showing the brief; implies -b

tsm configured [config]              # Start a configured session
tsm logs [session]                   # Browse session logs
tsm apply-default-config             # Apply the shared default configuration (inside a configuration's start())

tsm agents                           # Browse panes running an AI agent
tsm agent-state [state]              # Record agent state on the current pane (for agent hooks)

tsm help                             # Show help message
```

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
- `prefix + X` - Kill the current session and run its kill() hook
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
> bind-key s popup -h 24 -w 60 -E "~/.local/share/tmux-session-manager/tsm"
> bind-key d popup -h 24 -w 80 -E "~/.local/share/tmux-session-manager/tsm dir"
> bind-key X run-shell "~/.local/share/tmux-session-manager/tsm kill #{session_name}"
> ```
> 
> Adjust the path if the repository lives somewhere else.
> 
> **Note:** If you specify a custom `TSM_DIRS_CMD`, add it to the same file where you configure your PATH
> (e.g., `~/.zshenv` for zsh). Otherwise, `tsm dir` will use the default directory list in a tmux popup
> but a different custom list from an interactive shell, leading to inconsistent behavior.

</details>

# Command Overview

## Active Session Switcher

```bash
tsm active                  # Browse active sessions with fzf and switch to selection
tsm active <session-name>   # Switch to 'session-name'
```

![Session Switcher](docs/session_switcher.gif)

## Directory Sessions

Each directory session picker shown below opens a tmux session rooted at
a directory you pick. There are various pickers differing only in how they
help you find the directory:

- `tsm dir` - any directory on the filesystem
- `tsm git` - a git repository
- `tsm worktree` - a worktree of the current repository
- `tsm zoxide` - a zoxide entry (optional)

Once a directory is picked, all pickers resolve which session configuration to apply
to the newly created session in the same way. Configuration scripts are stored in
your configuration directory, `${XDG_CONFIG_HOME-~/.config}/tsm/`:

```
   -------------------------------------------------------
   | tsm dir  ·  tsm git  ·  tsm worktree  ·  tsm zoxide |
   -------------------------------------------------------
                            |
                   --------------------
                   | picked directory |
                   --------------------
                            |
      ---------------------------------------------------
      | does a ~/.config/tsm/*.sh set a matching $ROOT? |
      ---------------------------------------------------
             /                                 \
         -------                             ------
         | yes |                             | no |
         -------                             ------
            |                                   |
----------------------------   ----------------------------------
| start that configuration |   | does .default_config.sh exist? |
----------------------------   ----------------------------------
                                 /                          \
                              -------                     ------
                              | yes |                     | no |
                              -------                     ------
                                |                            |
                ---------------------------    -------------------------
                | create a session at the |    | create a bare session |
                | directory, then apply   |    |   at the directory    |
                | .default_config.sh      |    -------------------------
                ---------------------------
```

1. **A custom configuration is applied if a configuration script claims the directory.**

   Every `<name>.sh` in the configuration directory is checked for a `ROOT` equal to the
   path you picked. The first match starts as a [configured session](#configured-sessions),
   with its own name, `start()` and `kill()`.
2. **The shared default configuration, otherwise.**

   A session is created at the picked directory, named after that directory, and
   [`.default_config.sh`](#defining-a-default-configuration) is applied to it.
3. **Nothing, if there is no `.default_config.sh` either.**

   You get a plain one-window session at the picked directory.

So a project with a script of its own gets that script no matter which directory picker you use,
and everything else comes up in your usual setup.

Every picker takes the same flags: `-c` skips step 1, `-d` skips step 2 to allow you to bypass
this fallback behaviour.

> ### Directory (`tsm dir`)
>
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
> - `-c`, `--no-custom-config` - Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` - Skip the [shared default configuration](#defining-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` - Prompt for the session name instead of using the suggested one.
> 
> When no path is provided, fzf by default displays non-hidden directories within 4 levels of your
> `$HOME` directory, stopping at the root of each git repository. This can be changed by setting
> the `TSM_DIRS_CMD` environment variable in your `.bashrc/.zshenv`.
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

> ### Git Repositories (`tsm git`)
>
> Create a new tmux session rooted at a git repository.
> 
> ```bash
> tsm git           # Browse git repositories with fzf, then run the custom/default config
> tsm git -bf       # Browse git repositories with fzf, showing a brief summary fetched from origin
> tsm git <path>    # Start session for git repo as path 'path'
> ```
> 
> Optional flags:
> - `-b`, `--brief` - Show git status information in the picker. Off by default so the picker
>   appears immediately.
> - `-f`, `--fetch` - Run `git fetch` before displaying status, so the ahead/behind counts reflect
>   the latest remote tracking info. Implies `-b`.
> - `-c`, `--no-custom-config` - Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` - Skip the [shared default configuration](#defining-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` - Prompt for the session name instead of using the suggested one.
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

> ### Git Worktrees (`tsm worktree`)
>
> Create a new tmux session rooted at a git worktree.
>
> **NOTE:** Can only be run when the current working directory is inside a git repo
>
> ```bash
> tsm worktree         # Browse worktrees for current git repo with fzf
> tsm worktree <wt>    # Start session for worktree named 'wt'
> ```
> 
> Optional flags:
> - `-c`, `--no-custom-config` - Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` - Skip the [shared default configuration](#defining-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` - Prompt for the session name instead of using the suggested one.
> 
> ![Launch Worktree Sessions](docs/worktree_launcher.gif)

> ### Zoxide (`zoxide`, Optional)
>
> The Zoxide version of `dir`
>
> Requires **[zoxide](https://github.com/ajeetdsouza/zoxide)**.
>
> ```bash
> tsm zoxide           # Browse zoxide entries interactively and start session from selection
> tsm zoxide <proj>    # Start a session at the best zoxide match for "proj"
> ```
> 
> Zoxide tracks directories you visit frequently, ranking them by "frecency" (frequency + recency). This makes
> it easy to jump to projects with just a few characters of the directory name.
> 
> When no query is provided, `tsm zoxide` uses `zoxide query -i` for interactive selection with fzf. When a query is
> provided, it uses `zoxide query` to find the best match directly.
> 
> Optional flags:
> - `-c`, `--no-custom-config` - Ignore a [custom configuration](#configured-sessions) rooted at
>   the selected repository.
> - `-d`, `--no-default-config` - Skip the [shared default configuration](#defining-a-default-configuration)
>   once the session is created.
> - `-p`, `--prompt-name` - Prompt for the session name instead of using the suggested one.
> 
> ![Zoxide Session Launcher](docs/zoxide_launcher.gif)

## AI Agents (`tsm agents`)

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
   with the state `unknown` (the agent is running, but nothing has told `tsm` what it is doing).

The commands recognized in step 2 default to:

```
claude codex aider cursor-agent opencode goose gemini amp crush copilot droid
```

Override the list with the `TSM_AGENT_CMDS` environment variable (whitespace separated):

```bash
export TSM_AGENT_CMDS="claude codex my-agent"
```

<a id="agent-state-hooks"></a>

<details>
<summary><strong style="font-size: 1.25em;">Agent State Hooks</strong></summary>

Process detection tells you an agent is *running*; it can't tell you whether it is churning through
a task, waiting on a permission prompt, or done. Agents that support notification hooks can report
that themselves.

`tsm agent-state <state>` records a state on the pane it is called from, as the pane-scoped tmux
option `@tsm_agent_state`. Valid states, in the order they sort in the picker:

| State | Meaning |
|-------|---------|
| `blocked` | The agent needs input, a permission prompt or a question |
| `done` | The agent finished its turn and its response is waiting |
| `idle` | The agent is running but has nothing in flight |
| `working` | The agent is busy |
| `clear` | Not a state. Removes the option, dropping the pane back to process detection |

Plus one pseudo-state:

| Argument | Meaning |
|----------|---------|
| `notification` | Derive the state from an agent notification payload on stdin |

The command is safe to call from anywhere: it does nothing outside of tmux, ignores unknown states,
and always exits `0` so a misconfiguration never surfaces as an error inside the agent.

See [Agent Hook Setup](docs/agent-hooks.md) for how to wire this into a particular agent.

</details>

<a id="configured-sessions"></a>

## Configured Sessions (`tsm configured`)

Script up the perfect window/pane layout and automate tasks like starting up services when a session starts.
Ideal for projects you work on regularly to keep things consistent and reproducible.

> ```bash
> tsm configured                   # Browse the set of configured sessions with fzf, then launch that session
> tsm configured <session-name>    # Start a configured session with name <session-name>
> ```

![Launch Configured Sessions](docs/configured_launcher.gif)

Session configurations are shell scripts stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<config-name>.sh`.

**The file's name is the session's name** (`myproject.sh` starts a session called `myproject`).

tsm owns the session's lifecycle: it creates the session before your configuration runs, and kills it
when you kill the session. Everything the file defines is therefore optional, and describes what you
want *beyond* a plain session:
  - `ROOT`: The session's root directory, used as the working directory for its windows and panes.
    Defaults to `$HOME`.
  - `start()`: Function that defines how the session should be customized. The session already exists
    by the time it runs. This is where you add windows, split panes, run services.
  - `kill()`: Runs asynchronously when the session is killed. Use this for cleanup tasks like stopping services.

> **NOTE:** Configuration file names cannot contain `.` or `:`. tmux reads both as the window and
> pane separators of a target, so a session named `my.project` would be created and then be
> unreachable. tsm refuses such a name rather than quietly renaming the session out from under you.

`tsm configured` is not the only way in. The [directory pickers](#directory-sessions) look for a
configuration whose `ROOT` is the path you picked, and start it when they find one, so `tsm dir`,
`tsm git`, `tsm worktree` and `tsm zoxide` all land on the configured session for a project that
has one. Their `-c`, `--no-custom-config` flag skips that lookup.

Nesting works, and the whole path under the configuration directory is the session name -- so a session can
be called `myrepo/base`, matching the `repo/worktree` names [worktree sessions](#git-worktrees) get, and
sort next to them in the switcher:

```
~/.config/tsm/
  notes.sh                ->  session "notes"
  myrepo/base.sh          ->  session "myrepo/base"
  myrepo/experiment.sh    ->  session "myrepo/experiment"
```

An empty file is a valid configured session. This will launch a new session
at `$HOME` with a single window and pane.

A configured session file with just `$ROOT` specified is also valid.
This will launch a session at the `$ROOT` with a single window and pane.

```bash
# ~/.config/tsm/notes.sh  ->  a session named "notes", rooted at ~/notes
ROOT="$HOME/notes"
```

### Building a Session

Session configurations are plain shell scripts calling `tmux` commands directly.
The session already exists by the time `start()` runs with one window holding one
pane, rooted at `ROOT`. Building a session involves splitting off that pane, creating
new windows, and sending commands into the panes that result:

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
`tmux display-message -p -t "$SESSION" '#{pane_id}'` is the way in. That command
prints that pane's id. Naming its window is one more command, and only worth doing
if you care what the window is called:

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
layout has `cd`'d somewhere else.

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

### Defining a Default Configuration

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

A configuration that defines no `start()` at all gets it automatically. tsm falls back to
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
`ROOT` already in the environment. `.default_config.sh` itself is excluded from the configured-session
list and picker, since it is not a session to start. A configuration that wants no layout at all
defines its own empty `start()` to opt out of the fallback.

### Logging

Output from the `start()` and `kill()` hooks is redirected to a dedicated log file.
Directory sessions are logged the same way when the default configuration runs, so
`.default_config.sh` is as debuggable as a configuration of its own. A session created with `-d`
runs no script and gets no log. Logs can be found in
`${XDG_STATE_HOME:-~/.local/state}/tsm/logs/<session-name>/tsm.log`.

Use `tsm logs` to browse all log files across sessions with fzf. The fzf preview pane shows the
tail of the currently highlighted file.

> **NOTE:** Each session's `tsm.log` file is wiped on each start or kill,
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
> See [Building a Session](#building-a-session) for the pane-addressing idiom these examples use, and
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
> itself runs asynchronously, commands within it still run sequentially. If one hangs or is slow, it
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
