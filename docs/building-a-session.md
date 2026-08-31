# Building a Session

Session configurations are plain shell scripts calling `tmux` commands directly. There is no DSL
and no YAML abstraction over tmux, so anything tmux can do a configuration can do, and `man tmux`
is the reference for all of it.

Configurations are stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<config-name>.sh` and launched with
[`tsm configured`](../README.md#configured-sessions), or by the
[directory pickers](../README.md#directory-sessions) when one claims the directory you picked.

## The configuration file

**The file's name is the session's name** (`myproject.sh` starts a session called `myproject`).

tsm owns the session's lifecycle:
- it creates the session before your configuration runs,
- and kills it when you kill the session.

Everything the file defines is therefore optional, and describes what you want *beyond* a plain session:

- `ROOT`: The session's root directory, used as the working directory for its windows and panes.
  Defaults to `$HOME`.
- `start()`: Function that defines how the session should be customized. The session already exists
  by the time it runs. This is where you add windows, split panes, run services.
- `kill()`: Runs asynchronously when the session is killed. Use this for cleanup tasks like stopping
  services.

Both functions run with `SESSION`, the name of the session, and `ROOT` already in the environment.

A configuration that defines no `start()` gets exactly the plain session described above. The
[default configuration](#defining-a-default-configuration) is opted into, never inherited.

**NOTE:** Configuration file names cannot contain `.` or `:`. tmux reads both as the window and
pane separators of a target, so a session named `my.project` would be created and then be
unreachable. tsm refuses such a name rather than quietly renaming the session out from under you.

An empty file is a valid configured session, launching a session at `$HOME` with a single window and
pane. So is a file with nothing but a `ROOT`, which launches that session at `ROOT`:

```bash
# ~/.config/tsm/notes.sh  ->  a session named "notes", rooted at ~/notes
ROOT="$HOME/notes"
```

Nesting works, and the whole path under the configuration directory is the session name. For
example, a session can be called `myrepo/base`, matching the `repo/worktree` names
[worktree sessions](../README.md#git-worktrees) get, and sort next to them in the switcher:

```
~/.config/tsm/
  notes.sh                ->  session "notes"
  myrepo/base.sh          ->  session "myrepo/base"
  myrepo/experiment.sh    ->  session "myrepo/experiment"
```

## Pane addressing

The session already exists by the time `start()` runs, with one window holding one pane, rooted at
`ROOT`. Building a session means splitting off that pane, creating new windows, and sending
commands into the panes that result:

```bash
ROOT="$HOME/code/myproject"

start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
}
```

Pane addressing is the thing that is easy to get wrong. `-P -F '#{pane_id}'` makes `split-window`
and `new-window` print the id of the pane they just created, so layouts are built by capturing ids
and splitting off them. Positional targets like `"$SESSION:code.1"` shift underneath you as soon as
a later split renumbers the window; ids never do.

The session tsm hands you has one window holding one pane, so
`tmux display-message -p -t "$SESSION" '#{pane_id}'` is the way in. That command prints that pane's
id. Naming its window is one more command, and only worth doing if you care what the window is
called:

```bash
start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$code" code
}
```

A pane id is a valid `-t` target for `rename-window`: it names the window that pane is in, which
saves constructing a window target of your own.

`-c "$ROOT"` is worth passing to every `split-window` and `new-window`. Without it a new pane
inherits the working directory of the pane it came from, which is only `ROOT` until something in
the layout has `cd`'d somewhere else.

## Example: a useful default

This config creates:
- A window named `code` with:
  - your editor on the left
  - a coding agent on the right
- A window named `terminal` with nothing to run

```bash
ROOT="$HOME/projects/myproject"

start() {
  # code window with `nvim` on left and `ai` on right.
  code_window='code'
  nvim=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$nvim" "$code_window"
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$nvim" -c "$ROOT")
  tmux send-keys -t "$nvim" 'nvim' Enter
  tmux send-keys -t "$ai" 'ai' Enter
  
  # terminal window
  terminal_window='terminal'
  tmux new-window -t "$SESSION" -n "$terminal_window" -c "$ROOT"
  
  # session starts focused on `nvim` in 'code' window
  tmux select-window -t "$SESSION:$code_window"
  tmux select-pane -t "$nvim"
}
```

## Example: starting and stopping services

A configuration for a project at `~/.config/tsm/myproject.sh`, with a `kill()` hook that tears down
what `start()` brought up:

```bash
ROOT="$HOME/projects/myproject"

