"""config_service — manage the global ~/.makerbook/ directory and config.md.

The global directory holds:
- config.md   : last-opened project + list of known projects
- commands.md : @command registry with usage counters
- active.json : currently open project (written when a session starts)
- context.md  : human-readable version of active.json for Claude Code

All global paths are defined here so every other module imports from
one place.
"""

import re
from pathlib import Path

# ── Global paths ──────────────────────────────────────────────────────────────

GLOBAL_DIR     = Path.home() / ".makerbook"
CONFIG_FILE    = GLOBAL_DIR / "config.md"
COMMANDS_FILE  = GLOBAL_DIR / "commands.md"
ACTIVE_FILE    = GLOBAL_DIR / "active.json"
CONTEXT_FILE   = GLOBAL_DIR / "context.md"


def ensure_global_dir() -> None:
    """Create ~/.makerbook/ if it does not yet exist."""
    GLOBAL_DIR.mkdir(parents=True, exist_ok=True)


def read_config() -> dict:
    """Parse config.md and return ``{"last_opened": str|None, "projects": [str]}``.

    Missing or invalid entries are silently skipped.
    """
    config: dict = {"last_opened": None, "projects": []}
    if not CONFIG_FILE.exists():
        return config

    text = CONFIG_FILE.read_text()

    lo = re.search(r'## last opened\n(.+)', text, re.IGNORECASE)
    if lo:
        p = lo.group(1).strip()
        if p and Path(p).exists():
            config["last_opened"] = p

    proj = re.search(r'## projects\n((?:- .+\n?)*)', text, re.IGNORECASE | re.DOTALL)
    if proj:
        for line in proj.group(1).splitlines():
            m = re.match(r'- (.+)', line.strip())
            if m:
                p = m.group(1).strip()
                if p and Path(p).exists() and p not in config["projects"]:
                    config["projects"].append(p)

    return config


def write_config(last_opened: str | None, projects: list[str]) -> None:
    """Persist last-opened path and full project list to config.md."""
    ensure_global_dir()
    lines = [
        "# makerbook config\n",
        "## last opened",
        last_opened or "",
        "",
        "## projects",
        *[f"- {p}" for p in projects],
        "",
    ]
    CONFIG_FILE.write_text("\n".join(lines))


def register_project(journal_path: Path) -> None:
    """Add *journal_path* to the known-projects list and mark it as last opened."""
    config   = read_config()
    projects = config["projects"]
    path_str = str(journal_path)
    if path_str not in projects:
        projects.append(path_str)
    write_config(path_str, projects)
