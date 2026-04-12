"""screenshot — capture the screen and log the result to the journal.

Uses macOS `screencapture` to save a PNG into the project's assets/
directory, then appends a markdown image link to main.md.
"""

import subprocess
from datetime import datetime
from pathlib import Path

from src.journal.services.journal_service import append_journal


def cmd_screenshot(journal_path: Path, on_error=None, on_success=None) -> bool:
    """Capture a screenshot and write it into the project assets.

    Args:
        journal_path: Path to the project's main.md.
        on_error:     Optional callback(message: str) called on failure.
        on_success:   Optional callback(rel_path: str) called on success.

    Returns:
        True if the screenshot was saved, False on any error.
    """
    assets_dir = journal_path.parent / "assets"
    assets_dir.mkdir(exist_ok=True)

    ts       = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = f"screenshot-{ts}.png"
    filepath = assets_dir / filename

    result = subprocess.run(["screencapture", "-x", str(filepath)])

    if result.returncode != 0 or not filepath.exists():
        if on_error:
            on_error("screenshot failed.")
        return False

    rel    = f"assets/{filename}"
    log_ts = datetime.now().strftime("%d%m%Y - %H:%M")
    append_journal(journal_path, f"\n{log_ts} - screenshot\n\n![{ts}]({rel})\n")

    if on_success:
        on_success(rel)
    return True
