from prompt_toolkit.widgets import TextArea

from src.app.app_provider import AppProvider
from src.common.bloc import BlocListener
from src.log_history.log_history_bloc import MessageAdded

SCROLL_LINES = 5


def log_history_view(provider: AppProvider) -> TextArea:
    conversation = TextArea(
        text="",
        read_only=True,
        scrollbar=True,
        wrap_lines=True,
        focusable=True,
        style="class:conversation",
    )

    # ── BlocListener: state → UI ──────────────────────────────────────────────
    def on_state(state: MessageAdded) -> None:
        sep = "\n" if conversation.text else ""
        conversation.text += sep + f"[{state.ts}]  {state.sender}: {state.text}"
        conversation.buffer.cursor_position = len(conversation.buffer.text)

    BlocListener(provider.bloc, on_state)

    # ── Scroll helpers ────────────────────────────────────────────────────────
    def shift_cursor(delta: int) -> None:
        buf  = conversation.buffer
        text = buf.text
        pos  = buf.cursor_position

        if delta < 0:
            for _ in range(-delta):
                pos = text.rfind("\n", 0, pos)
                if pos <= 0:
                    pos = 0
                    break
        else:
            for _ in range(delta):
                nxt = text.find("\n", pos)
                if nxt == -1:
                    pos = len(text)
                    break
                pos = nxt + 1

        buf.cursor_position = pos

    @provider.kb.add("pageup")
    @provider.kb.add("c-up")
    def _(_): shift_cursor(-SCROLL_LINES)

    @provider.kb.add("pagedown")
    @provider.kb.add("c-down")
    def _(_): shift_cursor(SCROLL_LINES)

    return conversation
