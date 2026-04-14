"""interview_flow — questionary-based interview for new project intake.

Runs before the TUI when a maker opens a brand-new, empty project.
Shows QUESTIONS, collects answers, previews them in a panel, then writes
the formatted entry to the journal on confirmation.

Separation:
  - :mod:`src.python.journal.domain.interview` = pure data (schema + formatter)
  - This module = presentation (questionary prompts + Rich panel preview)
"""

from pathlib import Path

import questionary
from rich.panel import Panel
from rich.text import Text

from src.python.journal.services.journal_service import append_journal
from src.python.journal.domain.interview import QUESTIONS, format_entry
from src.python.common.styles import CYAN, STYLE, console


def run_interview() -> dict | None:
    """Run the structured intake interview in the terminal.

    Returns a dict of ``{key: answer}`` on completion, or ``None`` if the
    user cancelled (Ctrl+C or skipped a required question).
    """
    console.print()
    answers: dict = {}

    for q in QUESTIONS:
        prompt = q["label"] + ("" if q["required"] else "  (optional)")

        if "choices" in q:
            answer = questionary.select(
                prompt,
                choices=q["choices"] + ([] if q["required"] else ["↩ skip"]),
                style=STYLE,
            ).ask()
            if answer is None:
                return None
            if answer != "↩ skip":
                answers[q["key"]] = answer
        else:
            while True:
                answer = questionary.text(prompt, style=STYLE).ask()
                if answer is None:
                    return None
                val = answer.strip()
                if val:
                    answers[q["key"]] = val
                    break
                elif q["required"]:
                    console.print(Text("this answer is required.", style="dim red"))
                else:
                    break

    return answers


def confirm_and_write(journal_path: Path, answers: dict) -> bool:
    """Preview answers in a panel and, on confirmation, write to *journal_path*.

    Returns True if the entry was written, False if the user cancelled.
    """
    console.print()
    title = answers.get("name") or answers.get("hypothesis", "")[:48]
    lines = [f"[bold {CYAN}]{title}[/]", ""]
    for q in QUESTIONS:
        val = answers.get(q["key"])
        if val and q["key"] != "name":
            lines.append(f"[dim]{q['label']}[/]")
            lines.append(val)
            lines.append("")

    console.print(Panel("\n".join(lines).rstrip(), border_style=CYAN, padding=(1, 2)))
    console.print()

    confirmed = questionary.confirm("Write to makerbook?", default=True, style=STYLE).ask()
    if not confirmed:
        console.print(Text("discarded.", style="dim"))
        console.print()
        return False

    append_journal(journal_path, format_entry(answers))
    console.print()
    console.print(Text(f"written to {journal_path}", style=f"bold {CYAN}"))
    console.print()
    return True
