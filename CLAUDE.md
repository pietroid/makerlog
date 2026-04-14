# makerbook

> This file is auto-maintained by makerbook. You can add notes below the divider.

## Project Intent
**Hypothesis:** Maker book is unified CLI to report, write ideas, manage work and share your learnings, while builders can focus on actually building stuff
**Scope:** A CLI that is also a sort of text editor, and that can be used for memory for when you want to review your project and publish nice things. This can be connected in the future with multiple plugins but the current scope is very simple: just some place I can feel comfortable sharing ideas about my own projects. Also the scope of this iteration goes until the publish part, which will be the more challenging and interesting also because it solves my problem on organizing information to share about the things I do.
**Critical feature to validate:** Collect your logwork and be able to organize a blog post with it.
**Time budget:** 16h — 2 full days

## Journal
The project journal lives at `makerbook/main.md`. Read it for full context.
Screenshots are in `makerbook/assets/`.

## Makerbook Conventions
- Journal entries are timestamped markdown: `DDMMYYYY - HH:MM - <note>`
- `@claude` entries show conversations: `**you:** / **claude:**`
- `@screenshot` entries embed PNG links
- Use `python3 makerbook.py` to open the TUI

## Claude Code Integration
- Claude Code Stop hook appends session summaries to `makerbook/main.md`
- `git commit` via Claude Code is logged automatically
- Active project context: `~/.makerbook/active.json`

---
<!-- Custom notes below this line are preserved across makerbook updates -->














































































