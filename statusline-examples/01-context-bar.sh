#!/usr/bin/env bash
# Example 1 - Context window usage bar.
#
# This is the ONE percentage Claude Code hands you for free. It measures how
# full the session's context window is, NOT how much of your project is built.
#
#   Opus  ██████░░░░░░░░░░░░░░  31%  ctx
#
# Wire it up in .claude/settings.json:
#   { "statusLine": { "type": "command",
#                     "command": "~/.claude/statusline/01-context-bar.sh" } }

set -uo pipefail
input=$(cat)

MODEL=$(jq -r '.model.display_name // "claude"' <<<"$input")
PCT=$(jq -r '.context_window.used_percentage // 0' <<<"$input")
PCT=${PCT%%.*}

BAR_WIDTH=20
filled=$((PCT * BAR_WIDTH / 100))
rest=$((BAR_WIDTH - filled))

bar=""
((filled > 0)) && printf -v pad "%${filled}s" && bar="${pad// /█}"
((rest > 0)) && printf -v pad "%${rest}s" && bar="${bar}${pad// /░}"

# More context used is worse, so ramp green -> yellow -> red.
if ((PCT >= 85)); then
  color=$'\033[31m'
elif ((PCT >= 60)); then
  color=$'\033[33m'
else
  color=$'\033[32m'
fi
reset=$'\033[0m'

printf '%s  %s%s%s  %d%%  ctx\n' "$MODEL" "$color" "$bar" "$reset" "$PCT"
