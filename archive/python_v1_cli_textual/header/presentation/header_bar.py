"""HeaderBar — Textual widget showing project name, goal, and time progress.

The header is a fixed 3-line bar at the top of the editor:

    myproject  ·  What are you trying to solve?
    10042026  ·  47min / 960min (5%)

Refreshes every 30 seconds (interval set by EditorApp).
"""

import re
from datetime import datetime
from pathlib import Path

from rich.text import Text
from textual.widgets import Static

from journal.services.journal_service import project_label, read_journal
from header.domain.time_tracker import format_progress
from common.styles import CYAN


class HeaderBar(Static):
    """Fixed top bar showing project context and time budget progress.

    Args:
        journal_path:  Path to the project's main.md.
        session_start: Unix timestamp from ``time.time()`` at session open.

    Call :meth:`refresh_content` to redraw.  EditorApp wires this to a
    30-second interval timer.
    """

    def __init__(self, journal_path: Path, session_start: float, **kwargs):
        super().__init__("", **kwargs)
        self.journal_path  = journal_path
        self.session_start = session_start

    def refresh_content(self) -> None:
        """Re-read the journal and redraw the header bar."""
        name    = project_label(self.journal_path)
        content = read_journal(self.journal_path)

        m    = re.search(r'\*\*What are you trying to solve\?\*\*\s*\n([^\n]+)', content)
        goal = m.group(1).strip() if m else ""
        if len(goal) > 64:
            goal = goal[:64] + "…"

        prog     = format_progress(self.journal_path, self.session_start)
        date_str = datetime.now().strftime("%d%m%Y")
        right    = f"{date_str}  ·  {prog}" if prog else date_str

        text = Text()
        text.append(name, style=f"bold {CYAN}")
        if goal:
            text.append(f"  ·  {goal}", style="dim")
        text.append(f"\n{right}", style="dim")
        self.update(text)
