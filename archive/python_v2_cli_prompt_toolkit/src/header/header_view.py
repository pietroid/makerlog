from datetime import datetime

from prompt_toolkit.formatted_text import FormattedText
from prompt_toolkit.layout import FormattedTextControl, Window


def get_header() -> FormattedText:
        ts = datetime.now().strftime("%H:%M")
        return FormattedText([
            ("#A2FF00 bold", "questbook"),
            ("", "\n"),
            ("", "\n"),
            ("#ffffff", f"{ts}"),
        ])

def header() -> Window:
    return Window(
        content=FormattedTextControl(get_header),
        height=3,
    )
