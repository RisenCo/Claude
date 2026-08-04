#!/usr/bin/env bash
# Example 2 - Multi-line session dashboard.
#
# Every echo becomes its own row in the status line. This one shows the three
# resource meters Claude Code actually tracks: context window, and the 5-hour
# and 7-day rate limit windows.
#
#   Opus · Claude · main +2 ~1 · PR #14
#   ctx  ██████░░░░░░░░░░░░░░  31%   5h ███░░░░░░░  28%   7d █░░░░░░░░░  12%
#   $0.42 · 6m14s · +156/-23 lines

set -uo pipefail
input=$(cat)

# shellcheck source=lib/bar.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/bar.sh"

MODEL=$(jq -r '.model.display_name // "claude"' <<<"$input")
DIR=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")
CTX=$(jq -r '.context_window.used_percentage // 0' <<<"$input")
H5=$(jq -r '.rate_limits.five_hour.used_percentage // 0' <<<"$input")
D7=$(jq -r '.rate_limits.seven_day.used_percentage // 0' <<<"$input")
COST=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
DUR_MS=$(jq -r '.cost.total_duration_ms // 0' <<<"$input")
ADDED=$(jq -r '.cost.total_lines_added // 0' <<<"$input")
REMOVED=$(jq -r '.cost.total_lines_removed // 0' <<<"$input")
PR_NUM=$(jq -r '.pr.number // ""' <<<"$input")
PR_STATE=$(jq -r '.pr.review_state // ""' <<<"$input")

GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'

# --- Line 1: identity -------------------------------------------------------
line1="$MODEL"
[[ -n $DIR ]] && line1="${line1} ${DIM}·${RESET} ${DIR##*/}"

if git -C "${DIR:-.}" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$DIR" branch --show-current 2>/dev/null)
  staged=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  git_bit="${branch:-detached}"
  ((staged > 0)) && git_bit="${git_bit} ${GREEN}+${staged}${RESET}"
  ((modified > 0)) && git_bit="${git_bit} ${YELLOW}~${modified}${RESET}"
  line1="${line1} ${DIM}·${RESET} ${git_bit}"
fi

if [[ -n $PR_NUM ]]; then
  pr_bit="PR #${PR_NUM}"
  [[ -n $PR_STATE ]] && pr_bit="${pr_bit} (${PR_STATE})"
  line1="${line1} ${DIM}·${RESET} ${pr_bit}"
fi

# --- Line 2: the three resource meters --------------------------------------
# Narrow terminals get one meter instead of three.
width=${COLUMNS:-100}
if ((width < 80)); then
  line2=$(printf 'ctx  %s%s%s  %d%%' \
    "$(bar_color "$CTX")" "$(render_bar "$CTX" 20)" "$RESET" "${CTX%%.*}")
else
  line2=$(printf 'ctx  %s%s%s  %3d%%   5h %s%s%s %3d%%   7d %s%s%s %3d%%' \
    "$(bar_color "$CTX")" "$(render_bar "$CTX" 20)" "$RESET" "${CTX%%.*}" \
    "$(bar_color "$H5")" "$(render_bar "$H5" 10)" "$RESET" "${H5%%.*}" \
    "$(bar_color "$D7")" "$(render_bar "$D7" 10)" "$RESET" "${D7%%.*}")
fi

# --- Line 3: what the session has cost and produced --------------------------
secs=$((DUR_MS / 1000))
elapsed=$(printf '%dm%02ds' $((secs / 60)) $((secs % 60)))
line3=$(printf '%s$%.2f · %s · %s+%s%s/%s-%s%s lines%s' \
  "$DIM" "$COST" "$elapsed" "$GREEN" "$ADDED" "$DIM" "$RED" "$REMOVED" "$DIM" "$RESET")

printf '%s\n%s\n%s\n' "$line1" "$line2" "$line3"
