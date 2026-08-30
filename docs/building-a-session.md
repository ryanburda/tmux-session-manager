# Building a Session

Session configurations are plain shell scripts calling `tmux` commands directly. There is no DSL
and no YAML abstraction over tmux, so anything tmux can do a configuration can do, and `man tmux`
is the reference for all of it.

Configurations are stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/<config-name>.sh` and launched with
[`tsm configured`](../README.md#configured-sessions), or by the
[directory pickers](../README.md#directory-sessions) when one claims the directory you picked.

## The configuration file

**The file's name is the session's name** (`myproject.sh` starts a session called `myproject`).

tsm owns the session's lifecycle: it creates the session before your configuration runs, and kills it
when you kill the session. Everything the file defines is therefore optional, and describes what you
want *beyond* a plain session:

- `ROOT`: The session's root directory, used as the working directory for its windows and panes.
  Defaults to `$HOME`.
- `start()`: Function that defines how the session should be customized. The session already exists
  by the time it runs. This is where you add windows, split panes, run services.
- `kill()`: Runs asynchronously when the session is killed. Use this for cleanup tasks like stopping
  services.

Both functions run with `SESSION`, the name of the session, and `ROOT` already in the environment.

**NOTE:** Configuration file names cannot contain `.` or `:`. tmux reads both as the window and
pane separators of a target, so a session named `my.project` would be created and then be
unreachable. tsm refuses such a name rather than quietly renaming the session out from under you.

An empty file is a valid configured session, launching a session at `$HOME` with a single window and
pane. So is a file with nothing but a `ROOT`, which launches that session at `ROOT`:

```bash
# ~/.config/tsm/notes.sh  ->  a session named "notes", rooted at ~/notes
ROOT="$HOME/notes"
```

Nesting works, and the whole path under the configuration directory is the session name -- so a session can
be called `myrepo/base`, matching the `repo/worktree` names
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

## Example: an editor and an agent

An editor on the left, an AI agent on the right, focus back on the editor.

```bash
ROOT="$HOME/projects/myproject"

start() {
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$code" code
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
  tmux send-keys -t "$code" 'nvim' Enter
  tmux send-keys -t "$ai" 'ai' Enter
  tmux select-pane -t "$code"
}
```

## Example: multiple windows

```bash
ROOT="$HOME/projects/myproject"

start() {
  # First window: the one the session starts with. Just an editor.
  code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  tmux rename-window -t "$code" code
  tmux send-keys -t "$code" 'nvim' Enter

  # Second window: an editor with an agent to the right and a terminal below.
  nav=$(tmux new-window -P -F '#{pane_id}' -t "$SESSION" -n nav -c "$ROOT")
  nav_ai=$(tmux split-window -P -F '#{pane_id}' -h -l 30% -t "$nav" -c "$ROOT")
  nav_terminal=$(tmux split-window -P -F '#{pane_id}' -v -l 20% -t "$nav" -c "$ROOT")
  tmux send-keys -t "$nav" 'nvim lua/init.lua' Enter
  tmux send-keys -t "$nav_ai" 'ai' Enter
  tmux send-keys -t "$nav_terminal" 'ls' Enter
  tmux select-pane -t "$nav"

  # The last window created is the one you would attach to, so pick explicitly.
  tmux select-window -t "$SESSION:code"
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
in `${XDG_CONFIG_HOME:-~/.config}/tsm/.default_config.sh` -- the body of a `start()`, without the
wrapper:

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

The [directory pickers](../README.md#directory-sessions) apply it too, to every session they create
that no configuration of its own claims.

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
