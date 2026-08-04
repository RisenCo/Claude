# Progress bars in Claude Code

Working status line scripts, plus a straight answer about what Claude Code
does and doesn't measure.

## The short version

**Claude Code has no built-in "percent of project complete" bar, and can't.**
It has no definition of done for your project. Every percentage it shows you
out of the box is about *session resources* — how much context you've burned,
how much of your rate limit you've spent — not about how much software is
finished.

Progress toward *finishing the work* is tracked as a **checklist with no
percentage**: Claude's todo list, rendered as ☐/☑ items as it works.

So there are two separate things, and it's worth keeping them straight:

| What you want to know | What Claude Code gives you |
| --- | --- |
| How full is my context window? | `/context`, and `context_window.used_percentage` in the status line — a real percentage |
| What's this session costing? | `/usage` (alias `/cost`), and `cost.*` in the status line |
| How much of my rate limit is gone? | `rate_limits.five_hour` / `rate_limits.seven_day` — real percentages |
| What is Claude working on right now? | The todo checklist, and `/tasks` for background work |
| **How close is my project to done?** | **Nothing built in — you define it, these scripts count it** |

## Built-in commands worth knowing

- `/context` — context usage as a colored grid, with what's eating it
- `/usage` / `/cost` — token spend and cost for the session
- `/tasks` — background work and subagents, including finished ones
- `/status` — session status
- `/statusline` — asks Claude to *write you a status line script* from a plain
  description, e.g. `/statusline show a progress bar for ROADMAP.md checkboxes`

`/context`, `/usage`, `/tasks`, and `/status` run without interrupting
whatever Claude is currently doing.

## What's in here

| File | What it shows |
| --- | --- |
| `01-context-bar.sh` | Context window usage — the one free percentage |
| `02-dashboard.sh` | Three rows: identity, context + rate limits, cost |
| `03-checklist-bar.sh` | **Real project completion**, counted from markdown checkboxes |
| `hooks/todo-progress.sh` | PostToolUse hook that snapshots Claude's live todo list |
| `04-todo-bar.sh` | Completion bar for the current task's todo list |
| `05-combined.sh` | Session burn on top, plan + project completion underneath |
| `lib/bar.sh` | Shared bar rendering and color thresholds |
| `demo.sh` | Runs everything against sample JSON |

## Try it without installing anything

```bash
./demo.sh
```

That pipes `fixtures/session.json` — a realistic copy of the JSON Claude Code
sends a status line — through every script, and points the checklist example at
`fixtures/ROADMAP.md`. Nothing touches your real `~/.claude`.

Sample output:

```
Opus · Claude · main ~3 · PR #14 (draft)
ctx  ██████░░░░░░░░░░░░░░   31%   $0.42 · 6m14s · +156/-23
plan ███████████████░░░░░  75%  3/4   ▸ Running the test suite
ship  ██████████░░░░░░░░░░  54%  12/22   next: Wire up refresh tokens
```

`plan` is Claude's todo list for the task in front of it. `ship` is the whole
project. They move independently — Claude hits 100% on its plan constantly
while the project sits at 54%.

## Install

```bash
cp -r statusline-examples ~/.claude/statusline
```

Then copy the `statusLine` and `hooks` blocks from `settings.example.json` into
`.claude/settings.json` (this project) or `~/.claude/settings.json` (all
projects):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline/05-combined.sh"
  }
}
```

Claude Code runs **one** status line command. To show several meters, compose
them in a single script and print multiple lines — that's what `05-combined.sh`
does.

## How the project completion bar works

`03-checklist-bar.sh` counts GitHub-style checkboxes:

```markdown
- [x] done
- [ ] not done
```

Percentage is `done / (done + open)`. It also surfaces the first unchecked item
as `next:`, which turns out to be the useful part — a number tells you how far
along you are, the next item tells you what to do about it.

Configure with env vars:

- `CHECKLIST_PATH` — a file, or a directory whose `*.md` files are scanned two
  levels deep. Defaults to `<project_dir>/ROADMAP.md`.
- `CHECKLIST_LABEL` — text before the bar. Defaults to the filename.

This is deliberately dumb. Checkbox counting weights a two-minute task the same
as a two-week one, so treat it as a rough gauge, not a schedule. If you want
something better-grounded, point the same bar at a signal that's harder to fool
— passing tests, migrated call sites, closed issues in a milestone. The
rendering code doesn't care where the numerator comes from.

## How the todo bar works

The status line only receives the JSON documented at
[code.claude.com/docs/en/statusline](https://code.claude.com/docs/en/statusline),
and **there is no todo field in it**. So `hooks/todo-progress.sh` bridges the
gap: it fires on `PostToolUse` for `TodoWrite`, writes the counts to
`~/.claude/todo-progress/<session_id>.json`, and `04-todo-bar.sh` reads that
back.

Two caveats worth knowing before you rely on it:

- The todo tool is named `TodoWrite` in current Claude Code. The hook reads
  whichever of `.tool_input.todos` / `.tool_input.tasks` is present so it fails
  quiet rather than wrong, but a build that names things differently will
  simply show no bar.
- Snapshots are keyed by session id and never expire. `find
  ~/.claude/todo-progress -mtime +7 -delete` if the directory bothers you.

## Notes on writing your own

- **stdin is JSON.** Full field list in the
  [status line docs](https://code.claude.com/docs/en/statusline#available-data).
- **Each `echo` is a row.** Multi-line output is supported and renders above
  the built-in footer badges.
- **ANSI colors work**; `\033[32m` green, `\033[0m` reset.
- **`tput cols` does not work.** Claude Code captures your output instead of
  attaching a terminal, so read the `COLUMNS` and `LINES` env vars it sets
  (v2.1.153+). `02-dashboard.sh` drops to one meter under 80 columns.
- **Print nothing when you have nothing.** An empty bar reads as 0% complete,
  which is a lie. `04-todo-bar.sh` exits silently instead.
- **Never let a hook fail the session.** `hooks/todo-progress.sh` ends with
  `exit 0` no matter what.

## Requirements

`bash` and [`jq`](https://jqlang.org/). The official docs carry equivalent
Python and Node.js versions of the context bar if you'd rather not depend on
`jq`.
