# tmux-session-manager

`tsm` launches tmux sessions at directories. That's its whole job.

One command starts them, and a directory is the only thing it wants:

```bash
tsm at <path> [-c] [-p]
```

So anything that prints a directory can name one, through the shell's own command substitution.
That is the whole of the integration, and `tsm` has no part in it: your shell runs the program,
`tsm` gets a path. Some programs answer straight away:

```bash
tsm at "$(git rev-parse --show-toplevel)"    # the root of the repo you are in
tsm at "$(pwd)"                              # the current directory
tsm at "$(mktemp -d)"                        # a fresh scratch session
```

Others ask first, and print what you chose:

```bash
tsm at "$(zoxide query -i)"                  # your most-used directories
tsm at "$(dir-mark pick)"                    # a directory you marked
```

`tsm` has nothing built in for either kind. It reserves no names, keeps no list, and has no
plugin interface -- `git` above is git, run and finished before `tsm` starts. Four example
programs ship with it in [`examples/`](examples), and they are installed the way any other
program is: put one on your PATH, or don't.

| example | prints |
|---|---|
| [`examples/fzf-dir`](examples/fzf-dir) | a directory, chosen with fzf |
| [`examples/fzf-git`](examples/fzf-git) | a git repository, chosen with fzf |
| [`examples/fzf-git-brief`](examples/fzf-git-brief) | a git repository that has something to show |
| [`examples/fzf-worktree`](examples/fzf-worktree) | a worktree of the current repository |

```bash
ln -s ~/.local/share/tmux-session-manager/examples/fzf-git ~/.local/bin/fzf-git
tsm at "$(fzf-git)"
```

