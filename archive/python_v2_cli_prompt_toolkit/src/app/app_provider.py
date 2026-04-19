from prompt_toolkit.key_binding import KeyBindings

from src.log_history.log_history_bloc import LogHistoryBloc


class AppProvider:
    """Single source of shared dependencies.

    Created once in app.py and passed to every widget that needs kb or bloc.
    Widgets access provider.kb / provider.bloc instead of receiving them as
    separate parameters.
    """

    def __init__(self) -> None:
        self.kb   = KeyBindings()
        self.bloc = LogHistoryBloc()
