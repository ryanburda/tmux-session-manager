# The pickers: everything whose job is to name a directory.
#
# Sourced by tsm, not run on its own -- the functions here use tsm's helpers
# (notify, the bookmark store) and answer in PICKED_DIR the way tsm's own
# functions do.
#
# A picker names a directory and nothing else: it takes no arguments, decides
# nothing about the session that follows, and ends with one path in
# PICKED_DIR. `tsm via` is what turns that into a session, and it will run
# any program that prints a path just as readily -- these are only the ones
# that come with tsm.

pickers() {
  # The built-in picker names `tsm via` recognises before it falls back to
  # running its argument as a program.
  printf '%s\n' dir git git-brief worktree bookmark
}

run_picker() {
  # Set PICKED_DIR to the directory a picker names. Returns non-zero when
  # nothing was picked and there is nothing left to do.
  #
  # A built-in name is one of the fzf pickers below and takes no arguments.
  # Anything else is a program: it is run with the arguments given, prints
  # one path on stdout and says everything else on stderr. That is the whole
  # contract, so `zoxide query -i`, a script of your own, or anything else
  # that answers with a directory works without tsm knowing about it.
  #
  # Args:
  #   $1: a built-in picker name, or a program to run
  #   $@: the program's arguments
  local picker="$1"
  shift

  PICKED_DIR=""

  case "$picker" in
    dir | git | git-brief | worktree | bookmark)
      # The built-in pickers ask with fzf and nothing else, so an argument
      # here is a leftover from the days when they took one. Dropping it
      # silently would start a session somewhere that was not asked for.
      if [ $# -gt 0 ]; then
        notify "Error: the built-in '$picker' picker takes no arguments"
        exit 1
      fi

      # The case above is the whitelist, so this only ever names one of the
      # pick_* functions below.
      "pick_${picker//-/_}"
      ;;
    *)
      local program
      program=$(command -v -- "$picker" 2>/dev/null)

      if [ -z "$program" ]; then
        notify "Error: '$picker' is not a built-in picker or a program on PATH"
        exit 1
      fi

      # Stdout is the answer, so a status is all a program has left to fail
      # with; it is passed on rather than turned into a session at nowhere.
      # Printing nothing and succeeding is how it backs out.
      PICKED_DIR=$("$program" "$@") || exit $?

      [ -n "$PICKED_DIR" ]
      ;;
  esac
}

pick_dir() {
  # Any directory, chosen with fzf from TSM_DIRS_CMD.

  # The process substitution lets the directory generator be killed once fzf
  # exits, rather than run out to the end of the tree.
  local dirs_cmd="${TSM_DIRS_CMD:-$TSM_DIRS_CMD_DEFAULT}"

  exec 3< <(eval "$dirs_cmd")
  local dirs_pid=$!
  PICKED_DIR=$(fzf --cycle --prompt "Directory > " <&3)
  kill "$dirs_pid" 2>/dev/null
  wait "$dirs_pid" 2>/dev/null
  exec 3<&-

  [ -n "$PICKED_DIR" ]
}

pick_git() {
  # A git repository, chosen with fzf from TSM_GIT_DIRS_CMD. It lists paths
  # and nothing else, so it appears at once; `git-brief` is the same list
  # with the state of each repository beside it.
  local git_dirs_cmd="${TSM_GIT_DIRS_CMD:-$TSM_GIT_DIRS_CMD_DEFAULT}"

  local dirs
  dirs=$(eval "$git_dirs_cmd" | sort)

  if [ -z "$dirs" ]; then
    notify "No git repositories found"
    exit 1
  fi

  PICKED_DIR=$(printf '%s\n' "$dirs" | fzf --cycle --prompt "Repo > ")

  [ -n "$PICKED_DIR" ]
}