Each is one self-contained file: nothing to source, nothing to install, and no reason to keep
tsm's copy if you would rather copy it somewhere and change what it lists. See
[Writing your own](#writing-your-own), and [Programs you already have](#programs-you-already-have)
for the ones on your machine already.

Once a directory is named, every session is created or entered the same way:

1. **Does a session already exist for that directory?** Switch to it.
2. **Does a configuration claim that directory?** Use that configuration
   when creating/naming the session.
3. **Otherwise:** create a plain session named after the directory.

So `fzf-worktree` is not a different feature from `fzf-dir`. A program prints a directory and
stops there -- no flags, no say in the session that follows, no knowledge that `tsm` exists --
which is why writing one of your own is worth so little.

See [Usage](#usage) for the full list of commands, and
[Session Configuration](#session-configuration) for details on how to customize sessions.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

This clones the repository to `${XDG_DATA_HOME:-~/.local/share}/tmux-session-manager` and symlinks
`tsm` into `~/.local/bin`. Re-run it any time to update.

It links `tsm` and nothing else. `tsm` itself needs only `bash` and `tmux`; the examples are
opt-in, one symlink each, and those are what want `fzf`:

```bash
ln -s ~/.local/share/tmux-session-manager/examples/fzf-git ~/.local/bin/fzf-git
tsm at "$(fzf-git)"
```

<details>
<summary><strong style="font-size: 1.25em;">Custom Installation</strong></summary>

Two environment variables change where things land: `TSM_HOME` (where the repo is cloned) and
`BIN_DIR` (where the `tsm` symlink goes).

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh \
  | TSM_HOME=~/src/tsm BIN_DIR=~/bin sh
```

Or manually: clone the repo, symlink `tsm` into a directory on your PATH.

```bash
git clone https://github.com/ryanburda/tmux-session-manager.git ~/git/tmux-session-manager
ln -s ~/git/tmux-session-manager/tsm ~/.local/bin/tsm
```
</details>

<details>
<summary><strong style="font-size: 1.25em;">Shell Completions</strong></summary>

Completions cover active session names, directories, and sessions with logs. Paths below assume the install script's checkout location; substitute your own if you
cloned elsewhere.

**Bash**: add to `~/.bashrc`:

```bash
source ~/.local/share/tmux-session-manager/completions/tsm.bash
```

**Zsh**: add to `~/.zshrc` (or rename `tsm.zsh` to `_tsm` in an existing fpath directory):

```bash
fpath=(~/.local/share/tmux-session-manager/completions $fpath)
autoload -Uz compinit && compinit
```

**Fish**:

```bash
ln -s ~/.local/share/tmux-session-manager/completions/tsm.fish ~/.config/fish/completions/
```
</details>

<details>
<summary><strong style="font-size: 1.25em;">tmux Keybindings</strong></summary>

`tsm` is best driven from tmux keybinds in `~/.tmux.conf`:

```bash
bind-key s popup -E "tsm active"     # active session switcher
bind-key k popup -E "tsm kill"       # kill session selector
bind-key X run-shell "tsm kill #{session_name}"   # kill current session (runs its kill hook)
bind-key l run-shell "tsm last"      # most recent session still open

# Directory based sessions -- fzf-* are the examples, symlinked onto PATH
bind-key d popup -E 'tsm at "$(fzf-dir)"'                         # any directory
bind-key g popup -E 'tsm at "$(fzf-git)"'                         # a git repository
bind-key G popup -E 'tsm at "$(fzf-git-brief)"'                   # repositories with changes
bind-key w popup -E 'tsm at "$(fzf-worktree)"'                    # a worktree of this repo
bind-key b popup -E 'tsm at "$(dir-mark pick)"'                   # a marked directory
bind-key z popup -E 'tsm at "$(zoxide query -i)"'                 # anything that prints a path
bind-key r run-shell 'tsm at "$(git rev-parse --show-toplevel)"'  # this repo's root

# Marked directories (dir-mark)
bind-key m command-prompt -1 -p "Set mark:"    "run-shell -b \"dir-mark set '%%%'\""
bind-key \' command-prompt -1 -p "Go to mark:" { run-shell -b "tsm at \"$(dir-mark path '%%%')\"" }
bind-key M command-prompt -1 -p "Remove mark:" "run-shell -b \"dir-mark remove '%%%'\""

# Session logs
bind-key L popup -E "tsm logs"
```

**The quoting.** The substitution is your shell's, so the binding only has to reach the shell
intact. tmux performs no replacements inside single quotes, so wrapping the whole command in
them hands `sh` exactly what you wrote, the inner `"` included -- and those inner quotes are
what keep a directory with a space in its name one argument. The unquoted
`popup -E "tsm at $(fzf-dir)"` works right up until it meets `~/Documents/My Notes`.

The `'` binding cannot be wrapped in single quotes, since `%%%` already sits inside a pair of
them; tmux's braces do the same job and can hold quotes.

The `dir-mark` bindings want [`dir-mark`][dir-mark], a separate tool that maps one character to
one directory -- see [Marked directories](#marked-directories). It is not a dependency of
`tsm`: `dir-mark path m` prints a path, which is all `tsm at` ever asks for.

Those three ask in tmux's status line, so they need no popup: `-1` takes exactly one key and
`%%%` substitutes it with quotation marks escaped. `'` and `;` are the two keys that cannot be
answered with -- `;` is tmux's own command separator.

<details>
<summary><strong>Troubleshooting Keybinds</strong></summary>

> tmux's `run-shell` and `popup -E` run in a non-interactive, non-login shell, so `tsm` must be
> on PATH when that shell starts.
>
> - **zsh:** put your PATH setup in `~/.zshenv` (not `.zshrc`).
> - **bash:** set `BASH_ENV` to a file that configures your PATH, or use `/etc/environment`.
>
> | Shell | Login | Interactive | Non-interactive |
> |-------|-------|-------------|-----------------|
> | **zsh** | zshenv → zprofile → zshrc → zlogin | zshenv → zshrc | zshenv only |
> | **bash** | /etc/profile → (~/.bash_profile OR ~/.bash_login OR ~/.profile) | ~/.bashrc | $BASH_ENV only (if set) |
>
> The same goes for the program inside the substitution, which that same shell looks up on
> PATH. Fallback: use full paths in the bindings, e.g. `bind-key d popup -E
> '~/.local/share/tmux-session-manager/tsm at "$(~/.local/share/tmux-session-manager/examples/fzf-dir)"'`.
>
> The same file is where any environment your own program reads has to be set (e.g.
> `FZF_DEFAULT_COMMAND`), or it will behave differently inside a tmux popup than in your shell.

</details>

</details>

## Usage

```bash
tsm                                  # Show help message
tsm active [session]                 # Switch to an existing session
tsm kill [session]                   # Kill session (runs its kill hook if present)
tsm last                             # Switch to the most recent session that is still open

tsm at <path> [-c] [-p]              # Start a session at a directory, or switch to the
                                     # session already open there

  -c, --no-config                    # Ignore any configuration claiming that path
  -p, --prompt-name                  # Prompt for the session name instead of using the default

tsm match [path]                     # Configurations claiming a path, best first (defaults to the current directory)
tsm logs [session]                   # Browse session logs
```

A directory is all `tsm at` takes, so anything that prints one names it through the shell's own
command substitution. There is nothing to register and no list of names `tsm` treats specially
(see [Writing your own](#writing-your-own)):

```bash
tsm at "$(fzf-git)"                  # an example you symlinked onto PATH
tsm at "$(zoxide query -i)"
tsm at "$(dir-mark path m)"
tsm at "$(~/bin/my-chooser --since yesterday)"
```

The four examples each ask with fzf, take no arguments, and print the directory you chose. They
are ordinary programs, so running one on its own prints its answer:

```bash
ln -s ~/.local/share/tmux-session-manager/examples/fzf-dir ~/.local/bin/fzf-dir
fzf-dir                              # prints a directory
tsm at "$(fzf-dir)"                  # ...and that is the session
```

Press escape and `fzf-dir` prints nothing, so the substitution is empty and `tsm at` is left
with no directory to open. It does nothing, which is the whole of "cancel": no exit status to
arrange, nothing to special-case. Keep the quotation marks and a directory with a space in its
name stays one argument.

<a id="from-a-directory-to-a-session"></a>

## From a directory to a session

`tsm at` is handed one directory and takes it from there. Whatever produced that path -- typed
out, an example that shipped with tsm, `zoxide`, something you wrote -- had one job and has
already finished it: it decided nothing about the session that follows, and by the time `tsm`
runs, all it has is a path. So the rules below hold for every one of them equally.

A named directory becomes a session by the same three rules:

1. **A session is already open at that path?** Switch to it.
2. **A configuration's `pattern` claims the path?** Its `name` names the session, and its `start`
   builds it. See [Session Configuration](#session-configuration).
3. **Otherwise:** a bare session named after the directory.

The first check is about the path, not the name: `tsm` records the directory a session was
started at on the session itself (`@tsm_path`), so naming a directory you already have open
returns to that session, even if it has been renamed.

The flags are tsm's, and they mean the same thing however the directory arrived:

- `-c`, `--no-config`: ignore the configuration claiming the directory (both its `name` and its
  `start`), leaving a bare session named after the directory.
- `-p`, `--prompt-name`: prompt for the session name. The suggestion is whatever the rules
  produced, so enter accepts it and anything typed replaces it. When the path already has a
  session, `-p` has nothing to name and simply switches to it.

They can sit on either side of the path, because a program's own flags never meet them: `-i` in
`tsm at "$(zoxide query -i)"` is inside the substitution, where the shell has already run
`zoxide` and consumed it long before `tsm` starts.

```bash
tsm at -p "$(fzf-git)"
tsm at "$(fzf-git)" -p
```

That is also why `tsm` shadows nothing. It sees a path and never a program name, so `git` in
`tsm at "$(git rev-parse --show-toplevel)"` is git, and no name of tsm's could get in its way.

### Session names

A session is named after the directory it starts at: the sanitized basename, or `repo/worktree`
inside a git worktree.

```
~/code/api                        ->  api
~/code/project/.bare              ->  (the repository)
~/code/project/feature            ->  project/feature
```

Sanitizing replaces every character outside `[A-Za-z0-9_-/]` with `_`. `/` survives, since it joins
the two halves of a worktree name. `.` and `:` do not: tmux target syntax is
`session:window.pane`, so a session holding either could be created but never switched to or
killed again.

**Collisions.** Because a session is identified by its path, two *different* directories whose
names land on the same string (`~/code/api` and `~/work/api` are both `api`) are reported rather
than silently merged, and you are asked for a name:

```
$ tsm at ~/work/api
Session name collision
  name              api
  new session at    /home/you/work/api
  'api' is open at  /home/you/code/api
Enter session name:
```

**Naming from a configuration.** The `name` verb replaces the default derivation for every
directory a configuration claims: name sessions after their branch, group a tree under a
`work/` prefix, and so on. See [Naming the session](docs/building-a-session.md#naming-the-session).

### The examples

The four in [`examples/`](examples) are not part of `tsm` -- they are programs it happens to
ship, each one self-contained in a single file. Symlink the ones you want onto your PATH, or
copy one somewhere and change what it lists:

```bash
tsm=~/.local/share/tmux-session-manager
ln -s $tsm/examples/fzf-dir       ~/.local/bin/fzf-dir
ln -s $tsm/examples/fzf-git       ~/.local/bin/fzf-git
ln -s $tsm/examples/fzf-git-brief ~/.local/bin/fzf-git-brief
ln -s $tsm/examples/fzf-worktree  ~/.local/bin/fzf-worktree
```

All four ask with fzf, because that is the interesting half to show. Nothing requires it: a
program that prints `$PWD` and exits is just as valid, and the section below has several.

#### `examples/fzf-dir`

The shortest of the four, and the whole of it:

```bash
selected=$(find "$HOME" -name ".*" -prune -o -type d -print \
  | fzf --cycle --prompt "Directory > ")

[ -n "$selected" ] || exit 0

printf '%s\n' "$selected"
```

Every directory under `$HOME`, at any depth, skipping hidden ones and everything inside them.
There is nothing to configure: to list something else, copy the file and change the `find`. A
narrower one that stops at each repository root, for instance, and so never descends into
`node_modules` or `target`:

```bash
find "$HOME/code" -name ".*" -prune -o -type d \( -exec test -e {}/.git \; -print -prune -o -print \)
```

![Launch Directory Sessions](docs/directory_example.gif)

#### `examples/fzf-git`

Finds every git **working tree** under `$HOME`, at any depth, skipping hidden directories:

```bash
find "$HOME" -name .git -prune -print -o -name ".*" -prune 2>/dev/null \
  | while IFS= read -r gitpath; do
      if [ -d "$gitpath" ]; then
        [ -e "$gitpath/HEAD" ] || continue
        grep -q '^[[:space:]]*bare = true' "$gitpath/config" 2>/dev/null && continue
      fi
      printf '%s\n' "${gitpath%/.git}"
    done
```

It looks for the `.git` itself rather than asking each directory whether it has one, because
`.git` is not always a directory. A **linked worktree**, and a **checkout of a bare clone**,
each carry a `.git` *file* holding a `gitdir:` line; matching by name finds those the same way
it finds an ordinary clone. The two `-prune`s do different jobs, and their order matters: the
first stops `find` descending into a `.git` it has found, the second skips hidden directories
and comes second so that `.git` is not treated as one of them.

The loop then drops what you cannot open a session in:

| skipped | why |
|---|---|
| a `.git` directory with no `HEAD` | not a repository -- a stray directory that happens to be named `.git` |
| a `.git` directory with `bare = true` | a bare clone has no working tree; the worktrees checked out beside it are listed on their own, and are what you want to sit in |

So the `~/code/project/.bare` layout lists `project/main` and `project/feature-x`, not `project`
itself.

As with `fzf-dir` there is nothing to configure: copy the file and change the `find` if you
want it to look somewhere else -- rooting it at `$HOME/code` rather than `$HOME` is the usual
change, and it is faster.

It lists paths and nothing else, so it appears immediately. [`git-brief`](#tsm-git-brief) is
the same list narrowed to the repositories that have changed, with a git status brief beside
each; it is a separate program rather than a flag on this one, because fetching every
repository is a different thing to ask for.

![Launch Git Sessions](docs/git_example.gif)

<a id="tsm-git-brief"></a>

#### `examples/fzf-git-brief`

`fzf-git`, narrowed to the repositories that have something to show and annotated with what it
is: branch, ahead/behind counts, and the size of the working diff.

```bash
fzf-git-brief                  # prints the path
tsm at "$(fzf-git-brief)"      # ...and opens the session
```

A repository earns a row by having **commits waiting upstream**, **commits not yet pushed**, or
**uncommitted work** -- staged, unstaged or untracked. One that is level with its upstream and
clean is left out: there is nothing there to go and look at, which is the only reason to open
this at all. The fzf header says how many of the repositories checked made the list, so a short
list is distinguishable from a broken search:

```
:: 3 of 41 repositories have changes
```

Each row reads `branch ↑ahead ↓behind +added -removed ?untracked`, and a field appears only when
it is non-zero:

| field | |
|---|---|
| `↑2` | two commits not yet pushed |
| `↓5` | five commits waiting on the upstream |
| `+31 -4` | lines added and removed since the last commit, staged and unstaged counted together |
| `?3` | three untracked entries; a new directory counts once, and ignored files never |

When nothing has changed it says so and exits rather than opening an empty list.

The one state it cannot judge is a branch with **no upstream**: there is nothing to measure
"unpushed" against, so such a repository is listed only when it has uncommitted work of its own.

Every repository is fetched before it is inspected, so the ahead/behind counts are current --
that is the point of asking for a brief. It is also what makes this slower to appear than
`git`, which is there for when you just want the list.

It checks the repositories `fzf-git` lists, by the same `find`, and fetches 8 of them at a
time. Neither is configurable -- copy the file and change it. The fetch parallelism is the one
worth knowing about: each job opens a remote connection, so lower the `-P 8` on the `xargs` if
your connection is metered.

[`examples/fzf-git-brief`](examples/fzf-git-brief) is the longest of the four and the best one
to copy: everything below its `fzf` call is just deciding what to list.

<a id="git-worktrees"></a>

#### `examples/fzf-worktree`

A worktree of the current repository, in a session named `repo/worktree`. Must be run from
inside a git repo.

![Launch Worktree Sessions](docs/worktree_example.gif)

<a id="bookmarks"></a>
<a id="marked-directories"></a>

## Marked directories

[`dir-mark`][dir-mark] maps one printable character to one directory, the way vim marks do --
for the handful of directories you return to constantly. It used to be four `tsm bookmark-*`
subcommands; it is now a tool of its own, because naming a directory and opening a session at
one are two different jobs.

```bash
tsm at "$(dir-mark path m)"              # a session at whatever m marks
tsm at "$(dir-mark pick)"                # ...or at one you choose, with fzf
```

That is the entire integration, and it is the same `tsm at` line anything else would use --
`tsm` has no idea what a mark is. `dir-mark` also draws the marks that have a session open into
the tmux status line; see its [README][dir-mark].

<a id="programs-you-already-have"></a>

## Programs you already have

The contract is one directory on stdout, which means most of these satisfied it long before
`tsm` existed. None of them need installing beyond what you have.

**Ones that ask**

```bash
tsm at "$(zoxide query -i)"                             # your most-used directories
tsm at "$(FZF_DEFAULT_COMMAND= fzf --walker=dir)"       # fzf's own directory walker
tsm at "$(fzf-git-brief)"                               # repositories with something to show
```

fzf has walked the filesystem itself since 0.44, and `--walker=dir` restricts it to
directories -- a directory chooser with no pipe and no `find`. Add
`--walker-root=$HOME/code` to pin it to one tree instead of the current directory.

The `FZF_DEFAULT_COMMAND=` prefix is the catch. If you have `FZF_DEFAULT_COMMAND` set in your
shell -- a very common `fd` one-liner -- fzf runs *that* instead of its walker, and
`--walker=dir` is silently ignored: you get files. Clearing it for the one call brings the
walker back, and since the substitution is a shell, the bare assignment in front of the command
is all that takes. The same variable is why a bare `fzf` can behave differently inside a tmux
popup than in your shell.

**Ones that just answer** -- no prompt, straight to a path:

```bash
tsm at "$(pwd)"                              # the current directory
tsm at "$(git rev-parse --show-toplevel)"    # the root of the repo you are in
tsm at "$(mktemp -d)"                        # a fresh scratch session, new directory every time
tsm at "$(dir-mark path m)"                  # whatever m marks (see dir-mark)
tsm at "$(xdg-user-dir DOCUMENTS)"           # ~/Documents, wherever XDG says that is
tsm at "$(systemd-path user-configuration)"  # ~/.config
```

`git rev-parse --show-toplevel` is the one worth a keybind: from any subdirectory of a
repository it opens a session at the repository's root. `mktemp -d` is the throwaway -- a new
empty directory, and therefore a new session, every time you press the key.

```tmux
bind-key r run-shell 'tsm at "$(git rev-parse --show-toplevel)"'
bind-key t run-shell 'tsm at "$(mktemp -d)"'
```

Note that none of these are special-cased anywhere in `tsm`. `git` here is git, run by the
shell before `tsm` is started; `tsm` has no opinion about it and no name of its own that could
get in the way.

<a id="writing-your-own"></a>

## Writing your own

There is no such thing as a tsm chooser. There is only a program that prints one path on
stdout, says anything else on stderr, and stops -- and a `$( )` around it. It never sees `-c`
or `-p`, never decides whether to create or switch, and never touches the configuration that
claims the path; `tsm at` does all of that behind every path equally. Printing nothing is how
it declines to answer, and `tsm at` with no directory does nothing.

So it can be any executable, in any language, anywhere:

```sh
#!/bin/sh
# ~/.local/bin/recent-repo: the most recently touched repository under ~/code
ls -dt ~/code/*/ | head -n 1
```

```bash
chmod +x ~/.local/bin/recent-repo
tsm at -p "$(recent-repo)"
```

There is nothing to install and no naming convention to follow -- your shell resolves the name
inside the substitution the way it resolves any other, so a name on PATH, a relative path and
an absolute path all work. Programs you did not write count too, as long as they print a
directory -- see [Programs you already have](#programs-you-already-have).

`-p` above is tsm's, and it cannot be confused with the program's own flags: those live inside
the substitution, which the shell has finished with before `tsm` is started. That is also why
nothing you might want to run is shadowed -- in `tsm at "$(git rev-parse --show-toplevel)"`,
`git` is git. The four in [`examples/`](examples) have no more standing than that: they are
files on your PATH that print a path, reaching `tsm at` exactly the way yours does.

```bash
fzf-git               # the example, printing its answer
tsm at "$(fzf-git)"   # ...and the session that follows
```

### A pipeline, without writing a file

The substitution is a shell, so a pipeline needs nothing arranged for it:

```bash
tsm at "$(find . -type d | fzf)"
```

Bound in `~/.tmux.conf`, in single quotes so tmux hands `sh` the line unaltered:

```tmux
bind-key f popup -E 'tsm at "$(find . -type d | fzf)"'
```

One thing to watch: `find .` searches the directory the shell was started in, which under
`popup -E` is the current pane's. That is useful when you mean "somewhere below here" and
surprising when you don't, so give it an absolute root (`find ~/code -type d`) if the binding
should list the same thing wherever you press it.

Past a one-liner, put it in a file instead. It costs nothing, and it is easier to quote.

### Checking one

To see what a program answers, run it. That is the whole of it; there is nothing tsm-specific
to learn:

```bash
recent-repo
fzf-git
find . -type d | fzf
```

The examples are no different. Each of the four in [`examples/`](examples) is a single file
following this exact contract -- a path on stdout, messages on stderr, nothing printed when you
press escape -- and [`fzf-git-brief`](examples/fzf-git-brief) is the longest one and the best
to copy.

## Session Configuration

A session configuration is an executable program in `${XDG_CONFIG_HOME:-~/.config}/tsm/`. `tsm`
runs it with a verb and reads its answer. That is the whole contract, so it can be written in
any language:

| Verb | Called when | Answer |
|---|---|---|
| `pattern` | resolving which configuration claims a directory | print an ERE of the directories claimed, on stdout |
| `name` | naming the session **(optional)** | print the session name for the directory given as `$2`, on stdout |
| `start` | after tmux has created the session | build the layout |
| `kill` | when the session is killed **(optional)** | tear down what `start` built |

```bash
#!/bin/bash
# ~/.config/tsm/work.sh   (chmod +x)
# the layout for every repository directly under ~/code/work

case "$1" in
  pattern)
    printf '%s\n' "^$HOME/code/work/[^/]+$"
    ;;

  start)
    vim=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
    ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$vim" -c "$ROOT")
    tmux send-keys -t "$vim" 'vim' Enter
    tmux send-keys -t "$ai" 'ai' Enter
    ;;
esac
```

The essentials:

- **The file must be executable**: that is what makes it a configuration.
- `SESSION` (the session name) and `ROOT` (the claimed directory) are in the environment for
  `start` and `kill`.
- `pattern` is a POSIX extended regular expression tested against the resolved directory, so one
  file can claim a whole tree. Anchor it (`^...$`) to claim a single directory.
- When several patterns claim a directory, **the longest pattern wins**; `tsm match <path>`
  shows the ranking. A catch-all `.*` always loses to anything more specific. Only the winner
  runs, but a configuration is an ordinary executable: to build on a shared one, call its file
  directly from your `start` and `kill`.
- Output from `start` and `kill` lands in the session log, browsable with `tsm logs`.

See **[Building a Session](docs/building-a-session.md)** for the full guide: the contract's
rules, pane addressing, precedence, naming, services, logging, and examples in fish and Python.

## Active Session Switcher

Browse the running sessions and switch to one.

![Session Switcher](docs/session_switcher.gif)

## Last Session (`tsm last`)

Switches to the most recently visited session that is still open: like
`tmux switch-client -l`, but it keeps looking further back when the previous session has been
closed. It needs one hook in `~/.tmux.conf` to see switches as they happen:

```tmux
set-hook -g client-session-changed 'run-shell "tsm _record-switch #{q:client_last_session} #{q:client_session}"'
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

[dir-mark]: https://github.com/ryanburda/dir-mark
