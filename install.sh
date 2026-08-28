#!/bin/sh
# Install tmux-session-manager: symlink `tsm` into a directory on PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/ryanburda/tmux-session-manager/main/install.sh | sh
#
# Environment overrides:
#   TSM_HOME  where the repo is cloned  (default: ~/.local/share/tmux-session-manager)
#   BIN_DIR   where symlinks are placed (default: ~/.local/bin)

set -eu

REPO_URL=https://github.com/ryanburda/tmux-session-manager.git
TSM_HOME=${TSM_HOME:-"${XDG_DATA_HOME:-$HOME/.local/share}/tmux-session-manager"}
BIN_DIR=${BIN_DIR:-"$HOME/.local/bin"}

die() {
    echo "install.sh: $*" >&2
    exit 1
}

command -v git > /dev/null 2>&1 || die "git is required but was not found on PATH"
command -v tmux > /dev/null 2>&1 || die "tmux is required but was not found on PATH"

# Not fatal: the commands install fine and only some subcommands need these.
command -v fzf > /dev/null 2>&1 ||
    echo "install.sh: warning: fzf was not found on PATH; the session pickers require it." >&2
command -v ps > /dev/null 2>&1 ||
    echo "install.sh: warning: ps was not found on PATH; 'tsm agents' requires it." >&2

# Fetch (or update) the source checkout that the symlinks point at.
if [ -d "$TSM_HOME/.git" ]; then
    echo "Updating existing checkout at $TSM_HOME"
    git -C "$TSM_HOME" fetch --quiet origin
    git -C "$TSM_HOME" reset --quiet --hard origin/HEAD
elif [ -e "$TSM_HOME" ]; then
    die "$TSM_HOME exists but is not a git checkout; move it aside and retry"
else
    echo "Cloning $REPO_URL into $TSM_HOME"
    mkdir -p "$(dirname "$TSM_HOME")"
    git clone --quiet "$REPO_URL" "$TSM_HOME"
fi

mkdir -p "$BIN_DIR"

src="$TSM_HOME/tsm"
dest="$BIN_DIR/tsm"

[ -f "$src" ] || die "expected $src to exist"

if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    die "$dest exists and is not a symlink; remove it and retry"
fi

chmod +x "$src"
ln -sfn "$src" "$dest"
echo "Linked $dest -> $src"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo
        echo "install.sh: warning: $BIN_DIR is not on your PATH."
        echo "Add this to your shell profile (e.g. ~/.zshrc) and restart your shell:"
        echo
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo
echo "Done. Run 'tsm help' to see its usage."
echo "Shell completions are not installed by this script; see the Shell Completions"
echo "section of $TSM_HOME/README.md for the one-liner for your shell."
