"""file_manager — top-level project list and editor entry point.

The file manager is the first screen the user sees.  It lists known
projects, lets them create a new one, and launches the editor for the
selected project.  Control returns here after every editor session.

editor_loop() wraps a single editor session: starts the timer, runs the
new-project interview if needed, launches EditorApp, and persists elapsed
time on exit.
"""

import time
from pathlib import Path

import questionary
from rich.text import Text

from src.python.project.services.config_service import read_config, register_project
from src.python.project.services.context_service import write_active_context, clear_active_context
from src.python.journal.services.journal_service import project_label, read_journal
from src.python.header.domain.time_tracker import read_elapsed_seconds, write_elapsed_seconds
from src.python.journal.presentation.interview_flow import run_interview, confirm_and_write
from src.python.project.presentation.logo import print_logo, show_file
from src.python.common.styles import STYLE, console


def editor_loop(journal_path: Path) -> None:
    """Run a full editor session for *journal_path*.

    Handles project registration, context sync, first-entry interview,
    the Textual TUI, and time persistence on exit.
    """
    # Import here to avoid a circular import at module load time
    # (editor_app imports from project/conversation which imports from project)
    from src.python.editor_app import EditorApp

    register_project(journal_path)
    write_active_context(journal_path)
    session_start = time.time()

    if not read_journal(journal_path).strip():
        show_file(journal_path)
        label = project_label(journal_path)
        go = questionary.confirm(
            f"Start the first entry for '{label}'?",
            default=True,
            style=STYLE,
        ).ask()
        if not go:
            return

        answers = run_interview()
        if not answers:
            return
        written = confirm_and_write(journal_path, answers)
        if not written:
            return

    try:
        EditorApp(journal_path, session_start).run()
    finally:
        stored  = read_elapsed_seconds(journal_path)
        session = time.time() - session_start
        write_elapsed_seconds(journal_path, stored + session)
        clear_active_context()


def create_project() -> Path | None:
    """Prompt for a folder name and scaffold the makerbook directory.

    Returns the path to the new main.md, or None if the user cancelled.
    """
    console.print()
    name = questionary.text("Project folder name:", style=STYLE).ask()
    if not name or not name.strip():
        return None
    target = Path.cwd() / name.strip() / "makerbook"
    target.mkdir(parents=True, exist_ok=True)
    main_md = target / "main.md"
    console.print(Text(f"created {main_md}", style="dim"))
    console.print()
    return main_md


def file_manager() -> None:
    """Show the project list and dispatch to the editor or project creation.

    Always the landing layer — control returns here after every editor
    session so the maker can switch projects or quit cleanly.
    """
    while True:
        print_logo()
        config   = read_config()
        projects = config["projects"]

        choices: list = []
        for p in reversed(projects):
            mp    = Path(p)
            label = project_label(mp)
            choices.append(questionary.Choice(
                title=f"  {label}  [dim]{mp.parent.parent}[/dim]",
                value=p,
            ))

        choices.append(questionary.Choice(title="→  new project", value="__new__"))
        choices.append(questionary.Choice(title="   exit",        value="__exit__"))

        choice = questionary.select(
            "Open a project:" if projects else "No projects yet:",
            choices=choices,
            style=STYLE,
        ).ask()

        if choice is None or choice == "__exit__":
            console.print(Text("see you next time.", style="dim"))
            console.print()
            break
        elif choice == "__new__":
            main_md = create_project()
            if main_md:
                editor_loop(main_md)
        else:
            editor_loop(Path(choice))
