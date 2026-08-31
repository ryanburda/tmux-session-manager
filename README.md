# tmux-session-manager

Directory-based tmux sessions, configured on creation

- **Create** sessions rooted at directories
- **Script** how your sessions start
- **Switch** between sessions
- **Kill** sessions with background cleanup hooks

Session configurations are plain shell scripts. No YAML, no DSL.

Write a default configuration for a familiar setup across projects.

Write custom configurations for projects that need something a bit different.

You just define:
- which directory that configuration is associated with
- what to run on startup
- and what to clean up on the way out

`tsm` applies the appropriate configuration based on which directory the session is rooted in.

## Install

### Dependencies

- `fzf`

### Installation
```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
```

The command above:
- Clones the repository to `${XDG_DATA_HOME:-~/.local/share}/tmux-session-manager`
- symlinks `tsm` into `~/.local/bin`

Re-run it at any time to update to the latest revision.

Shell completions are not installed by the script. See Shell Completions section below.

<details>
<summary><strong style="font-size: 1.25em;">Custom Installation</strong></summary>

Two environment variables change where things land:
- `TSM_HOME` is where the repository is cloned
- `BIN_DIR` is where the `tsm` symlink is placed

Set either or both on the `sh` that runs the script:

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh \
  | TSM_HOME=~/src/tsm BIN_DIR=~/bin sh
```
</details>

<details>
<summary><strong style="font-size: 1.25em;">Manual Installation</strong></summary>

1. Clone the repository:
   ```bash
   git clone https://github.com/ryanburda/tmux-session-manager.git ~/git/ryanburda/tmux-session-manager
   ```

2. Symlink the script to a directory in your PATH:
   ```bash
   mkdir -p ~/.local/bin
   ln -s ~/git/ryanburda/tmux-session-manager/tsm ~/.local/bin/tsm
   ```

3. Ensure `~/.local/bin` is in your PATH. Add this to your `.bashrc` or `.zshrc` if needed:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

</details>

<details>
<summary><strong style="font-size: 1.25em;">Shell Completions</strong></summary>

Completions provide:
- Active session names for `tsm active` and `tsm kill`
- Directory completion for `tsm dir`
- Config names for `tsm configured`
- Session names with logs for `tsm logs`

The paths below are the install script's checkout location. If you overrode `TSM_HOME`, or cloned
manually, substitute that directory instead.

<details>
<summary><strong>Bash</strong></summary>

Add to your <code>~/.bashrc</code>:

```bash
source ~/.local/share/tmux-session-manager/completions/tsm.bash
```

</details>

<details>
<summary><strong>Zsh</strong></summary>

Add to your <code>~/.zshrc</code>:

```bash
fpath=(~/.local/share/tmux-session-manager/completions $fpath)
autoload -Uz compinit && compinit
```
Or rename `tsm.zsh` to `_tsm` and place in an existing fpath directory.

</details>

<details>
<summary><strong>Fish</strong></summary>

Symlink to fish completions directory:

```bash
ln -s ~/.local/share/tmux-session-manager/completions/tsm.fish ~/.config/fish/completions/
```

</details>

</details>

<details>
<summary><strong style="font-size: 1.25em;">tmux Keybindings</strong></summary>

`tsm` is best used with tmux keybinds which can be added to your `~/.tmux.conf`:

```bash
bind-key s popup -E "tsm active"
bind-key k popup -E "tsm kill"
bind-key X run-shell "tsm kill #{session_name}"
bind-key l run-shell "tsm last"

# Directory based sessions
bind-key d popup -E "tsm dir"
bind-key g popup -E "tsm git"
bind-key G popup -E "tsm git -bf"
bind-key w popup -E "tsm worktree"

