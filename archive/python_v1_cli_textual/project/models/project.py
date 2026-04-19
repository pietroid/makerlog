"""Project — structured metadata about the currently open makerbook project.

This is the shape written to ~/.makerbook/active.json so that external
tools (Claude Code hooks, shell scripts) can consume it without parsing
the raw markdown journal.
"""

from dataclasses import dataclass
from pathlib import Path


@dataclass
class Project:
    """All metadata for an open makerbook project.

    Attributes:
        name:         Human-readable project name (parent folder name).
        project_path: Root directory of the project.
        journal_path: Full path to makerbook/main.md.
        hypothesis:   What the maker is trying to solve.
        time_budget:  Raw time budget string, e.g. "16h — 2 full days".
        opened_at:    ISO-8601 timestamp of when the session started.
    """

    name: str
    project_path: Path
    journal_path: Path
    hypothesis: str = ""
    time_budget: str = ""
    opened_at: str = ""

    def to_dict(self) -> dict:
        """Serialize to the active.json schema."""
        return {
            "project_name": self.name,
            "project_path": str(self.project_path),
            "journal_path": str(self.journal_path),
            "hypothesis":   self.hypothesis,
            "time_budget":  self.time_budget,
            "opened_at":    self.opened_at,
        }
