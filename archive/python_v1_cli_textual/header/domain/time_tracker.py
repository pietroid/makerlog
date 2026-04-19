"""time_tracker — parse and persist the per-session time budget.

The time budget is stored as a human string in the journal
(e.g. "16h — 2 full days").  Elapsed seconds accumulate in a hidden
`.time` file next to main.md so progress survives restarts.

Primary consumer: HeaderBar (displays progress) and editor_loop
(persists elapsed time when the session ends).
"""

import re
import time
from pathlib import Path

from journal.services.journal_service import read_journal


def parse_budget_minutes(journal_text: str) -> int | None:
    """Extract the total time budget in minutes from the journal text.

    Understands "Xh" and "Xm" suffixes. Returns ``None`` if not found.
    """
    m = re.search(r'\*\*How much time are you dedicating\?\*\*\s*\n([^\n]+)', journal_text)
    if not m:
        return None
    val   = m.group(1).strip()
    hours = re.search(r'(\d+)\s*h', val)
    if hours:
        return int(hours.group(1)) * 60
    mins = re.search(r'(\d+)\s*m', val)
    if mins:
        return int(mins.group(1))
    return None


def _time_file(journal_path: Path) -> Path:
    return journal_path.parent / ".time"


def read_elapsed_seconds(journal_path: Path) -> float:
    """Return total seconds worked on this project across all sessions."""
    tf = _time_file(journal_path)
    if tf.exists():
        try:
            return float(tf.read_text().strip())
        except ValueError:
            pass
    return 0.0


def write_elapsed_seconds(journal_path: Path, seconds: float) -> None:
    """Persist *seconds* to the .time accumulator file."""
    _time_file(journal_path).write_text(str(seconds))


def format_progress(journal_path: Path, session_start: float) -> str | None:
    """Return a progress string like ``"47min / 960min (5%)"``.

    Returns ``None`` when no time budget is set in the journal.
    """
    content = read_journal(journal_path)
    budget  = parse_budget_minutes(content)
    if not budget:
        return None
    stored  = read_elapsed_seconds(journal_path)
    current = stored + (time.time() - session_start)
    elapsed = int(current / 60)
    pct     = min(100, int(elapsed / budget * 100))
    return f"{elapsed}min / {budget}min ({pct}%)"
