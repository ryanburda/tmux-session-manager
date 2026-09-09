# tmux-session-manager

`tsm` launches tmux sessions at directories.

```bash
tsm at <path>
```

The `path` argument can be:
- a specific path:
```bash
tsm at "$HOME/code/project_name"
```
- the result of a command:
```bash
tsm at "$(git rev-parse --show-toplevel)"    # the root of the repo you are in
tsm at "$(mktemp -d)"                        # a fresh scratch session
```
- or even an interactive command:
```bash
tsm at "$(find $HOME type -d | fzf)"         # fuzzy find directories
tsm at "$(zoxide query -i)"                  # your most-used directories
```

### Writing your own directory picker commands:

Any program that prints a directory works with `tsm at "$(<cmd>)"`.
This means you can write your own to fit a particular need.

The [`examples/`](examples) directory has a few to copy and modify as needed:

| Command | Prints |
|---|---|
| [`fzf-dir`](examples/fzf-dir) | any directory under `$HOME`, chosen with fzf |
| [`fzf-git`](examples/fzf-git) | the directory of a git repository, chosen with fzf |
| [`fzf-git-brief`](examples/fzf-git-brief) | a git repository with unpushed, unpulled, or uncommitted work |
| [`fzf-worktree`](examples/fzf-worktree) | a worktree of the repository you are in |

It is a good idea to add commands to your `PATH` so they are accessible.

### Session creation

Once a directory is passed to `tsm at <path>`, every session is created the same way:

1. **Does a session already exist for that directory?**

    Switch to it.

    A session is identified by the directory it started at, not by its name. `tsm` records that
    directory on the session in the `@tsm_path` tmux option. `tsm at` compares its `path` argument
    against every running session's `@tsm_path` to determine if a session exists already. This prevents
    multiple sessions from being created at the same directory even if a session has been renamed.

2. **Does a configuration claim that directory?**

    Use that configuration when creating/naming the session.

    See [Configured Sessions](docs/configured-sessions.md) for details on how to customize sessions.

3. **Otherwise:**

    Create a plain session named after the directory.

See [Usage](#usage) for the full list of commands.

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
run-shell "tsm init"                                          # required: runs a configuration's `kill` on session close
bind-key d popup -E 'tsm at "$(find $HOME type -d | fzf)"'    # any directory
bind-key X kill-session                                       # kill the session; its `kill` hook runs
bind-key l popup -E "tsm logs"                                # configured session logs
```

`tsm at` is how a configuration gets applied: it names the session, runs the configuration's
`start`, and switches to it. Nothing else does that -- a plain `tmux new-session` at a
configured directory is an ordinary tmux session, because that is what you asked for.

`run-shell "tsm init"` installs a single `session-closed` hook, which runs a configuration's
`kill` when the session it built goes away. It is needed because there is no command to hang
cleanup off: `X`, a kill picker, the last pane exiting and `tmux kill-server` all end a session
without going through tsm. The hook does nothing for a session `tsm at` did not build. See
[Why one hook](docs/configured-sessions.md#why-one-hook-tsm-init).

**NOTE:** if your `~/.tmux.conf` sets `session-closed` with a bare `set-hook -g`, put
`run-shell "tsm init"` after it -- tsm appends to that hook, and a later `set-hook -g` clears
it.
</details>

## Usage

```bash
tsm                                  # Show help message

tsm at <path> [-c] [-p]              # Start or switch to session at a directory
  -c, --no-config                    # Ignore any configuration claiming that path
  -p, --prompt-name                  # Prompt for the session name instead of using the default

tsm match [path]                     # Configurations claiming a path (defaults to the current directory)
tsm logs [session]                   # Browse configured session logs

tsm init                             # Install the hook that cleans up configured sessions (put this in tmux.conf)
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

[dir-mark]: https://github.com/ryanburda/dir-mark