# Configuration based sessions
bind-key c popup -E "tsm configured"
bind-key L popup -E "tsm logs"
```

This maps:
- `prefix + s` - Active session switcher
- `prefix + k` - Kill session selector
- `prefix + X` - Kill the current session and run its kill() hook
- `prefix + l` - Switch to the most recent session that is still open
- `prefix + d` - Directory session launcher
- `prefix + g` - Git repository session launcher
- `prefix + G` - Git repository session launcher (with git brief)
- `prefix + w` - Worktree session launcher
- `prefix + c` - Configured session launcher
- `prefix + L` - Browse configured session logs

<details>
<summary><strong style="font-size: 1.25em;">Troubleshooting Keybinds</strong></summary>

> tmux's `run-shell` and `popup -E` commands execute in a non-interactive, non-login shell.
> For `tsm` to be found, it must be in your PATH when this shell starts.
> 
> **For zsh users:** Add your PATH configuration to `~/.zshenv` (not `.zshrc`).
> 
> **For bash users:** Set the `BASH_ENV` environment variable to point to a file that configures your PATH,
> or add your PATH to `/etc/environment`.
> 
> **Shell startup file precedence:**
> 
> | Shell | Login | Interactive | Non-interactive |
> |-------|-------|-------------|-----------------|
> | **zsh** | zshenv → zprofile → zshrc → zlogin | zshenv → zshrc | zshenv only |
> | **bash** | /etc/profile → (~/.bash_profile OR ~/.bash_login OR ~/.profile) | ~/.bashrc | $BASH_ENV only (if set) |
> 
> Since tmux runs commands non-interactively, zsh only sources `~/.zshenv` and bash only sources the file
> specified by `$BASH_ENV` (if set). This is why PATH modifications in `.zshrc` or `.bashrc` won't apply.
> 
> **Fallback:** If configuring shell startup files isn't working, you can execute `tsm` using its full path
> in your keybindings:
> 
> ```bash
> bind-key s popup -h 24 -w 60 -E "~/.local/share/tmux-session-manager/tsm"
> bind-key d popup -h 24 -w 80 -E "~/.local/share/tmux-session-manager/tsm dir"
> bind-key X run-shell "~/.local/share/tmux-session-manager/tsm kill #{session_name}"
> ```
> 
> Adjust the path if the repository lives somewhere else.
> 
> **Note:** If you specify a custom `TSM_DIRS_CMD`, add it to the same file where you configure your PATH
> (e.g., `~/.zshenv` for zsh). Otherwise, `tsm dir` will use the default directory list in a tmux popup
> but a different custom list from an interactive shell, leading to inconsistent behavior.

</details>

</details>

## Usage

```bash
tsm                                  # Show help message
tsm active [session]                 # Switch to session
tsm kill [session]                   # Kill session (runs kill() hook if present)
tsm last                             # Switch to the most recent session that is still open

tsm dir [path] [-c] [-d] [-p]        # Create session at path
tsm git [-b] [-f] [-c] [-d] [-p]     # Browse git repositories with fzf, creates session at path
tsm worktree [name] [-c] [-d] [-p]   # Create session at git worktree path

  -c, --no-custom-config             # Ignore a custom configuration rooted at the selected path
  -d, --no-default-config            # Skip the shared default configuration
  -p, --prompt-name                  # Prompt for the session name instead of using the default
  -b, --brief                        # (git) Show git status information in the picker
  -f, --fetch                        # (git) Fetch before showing the brief; implies -b

tsm configured [config]              # Start a configured session
tsm logs [session]                   # Browse session logs
tsm apply-default-config             # Apply the default configuration's start() (inside a configuration's start())
tsm kill-default-config              # Run the default configuration's kill() (inside a configuration's kill())

tsm help                             # Show help message
```

## Session Configuration Setup

`tsm` allows you to define configurations for your sessions. Session configurations are plain shell
scripts in `${XDG_CONFIG_HOME:-~/.config}/tsm/`. There is no DSL or YAML abstraction over tmux
to learn. `man tmux` is the reference for all of it. Anything that can be done in a script, can
be done in a session configuration.

- The file's name is the session's name
- `ROOT` is the directory the session is rooted at
- `start()` sets up the session
- `kill()` cleans up the session when it is killed **(Optional)**

```bash
# ~/.config/tsm/myproject.sh
#
# a session named "myproject"
# rooted at ~/code/myproject

ROOT="$HOME/code/myproject"

