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
- or even the result of a command:
```bash
# the root of the repo you are currently in
tsm at "$(git rev-parse --show-toplevel)"
# a fresh scratch directory
tsm at "$(mktemp -d)"

# Use a fuzzy finder to make commands interactive
# fuzzy find directories in your HOME folder
tsm at "$(find $HOME -type d | fzf)"
# fuzzy find worktrees of the current git repo
tsm at "$(git worktree list | fzf | awk '{print $1}')"
# Search your most-used directories
tsm at "$(zoxide query -i)"
```

### Session creation

Once a directory is passed to `tsm at <path>`, every session is created the same way:

1. **Does a session already exist for that directory?**

    Switch to it.

    A session is identified by the directory it started at, not by its name. `tsm` records
    that directory on the session in the `@tsm_path` tmux option and compares against that.
    Sessions `tsm` did not create have no `@tsm_path` and fall back to tmux's `#{session_path}`,
    so a plain `tmux new-session` at that directory is found too.

    This makes `tsm at` idempotent, preventing multiple sessions from being created
    at the same directory even if a session has been renamed.

2. **Does a configuration claim that directory?**

    Use that configuration when creating/naming the session.

    See [Configured Sessions](docs/configured-sessions.md) for details on how to customize sessions.

3. **Otherwise:**

    Create a plain session named after the directory.

### Session teardown

Creating a session has one entry point. Ending one has many, and none of them is `tsm`'s:
`bind-key X kill-session`, a kill picker, the last pane's shell exiting, or a client attached
in another terminal all close a session without `tsm` being asked. A configuration's `kill`
therefore runs from a tmux `session-closed` hook rather than from a command:

```bash
run-shell "tsm init"      # in ~/.tmux.conf, installs the hook
```

The hook fires for every session tmux closes but it acts only on sessions `tsm at` built from
a configuration. Everything else closes exactly as it would on a server with no `tsm` on it.

See [Why one hook](docs/configured-sessions.md#why-one-hook-tsm-init) for the details.

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

Completions cover subcommands, their flags, and directories. Paths below assume the install script's checkout location; substitute your own if you
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

## Usage

```bash
tsm                                  # Show help message

tsm at <path> [-c] [-p]              # Start or switch to session at a directory
  -c, --no-config                    # Ignore any configuration claiming that path
  -p, --prompt-name                  # Prompt for the session name instead of using the default

tsm match [path]                     # Configurations claiming a path (defaults to the current directory)

tsm init                             # Install the hook that cleans up configured sessions (put this in tmux.conf)
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
