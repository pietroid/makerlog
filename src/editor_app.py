"""editor_app — the main Textual TUI application.

EditorApp sits at the top of src/ because it is the composition root: it
wires together all four features (journal, header, conversation, project)
into one screen.

Layout:

  ┌──────────────────────────────────┐
  │  HeaderBar  (project · goal · t) │  ← refreshes every 30s
  ├──────────────────────────────────┤
  │                                  │
  │  ScrollableFile  (main.md)       │  ← markdown journal, scrollable
  │                                  │
  ├──────────────────────────────────┤
  │  ActivityLog  (live feed)        │  ← tails journal, polls every 2s
  ├──────────────────────────────────┤
  │  Input  (command / note / chat)  │  ← always focused
  └──────────────────────────────────┘

Interaction flows:
  - Free text            → timestamped journal entry + ollama check-in
  - @claude [prompt]     → inline Claude session (ClaudeConversationMixin)
  - @screenshot          → screenshot captured and linked
  - @back / q            → exit to file manager
"""

from datetime import datetime
from pathlib import Path

from textual.app import App, ComposeResult
from textual.widgets import Input
from textual import work

from src.journal.services.journal_service import append_journal, read_journal
from src.project.services.context_service import write_active_context
from src.project.services.commands_service import increment_usage
from src.conversation.services.ollama_service import call_ollama_checkin
from src.journal.domain.screenshot import cmd_screenshot
from src.common.styles import APP_CSS, CYAN
from src.header.presentation.header_bar import HeaderBar
from src.journal.presentation.scrollable_file import ScrollableFile
from src.journal.presentation.activity_log import ActivityLog
from src.conversation.presentation.claude_conversation import ClaudeConversationMixin


class EditorApp(ClaudeConversationMixin, App):
    """Four-pane Textual editor for a single makerbook project.

    Args:
        journal_path:  Path to the project's main.md.
        session_start: Unix timestamp (``time.time()``) at session open.
    """

    CSS = APP_CSS

    def __init__(self, journal_path: Path, session_start: float):
        super().__init__()
        self.main_md         = journal_path      # alias used by ClaudeConversationMixin
        self.session_start   = session_start
        self.claude_mode     = False
        self.claude_turns:   list[tuple[str, str]] = []
        self.checkin_choices: list[str] = []

    # ── Composition ───────────────────────────────────────────────────────────

    def compose(self) -> ComposeResult:
        yield HeaderBar(self.main_md, self.session_start, id="header-bar")
        yield ScrollableFile(id="file-pane")
        yield ActivityLog(self.main_md, id="activity-log")
        yield Input(id="cmd-input", placeholder="›")

    def on_mount(self) -> None:
        self.query_one("#header-bar",   HeaderBar).refresh_content()
        self.query_one("#file-pane",    ScrollableFile).load(self.main_md)
        self.query_one("#activity-log", ActivityLog).load_initial()
        self.query_one("#cmd-input",    Input).focus()
        self.set_interval(30, self.query_one("#header-bar",   HeaderBar).refresh_content)
        self.set_interval(2,  self.query_one("#activity-log", ActivityLog).poll)

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _activity(self) -> ActivityLog:
        return self.query_one("#activity-log", ActivityLog)

    def _reload_file(self) -> None:
        self.query_one("#file-pane", ScrollableFile).load(self.main_md)

    # ── Keys ──────────────────────────────────────────────────────────────────

    def action_quit(self) -> None:
        if self.claude_mode:
            self._end_claude_session()
        else:
            self.exit(result="back")

    def on_key(self, event) -> None:
        if event.key == "space" and isinstance(self.focused, Input):
            self.query_one("#cmd-input", Input).insert_text_at_cursor(" ")
            event.prevent_default()
        elif event.key == "escape":
            self.query_one("#file-pane", ScrollableFile).focus()
            event.stop()

    # ── Input routing ─────────────────────────────────────────────────────────

    def on_input_submitted(self, event: Input.Submitted) -> None:
        """Route submitted text to the correct handler based on app state."""
        val = event.value.strip()
        event.input.value = ""

        if not val:
            if self.checkin_choices:
                self._dismiss_checkin()
            return

        if self.checkin_choices:
            self._handle_checkin_choice(val)
            return

        if self.claude_mode:
            if val.lower() in ("done", "exit", "quit"):
                self._end_claude_session()
            else:
                self._run_claude(val)
        elif val.startswith("@"):
            self._dispatch_command(val)
        else:
            ts = datetime.now().strftime("%d%m%Y - %H:%M")
            append_journal(self.main_md, f"\n{ts} - {val}\n")
            self._reload_file()
            write_active_context(self.main_md)
            self._start_checkin()

    # ── Check-in ──────────────────────────────────────────────────────────────

    @work(thread=True)
    def _start_checkin(self) -> None:
        """Ask Ollama for a check-in question in a background thread."""
        result = call_ollama_checkin(read_journal(self.main_md))
        if not result:
            self.call_from_thread(
                self._activity().write,
                "[dim]checkin unavailable — is ollama running? (`ollama serve`)[/dim]",
            )
            return
        if not result.question or not result.choices:
            return
        self.call_from_thread(self._show_checkin, result.question, result.choices)

    def _show_checkin(self, question: str, choices: list[str]) -> None:
        self.checkin_choices = choices
        log = self._activity()
        log.write(f"\n[bold {CYAN}]?[/bold {CYAN}]  {question}")
        for i, c in enumerate(choices, 1):
            log.write(f"  [dim]{i}.[/dim]  {c}")
        self.query_one("#cmd-input", Input).placeholder = f"› 1–{len(choices)}  (enter to skip)"

    def _handle_checkin_choice(self, val: str) -> None:
        try:
            idx = int(val.strip()) - 1
            if 0 <= idx < len(self.checkin_choices):
                choice = self.checkin_choices[idx]
                ts = datetime.now().strftime("%d%m%Y - %H:%M")
                append_journal(self.main_md, f"\n{ts} - checkin: {choice}\n")
                self._activity().sync_size()
                self._activity().write(f"[dim]→[/dim]  [magenta]{choice}[/magenta]")
                self._reload_file()
            else:
                self._activity().write(f"[dim]type 1–{len(self.checkin_choices)} or enter to skip[/dim]")
                return
        except ValueError:
            pass
        self._dismiss_checkin()

    def _dismiss_checkin(self) -> None:
        self.checkin_choices = []
        self.query_one("#cmd-input", Input).placeholder = "›"

    # ── @command dispatch ─────────────────────────────────────────────────────

    def _dispatch_command(self, cmd_str: str) -> None:
        """Parse and execute an @command entered in the input bar."""
        parts = cmd_str.strip().split(None, 1)
        cmd   = parts[0].lower()
        args  = parts[1] if len(parts) > 1 else ""

        if cmd in ("@", "@help", "@?"):
            self._activity().write("[dim]@screenshot  @claude [prompt]  @back[/dim]")
        elif cmd == "@screenshot":
            increment_usage("@screenshot")
            cmd_screenshot(
                self.main_md,
                on_error=lambda msg: self._activity().write(f"[red]{msg}[/red]"),
                on_success=lambda rel: self._activity().write(f"[yellow]screenshot[/yellow] → {rel}"),
            )
            self._reload_file()
        elif cmd == "@claude":
            increment_usage("@claude")
            self._start_claude(args)
        elif cmd == "@back":
            increment_usage("@back")
            self.exit(result="back")
        else:
            self._activity().write(f"[red]unknown '{cmd_str}' — type @ for help[/red]")
