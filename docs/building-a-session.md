# Building a Session

A session configuration is an executable program that calls `tmux` commands directly. There is no
DSL and no YAML abstraction over tmux, so anything tmux can do a configuration can do, and
`man tmux` is the reference for all of it.

Configurations are stored in `${XDG_CONFIG_HOME:-~/.config}/tsm/` and are reached by the
[directory pickers](../README.md#directory-sessions) when one claims the directory you picked.

## The contract

tsm runs your program with a verb and reads its answer. It never looks inside the file — it just
execs it — which is why a configuration can be written in any language, or be a compiled binary:

| Verb | Called when | What it should do |
| --- | --- | --- |
| `pattern` | resolving which configuration claims a directory | print an ERE of the directories it claims, on stdout |
| `name` | naming the session, before it exists | print the session name for the directory given as `$2`, on stdout |
| `start` | after tmux has created the session | build the layout |
| `kill` | asynchronously, when the session is killed | tear down what `start` built |

Three rules make it work in every language:

- **Only `pattern` and `name` treat stdout as an answer.** For `start` and `kill`, stdout is the
  [session log](#logging). A stray `echo` under `name` corrupts the name; under `start` it is just
  a log line.
- **A verb the program does not handle must exit 0.** That is how "no hook for this" is said. A
  `case` with no matching branch falls through and exits clean, which is exactly right. Only
  `pattern` is really required; everything else has a sensible default.
- **Nothing a configuration answers can fail the session.** A `pattern` that fails or prints
  nothing simply does not match. A `name` that fails or prints nothing falls back to the default
  derivation. `kill` is best-effort: tsm kills the tmux session either way.

`ROOT`, the claimed directory, is in the environment for `name`, `start` and `kill` — not for
`pattern`, which is asked before any particular directory has been settled on. `SESSION`, the name
of the session, is in the environment for `start` and `kill` — not for `name`, which is the verb
that decides it.

## The configuration file

**The file must be executable.** `chmod +x` is what makes it a configuration; a file without the
bit is ignored, which is what keeps a README or a half-written draft in the directory from being
mistaken for one.

**The file's name, minus any extension, identifies the configuration** in logs and error messages.
The extension is for your editor's benefit rather than tsm's, so `work`, `work.sh`, `work.fish` and
`work.py` are all the configuration `work`.

tsm owns the session's lifecycle:
- it names the session,
- creates it before your `start` runs,
- and kills it when you kill the session.

Everything the program answers beyond `pattern` is therefore optional, and describes what you want
*beyond* a plain session named after its directory.

The smallest useful configuration answers `pattern` and nothing else:

```bash
#!/bin/bash
# ~/.config/tsm/notes.sh  ->  claims ~/notes, session named "notes"
case "$1" in
  pattern) printf '%s\n' "^$HOME/notes$" ;;
esac
```

That is a configuration that changes nothing yet — it is the same bare session the directory would
have got on its own. It becomes useful the moment it answers `start`, or `name`.

**NOTE:** Session names cannot contain `.` or `:`. tmux reads both as the window and pane
separators of a target, so a session named `my.project` would be created and then be unreachable.
Names derived from a directory, and names a configuration returns from `name`, are
[sanitized](../README.md#session-names) rather than refused; a name you type at the `-p` prompt is
refused, since it is not tsm's to rewrite.

Nesting works, and the whole path under the configuration directory identifies the configuration:

```
~/.config/tsm/
  notes.sh                ->  configuration "notes"
  work/api.fish           ->  configuration "work/api"
  work/web.py             ->  configuration "work/web"
```

**NOTE:** The program runs once per verb, so its top level runs every time tsm asks it anything.
The directory pickers ask every configuration for its `pattern`, so keep the top level cheap and
put the work inside the branches. Anything expensive at the top level is paid on every `tsm dir`.

## Pane addressing

The session already exists by the time `start` runs, with one window holding one pane, rooted at
`ROOT`. Building a session means splitting off that pane, creating new windows, and sending
commands into the panes that result:

```bash
#!/bin/bash
case "$1" in
  pattern)
    printf '%s\n' "^$HOME/code/myproject$"
    ;;
  start)
    code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
    ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
    ;;
esac
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
  start)
    code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
    tmux rename-window -t "$code" code
    ;;
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
#!/bin/bash
# ~/.config/tsm/myproject.sh   (chmod +x)

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/projects/myproject$"
    ;;

  start)
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
    ;;
esac
```

## Example: starting and stopping services

A configuration for a project at `~/.config/tsm/myproject.sh`, with a `kill` branch that tears down
what `start` brought up:

```bash
#!/bin/bash

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/projects/myproject$"
    ;;

  start)
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
    ;;

  # Optional: the kill branch runs in the background when the session is killed.
  # This allows the tmux session to be killed immediately without waiting for
  # cleanup tasks to complete, providing a snappier user experience especially
  # when cleanup involves slow operations like stopping services.
  kill)
    # Stop the docker compose service that was started earlier.
    docker compose --project-directory "$ROOT" down
    ;;
esac
```

## Writing a configuration in another language

The contract is argv in, stdout and exit status out, so the language is entirely your choice. The
same `notes` configuration in fish and in Python:

```fish
#!/usr/bin/env fish
# ~/.config/tsm/notes.fish   (chmod +x)

# Quoted so that no verb at all expands to one empty argument rather than zero.
set -l verb "$argv[1]"

switch "$verb"
    case pattern
        printf '%s\n' "^$HOME/notes$"

    case name
        printf '%s\n' notes

    case start
        set -l code (tmux display-message -p -t "$SESSION" '#{pane_id}')
        tmux rename-window -t "$code" notes
        tmux send-keys -t "$code" 'nvim .' Enter

    case '*'
        exit 0
end
```

```python
#!/usr/bin/env python3
# ~/.config/tsm/notes.py   (chmod +x)

import os
import subprocess
import sys

SESSION = os.environ.get("SESSION", "")
ROOT = os.environ.get("ROOT", "")


def tmux(*args):
    """stderr is deliberately not captured, so tmux's own complaints reach the
    session log. check=True makes any failure fail the verb."""
    return subprocess.run(
        ("tmux",) + args, check=True, stdout=subprocess.PIPE, text=True
    ).stdout.strip()


def pattern():
    print("^" + os.path.expanduser("~/notes") + "$")


def name(path):
    print("notes")


def start(path):
    code = tmux("display-message", "-p", "-t", SESSION, "#{pane_id}")
    tmux("rename-window", "-t", code, "notes")
    tmux("send-keys", "-t", code, "nvim .", "Enter")


VERBS = {"pattern": lambda _: pattern(), "name": name, "start": start}

if __name__ == "__main__":
    verb = sys.argv[1] if len(sys.argv) > 1 else ""
    path = sys.argv[2] if len(sys.argv) > 2 else ROOT
    VERBS.get(verb, lambda _: None)(path)
```

**NOTE:** A `pattern` is matched by tsm with `grep -E`, not by your program, so it must be a POSIX
extended regular expression whatever language printed it. Python's `re`-only syntax (`\d`,
lookahead, non-greedy `*?`) will not work.

## Naming the session

A session is named after the directory it starts at: the sanitized basename, or `repo/worktree`
inside a git worktree. The `name` verb replaces that for every directory the configuration claims.

```bash
#!/bin/bash
# ~/.config/tsm/work.sh   (chmod +x)

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/code/work/"
    ;;

  name)
    # The claimed directory arrives as $2, and as $ROOT.
    echo "work/$(basename "$2")"
    ;;
esac
```

Only the first line of output is used, with surrounding whitespace trimmed. A configuration that
does not handle `name`, or that prints nothing, or that fails, gets the default derivation — a
naming scheme with no opinion about a particular directory is a normal thing to write, and it
should not wedge the pickers.

What it does print is sanitized rather than refused: every character outside `[A-Za-z0-9_-/]`
becomes `_`. A name is usually derived from something the configuration does not control — a branch,
a directory — and `feature/v1.2` is a reasonable thing to hand back and an unreasonable thing to
fail over. It arrives as `feature/v1_2`.

`SESSION` is deliberately *not* in the environment for `name`: it is the thing being computed.

**NOTE:** `tsm dir -p` beats `name`. The flag exists for the case the rules got wrong, so it is the
last word on the subject — though it still *offers* what `name` returned, so pressing enter accepts
it.

## Claiming directories

`pattern` is a [POSIX extended regular expression](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04)
tested against the directory you picked. One file can therefore describe a whole tree — "every
repository under `~/code/work` gets this layout" — without a file per repository:

```bash
#!/bin/bash
# ~/.config/tsm/work.sh   (chmod +x)

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/code/work/[^/]+$"
    ;;

  start)
    code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
    tmux rename-window -t "$code" code
    ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$code" -c "$ROOT")
    tmux send-keys -t "$code" 'nvim' Enter
    tmux send-keys -t "$ai" 'ai' Enter
    tmux select-pane -t "$code"
    ;;

  # kill)
  #   Implement kill if you need it
  #   ;;
esac
```

The match is unanchored, so anchor it yourself when you mean it. `^$HOME/code/work/[^/]+$` claims
the repositories directly under `~/code/work` and nothing deeper; `^$HOME/code/work/` claims
everything beneath it, at any depth; `^$HOME/code/work/myproject$` claims exactly one directory.

Being a regex rather than a glob is easy to forget. A pattern of `~/code/*` matches nothing at all:
`~` is not expanded inside quotes, and tsm tests against fully resolved absolute paths. Written
unquoted the tilde does expand, but `*` is still a regex quantifier on the preceding `/`, so
`~/code/*` reduces to "the path contains `/home/you/code`", which also claims `~/codegen`. Use
`$HOME` and anchor with `^`.

A session that a configuration claims gets its `start` on the way in and its `kill` on the way out.
`SESSION` is the session's name and `ROOT` is the directory you picked. A directory no `pattern`
claims gets a bare session and runs nothing.

### Precedence

Two patterns can claim the same directory. `^$HOME/code/work/` and `^$HOME/code/` both cover
`~/code/work/repo`, and only one configuration can name and build the session. **The longest pattern
wins.**

Length is a rough proxy for specificity, and it is the length of the *pattern* rather than of the
text it matched. That distinction is the whole design: `.*` matches an entire path and would beat
every pattern in the directory if matched text were the measure, when a catch-all is the one thing
that should always lose. At two characters it is the shortest useful pattern there is, so it sorts
last by construction:

```bash
#!/bin/bash
# ~/.config/tsm/default.sh   (chmod +x)
case "$1" in
  pattern) printf '%s\n' ".*" ;;
esac
```

Call it whatever you like. The file name no longer decides anything, so a catch-all needs no
`zz-` prefix to keep it out of the way.

| Path | `^$HOME/code/work/[^/]+$` | `^$HOME/code/` | `.*` | Winner |
| --- | --- | --- | --- | --- |
| `~/code/work/repo` | 26 | 16 | 2 | `^$HOME/code/work/[^/]+$` |
| `~/code/scratch` | — | 16 | 2 | `^$HOME/code/` |
| `~/notes` | — | — | 2 | `.*` |

(Scores are shown against a `$HOME` of `/home/you`; the pattern is measured after your shell expands
it, so the real numbers depend on the length of your home directory. Only the ordering matters.)

Two patterns of the same length are equally specific as far as this can tell, so the tie is broken
by byte order (`LC_ALL=C`) on the file path, first wins. That is deterministic, and it does not
change with your locale.

**NOTE:** Printing an empty `pattern` does not mean "match everything". Nothing printed reads as
declaring no pattern at all, and the file is skipped. Print `.*`.

### Seeing the ranking (`tsm match`)

Precedence is the one thing about a configuration you cannot read off the file, because it depends
on every *other* file too. `tsm match` answers it for a given directory:

```
$ tsm match ~/code/work/repo
26	/home/you/.config/tsm/work.sh
16	/home/you/.config/tsm/code.sh
2	/home/you/.config/tsm/default.sh
```

One tab-separated `<score>\t<file>` per claiming configuration, best first. **The first line is the
configuration that would name and build a session at that path**, and the rest are what
`tsm apply-matching-config` would fall through to, in order. With no argument it tests the current
directory.

Nothing on stdout means nothing claims the directory — it would get a bare session. That case says
so on stderr and exits non-zero, so `tsm match "$dir" >/dev/null` is a usable test.

It is also the fastest way to find a pattern that is not claiming what you think. A pattern of
`^$HOME/code/project/` has a trailing slash, so it claims everything *under* `~/code/project` but
not that directory itself:

```
$ tsm match ~/code/project          # nothing: the trailing / is not there to match
$ tsm match ~/code/project/feature  # claimed
35	/home/you/.config/tsm/project.sh
```

### Falling through to the next configuration

A configuration that matches first does not inherit the one behind it. It opts in, by calling
`tsm apply-matching-config` under `start` and `tsm kill-matching-config` under `kill`:

```bash
#!/bin/bash
# ~/.config/tsm/myproject.sh   (chmod +x)

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/code/work/myproject$"
    ;;

  start)
    tsm apply-matching-config
    make -C "$ROOT" up &
    ;;

  kill)
    tsm kill-matching-config
    make -C "$ROOT" down
    ;;
esac
```

`tsm apply-matching-config` finds the **next** configuration down the
[ranking](#precedence) whose `pattern` also matches `$ROOT` -- `work.sh` above, whose
`^$HOME/code/work/[^/]+$` is shorter than the `^$HOME/code/work/myproject$` here -- and runs its
`start`. `tsm kill-matching-config` does the same for its `kill`. `tsm match "$ROOT"` prints that
chain in the order it will run. Both run at the point they are called, with
`SESSION` and `ROOT` already in the environment, so a configuration is free to do its own work
before or after the shared setup. A configuration reached this way can fall through in turn, so a
chain of them composes. If nothing further matches `$ROOT`, both are a no-op and say so in the
session log. The files need not be written in the same language: tsm execs each one on its own.

## Beyond tmux commands

Since each configuration is a full program, you're not limited to running commands inside tmux
panes and windows.

You can kick off commands in the background with `&` so they don't block session startup. The
session attaches immediately while the command continues running, and its output is captured in the
[log file](#logging) for later review.

```bash
#!/bin/bash

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/projects/webapp$"
    ;;

  start)
    code=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
    tmux send-keys -t "$code" 'nvim' Enter

    # Start a service in the background so it doesn't block session startup.
    # Build output and errors are captured in the tsm log file.
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting my webapp"
    docker compose --project-directory "$ROOT" up --build --force-recreate --detach &
    ;;

  kill)
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Stopping my webapp"
    docker compose --project-directory "$ROOT" down
    ;;
esac
```

**NOTE:** Background cleanup tasks under `kill` with `&` so they run in parallel. Although the
`kill` verb itself runs asynchronously, commands within it still run sequentially. If one hangs or
is slow, it will block the rest.

## Logging

Output from the `start` and `kill` verbs is redirected to a dedicated log file. A session that
matched no configuration, or one created with `-c`, runs no program and gets no log. Logs can be
found in `${XDG_STATE_HOME:-~/.local/state}/tsm/logs/<session-name>/tsm.log`.

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
