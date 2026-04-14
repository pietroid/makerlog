"""JournalEntry — a single parsed event from a makerbook journal.

Each entry corresponds to a timestamped line in main.md, e.g.:
    10042026 - 14:32 - started working on auth flow
"""

from dataclasses import dataclass
from typing import Literal

EntryKind = Literal[
    "claude_session",
    "claude_code",
    "commit",
    "push",
    "screenshot",
    "checkin",
    "entry",
]


@dataclass
class JournalEntry:
    """A single parsed event from the journal.

    Attributes:
        time:    HH:MM timestamp extracted from the log line.
        content: The text after the timestamp (full raw content).
        kind:    Semantic category used by ActivityLog to decide rendering.
    """

    time: str
    content: str
    kind: EntryKind
