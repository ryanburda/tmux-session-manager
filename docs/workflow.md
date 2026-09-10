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

## Repo status

It's easy to lose track of work spread across many repos. This command fetches every
git repository under `$HOME/code` and lists the ones with commits waiting upstream,
commits not yet pushed, or uncommitted work (staged, unstaged, or untracked), so you
can jump straight to whichever one needs attention:

```sh
#!/usr/bin/env bash
#
# Prints the directory of a git repository that has:
#   - commits waiting upstream
#   - commits not yet pushed
#   - uncommitted work (staged, unstaged or untracked)
#
# Every repository is fetched before it is inspected, so the ahead/behind
# counts are current. That is what makes this somewhat slow to appear.

note() {
  if [ -n "$TMUX" ]; then tmux display-message "$1"; else echo "$1" >&2; fi
}

git_brief_row() {
  local dir="$1"
  local branch ahead behind stats added removed untracked

  git -C "$dir" rev-parse --git-dir > /dev/null 2>&1 || return 1

  git -C "$dir" fetch --quiet 2>/dev/null

  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch="(detached)"

  ahead=$(git -C "$dir" log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  behind=$(git -C "$dir" log HEAD..@{u} --oneline 2>/dev/null | wc -l | tr -d ' ')

  if git -C "$dir" rev-parse --verify -q HEAD > /dev/null 2>&1; then
    stats=$(git -C "$dir" diff HEAD --shortstat 2>/dev/null)
  else
    stats=$(git -C "$dir" diff --cached --shortstat 2>/dev/null)
  fi
  added=$(echo "$stats" | grep -o '[0-9]* insertion' | grep -o '[0-9]*')
  removed=$(echo "$stats" | grep -o '[0-9]* deletion' | grep -o '[0-9]*')

  untracked=$(git -C "$dir" ls-files --others --exclude-standard --directory \
    --no-empty-directory 2>/dev/null | wc -l | tr -d ' ')

  [ "${ahead:-0}" -gt 0 ] || [ "${behind:-0}" -gt 0 ] \
    || [ "${added:-0}" -gt 0 ] || [ "${removed:-0}" -gt 0 ] \
    || [ "${untracked:-0}" -gt 0 ] || return 1

  local blue='\033[34m' yellow='\033[33m' green='\033[32m' red='\033[31m'
  local cyan='\033[36m' reset='\033[0m'
  local brief="${blue}${branch}${reset}"
  [ "${ahead:-0}" -gt 0 ] && brief+=" ${yellow}↑${ahead}${reset}"
  [ "${behind:-0}" -gt 0 ] && brief+=" ${yellow}↓${behind}${reset}"
  [ "${added:-0}" -gt 0 ] && brief+=" ${green}+${added}${reset}"
  [ "${removed:-0}" -gt 0 ] && brief+=" ${red}-${removed}${reset}"
  [ "${untracked:-0}" -gt 0 ] && brief+=" ${cyan}?${untracked}${reset}"

  printf '%s\t%s  %b\n' "$dir" "$dir" "$brief"
}

dirs=$(find "$HOME/code" -name .git -prune -print -o -name ".*" -prune 2>/dev/null \
  | while IFS= read -r gitpath; do
      if [ -d "$gitpath" ]; then
        [ -e "$gitpath/HEAD" ] || continue
        grep -q '^[[:space:]]*bare = true' "$gitpath/config" 2>/dev/null && continue
      fi
      printf '%s\n' "${gitpath%/.git}"
    done | sort)

if [ -z "$dirs" ]; then
  note "No git repositories found"
  exit 1
fi

export -f git_brief_row
rows=$(
  printf '%s\n' "$dirs" | tr '\n' '\0' \
    | xargs -0 -P 8 -n 1 \
            bash -c 'git_brief_row "$1" || true' _ \
    | LC_ALL=C sort
)

checked=$(printf '%s\n' "$dirs" | wc -l | tr -d ' ')
changed=0
[ -n "$rows" ] && changed=$(printf '%s\n' "$rows" | wc -l | tr -d ' ')

if [ -z "$rows" ]; then
  note "Nothing to show: none of the $checked repositories checked have changes"
  exit 1
fi

header=$(printf ':: \033[33m%s\033[0m of \033[33m%s\033[0m repositories have changes' \
  "$changed" "$checked")

selected=$(printf '%s\n' "$rows" \
  | fzf --ansi --cycle --delimiter=$'\t' --with-nth=2 --prompt "Repo > " --header "$header")

[ -n "$selected" ] || exit 0

printf '%s\n' "${selected%%	*}"
```

Copy this into your `PATH` (say, at `~/.local/bin/git-brief`) and bind it in `tmux.conf`:

```
# ~/.config/tmux/tmux.conf

bind-key g popup -E "tsm at $(git-brief)"
```

Because every repository is fetched before it's inspected, this directory picker is not fast, but
it's helpful to see if you have work that hasn't been committed.
