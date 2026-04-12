"""ScrollableFile — Textual widget that renders the journal as markdown.

This is the main content pane of the editor.  It fills most of the screen
with a scrollable, formatted view of main.md.

Keyboard bindings:
- q / a  — scroll up / down (vi-style)
- Enter  — return focus to the command input
"""

from pathlib import Path

from rich.markdown import Markdown as RichMarkdown
from rich.text import Text
from textual.binding import Binding
from textual.containers import VerticalScroll
from textual.widgets import Input, Static

from src.journal.services.journal_service import read_journal


class ScrollableFile(VerticalScroll):
    """Scrollable markdown view of the project journal.

    Call :meth:`load` at any time to re-render (e.g. after a new entry).

    Usage::

        pane = ScrollableFile(id="file-pane")
        pane.load(journal_path)
    """

    can_focus = True

    BINDINGS = [
        Binding("q",     "scroll_up_step",  "Scroll up",   show=False),
        Binding("a",     "scroll_down_step", "Scroll down", show=False),
        Binding("enter", "focus_input",      "Type",        show=False),
    ]

    def compose(self):
        yield Static("", id="file-content")

    def load(self, journal_path: Path) -> None:
        """Re-render *journal_path* and scroll to the bottom."""
        content    = read_journal(journal_path)
        renderable = (
            RichMarkdown(content) if content.strip()
            else Text("  empty project.", style="dim")
        )
        self.query_one("#file-content", Static).update(renderable)
        self.scroll_end(animate=False)

    def action_scroll_up_step(self) -> None:
        self.scroll_up(animate=False)

    def action_scroll_down_step(self) -> None:
        self.scroll_down(animate=False)

    def action_focus_input(self) -> None:
        self.app.query_one("#cmd-input", Input).focus()
