setopt PROMPT_SUBST

# Shows the current Git branch in the prompt
parse_git_branch() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "[git ✗]"
    return
  fi
  local branch=$(git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/\1/p')
  if [ -n "$branch" ]; then
    local max_len=$(( COLUMNS - 15 ))
    if [ ${#branch} -gt $max_len ]; then
      echo "[${branch:0:$max_len}...]"
    else
      echo "[$branch]"
    fi
  fi
}

parse_path() {
  local dir=${(%):-%~}
  local max_len=$(( COLUMNS - 15 ))
  if [ ${#dir} -gt $max_len ]; then
    echo "[${dir:0:$max_len}...]"
  else
    echo "[$dir]"
  fi
}

# Colors
COLOR_USR=$'%F{160}'       # Red
COLOR_DIR=$'%F{33}'        # Blue
COLOR_GIT=$'%F{208}'       # Orange
COLOR_DEF=$'%F{FFF}'       # White

# Prompt layout
export PROMPT='${COLOR_DEF}╭─ ${COLOR_USR}[%n]
${COLOR_DEF}├─ ${COLOR_DIR}$(parse_path)
${COLOR_DEF}├─ ${COLOR_GIT}$(parse_git_branch)
${COLOR_DEF}╰─❯ $ '
