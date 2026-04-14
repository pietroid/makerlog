"""interview — question schema and entry formatter for new projects.

QUESTIONS defines the structured intake form that runs the first time a
maker opens a new project.  format_entry() converts the collected answers
into the markdown block that is appended to the journal.

This module has no I/O and no UI — it only transforms data.
"""

from datetime import datetime

QUESTIONS: list[dict] = [
    {
        "key":      "hypothesis",
        "label":    "What are you trying to solve?",
        "required": True,
    },
    {
        "key":      "name",
        "label":    "Project name",
        "required": False,
    },
    {
        "key":      "scope",
        "label":    "What's the scope?",
        "required": False,
    },
    {
        "key":      "critical_feature",
        "label":    "What's the critical feature to validate?",
        "required": False,
    },
    {
        "key":      "time",
        "label":    "How much time are you dedicating?",
        "required": False,
        "choices":  ["2h", "4h", "8h", "16h — 2 full days"],
    },
]


def format_entry(answers: dict) -> str:
    """Convert interview *answers* into a markdown journal entry string.

    The returned string is ready to be appended to main.md as-is.
    """
    title = answers.get("name") or answers["hypothesis"][:48]
    date  = datetime.now().strftime("%Y-%m-%d")
    parts = [f"\n---\n\n## {title} — {date}\n"]
    for q in QUESTIONS:
        val = answers.get(q["key"])
        if val and q["key"] != "name":
            parts.append(f"\n**{q['label']}**\n{val}\n")
    return "".join(parts)
