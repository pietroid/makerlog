"""commands_service — @command registry with usage-frequency tracking.

Commands are stored in ~/.makerbook/commands.md as lines like:
    - @screenshot | takes a screenshot and saves to the document | 3

Returned sorted by usage so frequently-used commands appear first.
"""

import re
from pathlib import Path

from src.python.project.services.config_service import COMMANDS_FILE, ensure_global_dir

_COMMAND_DEFAULTS: list[dict] = [
    {"name": "@screenshot", "description": "takes a screenshot and saves to the document", "usage": 0},
    {"name": "@claude",     "description": "open a claude session, logged to journal",     "usage": 0},
    {"name": "@back",       "description": "return to project list",                        "usage": 0},
]


def read_commands() -> list[dict]:
    """Return all commands sorted by usage (descending).

    Defaults are backfilled for any command not yet in the file.
    """
    commands: list[dict] = []

    if COMMANDS_FILE.exists():
        for line in COMMANDS_FILE.read_text().splitlines():
            m = re.match(r'^\s*-\s+(@\S+)\s*\|\s*(.+?)\s*\|\s*(\d+)\s*$', line)
            if m:
                commands.append({
                    "name":        m.group(1),
                    "description": m.group(2).strip(),
                    "usage":       int(m.group(3)),
                })

    existing = {c["name"] for c in commands}
    for d in _COMMAND_DEFAULTS:
        if d["name"] not in existing:
            commands.append(dict(d))

    return sorted(commands, key=lambda c: c["usage"], reverse=True)


def write_commands(commands: list[dict]) -> None:
    """Persist the command list to commands.md."""
    ensure_global_dir()
    lines = ["# makerbook commands\n"]
    for c in sorted(commands, key=lambda c: c["usage"], reverse=True):
        lines.append(f"- {c['name']} | {c['description']} | {c['usage']}")
    COMMANDS_FILE.write_text("\n".join(lines) + "\n")


def increment_usage(cmd_name: str) -> None:
    """Increment the usage counter for *cmd_name* and persist it."""
    commands = read_commands()
    for c in commands:
        if c["name"] == cmd_name:
            c["usage"] += 1
            break
    write_commands(commands)
