#!/usr/bin/env bash
# Run every example against sample session JSON so you can see the output
# before wiring anything into settings.json.
#
#   ./demo.sh

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

export COLUMNS="${COLUMNS:-100}"

SAMPLE=fixtures/session.json
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# Point the checklist example at the sample roadmap, and the todo example at a
# throwaway snapshot dir so the demo never touches your real ~/.claude.
export CHECKLIST_PATH="$PWD/fixtures/ROADMAP.md"
export TODO_PROGRESS_DIR="$PWD/fixtures/todo-snapshots"

section() {
  printf '\n%s%s%s\n%s%s%s\n' "$BOLD" "$1" "$RESET" "$DIM" "$2" "$RESET"
}

section "01  Context window bar" "how full the session context is"
./01-context-bar.sh <"$SAMPLE"

section "02  Session dashboard" "context + rate limits + cost, three rows"
./02-dashboard.sh <"$SAMPLE"

section "03  Project completion bar" "counted from ROADMAP.md checkboxes"
./03-checklist-bar.sh <"$SAMPLE"

section "04  Live todo bar" "fed by the PostToolUse hook"
# Simulate the hook firing on a TodoWrite call, then render.
./hooks/todo-progress.sh <fixtures/todowrite-hook.json
./04-todo-bar.sh <"$SAMPLE"

section "05  Combined" "session burn on top, project completion underneath"
./05-combined.sh <"$SAMPLE"

section "Empty states" "what you see when there is nothing to measure"
CHECKLIST_PATH="$PWD/fixtures/does-not-exist.md" ./03-checklist-bar.sh <"$SAMPLE"

empty_out=$(TODO_PROGRESS_DIR="$PWD/fixtures/empty" ./04-todo-bar.sh <"$SAMPLE")
if [[ -z $empty_out ]]; then
  printf '%s(todo bar emits nothing at all when no snapshot exists)%s\n' "$DIM" "$RESET"
else
  printf '%s\n' "$empty_out"
fi

printf '\n'
