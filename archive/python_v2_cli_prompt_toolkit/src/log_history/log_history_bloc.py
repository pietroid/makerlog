from dataclasses import dataclass, field
from datetime import datetime

from src.common.bloc import Bloc


# ── States ────────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class MessageAdded:
    sender: str
    text:   str
    ts:     str = field(default_factory=lambda: datetime.now().strftime("%H:%M"))


# ── Bloc ──────────────────────────────────────────────────────────────────────

class LogHistoryBloc(Bloc[MessageAdded]):
    """Owns the conversation history.

    The only way to add a message is through add_message(), which emits a
    MessageAdded state.  The UI reacts via a BlocListener — the bloc itself
    has no knowledge of prompt_toolkit or any widget.
    """

    def add_message(self, sender: str, text: str) -> None:
        self.emit(MessageAdded(sender=sender, text=text))
