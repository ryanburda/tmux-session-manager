# tmux-session-manager

`tsm` launches tmux sessions at directories. That's its whole job.

Several [pickers](#directory-sessions) help you find that directory:

| | |
|---|---|
| `tsm dir` | any directory on the filesystem |
| `tsm git` | a git repository |
| `tsm worktree` | a worktree of the current repository |
| `tsm bookmark` | a directory bookmarked to a single character |

Once a path is chosen, every session is created or entered the same way:

1. **Does a session already exist for that directory?** Switch to it.
2. **Does a configuration claim that directory?** Use that configuration
   when creating/naming the session.
3. **Otherwise:** create a plain session named after the directory.

So `tsm worktree` is not a different feature from `tsm dir`; it is the same session launcher
reached through a different directory picker.

See [Usage](#usage) for the full list of commands, and
[Session Configuration](#session-configuration) for details on how to customize sessions.

## Install

Requires `fzf`.

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

This clones the repository to `${XDG_DATA_HOME:-~/.local/share}/tmux-session-manager` and symlinks
`tsm` into `~/.local/bin`. Re-run it any time to update.

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

Completions cover active session names, directories, worktrees, bookmarks, and sessions with
logs. Paths below assume the install script's checkout location; substitute your own if you
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

# Directory based sessions
bind-key d popup -E "tsm dir"        # directory launcher
bind-key g popup -E "tsm git"        # git repository launcher
bind-key G popup -E "tsm git -bf"    # git launcher with fetched status brief
bind-key w popup -E "tsm worktree"   # worktree launcher
bind-key b run-shell -b "tsm bookmark"        # session at a bookmark (asks for its char)
bind-key B popup -E "tsm bookmark-list -f"    # browse bookmarks with fzf
bind-key m run-shell -b "tsm bookmark-add"    # bookmark the session's directory
bind-key M run-shell -b "tsm bookmark-remove" # remove a bookmark

# Session logs
bind-key L popup -E "tsm logs"
```

The three bindings that ask for a character use `run-shell` rather than `popup -E`: the prompt is
tmux's own, in the status line. `tsm bookmark-add` bound this way bookmarks the directory the
session is rooted at; to bookmark the current pane's directory instead:
`bind-key m run-shell -b "tsm bookmark-add '' '#{pane_current_path}'"`.

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
> Fallback: use `tsm`'s full path in the bindings, e.g.
> `bind-key d popup -E "~/.local/share/tmux-session-manager/tsm dir"`.
>
> If you set a custom `TSM_DIRS_CMD`, define it in the same file as your PATH (e.g. `~/.zshenv`),
> or `tsm dir` will show different lists inside and outside tmux popups.

</details>

</details>

## Usage

```bash
tsm                                  # Show help message
tsm active [session]                 # Switch to an existing session
tsm kill [session]                   # Kill session (runs its kill hook if present)
tsm last                             # Switch to the most recent session that is still open

tsm dir [path] [-c] [-p]             # Create session at path
tsm git [-b] [-f] [-c] [-p]          # Browse git repositories with fzf, creates session at path
tsm worktree [name] [-c] [-p]        # Create session at git worktree path
tsm bookmark [char] [-c] [-p]        # Create session at a bookmarked directory (prompts for char)

  -c, --no-config                    # Ignore any configuration claiming the selected path
  -p, --prompt-name                  # Prompt for the session name instead of using the default
  -b, --brief                        # (git) Show git status information in the picker
  -f, --fetch                        # (git) Fetch before showing the brief; implies -b

tsm bookmark-add [char] [path]       # Bookmark a directory (prompts for char; path defaults to the current directory)
tsm bookmark-remove [char]           # Remove a bookmark (prompts for char)
tsm bookmark-list [-f]               # List bookmarks (-f, --fzf browses them with fzf and starts a session)
tsm bookmark-status [path]           # Bookmarks of the open sessions, for a tmux status line

tsm match [path]                     # Configurations claiming a path, best first (defaults to the current directory)
tsm logs [session]                   # Browse session logs
```

## Directory Sessions

`dir`, `git`, `worktree` and `bookmark` are four ways of arriving at one path. The sections
below cover what is particular to each picker; everything here is what they share.

A picked directory becomes a session by the same three rules, whichever picker produced it:

1. **A session is already open at that path?** Switch to it.
2. **A configuration's `pattern` claims the path?** Its `name` names the session, and its `start`
   builds it. See [Session Configuration](#session-configuration).
3. **Otherwise:** a bare session named after the directory.

The first check is about the path, not the name: `tsm` records the directory a session was
started at on the session itself (`@tsm_path`), so picking a directory you already have open
returns to that session however it has since been renamed.

All four pickers take the same flags:

- `-c`, `--no-config`: ignore the configuration claiming the directory (both its `name` and its
  `start`), leaving a bare session named after the directory.
- `-p`, `--prompt-name`: prompt for the session name. The suggestion is whatever the rules
  produced, so enter accepts it and anything typed replaces it. When the path already has a
  session, `-p` has nothing to name and simply switches to it.

Each picker also takes an argument (a path, a worktree name, a bookmark character) to skip the
picker entirely.

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
$ tsm dir ~/work/api
Session name collision
  name              api
  new session at    /home/you/work/api
  'api' is open at  /home/you/code/api
Enter session name:
```

**Naming from a configuration.** The `name` verb replaces the default derivation for every
directory a configuration claims: name sessions after their branch, group a tree under a
`work/` prefix, and so on. See [Naming the session](docs/building-a-session.md#naming-the-session).

### Directory (`tsm dir`)

By default fzf lists non-hidden directories within 4 levels of `$HOME`, stopping at the root of
each git repository. Set `TSM_DIRS_CMD` (in `~/.zshenv` / `~/.bashrc`) to any command that
prints directories:

```bash
export TSM_DIRS_CMD='{
  find "$HOME" -maxdepth 1 -name ".*" -prune -o -type d -print;
  find "$HOME/code" -maxdepth 4 -name ".*" -prune -o -type d \( -exec test -e {}/.git \; -print -prune -o -print \);
}'
```

![Launch Directory Sessions](docs/directory_launcher.gif)

### Git Repositories (`tsm git`)

By default finds all directories containing `.git` within 4 levels of `$HOME`. Set
`TSM_GIT_DIRS_CMD` to change that; limiting it to where you keep projects is a good idea:

```bash
export TSM_GIT_DIRS_CMD='find "$HOME/code" -maxdepth 4 -name ".git" 2>/dev/null | sed "s/\/\.git$//"'
```

Two flags are specific to this picker:

- `-b`, `--brief`: show git status in the picker. Off by default so the picker appears
  immediately.
- `-f`, `--fetch`: fetch first, so ahead/behind counts are current. Implies `-b`. Fetches run
  in parallel, 8 repositories at a time; `TSM_GIT_FETCH_JOBS` changes the cap (each fetch opens
  a remote connection, so lower it if the picker is slow or your connection is metered).

![Launch Git Sessions](docs/git_launcher.gif)

<a id="git-worktrees"></a>

### Git Worktrees (`tsm worktree`)

A worktree of the current repository, in a session named `repo/worktree`. Must be run from
inside a git repo.

![Launch Worktree Sessions](docs/worktree_launcher.gif)

<a id="bookmarks"></a>

### Bookmarks (`tsm bookmark`)

A bookmark maps one printable character to one directory, the way vim marks do. `tsm bookmark m`
goes straight to a session at whatever `m` bookmarks, with no picker in the way. They are for the handful of
directories you return to constantly.

| command | description |
|---------|-------------|
| `tsm bookmark [char] [-c] [-p]` | Start a session at the directory bookmarked at `char` |
| `tsm bookmark-add [char] [path]` | Bookmark a directory (default: the current directory) |
| `tsm bookmark-remove [char]` | Remove the bookmark |
| `tsm bookmark-list [-f]` | List bookmarks; `-f` browses them with fzf (`enter` starts a session, `ctrl-x` removes) |
| `tsm bookmark-status [path]` | The open sessions' bookmarks, for a tmux status line |

Bookmarking a character that is already set replaces it. Called without a character, `bookmark`,
`bookmark-add` and `bookmark-remove` take the next key pressed (`enter`/`escape` backs out).
Inside tmux the prompt is in the status line, so a keybind needs no popup; outside tmux the
character is read from the terminal. Bookmarks are stored in
`${XDG_STATE_HOME:-~/.local/state}/tsm/bookmarks.json`.

#### Status Line (`tsm bookmark-status`)

Prints the bookmark characters of the sessions that are **open**, the current session's styled
differently, a compact alternative to reading session names off the status line:

```tmux
set -g status-right "#(tsm bookmark-status '#{session_path}')"
```

Two flags set the styles, written without their `#[]` wrapper: `-s`/`--style` for other open
sessions (default `dim`) and `-c`/`--current-style` for the current one (default
`fg=yellow,bold`):

```tmux
set -g status-right "#(tsm bookmark-status '#{session_path}' -s 'fg=colour244' -c 'fg=black,bg=blue,bold')"
```

A status line is only redrawn every `status-interval` seconds. Two hooks make sessions opened or
killed elsewhere appear immediately, on every attached client:

```tmux
set-hook -g session-created 'run-shell -b "tsm _refresh-status"'
set-hook -g session-closed 'run-shell -b "tsm _refresh-status"'
```

Switching sessions, and setting or removing bookmarks, refresh the line on their own.

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
