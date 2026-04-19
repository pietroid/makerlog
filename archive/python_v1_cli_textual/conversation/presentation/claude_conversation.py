"""claude_conversation — Claude session logic for the EditorApp TUI.

This mixin encapsulates all state and behaviour for an inline Claude
session that runs inside the activity log.  When the user types @claude,
the input prompt switches to "you ›" and all subsequent messages are
routed through the Claude CLI until the session ends.

At session end, every turn is flushed to the journal as:

    DDMMYYYY - HH:MM - @claude
    **you:** <message>
    **claude:** <response>

Implemented as a mixin so EditorApp can compose it simply:
    class EditorApp(ClaudeConversationMixin, App): ...
"""

import subprocess
from datetime import datetime
from pathlib import Path

from textual import work
from textual.widgets import Input

from journal.services.journal_service import append_journal
from project.services.context_service import write_active_context
from common.styles import CYAN


class ClaudeConversationMixin:
    """Mixin that adds Claude session state and methods to EditorApp.

    Requires on ``self``:
        main_md (Path):               active journal path
        claude_mode (bool):           True while a session is active
        claude_turns (list[tuple]):   accumulated (user, claude) pairs
    """

    def _start_claude(self, seed: str) -> None:
        """Enter Claude mode and optionally send *seed* as the first message."""
        self.claude_mode  = True
        self.claude_turns = []
        self._activity().write("[dim]@claude — type 'done' to end[/dim]")
        self.query_one("#cmd-input", Input).placeholder = "you ›"
        if seed.strip():
            self._run_claude(seed.strip())

    def _end_claude_session(self) -> None:
        """Exit Claude mode and flush accumulated turns to the journal."""
        self.claude_mode = False
        if self.claude_turns:
            ts    = datetime.now().strftime("%d%m%Y - %H:%M")
            lines = [f"\n{ts} - @claude\n"]
            for u, c in self.claude_turns:
                lines.append(f"\n**you:** {u}\n\n**claude:** {c}\n")
            append_journal(self.main_md, "".join(lines))
            self._activity().sync_size()
            self._reload_file()
            write_active_context(self.main_md)
        self.query_one("#cmd-input", Input).placeholder = "›"

    @work(thread=True)
    def _run_claude(self, user_input: str) -> None:
        """Send *user_input* to the Claude CLI in a background thread.

        Posts results back to the main thread via ``call_from_thread``.
        """
        t = datetime.now().strftime("%H:%M")
        self.call_from_thread(
            self._activity().write,
            f"[dim]{t}[/dim]  [bold {CYAN}]you[/bold {CYAN}]  {user_input}",
        )

        result = subprocess.run(
            ["claude", "--print", user_input],
            capture_output=True, text=True,
        )

        if result.returncode != 0:
            err = (result.stderr or "unknown error").strip()
            self.call_from_thread(self._activity().write, f"[red]error:[/red] {err}")
            return

        response = result.stdout.strip()
        short    = response[:200] + ("…" if len(response) > 200 else "")
        t2       = datetime.now().strftime("%H:%M")
        self.call_from_thread(
            self._activity().write,
            f"[dim]{t2}[/dim]  [dim {CYAN}]claude[/dim {CYAN}]  {short}",
        )
        self.claude_turns.append((user_input, response))
