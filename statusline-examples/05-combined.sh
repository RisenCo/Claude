#!/usr/bin/env bash
# Example 5 - The one you probably want: session resources on top, project
# completion underneath.
#
# Claude Code runs exactly one status line command, so to show several meters
# you compose them in a single script and print multiple rows.
#
#   Opus · Claude · main ~3 · PR #14 (draft)
#   ctx  ██████░░░░░░░░░░░░░░  31%   $0.42 · 6m14s · +156/-23
#   plan ███████████████░░░░░  75%  3/4   ▸ Running the test suite
#   ship ██████████░░░░░░░░░░  54%  12/22   next: Wire up refresh tokens
#
# Row 3 ("plan") is the current task. Row 4 ("ship") is the whole project.
# Those are different questions and it's worth seeing both: Claude can be at
# 100% on its plan while the project is at 54%.

set -uo pipefail
input=$(cat)

here="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=lib/bar.sh
source "$here/lib/bar.sh"

MODEL=$(jq -r '.model.display_name // "claude"' <<<"$input")
DIR=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")
CTX=$(jq -r '.context_window.used_percentage // 0' <<<"$input")
COST=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
DUR_MS=$(jq -r '.cost.total_duration_ms // 0' <<<"$input")
ADDED=$(jq -r '.cost.total_lines_added // 0' <<<"$input")
REMOVED=$(jq -r '.cost.total_lines_removed // 0' <<<"$input")
PR_NUM=$(jq -r '.pr.number // ""' <<<"$input")
PR_STATE=$(jq -r '.pr.review_state // ""' <<<"$input")

GREEN=$'\033[32m'
YELLOW=$'\033[33m'

# --- Row 1: where am I ------------------------------------------------------
row1="$MODEL"
[[ -n $DIR ]] && row1="${row1} ${DIM}·${RESET} ${DIR##*/}"
if git -C "${DIR:-.}" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$DIR" branch --show-current 2>/dev/null)
  modified=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  row1="${row1} ${DIM}·${RESET} ${branch:-detached}"
  ((modified > 0)) && row1="${row1} ${YELLOW}~${modified}${RESET}"
fi
if [[ -n $PR_NUM ]]; then
  row1="${row1} ${DIM}·${RESET} PR #${PR_NUM}"
  [[ -n $PR_STATE ]] && row1="${row1} ${DIM}(${PR_STATE})${RESET}"
fi

# --- Row 2: session burn ----------------------------------------------------
secs=$((DUR_MS / 1000))
row2=$(printf 'ctx  %s%s%s  %3d%%   %s$%.2f · %dm%02ds · +%s/-%s%s' \
  "$(bar_color "$CTX")" "$(render_bar "$CTX" 20)" "$RESET" "${CTX%%.*}" \
  "$DIM" "$COST" $((secs / 60)) $((secs % 60)) "$ADDED" "$REMOVED" "$RESET")

printf '%s\n%s\n' "$row1" "$row2"

# --- Rows 3 and 4: completion, if the inputs exist --------------------------
# Both sub-scripts print nothing when they have nothing to measure, so the
# status line shrinks instead of showing empty meters.
todo_row=$(printf '%s' "$input" | "$here/04-todo-bar.sh" 2>/dev/null)
[[ -n $todo_row ]] && printf '%s\n' "${todo_row/#todo/plan}"

check_row=$(printf '%s' "$input" | CHECKLIST_LABEL="ship" "$here/03-checklist-bar.sh" 2>/dev/null)
# Skip the "no checklist" notice here; row 1 already tells you where you are.
[[ -n $check_row && $check_row != *"no checklist"* && $check_row != *"no checkboxes"* ]] \
  && printf '%s\n' "$check_row"

exit 0
