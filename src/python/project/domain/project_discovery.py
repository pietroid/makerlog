"""project_discovery — locate the nearest makerbook journal on the filesystem.

Discovery walks up from the current working directory looking for a
`makerbook/` subfolder, mirroring how tools like git find their `.git`
directory.
"""

from pathlib import Path


def find_nearest_makerbook() -> Path | None:
    """Walk up from cwd until a ``makerbook/main.md`` is found.

    Returns the absolute path to main.md, or ``None`` if no makerbook
    directory exists in the current directory or any of its ancestors.
    """
    current = Path.cwd()
    for directory in [current, *current.parents]:
        candidate = directory / "makerbook"
        if candidate.is_dir():
            return candidate / "main.md"
    return None