start() {
  # Take the pane the session starts with and name its window 'code'.
  # This window will have two vertical splits:
  #     - nvim on top 80%
  #     - a terminal at the bottom 20%
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$code" code
  tmux split-window -v -l 20% -t "$code" -c "$ROOT"   # a plain shell; no pane id needed
  tmux send-keys -t "$code" 'nvim' Enter

  # Create a second window named 'docker'.
  # This window will have an even-vertical layout with:
  #     - a terminal that starts docker compose on top
  #     - lazydocker on bottom
  compose=$(tmux new-window -P -F '#{pane_id}' -t "$SESSION" -n docker -c "$ROOT")
  lazydocker=$(tmux split-window -P -F '#{pane_id}' -v -l 50% -t "$compose" -c "$ROOT")
  tmux send-keys -t "$compose" 'docker compose up --force-recreate --detach' Enter
  tmux send-keys -t "$lazydocker" 'lazydocker' Enter
  tmux select-layout -t "$SESSION:docker" even-vertical

  # Select first window
  tmux select-window -t "$SESSION:code"
}

# Optional: cleanup function runs in background when session is killed.
# This allows the tmux session to be killed immediately without waiting for
# cleanup tasks to complete, providing a snappier user experience especially
# when cleanup involves slow operations like stopping services.
kill() {
  # Stop the docker compose service that was started earlier.
  docker compose --project-directory "$ROOT" down
}
```

## Defining a Default Configuration

Most configurations end up wanting the same layout. Rather than repeat it in every file, put it once
in `${XDG_CONFIG_HOME:-~/.config}/tsm/.default_config.sh`. It is a configuration like any other:
`start()` builds the layout, `kill()` tears down whatever `start()` brought up.

```bash
# ~/.config/tsm/.default_config.sh
start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$code" code
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
  tmux send-keys -t "$code" 'nvim' Enter
  tmux send-keys -t "$ai" 'ai' Enter
  tmux select-pane -t "$code"
}

# kill() {
#   # Implement kill if you need it
# }
```

[Directory sessions](../README.md#directory-sessions) get both hooks without asking: any session
`tsm dir`, `tsm git`, `tsm worktree` or `tsm zoxide` creates that no configuration of its own claims
runs the default `start()` on the way in and the default `kill()` on the way out. `SESSION` is the
new session's name and `ROOT` is the directory you picked.

Configurations of your own get neither. Opt in by calling `tsm apply-default-config` in `start()`
and `tsm kill-default-config` in `kill()`:

```bash
# ~/.config/tsm/myproject.sh
ROOT="$HOME/code/myproject"

start() {
  tsm apply-default-config
  make -C "$ROOT" up &
}

kill() {
  tsm kill-default-config
  make -C "$ROOT" down
}
```

`tsm apply-default-config` sources `.default_config.sh` and runs its `start()`.
`tsm kill-default-config` does the same for its `kill()`. Both run at the point they are called,
with `SESSION` and `ROOT` already in the environment, so a configuration is free to do its own work
before or after the shared setup.

`.default_config.sh` is excluded from the configured-session list and picker, since it is not a
session to start.

**NOTE:** Like every configuration, the file is sourced on the way in *and* on the way out, so
top-level code runs on both. The layout belongs inside `start()`. Anything left at the top level
runs a second time as the session is torn down.

## Beyond tmux commands

Since each session file is a full shell script, you're not limited to running commands inside tmux
panes and windows.

You can kick off commands in the background with `&` so they don't block session startup. The
session attaches immediately while the command continues running, and its output is captured in the
[log file](#logging) for later review.

```bash
ROOT="$HOME/projects/webapp"

start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux send-keys -t "$code" 'nvim' Enter

  # Start a service in the background so it doesn't block session startup.
  # Build output and errors are captured in the tsm log file.
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting my webapp"
  docker compose --project-directory "$ROOT" up --build --force-recreate --detach &
}

kill() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Stopping my webapp"
  docker compose --project-directory "$ROOT" down
}
```

**NOTE:** Background cleanup tasks in `kill()` with `&` so they run in parallel. Although `kill()`
itself runs asynchronously, commands within it still run sequentially. If one hangs or is slow, it
will block the rest.

## Logging

Output from the `start()` and `kill()` hooks is redirected to a dedicated log file.
Directory sessions are logged the same way when the default configuration runs, so
`.default_config.sh` is as debuggable as a configuration of its own. A session created with `-d`
runs no script and gets no log. Logs can be found in
`${XDG_STATE_HOME:-~/.local/state}/tsm/logs/<session-name>/tsm.log`.

Use `tsm logs` to browse all log files across sessions with fzf. The fzf preview pane shows the
tail of the currently highlighted file.

**NOTE:** Each session's `tsm.log` file is wiped on each start or kill, so it only contains output
from the most recent invocation. This prevents log files from growing unbounded.

**NOTE:** When backgrounding multiple processes, their output may interleave in the tsm log file.
To avoid this, redirect each process to its own log file in the session's log directory:

```bash
docker compose up --detach > "$HOME/.local/state/tsm/logs/$SESSION/docker.log" 2>&1 &
pg_ctl start -l "$HOME/.local/state/tsm/logs/$SESSION/postgres.log" &
```

These files will be browsable with `tsm logs`.
