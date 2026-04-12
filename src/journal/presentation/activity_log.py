"""ActivityLog — Textual widget that tails the journal for new events.

Sits in the lower portion of the editor and shows a live feed of
timestamped events.  Polls the journal file every 2 seconds and renders
new entries as they are appended.

Receives parsed :class:`JournalEntry` objects from
:mod:`src.journal.domain.journal_parser` — no raw text parsing here.
"""

from pathlib import Path

from textual.widgets import RichLog

from src.journal.models.journal_entry import JournalEntry
from src.journal.services.journal_service import read_journal
from src.journal.domain.journal_parser import parse_journal_events
from src.common.styles import CYAN


class ActivityLog(RichLog):
    """Always-visible live feed of journal events.

    Loads the last 20 events on mount and polls for new content every
    2 seconds (interval configured by EditorApp).

    Usage::

        log = ActivityLog(journal_path, id="activity-log")
        log.load_initial()
        # set_interval(2, log.poll) in EditorApp.on_mount
    """

    def __init__(self, journal_path: Path, **kwargs):
        super().__init__(markup=True, highlight=False, **kwargs)
        self.journal_path = journal_path
        self._last_size   = 0

    def load_initial(self) -> None:
        """Render the last 20 events and capture the current file size."""
        content         = read_journal(self.journal_path)
        self._last_size = self.journal_path.stat().st_size if self.journal_path.exists() else 0
        for entry in parse_journal_events(content)[-20:]:
            self._render(entry)

    def poll(self) -> None:
        """Check for new bytes appended to the journal and render them."""
        if not self.journal_path.exists():
            return
        size = self.journal_path.stat().st_size
        if size <= self._last_size:
            return
        with open(self.journal_path) as f:
            f.seek(self._last_size)
            new = f.read()
        self._last_size = size
        for entry in parse_journal_events(new):
            self._render(entry)

    def sync_size(self) -> None:
        """Advance the internal cursor after a manual journal write.

        Call this after appending programmatically to prevent the next
        poll from re-displaying content that was just written.
        """
        if self.journal_path.exists():
            self._last_size = self.journal_path.stat().st_size

    # ── Rendering ─────────────────────────────────────────────────────────────

    def _render(self, entry: JournalEntry) -> None:
        """Format and write a single journal entry to the log widget."""
        t, content, kind = entry.time, entry.content, entry.kind

        if kind == "claude_session":
            self.write(f"[dim]{t}[/dim]  [bold {CYAN}]@claude[/bold {CYAN}] session")
        elif kind == "claude_code":
            self.write(f"[dim]{t}[/dim]  [dim {CYAN}]claude code[/dim {CYAN}] session logged")
        elif kind == "commit":
            self.write(f"[dim]{t}[/dim]  [green]commit[/green]  {content[len('git commit:'):].strip()}")
        elif kind == "push":
            self.write(f"[dim]{t}[/dim]  [green]push[/green]")
        elif kind == "screenshot":
            self.write(f"[dim]{t}[/dim]  [yellow]screenshot[/yellow]")
        elif kind == "checkin":
            action = content[len("checkin:"):].strip()
            self.write(f"[dim]{t}[/dim]  [magenta]→[/magenta]  {action}")
        else:
            short = content[:72] + ("…" if len(content) > 72 else "")
            self.write(f"[dim]{t}[/dim]  {short}")
