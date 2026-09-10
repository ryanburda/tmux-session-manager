# Workflow

`tsm` is adaptable but bare bones. To integrate it into your workflow you'll want to do a bit of setup.

## Set up

The examples in the [README](../README.md) show commands substituted directly into calls to
`tsm at`. That works well for one-liners, but gets messy for anything longer.

A command passed to `tsm at` just needs to print the path to start a new tmux session at.
Writing that logic once as a script on your `PATH`, instead of inline, keeps it in one place
and gives it a name you can reuse from a shell alias and a tmux key bind alike.

For example, here is a command that searches for directories under `$HOME`, pruning hidden
ones, and prompts you to fuzzy-find the one you want with `fzf`:

```sh
#!/usr/bin/env bash

selected=$(find "$HOME" -name ".*" -prune -o -type d -print | fzf --cycle --prompt "Directory > ")

# Backing out is not a failure: say nothing and succeed.
[ -n "$selected" ] || exit 0

printf '%s\n' "$selected"
```

Copying this script into your `PATH` (say, at `~/.local/bin/dirs`) means you can run it by just
calling `dirs`.

Take this a step further:

- add an alias to your shell's rc file:
  ```zsh
  # ~/.zshrc

  alias d='tsm at $(dirs)'
  ```
- add a corresponding key bind in your `tmux.conf`:
  ```
  # ~/.config/tmux/tmux.conf

  bind-key d popup -E "tsm at $(dirs)"
  ```

Now you have parity for pulling up this directory picker both from a fresh shell with no tmux
server running and from within an existing tmux session.

Repeat/modify this for whatever other commands you find useful to build out your workflow.

## Other examples

## Worktrees

Git worktrees give you isolation by letting you have multiple branches checked out at once, but
they don't solve laying out your setup for each one. `cd`ing between worktrees is tedious and
confining worktrees to a single tab or pane is limiting.

A tmux session per worktree solves that. Create another command on your `PATH`
(`~/.local/bin/worktrees`):

```sh
#!/usr/bin/env bash

selected=$(git worktree list | fzf --cycle --prompt "Worktrees > " | awk '{print $1}')

# Backing out is not a failure: say nothing and succeed.
[ -n "$selected" ] || exit 0

printf '%s\n' "$selected"
```

and bind it in `tmux.conf`:

```
# ~/.config/tmux/tmux.conf

bind-key w popup -E 'tsm at $(worktrees)'
```

Now you can quickly switch between worktrees of whatever repo you're currently in. Every
worktree gets its own session that can be laid out however that worktree needs.
