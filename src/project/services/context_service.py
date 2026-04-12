"""context_service — write shared context files for Claude Code and other tools.

When a session starts, three files are written so external tools know
what the maker is working on:

- ~/.makerbook/active.json  — machine-readable structured data
- ~/.makerbook/context.md   — human-readable summary for Claude Code
- <project>/CLAUDE.md       — auto-loaded by Claude Code at project root
"""

import json
import re
from datetime import datetime
from pathlib import Path

from src.project.services.config_service import ACTIVE_FILE, CONTEXT_FILE, ensure_global_dir
from src.journal.services.journal_service import project_label, read_journal

_DIVIDER = "<!-- Custom notes below this line are preserved across makerbook updates -->"


def write_active_context(journal_path: Path) -> None:
    """Write active.json, context.md, and CLAUDE.md from the current journal.

    Call this whenever the journal changes so all downstream tools stay
    in sync.
    """
    ensure_global_dir()
    journal_text = read_journal(journal_path)
    project_path = journal_path.parent.parent

    def _field(pattern: str) -> str:
        m = re.search(pattern, journal_text)
        return m.group(1).strip() if m else ""

    hypothesis       = _field(r'\*\*What are you trying to solve\?\*\*\s*\n([^\n]+)')
    scope            = _field(r'\*\*What\'s the scope\?\*\*\s*\n([^\n]+)')
    critical_feature = _field(r'\*\*What\'s the critical feature to validate\?\*\*\s*\n([^\n]+)')
    time_budget      = _field(r'\*\*How much time are you dedicating\?\*\*\s*\n([^\n]+)')
    name             = project_label(journal_path)

    active = {
        "project_name": name,
        "project_path": str(project_path),
        "journal_path": str(journal_path),
        "hypothesis":   hypothesis,
        "time_budget":  time_budget,
        "opened_at":    datetime.now().isoformat(timespec="seconds"),
    }
    ACTIVE_FILE.write_text(json.dumps(active, indent=2))

    lines        = journal_text.splitlines()
    recent_lines = lines[-40:] if len(lines) > 40 else lines
    recent       = "\n".join(recent_lines).strip()

    CONTEXT_FILE.write_text(
        f"# Active Makerbook Project: {name}\n\n"
        f"**Journal:** `{journal_path}`\n"
        f"**Hypothesis:** {hypothesis or '—'}\n"
        f"**Scope:** {scope or '—'}\n"
        f"**Critical feature:** {critical_feature or '—'}\n"
        f"**Time budget:** {time_budget or '—'}\n"
        f"**Opened:** {active['opened_at']}\n\n"
        f"## Recent Journal\n```\n{recent}\n```\n\n"
        f"---\n*Written by makerbook. "
        f"Other tools can read `~/.makerbook/active.json` for structured data.*\n"
    )

    _write_project_claude_md(journal_path, active, scope, critical_feature, time_budget)


def _write_project_claude_md(
    journal_path: Path,
    active: dict,
    scope: str,
    critical_feature: str,
    time_budget: str,
) -> None:
    """Write or update CLAUDE.md at the project root.

    Content above _DIVIDER is regenerated. Content below (hand-written
    notes) is preserved across updates.
    """
    project_path = journal_path.parent.parent
    claude_md    = project_path / "CLAUDE.md"
    name         = active["project_name"]
    hypothesis   = active["hypothesis"]
    journal_rel  = journal_path.relative_to(project_path)

    header = (
        f"# {name}\n\n"
        f"> This file is auto-maintained by makerbook. You can add notes below the divider.\n\n"
        f"## Project Intent\n"
        f"**Hypothesis:** {hypothesis or '—'}\n"
        f"**Scope:** {scope or '—'}\n"
        f"**Critical feature to validate:** {critical_feature or '—'}\n"
        f"**Time budget:** {time_budget or '—'}\n\n"
        f"## Journal\n"
        f"The project journal lives at `{journal_rel}`. Read it for full context.\n"
        f"Screenshots are in `makerbook/assets/`.\n\n"
        f"## Makerbook Conventions\n"
        f"- Journal entries are timestamped markdown: `DDMMYYYY - HH:MM - <note>`\n"
        f"- `@claude` entries show conversations: `**you:** / **claude:**`\n"
        f"- `@screenshot` entries embed PNG links\n"
        f"- Use `python3 makerbook.py` to open the TUI\n\n"
        f"## Claude Code Integration\n"
        f"- Claude Code Stop hook appends session summaries to `{journal_rel}`\n"
        f"- `git commit` via Claude Code is logged automatically\n"
        f"- Active project context: `~/.makerbook/active.json`\n\n"
        f"---\n{_DIVIDER}\n"
    )

    custom_suffix = "\n"
    if claude_md.exists():
        existing = claude_md.read_text()
        if _DIVIDER in existing:
            custom_suffix = existing.split(_DIVIDER, 1)[1]

    claude_md.write_text(header + custom_suffix)


def clear_active_context() -> None:
    """Remove active.json when no project is open (session ended)."""
    if ACTIVE_FILE.exists():
        ACTIVE_FILE.unlink()