git_brief_row() {
  # One fzf row for the repo at $1 -- "<path>\t<path>  <brief>", the brief
  # being branch ↑ahead ↓behind +added -removed ?untracked -- or nothing with
  # a non-zero status when the repository has nothing to report.
  #
  # The fetch happens here rather than in a pass of its own, so one job both
  # fetches and inspects a repository and there is no barrier between the two.
  #
  # Args:
  #   $1: dir: the repository to inspect
  local dir="$1"
  local branch ahead behind stats added removed untracked

  git -C "$dir" rev-parse --git-dir > /dev/null 2>&1 || return 1

  git -C "$dir" fetch --quiet 2>/dev/null

  # Empty on a detached HEAD, which is still worth showing when it is dirty.
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch="(detached)"

  # With no upstream both counts come out 0, so a repository whose branch has
  # never been pushed is listed only if it has uncommitted work.
  ahead=$(git -C "$dir" log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  behind=$(git -C "$dir" log HEAD..@{u} --oneline 2>/dev/null | wc -l | tr -d ' ')

  # Against HEAD rather than the index, so staged work counts as a change too.
  # Before the first commit there is no HEAD to compare against, and the index
  # is measured against the empty tree instead.
  if git -C "$dir" rev-parse --verify -q HEAD > /dev/null 2>&1; then
    stats=$(git -C "$dir" diff HEAD --shortstat 2>/dev/null)
  else
    stats=$(git -C "$dir" diff --cached --shortstat 2>/dev/null)
  fi
  added=$(echo "$stats" | grep -o '[0-9]* insertion' | grep -o '[0-9]*')
  removed=$(echo "$stats" | grep -o '[0-9]* deletion' | grep -o '[0-9]*')

  # --exclude-standard so ignored files stay ignored, and --directory so a new
  # directory counts once instead of once per file inside it -- both what
  # `git status` itself shows.
  untracked=$(git -C "$dir" ls-files --others --exclude-standard --directory \
    --no-empty-directory 2>/dev/null | wc -l | tr -d ' ')

  # Nothing waiting, nothing unpushed, nothing uncommitted, nothing new: no row.
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

  # The path is carried in a first column fzf is told not to display, so the
  # brief can be coloured without the selection having to be parsed back out.
  printf '%s\t%s  %b\n' "$dir" "$dir" "$brief"
}

pick_git_brief() {
  # A git repository that has something to show -- commits waiting upstream,
  # commits not yet pushed, or uncommitted work (staged, unstaged or
  # untracked). A repository level with its upstream and clean in the working
  # tree is left out: there is nothing there to go and look at, which is the
  # only reason to reach for this picker.
  #
  # Every repository is fetched before it is inspected, so the ahead/behind
  # counts are current. That is what makes this picker slower to appear than
  # `git`, which is there for when you just want the list.
  #
  # Environment
  #   TSM_GIT_DIRS_CMD     the repositories to check; the same variable the
  #                        `git` picker reads, and the same default
  #   TSM_GIT_FETCH_JOBS   how many repositories are fetched and inspected at
  #                        once (default 8)
  local dirs
  dirs=$(eval "${TSM_GIT_DIRS_CMD:-$TSM_GIT_DIRS_CMD_DEFAULT}" | sort)

  if [ -z "$dirs" ]; then
    notify "No git repositories found"
    exit 1
  fi

  # Inspected in parallel, but bounded: each job opens a remote connection for
  # its fetch, and forking the whole list at once can hit the process limit.
  # NUL separation so repository paths with spaces survive. `|| true` because
  # a repository with nothing to report is the ordinary case, not an xargs
  # failure. The export lives in the command substitution's subshell, so the
  # session that follows does not inherit it.
  local rows
  rows=$(
    export -f git_brief_row
    printf '%s\n' "$dirs" | tr '\n' '\0' \
      | xargs -0 -P "${TSM_GIT_FETCH_JOBS:-8}" -n 1 \
              bash -c 'git_brief_row "$1" || true' _ \
      | LC_ALL=C sort
  )

  local checked changed=0
  checked=$(printf '%s\n' "$dirs" | wc -l | tr -d ' ')
  [ -n "$rows" ] && changed=$(printf '%s\n' "$rows" | wc -l | tr -d ' ')

  if [ -z "$rows" ]; then
    notify "Nothing to show: none of the $checked repositories checked have changes"
    exit 1
  fi

  # The header says how many of the repositories checked had changes, so an
  # empty-looking list is distinguishable from a short one.
  local header
  header=$(printf ':: \033[33m%s\033[0m of \033[33m%s\033[0m repositories have changes' \
    "$changed" "$checked")

  local selected
  selected=$(printf '%s\n' "$rows" \
    | fzf --ansi --cycle --delimiter=$'\t' --with-nth=2 --prompt "Repo > " --header "$header")

  PICKED_DIR="${selected%%	*}"

  [ -n "$PICKED_DIR" ]
}

pick_worktree() {
  # A worktree of the current repository, chosen with fzf.
  local worktree_data
  worktree_data=$(git worktree list --porcelain 2>/dev/null | awk '
    /^worktree / { path = substr($0, 10); branch = "" }
    /^branch / { branch = substr($0, 8); sub("refs/heads/", "", branch) }
    /^bare$/ { path = "" }
    /^$/ { if (path != "") print path "\t" (branch != "" ? branch : "(detached)"); path = ""; branch = "" }
    END { if (path != "") print path "\t" (branch != "" ? branch : "(detached)") }
  ')

  if [ -z "$worktree_data" ]; then
    notify "No worktrees found"
    exit 1
  fi

  # Header labels are measured alongside the values so short columns still
  # widen to fit them. fzf indents --header by the two columns its pointer
  # takes, so the header lines up with the rows on its own.
  local name_label='wt' branch_label='branch'
  local fzf_input header max_name=${#name_label} max_branch=${#branch_label}
  while IFS=$'\t' read -r wt branch; do
    local wt_name="${wt##*/}"
    (( ${#wt_name} > max_name )) && max_name=${#wt_name}
    (( ${#branch} > max_branch )) && max_branch=${#branch}
  done <<< "$worktree_data"
  fzf_input=$(echo "$worktree_data" | while IFS=$'\t' read -r wt branch; do
    printf '%s\t%-*s  \033[32m%-*s\033[0m  %s\n' "$wt" "$max_name" "${wt##*/}" "$max_branch" "$branch" "$wt"
  done)
  header=$(printf '%-*s  %-*s  %s' "$max_name" "$name_label" "$max_branch" "$branch_label" 'path')

  local selected
  selected=$(echo "$fzf_input" | fzf --ansi --cycle --with-nth=2 --delimiter=$'\t' --prompt "Worktree > " --header "$header")

  PICKED_DIR="${selected%%	*}"

  [ -n "$PICKED_DIR" ]
}

pick_bookmark() {
  # A bookmarked directory, chosen with fzf. To go straight to one without
  # the fzf, `tsm bookmark-path <char>` prints it -- which makes it a picker
  # of the other kind: `tsm via tsm bookmark-path m`.
  local entries
  entries=$(bookmark_entries)

  if [ -z "$entries" ]; then
    notify "No bookmarks set"
    exit 1
  fi

  # ctrl-x removes the bookmark under the cursor, then rebuilds the list from
  # disk. fzf hands a binding to a shell, so tsm's path is quoted for one;
  # fzf itself quotes {1}.
  local self
  printf -v self '%q' "$(tsm_self)"

  local selected
  selected=$(printf '%s\n' "$entries" | fzf \
    --cycle \
    --delimiter=$'\t' \
    --with-nth=3 \
    --prompt "Bookmark > " \
    --header $':: \e[33mctrl-x\e[0m to \e[31mremove\e[0m' \
    --bind "ctrl-x:execute-silent($self bookmark-remove {1})+reload($self _bookmark-entries)")

  [ -n "$selected" ] || return 1

  # The row carries the directory in its second field, so the session is
  # rooted at the bookmarked path rather than the ~ the row displayed.
  local row="${selected#*$'\t'}"
  PICKED_DIR="${row%%$'\t'*}"
}
