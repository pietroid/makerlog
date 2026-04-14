"""styles — shared visual constants used across all features.

All colours, the questionary Style object, and the Textual app CSS live
here so every widget and screen imports from a single source of truth.
Changing CYAN here changes the whole app.
"""

from rich.console import Console
from questionary import Style

# ── Colour palette ────────────────────────────────────────────────────────────

CYAN = "#00d7ff"

# ── Shared Rich console ───────────────────────────────────────────────────────

console = Console()

# ── Questionary prompt style ──────────────────────────────────────────────────

STYLE = Style([
    ("qmark",       f"fg:{CYAN} bold"),
    ("question",    "bold"),
    ("answer",      f"fg:{CYAN} bold"),
    ("pointer",     f"fg:{CYAN} bold"),
    ("highlighted", f"fg:{CYAN} bold"),
    ("selected",    f"fg:{CYAN}"),
    ("separator",   "fg:#6c6c6c"),
    ("instruction", "fg:#6c6c6c"),
])

# ── Textual EditorApp CSS ─────────────────────────────────────────────────────

APP_CSS = f"""
#header-bar {{
    height: 3;
    padding: 0 2;
    background: $surface-darken-1;
    border-bottom: solid $surface-darken-2;
}}
ScrollableFile {{
    height: 1fr;
    padding: 1 2;
    border-bottom: solid $surface-darken-2;
}}
#activity-log {{
    height: 9;
    background: $surface-darken-1;
    border-bottom: solid $surface-darken-2;
    padding: 0 1;
}}
#cmd-input {{
    dock: bottom;
    border-top: tall {CYAN};
}}
#cmd-input:focus {{
    border-top: tall {CYAN};
}}
"""
