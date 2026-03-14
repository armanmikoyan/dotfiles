setopt PROMPT_SUBST

# Colors
COLOR_USR=$'%F{160}'       # Red
COLOR_DIR=$'%F{33}'        # Blue
COLOR_GIT=$'%F{208}'       # Orange
COLOR_TIME=$'%F{141}'      # Purple
COLOR_BAT_HIGH=$'%F{34}'   # Green (70%+)
COLOR_BAT_MID=$'%F{226}'   # Yellow (40-69%)
COLOR_BAT_LOW=$'%F{196}'   # Red (<40%)
COLOR_SYS=$'%F{117}'      # Light blue
COLOR_DEF=$'%F{255}'       # White

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

parse_cpu() {
  local total=$(sysctl -n hw.ncpu 2>/dev/null)
  local pct=$(top -l 1 -n 0 -s 0 2>/dev/null | awk '/CPU usage/ {printf "%.0f", (100 - $7) * '"$total"'}')
  local used=$(awk "BEGIN {printf \"%.1f\", $pct/100}")
  echo "[CPU ${used}/${total} ${pct}%%]"
}

parse_mem() {
  local used=$(vm_stat 2>/dev/null | awk '/page size of/ {ps=$8} /Anonymous pages/ {a=$NF} /Pages wired/ {w=$NF} /Pages occupied by compressor/ {c=$NF} END {printf "%.1f", (a+w+c)*ps/1073741824}')
  local total=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1073741824}')
  echo "[MEM ${used}/${total}GB]"
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

parse_top_line() {
  local batt="$(parse_battery)"
  local cpu="$(parse_cpu)"
  local mem="$(parse_mem)"
  local time="[%D{%b %d, %I:%M %p}]"

  if [[ $COLUMNS -ge 65 ]]; then
    echo "${batt} ${COLOR_SYS}${cpu} ${mem} ${COLOR_TIME}${time}"
  elif [[ $COLUMNS -ge 55 ]]; then
    echo "${batt} ${COLOR_SYS}${cpu} ${mem}"
  else
    echo "${batt}"
  fi
}

# Prompt layout
export PROMPT='${COLOR_DEF}╭─ $(parse_top_line)
${COLOR_DEF}├─ ${COLOR_USR}[%n] ${COLOR_DIR}$(parse_path)
${COLOR_DEF}├─ ${COLOR_GIT}$(parse_git_branch)
${COLOR_DEF}╰─❯ $ '
