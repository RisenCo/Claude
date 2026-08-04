#!/usr/bin/env bash
# Example 3 - Project completion bar driven by a markdown checklist.
#
# Claude Code does NOT ship a "percent of project complete" meter, because it
# has no way to know what "done" means for your project. You define done by
# writing it down; this script counts it.
#
# Point it at a file (or a directory of files) containing GitHub-style
# checkboxes and it renders real completion:
#
#   - [x] shipped
#   - [ ] not yet
#
#   ROADMAP  ████████████░░░░░░░░  61%  14/23   next: wire up refresh tokens
#
# Config via env vars in .claude/settings.json:
#   CHECKLIST_PATH   file or directory to scan (default: <project>/ROADMAP.md)
#   CHECKLIST_LABEL  label shown before the bar (default: file basename)

set -uo pipefail
input=$(cat)

# shellcheck source=lib/bar.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/bar.sh"

PROJECT_DIR=$(jq -r '.workspace.project_dir // .cwd // "."' <<<"$input")
TARGET="${CHECKLIST_PATH:-$PROJECT_DIR/ROADMAP.md}"

# Collect the files to scan. A directory scans its markdown two levels deep.
files=()
if [[ -d $TARGET ]]; then
  while IFS= read -r f; do files+=("$f"); done \
    < <(find "$TARGET" -maxdepth 2 -name '*.md' -type f 2>/dev/null | sort)
elif [[ -f $TARGET ]]; then
  files=("$TARGET")
fi

if ((${#files[@]} == 0)); then
  # Nothing to measure - stay quiet rather than showing a fake 0%.
  printf '%sno checklist at %s%s\n' "$DIM" "${TARGET/#$HOME/\~}" "$RESET"
  exit 0
fi

DONE_RE='^[[:space:]]*[-*][[:space:]]+\[[xX]\]'
OPEN_RE='^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\]'

done_count=0
open_count=0
for f in "${files[@]}"; do
  d=$(grep -cE "$DONE_RE" "$f" 2>/dev/null) || d=0
  o=$(grep -cE "$OPEN_RE" "$f" 2>/dev/null) || o=0
  done_count=$((done_count + d))
  open_count=$((open_count + o))
done

total=$((done_count + open_count))
if ((total == 0)); then
  printf '%sno checkboxes found%s\n' "$DIM" "$RESET"
  exit 0
fi

pct=$((done_count * 100 / total))

# The first unchecked box is the natural "you are here" marker.
next=""
for f in "${files[@]}"; do
  next=$(grep -m1 -E "$OPEN_RE" "$f" 2>/dev/null \
    | sed -E 's/^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\][[:space:]]*//') || next=""
  [[ -n $next ]] && break
done
# Keep the status line to one row: truncate a long task title.
if ((${#next} > 42)); then next="${next:0:41}…"; fi

if [[ -n ${CHECKLIST_LABEL:-} ]]; then
  label=$CHECKLIST_LABEL
elif ((${#files[@]} > 1)); then
  label="$(basename "$TARGET")"
else
  label="$(basename "${files[0]}" .md)"
fi

printf '%s  %s%s%s  %d%%  %d/%d' \
  "$label" "$(progress_color "$pct")" "$(render_bar "$pct" 20)" "$RESET" \
  "$pct" "$done_count" "$total"

[[ -n $next ]] && printf '   %snext: %s%s' "$DIM" "$next" "$RESET"
printf '\n'
