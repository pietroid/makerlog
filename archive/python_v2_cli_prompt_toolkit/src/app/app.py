from prompt_toolkit import Application
from prompt_toolkit.layout import HSplit, Layout, Window
from prompt_toolkit.styles import Style

from src.app.app_provider import AppProvider
from src.header.header_view import header
from src.log_history.log_history_view import log_history_view
from src.user_input.user_input_view import user_input_view


def app() -> Application:
    provider = AppProvider()

    @provider.kb.add("c-c")
    @provider.kb.add("c-q")
    def _(event): event.app.exit()

    conversation = log_history_view(provider)
    _user_input  = user_input_view(provider)

    provider.bloc.add_message(
        "System",
        "Welcome! Type a message and press Enter. "
        "Scroll with PageUp / PageDown or Ctrl+↑/↓.",
    )

    style = Style.from_dict({
        "header":         "bold reverse",
        "header.title":   "bold",
        "header.hint":    "nobold fg:ansibrightblack",
        "header.ts":      "nobold",
        "rule":           "fg:ansibrightblack",
        "conversation":   "",
        "input":          "",
    })

    return Application(
        layout=Layout(
            HSplit([
                header(),
                Window(height=1, char="─", style="class:rule"),
                conversation,
                Window(height=1, char="─", style="class:rule"),
                _user_input,
            ]),
            focused_element=_user_input,
        ),
        key_bindings=provider.kb,
        style=style,
        full_screen=True,
        mouse_support=True,
    )
