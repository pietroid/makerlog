from typing import Callable, Generic, TypeVar

S = TypeVar("S")


class Bloc(Generic[S]):
    """Base class for all blocs.

    Subclasses call self.emit(state) to push a new state to every listener.
    Listeners are registered with on_state() and called synchronously in the
    order they were added — safe for prompt_toolkit's single-threaded event loop.
    """

    def __init__(self) -> None:
        self._listeners: list[Callable[[S], None]] = []

    def emit(self, state: S) -> None:
        """Push state to every registered listener."""
        for listener in self._listeners:
            listener(state)

    def on_state(self, listener: Callable[[S], None]) -> Callable[[], None]:
        """Register a listener.  Returns an unsubscribe callable."""
        self._listeners.append(listener)
        return lambda: self._listeners.remove(listener)


class BlocListener(Generic[S]):
    """Binds one callback to a Bloc's state stream.

    The callback fires synchronously every time the bloc emits a state.
    Call close() to unsubscribe.

    Usage:
        listener = BlocListener(my_bloc, lambda state: ...)
        ...
        listener.close()   # stop listening
    """

    def __init__(self, bloc: Bloc[S], on_state: Callable[[S], None]) -> None:
        self._unsubscribe = bloc.on_state(on_state)

    def close(self) -> None:
        self._unsubscribe()
