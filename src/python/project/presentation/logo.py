"""logo — Rich terminal views that run outside the Textual TUI.

These functions render to stdout before the TUI launches or after it
exits.  Each is a self-contained view: call it and it prints.
"""

from pathlib import Path

from rich.markdown import Markdown as RichMarkdown
from rich.rule import Rule
from rich.text import Text

from src.python.journal.services.journal_service import project_label, read_journal
from src.python.common.styles import CYAN, console


def print_logo() -> None:
    """Print the makerbook wordmark and tagline."""
    console.print()
    console.print(
        Text.assemble(Text("maker", style="bold white"), Text("book", style=f"bold {CYAN}")),
        justify="center",
    )
    console.print(Text("build with intention.", style="dim"), justify="center")
    console.print()


def show_file(journal_path: Path) -> None:
    """Render *journal_path* to the terminal as a formatted document view."""
    label   = project_label(journal_path)
    content = read_journal(journal_path)
    console.print()
    console.print(Rule(
        title=f"[bold {CYAN}]{label}[/]  [dim]{journal_path}[/]",
        style="dim",
    ))
    console.print()
    if content.strip():
        console.print(RichMarkdown(content))
    else:
        console.print(Text("  empty project.", style="dim"))
    console.print()
    console.print(Rule(style="dim"))
    console.print()


def show_commands() -> None:
    """Print the available @commands to the terminal."""
    console.print()
    console.print(Text("commands:", style="dim"))
    console.print(Text("  @screenshot         capture screen → assets/ + link in main.md", style=f"bold {CYAN}"))
    console.print(Text("  @claude [prompt]    open a claude session, logged to journal",    style=f"bold {CYAN}"))
    console.print(Text("  @back               return to project list",                      style=f"bold {CYAN}"))
    console.print()
