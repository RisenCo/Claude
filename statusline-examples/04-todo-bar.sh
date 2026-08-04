#!/usr/bin/env bash
# Example 4 - Live todo list completion bar.
#
# Reads the snapshot written by hooks/todo-progress.sh and turns Claude's own
# in-session todo list into a percentage. This tracks the plan for the current
# task, not the whole project - it resets whenever Claude starts a new plan.
#
#   todo  ███████████████░░░░░  75%  3/4   ▸ Running the test suite
#
# Needs hooks/todo-progress.sh installed as a PostToolUse hook. Without it,
# this prints nothing at all.

set -uo pipefail
input=$(cat)

# shellcheck source=lib/bar.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/bar.sh"

SNAPSHOT_DIR="${TODO_PROGRESS_DIR:-$HOME/.claude/todo-progress}"
session=$(jq -r '.session_id // ""' <<<"$input")
snapshot="$SNAPSHOT_DIR/$session.json"

# No todo list yet this session - print nothing rather than a hollow 0%.
[[ -s $snapshot ]] || exit 0

total=$(jq -r '.total // 0' "$snapshot" 2>/dev/null) || exit 0
completed=$(jq -r '.completed // 0' "$snapshot" 2>/dev/null) || exit 0
# Collapse newlines so a multi-line task title can't break the status line.
active=$(jq -r '(.active // "") | gsub("\\s+"; " ")' "$snapshot" 2>/dev/null)

[[ ${total:-0} -gt 0 ]] || exit 0

pct=$((completed * 100 / total))

if ((${#active} > 44)); then active="${active:0:43}…"; fi

printf 'todo  %s%s%s  %d%%  %d/%d' \
  "$(progress_color "$pct")" "$(render_bar "$pct" 20)" "$RESET" \
  "$pct" "$completed" "$total"

[[ -n $active ]] && printf '   %s▸ %s%s' "$DIM" "$active" "$RESET"
printf '\n'
