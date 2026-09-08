# tmux-session-manager

`tsm` launches tmux sessions at directories.

```bash
tsm at <path>
```

The path can be the result of a command:

```bash
tsm at "$(git rev-parse --show-toplevel)"    # the root of the repo you are in
tsm at "$(mktemp -d)"                        # a fresh scratch session
```

Commands can even be interactive:

```bash
tsm at "$(find $HOME type -d | fzf)"         # fuzzy find directories
tsm at "$(zoxide query -i)"                  # your most-used directories
```

Once a directory is picked, every session is created or entered the same way:

1. **Does a session already exist for that directory?**

    Switch to it.
2. **Does a configuration claim that directory?**

    Use that configuration when creating/naming the session.
3. **Otherwise:**

    Create a plain session named after the directory.

See [Usage](#usage) for the full list of commands.

See [Session Configuration](#session-configuration) for details on how to customize sessions.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

The install script:
- clones the repository to `${XDG_DATA_HOME:-~/.local/share}/tmux-session-manager`
- symlinks `tsm` into `~/.local/bin`.

Re-run it any time to update.

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
bind-key d popup -E 'tsm at "$(find $HOME type -d | fzf)"'    # any directory
bind-key a popup -E "tsm active"                              # active session switcher
bind-key k popup -E "tsm kill"                                # kill session selector
bind-key X run-shell "tsm kill #{session_name}"               # kill current session (runs its kill hook)
bind-key l popup -E "tsm logs"                                # Configured session logs
```
</details>

## Usage

```bash
tsm                                  # Show help message

tsm at <path> [-c] [-p]              # Start or switch to session at a directory
  -c, --no-config                    # Ignore any configuration claiming that path
  -p, --prompt-name                  # Prompt for the session name instead of using the default

tsm match [path]                     # Configurations claiming a path (defaults to the current directory)
tsm logs [session]                   # Browse configured session logs

tsm active [session]                 # Switch to an existing session
tsm kill [session]                   # Kill session (runs its kill hook if present)
```

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

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

[dir-mark]: https://github.com/ryanburda/dir-mark
