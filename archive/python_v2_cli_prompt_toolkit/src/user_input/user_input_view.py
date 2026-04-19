from prompt_toolkit.filters import has_focus
from prompt_toolkit.widgets import TextArea

from src.app.app_provider import AppProvider


def user_input_view(provider: AppProvider) -> TextArea:
    component = TextArea(
        height=1,
        prompt="› ",
        multiline=False,
        wrap_lines=False,
        style="class:input",
    )

    @provider.kb.add("enter", filter=has_focus(component))
    def _(_):
        text = component.text.strip()
        component.text = ""
        if text:
            provider.bloc.add_message("You", text)
            # ── Replace with your LLM call ─────────────────────────────────
            provider.bloc.add_message("Bot", f"(echo) {text}")

    return component
