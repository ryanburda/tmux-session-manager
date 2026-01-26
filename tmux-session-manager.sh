#!/bin/bash

tsm() {
  local CONFIG_DIR="$HOME/.config/tsm"
  mkdir -p "$CONFIG_DIR"

  _tsm_usage() {
    echo "Tmux Session Manager"
    echo ""
    echo "A combination of tmuxinator and tmux sessionizer"
    echo ""
    echo "Usage: tsm [session-name]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -l, --list         List available sessions"
    echo "  -k, --kill [name]  Run kill.sh, if it exists, and kill the session"
    echo "  -d, --dir [path]   Browse directories with fzf, or start session at path if provided"
    echo ""
    echo "Examples:"
    echo "  tsm                Select from configured/active sessions with fzf"
    echo "  tsm myproject      Start or attach to session"
    echo "  tsm -k             Select session to kill with fzf"
    echo "  tsm -k myproject   Kill session"
    echo "  tsm -d             Browse directories with fzf (\$HOME + git repos)"
    echo "  tsm -d ~/projects  Start session at ~/projects"
    echo "  tsm -l             List available sessions"
    echo ""
    echo "Configuration:"
    echo "  Sessions are configured in \$HOME/.config/tsm/<session-name>/"
    echo ""
    echo "  start.sh  Required script that runs when starting a session."
    echo "            Use this to create tmux windows, panes, and run commands."
    echo ""
    echo "  kill.sh   Optional script that runs asynchronously when session is killed."
    echo "            Use this for cleanup tasks like stopping services."
    echo ""
    echo "Environment Variables:"
    echo "  TSM_DIRS_CMD  Command to generate directories for 'tsm -d'."
    echo "                The command is evaluated at runtime and piped to fzf."
    echo ""
    echo "                Default (when unset): \$HOME + git repos within 3 levels"
  }

  _tsm_list_sessions() {
    if [ ! -d "$CONFIG_DIR" ]; then
      echo "No sessions configured. Create directories in $CONFIG_DIR"
      return 1
    fi

    for dir in "$CONFIG_DIR"/*/; do
      [ -d "$dir" ] && echo "$(basename "$dir")"
    done
  }

  _tsm_start_session() {
    local session="$1"
    local session_dir="$CONFIG_DIR/$session"

    if [ ! -d "$session_dir" ]; then
      echo "Error: Session '$session' not found in $CONFIG_DIR"
      return 1
    fi

    if [ ! -f "$session_dir/start.sh" ]; then
      echo "Error: No start.sh found for session '$session'"
      return 1
    fi

    # Check if session already exists
    if tmux has-session -t "$session" 2>/dev/null; then
      echo "Session '$session' already running, switching..."
      if [ -n "$TMUX" ]; then
        tmux switch-client -t "$session"
      else
        tmux attach-session -t "$session"
      fi
    else
      echo "Starting session '$session'..."
      bash "$session_dir/start.sh"
    fi
  }

  _tsm_stop_session() {
    local session="$1"

    # If no session provided, use fzf to select from active sessions
    if [ -z "$session" ]; then
      local active_sessions
      active_sessions=$(tmux ls 2>/dev/null | awk -F: '{print $1}')

      if [ -z "$active_sessions" ]; then
        echo "No active sessions to kill"
        return 1
      fi

      session=$(echo "$active_sessions" | fzf --prompt "> " --header "Kill session")

      if [ -z "$session" ]; then
        echo "No session selected"
        return 0
      fi
    fi

    local session_dir="$CONFIG_DIR/$session"

    if ! tmux has-session -t "$session" 2>/dev/null; then
      echo "Error: Session '$session' is not running"
      return 1
    fi

    # Run kill.sh in background if it exists
    if [ -f "$session_dir/kill.sh" ]; then
      nohup bash "$session_dir/kill.sh" >/dev/null 2>&1 &
    fi

    tmux kill-session -t "$session"
  }

  _tsm_format_sessions() {
    local configured_sessions
    configured_sessions=$(_tsm_list_sessions 2>/dev/null)

    local active_sessions
    active_sessions=$(tmux ls 2>/dev/null | awk -F: '{print $1}')

    local all_sessions
    all_sessions=$(printf "%s\n%s" "$configured_sessions" "$active_sessions" | sort -u | grep -v '^$')

    local BLUE=$'\033[34m'
    local RESET=$'\033[0m'

    echo "$all_sessions" | while read -r session; do
      [ -z "$session" ] && continue
      if echo "$active_sessions" | grep -q "^${session}$"; then
        printf '%s|%s%s%s\n' "$session" "$BLUE" "$session" "$RESET"
      else
        printf '%s|%s\n' "$session" "$session"
      fi
    done
  }

  _tsm_fzf_session() {
    local formatted
    formatted=$(_tsm_format_sessions)

    if [ -z "$formatted" ]; then
      echo "No sessions available"
      return 1
    fi

    local selected
    selected=$(echo "$formatted" | fzf \
      --cycle \
      --prompt "> " \
      --header "Select session" \
      --ansi \
      --with-nth 2 \
      --delimiter '|')

    if [ -z "$selected" ]; then
      echo "No session selected"
      return 0
    fi

    # Extract session name from delimiter format
    selected=$(echo "$selected" | awk -F'|' '{print $1}')

    # Check if it's a configured session
    if [ -d "$CONFIG_DIR/$selected" ]; then
      _tsm_start_session "$selected"
    else
      # It's an active but unconfigured session, just switch to it
      if [ -n "$TMUX" ]; then
        tmux switch-client -t "$selected"
      else
        tmux attach-session -t "$selected"
      fi
    fi
  }

  _tsm_dir_session() {
    local target_dir="$1"
    local selected

    if [ -n "$target_dir" ]; then
      # Path provided, use it directly
      # Expand tilde if present
      selected="${target_dir/#\~/$HOME}"

      if [ ! -d "$selected" ]; then
        echo "Error: Directory '$selected' does not exist"
        return 1
      fi
    else
      # No path provided, use fzf to select from TSM_DIRS_CMD or default
      if [ -n "$TSM_DIRS_CMD" ]; then
        selected=$(eval "$TSM_DIRS_CMD" | fzf --prompt "> " --header "Select directory")
      else
        # Default: HOME + git repos within 3 levels
        selected=$({ echo "$HOME"; find "$HOME" -maxdepth 3 -type d -exec test -d '{}/.git' \; -print -prune 2>/dev/null; } | fzf --prompt "> " --header "Select directory")
      fi

      if [ -z "$selected" ]; then
        echo "No directory selected"
        return 0
      fi
    fi

    # Resolve to absolute path
    selected=$(cd "$selected" && pwd -P)

    local session_name
    session_name=$(basename "$selected")

    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
      echo "Session '$session_name' already running, switching..."
      if [ -n "$TMUX" ]; then
        tmux switch-client -t "$session_name"
      else
        tmux attach-session -t "$session_name"
      fi
    else
      echo "Starting new session '$session_name' in $selected..."
      if [ -n "$TMUX" ]; then
        tmux new-session -d -s "$session_name" -c "$selected"
        tmux switch-client -t "$session_name"
      else
        tmux new-session -s "$session_name" -c "$selected"
      fi
    fi
  }

  # Parse arguments
  if [ $# -eq 0 ]; then
    _tsm_fzf_session
    return 0
  fi

  case "$1" in
    -l|--list)
      _tsm_list_sessions
      ;;
    -k|--kill)
      _tsm_stop_session "$2"
      ;;
    -d|--dir)
      _tsm_dir_session "$2"
      ;;
    -h|--help)
      _tsm_usage
      ;;
    -*)
      echo "Error: Unknown option '$1'"
      _tsm_usage
      return 1
      ;;
    *)
      _tsm_start_session "$1"
      ;;
  esac
}
