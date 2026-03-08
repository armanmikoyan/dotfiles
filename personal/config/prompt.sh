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

parse_battery() {
  local batt=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')
  if [[ -z "$batt" ]]; then
    echo "${COLOR_BAT_LOW}[⚡--]"
  elif [[ $batt -ge 70 ]]; then
    echo "${COLOR_BAT_HIGH}[⚡${batt}%%]"
  elif [[ $batt -ge 40 ]]; then
    echo "${COLOR_BAT_MID}[⚡${batt}%%]"
  else
    echo "${COLOR_BAT_LOW}[⚡${batt}%%]"
  fi
}

# Colors
COLOR_USR=$'%F{160}'       # Red
COLOR_DIR=$'%F{33}'        # Blue
COLOR_GIT=$'%F{208}'       # Orange
COLOR_TIME=$'%F{141}'      # Purple
COLOR_BAT_HIGH=$'%F{34}'   # Green (70%+)
COLOR_BAT_MID=$'%F{226}'   # Yellow (40-69%)
COLOR_BAT_LOW=$'%F{196}'   # Red (<40%)
COLOR_DEF=$'%F{255}'       # White

# Prompt layout
export PROMPT='${COLOR_DEF}╭─ ${COLOR_USR}[%n] $(parse_battery) ${COLOR_TIME}[%D{%b %d, %I:%M %p}]
${COLOR_DEF}├─ ${COLOR_DIR}$(parse_path)
${COLOR_DEF}├─ ${COLOR_GIT}$(parse_git_branch)
${COLOR_DEF}╰─❯ $ '