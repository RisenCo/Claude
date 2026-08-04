#!/usr/bin/env bash
# PostToolUse hook - snapshot Claude's live todo list to a file the status
# line can read.
#
# The status line and the todo list don't talk to each other. The status line
# only gets the JSON blob documented at code.claude.com/docs/en/statusline, and
# there is no todo field in it. This hook bridges the gap: every time Claude
# rewrites its todo list, we cache the counts, keyed by session id.
#
# Wire it up in .claude/settings.json:
#   { "hooks": { "PostToolUse": [ {
#       "matcher": "TodoWrite",
#       "hooks": [ { "type": "command",
#                    "command": "~/.claude/statusline/hooks/todo-progress.sh" } ]
#   } ] } }
#
# Note: the todo tool is named TodoWrite in current Claude Code. Some builds
# expose task tools under different names; this script reads whichever of
# .tool_input.todos / .tool_input.tasks is present, so it degrades quietly
# rather than writing garbage.

set -uo pipefail
input=$(cat)

SNAPSHOT_DIR="${TODO_PROGRESS_DIR:-$HOME/.claude/todo-progress}"
session=$(jq -r '.session_id // "unknown"' <<<"$input" 2>/dev/null) || exit 0
[[ -n $session ]] || exit 0

snapshot=$(jq -c '
  ((.tool_input.todos // .tool_input.tasks // []) | map(select(type == "object"))) as $t
  | ($t | map(select(.status == "in_progress")) | first) as $active
  | {
      total:       ($t | length),
      completed:   ($t | map(select(.status == "completed"))   | length),
      in_progress: ($t | map(select(.status == "in_progress")) | length),
      active:      ($active | (.activeForm // .content // .description // null))
    }
' <<<"$input" 2>/dev/null) || exit 0

# An empty list means Claude cleared its todos - drop the snapshot so the
# status line stops showing a stale 100%.
total=$(jq -r '.total // 0' <<<"$snapshot" 2>/dev/null) || total=0

mkdir -p "$SNAPSHOT_DIR" 2>/dev/null || exit 0
if [[ ${total:-0} -gt 0 ]]; then
  printf '%s\n' "$snapshot" >"$SNAPSHOT_DIR/$session.json"
else
  rm -f "$SNAPSHOT_DIR/$session.json"
fi

# Hooks must never break the session: always succeed.
exit 0
