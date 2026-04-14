"""main — entry point for the makerbook CLI.

Start order:
1. If there is a makerbook/ directory in (or above) cwd, open it directly.
2. If not, fall back to the last-opened project from config.
3. Always drop into the file manager so the user can switch projects.
"""

from pathlib import Path

from src.python.project.services.config_service import ensure_global_dir, read_config
from src.python.project.domain.project_discovery import find_nearest_makerbook
from src.python.project.presentation.file_manager import editor_loop, file_manager


def main() -> None:
    ensure_global_dir()

    journal_path = find_nearest_makerbook()

    if journal_path is None:
        config = read_config()
        if config["last_opened"]:
            journal_path = Path(config["last_opened"])

    if journal_path is not None:
        editor_loop(journal_path)

    file_manager()
