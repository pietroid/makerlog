"""journal_parser — convert raw journal text into structured JournalEntry objects.

The parser understands the makerbook timestamp format:

    DDMMYYYY - HH:MM - <content>

and classifies each entry into a semantic *kind* so the ActivityLog
widget can render it with the right colour without knowing anything
about the raw text format.
"""

import re
from src.journal.models.journal_entry import JournalEntry


def parse_journal_events(text: str) -> list[JournalEntry]:
    """Parse *text* and return a list of :class:`JournalEntry` objects.

    Lines that do not match the timestamp format are silently skipped.
    Entries with empty content (after stripping) are also skipped.
    """
    events: list[JournalEntry] = []
    for line in text.splitlines():
        m = re.match(r'^(\d{8})\s*-\s*(\d{2}:\d{2})\s*-\s*(.*)', line.strip())
        if not m:
            continue
        content = m.group(3).strip()
        if not content:
            continue
        events.append(JournalEntry(time=m.group(2), content=content, kind=_classify(content)))
    return events


def _classify(content: str) -> str:
    """Return the entry kind based on the content prefix."""
    if content.startswith("@claude"):
        return "claude_session"
    if content.startswith("claude code session"):
        return "claude_code"
    if content.startswith("git commit:"):
        return "commit"
    if content.startswith("git push"):
        return "push"
    if content.startswith("screenshot"):
        return "screenshot"
    if content.startswith("checkin:"):
        return "checkin"
    return "entry"