start() {
  vim=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
  ai=$(tmux split-window -P -F '#{pane_id}' -h -l 35% -t "$vim" -c "$ROOT")
  tmux send-keys -t "$vim" 'vim' Enter
  tmux send-keys -t "$ai" 'ai' Enter
}
```

The script above:
- splits the pane the session starts with into two
- puts your editor on the left
- puts your ai on the right

See **[Building a Session](docs/building-a-session.md)** for the full guide: pane addressing,
multi-window layouts, starting and stopping services, and worked examples.

A default configuration can be defined at `${XDG_CONFIG_HOME:-~/.config}/tsm/.default_config.sh`.
It defines `start()` and `kill()` like any other configuration, and is applied to any session
started with one of the [directory session pickers](#directory-sessions) if a custom configuration
doesn't exist for the selected directory.

Configurations of your own never inherit it. They opt in by calling `tsm apply-default-config` in
`start()` and `tsm kill-default-config` in `kill()`, which leaves them free to run their own work
before or after the shared setup.

# Overview

## Directory Sessions

Each directory session picker shown below opens a tmux session rooted at
a directory you pick. There are various pickers differing only in how they
help you find the directory:

- `tsm dir` - any directory on the filesystem
- `tsm git` - a git repository
- `tsm worktree` - a worktree of the current repository

Once a directory is picked, all pickers resolve which session configuration to apply
to the newly created session in the same way:

```
          ----------------------------------------
          | tsm dir  ·  tsm git  ·  tsm worktree |
          ----------------------------------------
                            |
                   --------------------
                   | picked directory |
                   --------------------
                            |
      ---------------------------------------------------
      | does a ~/.config/tsm/*.sh set a matching $ROOT? |
      ---------------------------------------------------
             /                                 \
         -------                             ------
         | yes |                             | no |
         -------                             ------
            |                                   |
----------------------------   ----------------------------------
| start that configuration |   | does .default_config.sh exist? |
----------------------------   ----------------------------------
                                 /                          \
                              -------                     ------
                              | yes |                     | no |
                              -------                     ------
                                |                            |
                ---------------------------    -------------------------
                | create a session at the |    | create a bare session |
                | directory, then apply   |    |   at the directory    |
                | .default_config.sh      |    -------------------------
                ---------------------------
```

All three pickers take the same flags. `-c` and `-d` opt out of a step of the resolution above:

- `-c`, `--no-custom-config` - Ignore a [custom configuration](#configured-sessions) rooted at the
  picked directory and apply the default configuration instead.
- `-d`, `--no-default-config` - Skip the [shared default configuration](docs/building-a-session.md#defining-a-default-configuration),
  leaving a bare session at the directory.
- `-p`, `--prompt-name` - Prompt for the session name instead of using the suggested one.

Each picker also takes an argument (a path, a worktree name) to skip `fzf` and go
straight to a session.

See [Usage](#usage) for the exact arguments.

> ### Directory (`tsm dir`)
>
> Any directory on the filesystem.
>
> By default fzf displays non-hidden directories within 4 levels of your `$HOME` directory, stopping
> at the root of each git repository. This can be changed by setting the `TSM_DIRS_CMD` environment
> variable in your `.bashrc/.zshenv`.
>
> <details>
> <summary><strong style="font-size: 1.25em;">Modifying <code>TSM_DIRS_CMD</code></strong></summary>
>
> > `TSM_DIRS_CMD` can be set to any command that returns directories.
> >
> > The following example shows:
> > - directories 1 level deep in the `$HOME` directory
> > - directories 4 levels deep in `$HOME/code` while also pruning the search once it finds the root of a git repo
> >
> > ```bash
> > export TSM_DIRS_CMD='{
> >   find "$HOME" -maxdepth 1 -name ".*" -prune -o -type d -print;
> >   find "$HOME/code" -maxdepth 4 -name ".*" -prune -o -type d \( -exec test -e {}/.git \; -print -prune -o -print \);
> > }'
> > ```
> </details>
>
> ![Launch Directory Sessions](docs/directory_launcher.gif)

> ### Git Repositories (`tsm git`)
>
> A git repository.
>
> By default `tsm git` finds all directories containing `.git` within 4 levels of `$HOME`. This can
> be changed by setting the `TSM_GIT_DIRS_CMD` environment variable in your `.bashrc/.zshenv`.
>
> Two flags are specific to this picker:
> - `-b`, `--brief` - Show git status information in the picker. Off by default so the picker
>   appears immediately.
> - `-f`, `--fetch` - Run `git fetch` before displaying status, so the ahead/behind counts reflect
>   the latest remote tracking info. Implies `-b`.
>
> With `-f`, the fetches run in parallel, 8 repositories at a time. `TSM_GIT_FETCH_JOBS` raises or
> lowers that cap:
> 
> <details>
> <summary><strong style="font-size: 1.25em;">Modifying <code>TSM_GIT_DIRS_CMD/TSM_GIT_FETCH_JOBS</code></strong></summary>
> 
> > `TSM_GIT_DIRS_CMD` can be set to any command that returns directories of git repositories.
> >
> > It is a good idea to limit this search to a directory where you keep your projects:
> > ```bash
> > export TSM_GIT_DIRS_CMD='find "$HOME/code" -maxdepth 4 -name ".git" 2>/dev/null | sed "s/\/\.git$//"'
> > ```
> >
> > The `TSM_GIT_FETCH_JOBS` cap matters because every fetch also opens a connection to a remote. Lower it if a wide
> > `TSM_GIT_DIRS_CMD` makes the picker slow to appear or your connection is metered, or drop `-f`
> > to skip fetching altogether.
> >
> > ```bash
> > export TSM_GIT_FETCH_JOBS=4
> > ```
> </details>
>
> ![Launch Git Sessions](docs/git_launcher.gif)

<a id="git-worktrees"></a>

> ### Git Worktrees (`tsm worktree`)
>
> A worktree of the current repository, in a session named `repo/worktree`.
>
> **NOTE:** Can only be run when the current working directory is inside a git repo
> 
> ![Launch Worktree Sessions](docs/worktree_launcher.gif)

<a id="configured-sessions"></a>

## Configured Sessions (`tsm configured`)

Launch a configured session directly, without going through a directory picker.

![Launch Configured Sessions](docs/configured_launcher.gif)

See **[Building a Session](docs/building-a-session.md)** for more info on writing session configurations.

## Active Session Switcher

Browse the sessions that are currently running and switch to one.

![Session Switcher](docs/session_switcher.gif)

## Last Session (`tsm last`)

`tsm last` switches to the most recently visited session that is still open.
This is like `tmux switch-client -l`, but it keeps looking further back in history
instead of failing outright when the previous session has since been closed.

This only works if tmux tells `tsm` about session switches as they happen, so it
requires one addition to `~/.tmux.conf`:

```tmux
set-hook -g client-session-changed 'run-shell "tsm _record-switch #{q:client_last_session} #{q:client_session}"'
```
This allows all session switches, not just ones made through `tsm`, appear in the history file.
Without this hook, `tsm last` has nothing to work from and will tell you so.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
