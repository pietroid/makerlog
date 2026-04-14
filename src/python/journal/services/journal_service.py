"""journal_service — read and write the per-project main.md journal file.

The journal is a plain markdown file where every entry follows the
timestamped format:

    DDMMYYYY - HH:MM - <note>

This service owns all I/O for that file and nothing else — no parsing
of structured fields, no business logic.
"""

from pathlib import Path


def project_label(journal_path: Path) -> str:
    """Return the human-readable project name (the grandparent folder name).

    Given  ~/projects/myapp/makerbook/main.md  →  "myapp".
    """
    return journal_path.parent.parent.name


def read_journal(journal_path: Path) -> str:
    """Return the full text of the journal, or an empty string if missing."""
    return journal_path.read_text() if journal_path.exists() else ""


def append_journal(journal_path: Path, content: str) -> None:
    """Append *content* to the journal, creating parent directories if needed."""
    journal_path.parent.mkdir(parents=True, exist_ok=True)
    with open(journal_path, "a") as f:
        f.write(content)
