#!/usr/bin/env bash
# Shared bar-rendering helpers. Source this, or copy the two functions into
# your own status line script so it stays a single self-contained file.

# render_bar <percent> <width> [filled_char] [empty_char]
# Clamps percent to 0..100 and prints a bar of exactly <width> characters.
render_bar() {
  local pct=${1:-0} width=${2:-10} fill=${3:-█} empty=${4:-░}
  local filled rest out="" pad

  # Strip any decimal part; used_percentage can arrive as a float.
  pct=${pct%%.*}
  [[ $pct =~ ^-?[0-9]+$ ]] || pct=0
  ((pct < 0)) && pct=0
  ((pct > 100)) && pct=100

  filled=$((pct * width / 100))
  rest=$((width - filled))

  if ((filled > 0)); then
    printf -v pad "%${filled}s"
    out="${pad// /$fill}"
  fi
  if ((rest > 0)); then
    printf -v pad "%${rest}s"
    out="${out}${pad// /$empty}"
  fi

  printf '%s' "$out"
}

# bar_color <percent> <warn_at> <crit_at>
# Prints the ANSI color for a "consumption" bar, where more is worse.
bar_color() {
  local pct=${1:-0} warn=${2:-60} crit=${3:-85}
  pct=${pct%%.*}
  [[ $pct =~ ^-?[0-9]+$ ]] || pct=0
  if ((pct >= crit)); then
    printf '\033[31m'   # red
  elif ((pct >= warn)); then
    printf '\033[33m'   # yellow
  else
    printf '\033[32m'   # green
  fi
}

# progress_color <percent>
# Prints the ANSI color for a "completion" bar, where more is better.
progress_color() {
  local pct=${1:-0}
  pct=${pct%%.*}
  [[ $pct =~ ^-?[0-9]+$ ]] || pct=0
  if ((pct >= 100)); then
    printf '\033[32m'   # green - done
  elif ((pct >= 50)); then
    printf '\033[36m'   # cyan - past halfway
  else
    printf '\033[33m'   # yellow - early
  fi
}

RESET=$'\033[0m'
DIM=$'\033[2m'
